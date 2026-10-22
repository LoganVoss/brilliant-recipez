import SwiftUI
import PhotosUI
import AVFoundation
import RecipeCore

struct RootView: View {
    @EnvironmentObject private var model: AppModel
    var body: some View {
        TabView(selection: $model.selectedTab) {
            HomeView().tabItem { Label("Create", systemImage: "lightbulb") }.tag(0)
            LibraryView().tabItem { Label("Recipe box", systemImage: "books.vertical") }.tag(1)
                .accessibilityIdentifier("libraryTab")
            SettingsView().tabItem { Label("Settings", systemImage: "slider.horizontal.3") }.tag(2)
        }
        .sheet(item: $model.presentedRecipe) { RecipeDetailView(recipe: $0) }
        .alert("Let’s try that again", isPresented: Binding(get: { model.errorMessage != nil && !model.showComposer && model.presentedRecipe == nil }, set: { if !$0 { model.errorMessage = nil } })) {
            Button("OK", role: .cancel) { model.errorMessage = nil }
        } message: { Text(model.errorMessage ?? "") }
    }
}

struct HomeView: View {
    @EnvironmentObject private var model: AppModel
    @ScaledMetric(relativeTo: .largeTitle) private var heroFont: CGFloat = 43
    @State private var selection: PhotosPickerItem?
    @State private var photo: Data?
    @State private var showCamera = false
    @State private var importing = false
    @State private var capturedPhoto: Data?
    @State private var cameraDenied = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    HStack(spacing: 11) {
                        Image("BrandMark").resizable().frame(width: 45, height: 45).clipShape(RoundedRectangle(cornerRadius: 13))
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Brilliant!").font(.system(.title2, design: .serif).weight(.bold))
                            Text("RECIPEZ").font(.caption2.weight(.bold)).tracking(3)
                        }
                        Spacer()
                        Text("YOUR KITCHEN, REIMAGINED").font(.system(size: 9, weight: .bold)).tracking(1).multilineTextAlignment(.trailing).frame(maxWidth: 125)
                    }
                    hero
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("What’s in your kitchen?").font(.title3.bold())
                            Spacer()
                        }
                        HStack(spacing: 12) {
                            Button { requestCamera() } label: { actionLabel("Camera", icon: "camera", note: "Snap ingredients") }
                            PhotosPicker(selection: $selection, matching: .images) { actionLabel("Photos", icon: "photo.on.rectangle", note: "Pick a favorite") }
                        }.buttonStyle(.plain).disabled(importing)
                        Button { photo = nil; model.showComposer = true } label: {
                            HStack { Image(systemName: "text.badge.plus"); Text("Or type your ingredients"); Spacer(); Image(systemName: "arrow.right") }
                                .font(.subheadline.weight(.semibold)).padding(.vertical, 8)
                        }.accessibilityIdentifier("manualIngredients")
                        if importing { ProgressView("Preparing your photo…") }
                    }
                    Button { model.presentedRecipe = .demo } label: {
                        HStack(spacing: 14) {
                            BowlArtwork().frame(width: 82, height: 82)
                            VStack(alignment: .leading, spacing: 6) {
                                Eyebrow(text: "A little inspiration").font(.caption2)
                                Text("Try a bright idea").font(.system(.title3, design: .serif).bold())
                                Text("Explore a sample. No key needed.").font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer(minLength: 0)
                            Image(systemName: "arrow.up.right")
                        }.padding(16).background(Theme.paper, in: RoundedRectangle(cornerRadius: 22))
                    }.buttonStyle(.plain).accessibilityIdentifier("demoRecipe")
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "sparkle").foregroundStyle(Theme.tint)
                        Text(model.hasKey ? "Your Grok key is ready. A photo, a few ingredients, a delicious possibility." : "Bring your own Grok API key to create recipes. Add it once in Settings.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                }.padding(24).frame(maxWidth: 720).frame(maxWidth: .infinity)
            }
            .background(Theme.cream).toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $model.showComposer) { ComposerView(photo: photo) }
            .fullScreenCover(isPresented: $showCamera, onDismiss: {
                if let data = capturedPhoto { capturedPhoto = nil; preparePhoto(data) }
            }) {
                CameraView { data in
                    capturedPhoto = data
                    showCamera = false
                }.ignoresSafeArea()
            }
            .alert("Camera access", isPresented: $cameraDenied) {
                Button("Open Settings") { if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) } }
                Button("Cancel", role: .cancel) { }
            } message: { Text("Allow camera access in Settings, choose a photo, or type your ingredients. The simulator has no camera.") }
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

    private var hero: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Eyebrow(text: "Less waste. More wonder.").foregroundStyle(Theme.citrus)
                Spacer()
                Image(systemName: "sparkle").foregroundStyle(Theme.citrus)
            }
            Text("Good food.\nBright ideas.").font(.system(size: heroFont, weight: .medium, design: .serif)).tracking(-1.5)
                .fixedSize(horizontal: false, vertical: true)
            Text("Turn what you have into\nsomething you’ll love.").font(.body).foregroundStyle(.white.opacity(0.8))
            HStack(spacing: 8) {
                step("01", "Snap"); Image(systemName: "arrow.right").font(.caption2)
                step("02", "Review"); Image(systemName: "arrow.right").font(.caption2)
                step("03", "Cook")
            }.padding(.top, 8)
        }.foregroundStyle(.white).padding(26).frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.green, in: RoundedRectangle(cornerRadius: 28))
    }

    private func step(_ number: String, _ label: String) -> some View {
        HStack(spacing: 5) { Text(number).foregroundStyle(Theme.citrus); Text(label) }.font(.caption.weight(.medium))
    }

    nonisolated private func actionLabel(_ title: String, icon: String, note: String) -> some View {
        VStack(alignment: .leading, spacing: 13) {
            Image(systemName: icon).font(.title2).foregroundStyle(Theme.tint)
            VStack(alignment: .leading, spacing: 4) { Text(title).font(.headline); Text(note).font(.caption).foregroundStyle(.secondary) }
        }.frame(maxWidth: .infinity, alignment: .leading).padding(20).background(Theme.paper, in: RoundedRectangle(cornerRadius: 20))
    }

    private func preparePhoto(_ data: Data) {
        do { photo = try PhotoPreparation.jpeg(from: data); model.showComposer = true }
        catch { model.errorMessage = error.localizedDescription }
    }

    private func requestCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else { cameraDenied = true; return }
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
