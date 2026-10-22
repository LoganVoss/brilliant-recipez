import SwiftUI
import RecipeCore

@MainActor
final class AppModel: ObservableObject {
    @Published var savedRecipes: [Recipe] = []
    @Published var presentedRecipe: Recipe?
    @Published var showComposer = false
    @Published var errorMessage: String?
    @Published var busyMessage: String?
    @Published var hasKey = false
    @Published var selectedTab = 0
    @Published var textModel: String
    @Published var visionModel: String
    private var operation: Task<Void, Never>?
    private var operationID = UUID()
    private let libraryURL: URL
    private var libraryReadable = true
    private let defaults = AppEnvironment.defaults

    init() {
        textModel = defaults.string(forKey: "textModel") ?? "grok-4.7"
        visionModel = defaults.string(forKey: "visionModel") ?? "grok-4.7"
        let folder = URL.applicationSupportDirectory.appending(path: AppEnvironment.isUITesting ? "BrilliantRecipezUITests" : "BrilliantRecipez", directoryHint: .isDirectory)
        libraryURL = folder.appending(path: "recipes.json")
        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            if AppEnvironment.isUITesting && ProcessInfo.processInfo.arguments.contains("-reset-demo-state") {
                defaults.removePersistentDomain(forName: "com.loganvoss.brilliantrecipez.uitests")
                textModel = "grok-4.7"
                visionModel = "grok-4.7"
                if FileManager.default.fileExists(atPath: libraryURL.path) { try FileManager.default.removeItem(at: libraryURL) }
            }
            if FileManager.default.fileExists(atPath: libraryURL.path) {
                savedRecipes = try JSONDecoder().decode([Recipe].self, from: Data(contentsOf: libraryURL))
            }
        } catch {
            libraryReadable = false
            errorMessage = "Your saved collection could not be loaded. Its file has been preserved for recovery."
        }
        do {
            if AppEnvironment.isUITesting && ProcessInfo.processInfo.arguments.contains("-reset-demo-state") { try KeychainStore.delete() }
            hasKey = !(try KeychainStore.read()).isEmpty
        }
        catch { errorMessage = error.localizedDescription }
        if ProcessInfo.processInfo.arguments.contains("-show-demo") { presentedRecipe = .demo }
        if ProcessInfo.processInfo.arguments.contains("-seed-demo-library") {
            if !isSaved(.demo) { toggleSave(.demo) }
            selectedTab = 1
        }
    }

    func saveSettings(key: String?, text: String, vision: String) throws {
        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanVision = vision.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanText.isEmpty, !cleanVision.isEmpty else {
            throw SettingsError.missingModel
        }
        if let key {
            let cleanKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !cleanKey.isEmpty else { throw SettingsError.missingKey }
            try KeychainStore.save(cleanKey)
        }
        textModel = cleanText
        visionModel = cleanVision
        defaults.set(textModel, forKey: "textModel")
        defaults.set(visionModel, forKey: "visionModel")
        hasKey = !(try KeychainStore.read()).isEmpty
    }

    func removeKey() {
        do { try KeychainStore.delete(); hasKey = false }
        catch { errorMessage = error.localizedDescription }
    }

    private func service() throws -> GrokService {
        let key = try KeychainStore.read()
        guard !key.isEmpty else { throw SettingsError.missingKey }
        return GrokService(configuration: GrokConfiguration(apiKey: key, textModel: textModel, visionModel: visionModel))
    }

    func identify(_ photo: Data, completion: @escaping ([String]) -> Void) {
        run(message: "Looking for ingredients…") { [self] in
            let ingredients = try await service().identifyIngredients(jpegData: photo)
            try Task.checkCancellation()
            completion(ingredients)
        }
    }

    func generate(ingredients: [String], preferences: RecipePreferences, completion: @escaping (Recipe) -> Void) {
        run(message: "A bright idea is cooking…") { [self] in
            let recipe = try await service().generateRecipe(ingredients: ingredients, preferences: preferences)
            try Task.checkCancellation()
            completion(recipe)
        }
    }

    private func run(message: String, body: @escaping @MainActor () async throws -> Void) {
        cancel()
        busyMessage = message
        let id = UUID()
        operationID = id
        operation = Task { [weak self] in
            do { try await body() }
            catch is CancellationError { }
            catch let error as URLError where error.code == .cancelled { }
            catch { if !Task.isCancelled { self?.errorMessage = error.localizedDescription } }
            if self?.operationID == id { self?.busyMessage = nil; self?.operation = nil }
        }
    }

    func cancel() {
        operation?.cancel()
        operation = nil
        operationID = UUID()
        busyMessage = nil
    }

    func isSaved(_ recipe: Recipe) -> Bool { savedRecipes.contains { $0.id == recipe.id } }

    func toggleSave(_ recipe: Recipe) {
        guard libraryReadable else {
            errorMessage = "Saving is paused because the existing collection could not be read. Recover or remove recipes.json using Xcode’s app container tools first."
            return
        }
        var updated = savedRecipes
        if isSaved(recipe) { updated.removeAll { $0.id == recipe.id } }
        else { updated.insert(recipe, at: 0) }
        do {
            try JSONEncoder().encode(updated).write(to: libraryURL, options: [.atomic, .completeFileProtectionUnlessOpen])
            savedRecipes = updated
        } catch { errorMessage = StoreError.library.localizedDescription }
    }
}

enum SettingsError: LocalizedError {
    case missingKey, missingModel
    var errorDescription: String? {
        switch self {
        case .missingKey: "Add your own Grok API key in Settings to identify ingredients or create recipes. You can explore the sample recipe without a key."
        case .missingModel: "Enter both a recipe model and a vision model. Check xAI’s current model catalog for IDs available to your account."
        }
    }
}


/// UI automation uses separate local data and never touches a developer’s real key.
enum AppEnvironment {
    static var isUITesting: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("-ui-testing")
        #else
        false
        #endif
    }
    static var defaults: UserDefaults {
        isUITesting ? UserDefaults(suiteName: "com.loganvoss.brilliantrecipez.uitests")! : .standard
    }
}
