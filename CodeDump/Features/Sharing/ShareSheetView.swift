import SwiftUI

// MARK: - Share Sheet

struct ShareSheetView: View {
    let workoutName: String
    let totalTime: Int
    let exercisesCompleted: Int
    let setsCompleted: Int
    let setLogs: [SetLog]
    let workout: Workout?

    @Environment(\.dismiss) private var dismiss
    @State private var shareImage: UIImage?
    @State private var showingImageShare = false
    @State private var isRendering = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.outrunBackground.ignoresSafeArea()

                VStack(spacing: 20) {
                    // Preview (scaled down)
                    if let image = shareImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 400)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: .outrunPink.opacity(0.3), radius: 16)
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.outrunSurface)
                            .frame(height: 400)
                            .overlay {
                                if isRendering {
                                    ProgressView()
                                        .tint(.outrunCyan)
                                } else {
                                    Text("GENERATING...")
                                        .font(.outrunFuture(14))
                                        .foregroundColor(.outrunCyan.opacity(0.5))
                                }
                            }
                    }

                    // Share Image button
                    Button {
                        if let image = shareImage {
                            showingImageShare = true
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "photo")
                            Text("SHARE IMAGE")
                                .font(.outrunFuture(18))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [.outrunPink, .outrunPurple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                        .opacity(shareImage != nil ? 1 : 0.4)
                    }
                    .disabled(shareImage == nil)

                    // Share Workout Template button
                    if let workout {
                        let export = WorkoutExport(from: workout)
                        ShareLink(item: export, preview: SharePreview(workout.name, image: Image(systemName: "figure.strengthtraining.traditional"))) {
                            HStack(spacing: 10) {
                                Image(systemName: "square.and.arrow.up")
                                Text("SHARE TEMPLATE")
                                    .font(.outrunFuture(18))
                            }
                            .foregroundColor(.outrunCyan)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.outrunSurface)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.outrunCyan.opacity(0.3), lineWidth: 1)
                            )
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
            }
            .navigationTitle("SHARE")
            .navigationBarTitleDisplayMode(.inline)
            .outrunNavBar()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.outrunCyan)
                }
            }
            .sheet(isPresented: $showingImageShare) {
                if let image = shareImage {
                    ActivityViewController(items: [image])
                }
            }
            .task {
                isRendering = true
                shareImage = WorkoutShareCardView.renderImage(
                    workoutName: workoutName,
                    totalTime: totalTime,
                    exercisesCompleted: exercisesCompleted,
                    setsCompleted: setsCompleted,
                    setLogs: setLogs
                )
                isRendering = false
            }
        }
    }
}

// MARK: - UIActivityViewController Wrapper

struct ActivityViewController: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
