import XCTest
import SwiftUI
import SwiftData
@testable import CodeDump

/// Snapshot / screenshot tests for the Strava button in all visual states.
///
/// These render `WorkoutCompletedView` into a UIImage using `ImageRenderer`
/// and compare against stored reference images. On first run (or when
/// `RECORD_SNAPSHOTS=1`), reference images are written to disk.
///
/// Add to CI with: `xcodebuild test -scheme CodeDump -testPlan Snapshots`
@MainActor
final class StravaSnapshotTests: XCTestCase {

    private var container: ModelContainer!
    private var context: ModelContext!

    // Directory for reference images
    private var referenceDir: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("__Snapshots__", isDirectory: true)
            .appendingPathComponent("StravaSnapshotTests", isDirectory: true)
    }

    override func setUp() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(
            for: Workout.self, Exercise.self, WorkoutSession.self, SetLog.self,
            configurations: config
        )
        context = container.mainContext
        try FileManager.default.createDirectory(at: referenceDir, withIntermediateDirectories: true)
    }

    override func tearDown() async throws {
        container = nil
        context = nil
    }

    // MARK: - Helpers

    private func makeCompletedView(
        strava: StravaManager,
        workoutName: String = "TEST WORKOUT",
        totalTime: Int = 1800,
        exercises: Int = 5,
        sets: Int = 15
    ) -> some View {
        WorkoutCompletedView(
            totalTime: totalTime,
            exercisesCompleted: exercises,
            setsCompleted: sets,
            workoutName: workoutName,
            onDone: {}
        )
        .frame(width: 393, height: 852) // iPhone 15 Pro
        .environment(\.modelContext, context)
    }

    @MainActor
    private func renderImage(_ view: some View) -> UIImage? {
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2.0 // @2x
        return renderer.uiImage
    }

    private func assertSnapshot(
        _ image: UIImage?,
        named name: String,
        tolerance: CGFloat = 0.01,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard let image else {
            XCTFail("Failed to render image for snapshot '\(name)'", file: file, line: line)
            return
        }

        let referenceURL = referenceDir.appendingPathComponent("\(name).png")
        let isRecording = ProcessInfo.processInfo.environment["RECORD_SNAPSHOTS"] == "1"

        if isRecording || !FileManager.default.fileExists(atPath: referenceURL.path) {
            // Record mode: save reference image
            guard let pngData = image.pngData() else {
                XCTFail("Could not encode image as PNG", file: file, line: line)
                return
            }
            try? pngData.write(to: referenceURL)
            XCTFail("Recorded snapshot '\(name)'. Re-run without RECORD_SNAPSHOTS to verify.", file: file, line: line)
            return
        }

        // Compare mode
        guard let referenceData = try? Data(contentsOf: referenceURL),
              let referenceImage = UIImage(data: referenceData) else {
            XCTFail("Could not load reference image for '\(name)'", file: file, line: line)
            return
        }

        let diff = pixelDifference(between: image, and: referenceImage)
        XCTAssertLessThan(
            diff, tolerance,
            "Snapshot '\(name)' differs by \(String(format: "%.4f", diff)) (tolerance: \(tolerance)). "
            + "Run with RECORD_SNAPSHOTS=1 to update.",
            file: file, line: line
        )
    }

    /// Returns fraction of pixels that differ (0.0 = identical, 1.0 = completely different).
    private func pixelDifference(between imageA: UIImage, and imageB: UIImage) -> CGFloat {
        guard let cgA = imageA.cgImage, let cgB = imageB.cgImage else { return 1.0 }

        let width = min(cgA.width, cgB.width)
        let height = min(cgA.height, cgB.height)
        guard width > 0, height > 0 else { return 1.0 }

        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        let totalBytes = height * bytesPerRow

        var bufferA = [UInt8](repeating: 0, count: totalBytes)
        var bufferB = [UInt8](repeating: 0, count: totalBytes)

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue

        guard let ctxA = CGContext(data: &bufferA, width: width, height: height,
                                   bitsPerComponent: 8, bytesPerRow: bytesPerRow,
                                   space: colorSpace, bitmapInfo: bitmapInfo),
              let ctxB = CGContext(data: &bufferB, width: width, height: height,
                                   bitsPerComponent: 8, bytesPerRow: bytesPerRow,
                                   space: colorSpace, bitmapInfo: bitmapInfo) else {
            return 1.0
        }

        ctxA.draw(cgA, in: CGRect(x: 0, y: 0, width: width, height: height))
        ctxB.draw(cgB, in: CGRect(x: 0, y: 0, width: width, height: height))

        var differentPixels = 0
        let totalPixels = width * height
        for i in stride(from: 0, to: totalBytes, by: bytesPerPixel) {
            if bufferA[i] != bufferB[i] || bufferA[i+1] != bufferB[i+1] ||
               bufferA[i+2] != bufferB[i+2] || bufferA[i+3] != bufferB[i+3] {
                differentPixels += 1
            }
        }

        return CGFloat(differentPixels) / CGFloat(totalPixels)
    }

    // MARK: - Snapshot: Disconnected

    func testSnapshot_DisconnectedState() {
        let strava = StravaManager(tokenStore: MockTokenStore(), networkClient: MockNetworkClient())
        // Not connected — no token
        let view = makeCompletedView(strava: strava)
        let image = renderImage(view)
        assertSnapshot(image, named: "strava_disconnected")
    }

    // MARK: - Snapshot: Connected / Ready to Upload

    func testSnapshot_ConnectedReadyState() {
        let store = MockTokenStore()
        store.save(key: "strava_access_token", value: "tok")
        let strava = StravaManager(tokenStore: store, networkClient: MockNetworkClient())
        let view = makeCompletedView(strava: strava)
        let image = renderImage(view)
        assertSnapshot(image, named: "strava_connected_ready")
    }

    // MARK: - Snapshot: Upload Success

    func testSnapshot_UploadSuccessState() {
        let store = MockTokenStore()
        store.save(key: "strava_access_token", value: "tok")
        let strava = StravaManager(tokenStore: store, networkClient: MockNetworkClient())
        strava.uploadResult = .success
        let view = makeCompletedView(strava: strava)
        let image = renderImage(view)
        assertSnapshot(image, named: "strava_upload_success")
    }

    // MARK: - Snapshot: Upload Error

    func testSnapshot_UploadErrorState() {
        let store = MockTokenStore()
        store.save(key: "strava_access_token", value: "tok")
        let strava = StravaManager(tokenStore: store, networkClient: MockNetworkClient())
        strava.uploadResult = .error("Upload failed: Status 500")
        let view = makeCompletedView(strava: strava)
        let image = renderImage(view)
        assertSnapshot(image, named: "strava_upload_error")
    }

    // MARK: - Snapshot: Size Classes

    func testSnapshot_DisconnectedCompact() {
        let strava = StravaManager(tokenStore: MockTokenStore(), networkClient: MockNetworkClient())
        let view = makeCompletedView(strava: strava)
            .frame(width: 320, height: 568) // iPhone SE size
        let image = renderImage(view)
        assertSnapshot(image, named: "strava_disconnected_compact")
    }

    func testSnapshot_ConnectedLargeScreen() {
        let store = MockTokenStore()
        store.save(key: "strava_access_token", value: "tok")
        let strava = StravaManager(tokenStore: store, networkClient: MockNetworkClient())
        let view = makeCompletedView(strava: strava)
            .frame(width: 430, height: 932) // iPhone 15 Pro Max
        let image = renderImage(view)
        assertSnapshot(image, named: "strava_connected_large")
    }
}
