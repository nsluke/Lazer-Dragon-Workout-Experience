import SwiftUI

/// Provides SwiftUI Path geometry for a stylized human body silhouette,
/// with separate paths for each major muscle group region.
/// All coordinates are defined on a normalized 200×440 grid and scaled to the provided rect.
enum BodySilhouettePaths {

    enum Side { case front, back }

    // MARK: - Body Outline

    /// Full body outline (head, torso, arms, legs) for a dim border/wireframe.
    static func outline(side: Side, in rect: CGRect) -> Path {
        var path = Path()
        let s = scale(for: rect)

        // Head
        path.addEllipse(in: CGRect(
            x: rect.minX + 82 * s.x,
            y: rect.minY + 4 * s.y,
            width: 36 * s.x,
            height: 40 * s.y
        ))

        // Neck
        path.addRoundedRect(in: CGRect(
            x: rect.minX + 90 * s.x,
            y: rect.minY + 42 * s.y,
            width: 20 * s.x,
            height: 14 * s.y
        ), cornerSize: CGSize(width: 4 * s.x, height: 4 * s.y))

        // Torso
        path.addRoundedRect(in: CGRect(
            x: rect.minX + 62 * s.x,
            y: rect.minY + 54 * s.y,
            width: 76 * s.x,
            height: 120 * s.y
        ), cornerSize: CGSize(width: 12 * s.x, height: 12 * s.y))

        // Left arm
        path.addRoundedRect(in: CGRect(
            x: rect.minX + 30 * s.x,
            y: rect.minY + 60 * s.y,
            width: 28 * s.x,
            height: 100 * s.y
        ), cornerSize: CGSize(width: 10 * s.x, height: 10 * s.y))

        // Right arm
        path.addRoundedRect(in: CGRect(
            x: rect.minX + 142 * s.x,
            y: rect.minY + 60 * s.y,
            width: 28 * s.x,
            height: 100 * s.y
        ), cornerSize: CGSize(width: 10 * s.x, height: 10 * s.y))

        // Left leg
        path.addRoundedRect(in: CGRect(
            x: rect.minX + 62 * s.x,
            y: rect.minY + 178 * s.y,
            width: 34 * s.x,
            height: 150 * s.y
        ), cornerSize: CGSize(width: 10 * s.x, height: 10 * s.y))

        // Right leg
        path.addRoundedRect(in: CGRect(
            x: rect.minX + 104 * s.x,
            y: rect.minY + 178 * s.y,
            width: 34 * s.x,
            height: 150 * s.y
        ), cornerSize: CGSize(width: 10 * s.x, height: 10 * s.y))

        return path
    }

    // MARK: - Front Paths

    /// Chest — two pectoral regions on the front view.
    static func chestPath(in rect: CGRect) -> Path {
        let s = scale(for: rect)
        var path = Path()
        // Left pec
        path.addRoundedRect(in: CGRect(
            x: rect.minX + 64 * s.x,
            y: rect.minY + 58 * s.y,
            width: 34 * s.x,
            height: 30 * s.y
        ), cornerSize: CGSize(width: 8 * s.x, height: 8 * s.y))
        // Right pec
        path.addRoundedRect(in: CGRect(
            x: rect.minX + 102 * s.x,
            y: rect.minY + 58 * s.y,
            width: 34 * s.x,
            height: 30 * s.y
        ), cornerSize: CGSize(width: 8 * s.x, height: 8 * s.y))
        return path
    }

    /// Front shoulders — deltoid caps.
    static func frontShoulderPath(in rect: CGRect) -> Path {
        let s = scale(for: rect)
        var path = Path()
        // Left delt
        path.addEllipse(in: CGRect(
            x: rect.minX + 48 * s.x,
            y: rect.minY + 54 * s.y,
            width: 22 * s.x,
            height: 24 * s.y
        ))
        // Right delt
        path.addEllipse(in: CGRect(
            x: rect.minX + 130 * s.x,
            y: rect.minY + 54 * s.y,
            width: 22 * s.x,
            height: 24 * s.y
        ))
        return path
    }

    /// Front biceps.
    static func bicepsPath(in rect: CGRect) -> Path {
        let s = scale(for: rect)
        var path = Path()
        // Left bicep
        path.addRoundedRect(in: CGRect(
            x: rect.minX + 34 * s.x,
            y: rect.minY + 80 * s.y,
            width: 20 * s.x,
            height: 38 * s.y
        ), cornerSize: CGSize(width: 8 * s.x, height: 8 * s.y))
        // Right bicep
        path.addRoundedRect(in: CGRect(
            x: rect.minX + 146 * s.x,
            y: rect.minY + 80 * s.y,
            width: 20 * s.x,
            height: 38 * s.y
        ), cornerSize: CGSize(width: 8 * s.x, height: 8 * s.y))
        return path
    }

    /// Front core / abs.
    static func frontCorePath(in rect: CGRect) -> Path {
        let s = scale(for: rect)
        var path = Path()
        path.addRoundedRect(in: CGRect(
            x: rect.minX + 76 * s.x,
            y: rect.minY + 92 * s.y,
            width: 48 * s.x,
            height: 68 * s.y
        ), cornerSize: CGSize(width: 8 * s.x, height: 8 * s.y))
        return path
    }

    /// Front quads.
    static func quadsPath(in rect: CGRect) -> Path {
        let s = scale(for: rect)
        var path = Path()
        // Left quad
        path.addRoundedRect(in: CGRect(
            x: rect.minX + 64 * s.x,
            y: rect.minY + 180 * s.y,
            width: 30 * s.x,
            height: 72 * s.y
        ), cornerSize: CGSize(width: 10 * s.x, height: 10 * s.y))
        // Right quad
        path.addRoundedRect(in: CGRect(
            x: rect.minX + 106 * s.x,
            y: rect.minY + 180 * s.y,
            width: 30 * s.x,
            height: 72 * s.y
        ), cornerSize: CGSize(width: 10 * s.x, height: 10 * s.y))
        return path
    }

    /// Front calves (lower leg).
    static func frontCalvesPath(in rect: CGRect) -> Path {
        let s = scale(for: rect)
        var path = Path()
        // Left calf
        path.addRoundedRect(in: CGRect(
            x: rect.minX + 66 * s.x,
            y: rect.minY + 268 * s.y,
            width: 26 * s.x,
            height: 56 * s.y
        ), cornerSize: CGSize(width: 8 * s.x, height: 8 * s.y))
        // Right calf
        path.addRoundedRect(in: CGRect(
            x: rect.minX + 108 * s.x,
            y: rect.minY + 268 * s.y,
            width: 26 * s.x,
            height: 56 * s.y
        ), cornerSize: CGSize(width: 8 * s.x, height: 8 * s.y))
        return path
    }

    // MARK: - Back Paths

    /// Back — upper back, lats, traps region.
    static func backPath(in rect: CGRect) -> Path {
        let s = scale(for: rect)
        var path = Path()
        // Upper back / traps
        path.addRoundedRect(in: CGRect(
            x: rect.minX + 66 * s.x,
            y: rect.minY + 56 * s.y,
            width: 68 * s.x,
            height: 36 * s.y
        ), cornerSize: CGSize(width: 8 * s.x, height: 8 * s.y))
        // Left lat
        path.addRoundedRect(in: CGRect(
            x: rect.minX + 62 * s.x,
            y: rect.minY + 94 * s.y,
            width: 28 * s.x,
            height: 52 * s.y
        ), cornerSize: CGSize(width: 8 * s.x, height: 8 * s.y))
        // Right lat
        path.addRoundedRect(in: CGRect(
            x: rect.minX + 110 * s.x,
            y: rect.minY + 94 * s.y,
            width: 28 * s.x,
            height: 52 * s.y
        ), cornerSize: CGSize(width: 8 * s.x, height: 8 * s.y))
        return path
    }

    /// Back shoulders / rear delts.
    static func backShoulderPath(in rect: CGRect) -> Path {
        frontShoulderPath(in: rect) // Same position on back view
    }

    /// Triceps on the back view.
    static func tricepsPath(in rect: CGRect) -> Path {
        let s = scale(for: rect)
        var path = Path()
        // Left tricep
        path.addRoundedRect(in: CGRect(
            x: rect.minX + 34 * s.x,
            y: rect.minY + 80 * s.y,
            width: 20 * s.x,
            height: 38 * s.y
        ), cornerSize: CGSize(width: 8 * s.x, height: 8 * s.y))
        // Right tricep
        path.addRoundedRect(in: CGRect(
            x: rect.minX + 146 * s.x,
            y: rect.minY + 80 * s.y,
            width: 20 * s.x,
            height: 38 * s.y
        ), cornerSize: CGSize(width: 8 * s.x, height: 8 * s.y))
        return path
    }

    /// Back core / lower back.
    static func backCorePath(in rect: CGRect) -> Path {
        let s = scale(for: rect)
        var path = Path()
        path.addRoundedRect(in: CGRect(
            x: rect.minX + 78 * s.x,
            y: rect.minY + 128 * s.y,
            width: 44 * s.x,
            height: 36 * s.y
        ), cornerSize: CGSize(width: 6 * s.x, height: 6 * s.y))
        return path
    }

    /// Glutes on the back view.
    static func glutesPath(in rect: CGRect) -> Path {
        let s = scale(for: rect)
        var path = Path()
        // Left glute
        path.addEllipse(in: CGRect(
            x: rect.minX + 64 * s.x,
            y: rect.minY + 162 * s.y,
            width: 34 * s.x,
            height: 26 * s.y
        ))
        // Right glute
        path.addEllipse(in: CGRect(
            x: rect.minX + 102 * s.x,
            y: rect.minY + 162 * s.y,
            width: 34 * s.x,
            height: 26 * s.y
        ))
        return path
    }

    /// Hamstrings on the back view.
    static func hamstringsPath(in rect: CGRect) -> Path {
        let s = scale(for: rect)
        var path = Path()
        // Left hamstring
        path.addRoundedRect(in: CGRect(
            x: rect.minX + 64 * s.x,
            y: rect.minY + 192 * s.y,
            width: 30 * s.x,
            height: 64 * s.y
        ), cornerSize: CGSize(width: 10 * s.x, height: 10 * s.y))
        // Right hamstring
        path.addRoundedRect(in: CGRect(
            x: rect.minX + 106 * s.x,
            y: rect.minY + 192 * s.y,
            width: 30 * s.x,
            height: 64 * s.y
        ), cornerSize: CGSize(width: 10 * s.x, height: 10 * s.y))
        return path
    }

    /// Back calves.
    static func backCalvesPath(in rect: CGRect) -> Path {
        frontCalvesPath(in: rect) // Same position
    }

    // MARK: - Lookup

    /// Returns all (MuscleGroup, Path) pairs visible for the given side.
    static func musclePaths(side: Side, in rect: CGRect) -> [(muscle: MuscleGroup, path: Path)] {
        switch side {
        case .front:
            return [
                (.shoulders, frontShoulderPath(in: rect)),
                (.chest,     chestPath(in: rect)),
                (.biceps,    bicepsPath(in: rect)),
                (.core,      frontCorePath(in: rect)),
                (.quads,     quadsPath(in: rect)),
                (.calves,    frontCalvesPath(in: rect)),
            ]
        case .back:
            return [
                (.shoulders,  backShoulderPath(in: rect)),
                (.back,       backPath(in: rect)),
                (.triceps,    tricepsPath(in: rect)),
                (.core,       backCorePath(in: rect)),
                (.glutes,     glutesPath(in: rect)),
                (.hamstrings, hamstringsPath(in: rect)),
                (.calves,     backCalvesPath(in: rect)),
            ]
        }
    }

    // MARK: - Scaling

    /// The design grid is 200 × 340, leaving margin at bottom for feet.
    private static let designWidth: CGFloat = 200
    private static let designHeight: CGFloat = 340

    private static func scale(for rect: CGRect) -> CGPoint {
        CGPoint(
            x: rect.width / designWidth,
            y: rect.height / designHeight
        )
    }
}
