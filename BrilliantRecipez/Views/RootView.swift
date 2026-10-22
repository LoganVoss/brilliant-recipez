import SwiftUI
import PhotosUI
import AVFoundation
import RecipeCore

struct RootView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.scenePhase) private var scenePhase
    var body: some View {
        TabView(selection: $model.selectedTab) {
            HomeView().tabItem { Label("Create", systemImage: "lightbulb") }.tag(0)
            LibraryView().tabItem { Label("Saved", systemImage: "bookmark") }.tag(1)
                .accessibilityIdentifier("libraryTab")
            SettingsView().tabItem { Label("Settings", systemImage: "slider.horizontal.3") }.tag(2)
        }
        .onChange(of: scenePhase) { _, phase in if phase == .active { model.refreshAvailability() } }
        .sheet(item: $model.presentedRecipe) { RecipeDetailView(recipe: $0) }
        .alert("Unable to continue", isPresented: Binding(get: { model.errorMessage != nil && !model.showComposer && model.presentedRecipe == nil }, set: { if !$0, model.errorMessage != nil { model.errorMessage = nil } })) {
            Button("OK", role: .cancel) { model.errorMessage = nil }
        } message: { Text(model.errorMessage ?? "") }
    }
}

struct HomeView: View {
    @EnvironmentObject private var model: AppModel
    @ScaledMetric(relativeTo: .largeTitle) private var headlineSize: CGFloat = 39
    @State private var selection: PhotosPickerItem?
    @State private var photo: Data?
    @State private var showCamera = false
    @State private var importing = false
    @State private var capturedPhoto: Data?
    @State private var cameraDenied = false
    @State private var cameraUnavailable = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    HStack(spacing: 12) {
                        Image("BrandMark").resizable().frame(width: 39, height: 39)
                            .clipShape(RoundedRectangle(cornerRadius: 12)).accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Brilliant!").font(.system(.title2, design: .serif).weight(.medium))
                            Text("RECIPEZ").font(.system(size: 9, weight: .medium)).tracking(3.2)
                        }
                        Spacer()
                        Image(systemName: "fork.knife").font(.system(size: 17, weight: .ultraLight)).foregroundStyle(Theme.brass)
                            .accessibilityHidden(true)
                    }.padding(.top, 12)
                    Rectangle().fill(Theme.line).frame(height: 0.5).accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 18) {
                        Text("Turn what you have into something you’ll love.")
                            .font(.system(size: headlineSize, weight: .regular, design: .serif)).tracking(-1.3)
                            .lineSpacing(1).fixedSize(horizontal: false, vertical: true)
                        Text("Choose a photo or enter your ingredients.")
                            .font(.subheadline).foregroundStyle(.secondary).lineSpacing(3)
                    }.padding(.vertical, 5)
                    VStack(spacing: 12) {
                        Button { photo = nil; model.showComposer = true } label: {
                            HStack { Text("Type ingredients"); Spacer(); Image(systemName: "arrow.right") }.padding(.horizontal, 21)
                        }.buttonStyle(PrimaryButtonStyle()).disabled(importing).accessibilityIdentifier("manualIngredients")
                        HStack(spacing: 12) {
                            Button { requestCamera() } label: { actionLabel("Take photo", icon: "camera") }
                            PhotosPicker(selection: $selection, matching: .images) { actionLabel("Choose photo", icon: "photo") }
                        }.buttonStyle(.plain).disabled(importing)
                        if importing { ProgressView("Opening photo…").font(.footnote).padding(.top, 8) }
                    }
                    Button { model.presentedRecipe = .demo } label: {
                        HStack(spacing: 15) {
                            BowlArtwork().frame(width: 48, height: 48)
                            VStack(alignment: .leading, spacing: 5) {
                                Text("View sample recipe").font(.subheadline.weight(.medium))
                                Text("Chickpea and spinach bowls").font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer(minLength: 4)
                            Image(systemName: "arrow.up.right").font(.caption).foregroundStyle(Theme.brass)
                        }.padding(.vertical, 4).contentShape(Rectangle())
                    }.buttonStyle(.plain).accessibilityIdentifier("demoRecipe")
                    VStack(alignment: .leading, spacing: 14) {
                        Rectangle().fill(Theme.line).frame(height: 0.5).accessibilityHidden(true)
                        if model.availability.isAvailable {
                            Label("Processed on your device", systemImage: "iphone")
                                .font(.caption).foregroundStyle(.secondary)
                        } else {
                            Button { model.selectedTab = 2 } label: {
                                HStack(alignment: .top, spacing: 10) {
                                    Image(systemName: "info.circle").foregroundStyle(Theme.brass)
                                    Text(model.availability.title).frame(maxWidth: .infinity, alignment: .leading)
                                    Image(systemName: "chevron.right").font(.caption2)
                                }.font(.caption).foregroundStyle(.secondary).padding(.vertical, 5)
                            }.buttonStyle(.plain)
                        }
                    }
                }.padding(.horizontal, 28).padding(.bottom, 28).frame(maxWidth: 600).frame(maxWidth: .infinity)
            }
            .background(Theme.cream).toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $model.showComposer) { ComposerView(photo: photo) }
            .fullScreenCover(isPresented: $showCamera, onDismiss: {
                if let data = capturedPhoto { capturedPhoto = nil; preparePhoto(data) }
            }) {
                CameraView { data in capturedPhoto = data; showCamera = false }.ignoresSafeArea()
            }
            .alert("Allow camera access", isPresented: $cameraDenied) {
                Button("Open Settings") { if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) } }
                Button("Cancel", role: .cancel) { }
            } message: { Text("Allow camera access in Settings, or choose an existing photo.") }
            .alert("Camera unavailable", isPresented: $cameraUnavailable) {
                Button("OK", role: .cancel) { }
            } message: { Text("Choose a photo or type your ingredients instead.") }
            .task(id: selection) {
                guard let item = selection else { return }
                importing = true
                defer { importing = false }
                do {
                    guard let data = try await item.loadTransferable(type: Data.self) else { throw StoreError.photo }
                    try Task.checkCancellation()
                    photo = try PhotoPreparation.jpeg(from: data)
                    model.showComposer = true
                } catch is CancellationError { }
                catch { model.errorMessage = error.localizedDescription }
                selection = nil
            }
        }
    }

    nonisolated private func actionLabel(_ title: String, icon: String) -> some View {
        HStack(spacing: 9) {
            Image(systemName: icon).font(.system(size: 17, weight: .light))
            Text(title).font(.subheadline)
        }.frame(maxWidth: .infinity).padding(.vertical, 21)
            .background(Theme.paper, in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.line, lineWidth: 0.5))
    }

    private func preparePhoto(_ data: Data) {
        do { photo = try PhotoPreparation.jpeg(from: data); model.showComposer = true }
        catch { model.errorMessage = error.localizedDescription }
    }

    private func requestCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else { cameraUnavailable = true; return }
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: showCamera = true
        case .notDetermined:
            Task { if await AVCaptureDevice.requestAccess(for: .video) { showCamera = true } else { cameraDenied = true } }
        default: cameraDenied = true
        }
    }
}

struct CameraView: UIViewControllerRepresentable {
    let completion: (Data?) -> Void
    func makeCoordinator() -> Coordinator { Coordinator(completion: completion) }
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.delegate = context.coordinator
        return picker
    }
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) { }
    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let completion: (Data?) -> Void
        init(completion: @escaping (Data?) -> Void) { self.completion = completion }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { completion(nil) }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            completion((info[.originalImage] as? UIImage)?.jpegData(compressionQuality: 0.9))
        }
    }
}
