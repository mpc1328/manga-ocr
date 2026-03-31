import SwiftUI

struct ContentView: View {

    @StateObject private var viewModel = MangaOCRViewModel()

    var body: some View {
        ZStack {
            // Camera preview (full screen)
            CameraPreviewView(session: viewModel.cameraManager.session)
                .ignoresSafeArea()

            // Translated text overlay
            GeometryReader { geo in
                TextOverlayView(
                    blocks: viewModel.textBlocks,
                    viewSize: geo.size
                )
            }
            .ignoresSafeArea()

            // HUD controls
            VStack {
                // Top bar
                HStack {
                    // Processing indicator
                    if viewModel.isProcessing {
                        HStack(spacing: 6) {
                            ProgressView()
                                .tint(.white)
                            Text("Scansione...")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                    }

                    Spacer()

                    // Block count
                    if !viewModel.textBlocks.isEmpty {
                        Text("\(viewModel.textBlocks.count) testi")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)

                Spacer()

                // Bottom controls
                HStack(spacing: 40) {
                    // Pause / Resume button
                    Button(action: { viewModel.togglePause() }) {
                        Image(systemName: viewModel.isPaused ? "play.circle.fill" : "pause.circle.fill")
                            .font(.system(size: 56))
                            .foregroundColor(.white)
                            .shadow(radius: 4)
                    }
                }
                .padding(.bottom, 30)
            }

            // Error overlay
            if let error = viewModel.errorMessage {
                VStack {
                    Spacer()
                    Text(error)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(12)
                        .padding()
                    Spacer()
                }
            }
        }
        .onAppear {
            viewModel.startCamera()
        }
        .onDisappear {
            viewModel.stopCamera()
        }
        .statusBarHidden()
    }
}

#Preview {
    ContentView()
}
