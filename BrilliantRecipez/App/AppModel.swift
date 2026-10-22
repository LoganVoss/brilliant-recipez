import SwiftUI
import RecipeCore

@MainActor
final class AppModel: ObservableObject {
    @Published var savedRecipes: [Recipe] = []
    @Published var presentedRecipe: Recipe?
    @Published var showComposer = false
    @Published var errorMessage: String?
    @Published var busyMessage: String?
    @Published var availability: AppleModelAvailability = .unavailable
    @Published var selectedTab = 0
    private var operation: Task<Void, Never>?
    private var operationID = UUID()
    private let libraryURL: URL
    private var libraryReadable = true

    var supportsImageInput: Bool { !AppEnvironment.isUITesting && AppleRecipeService.supportsImageInput }

    init() {
        LegacyCredentialCleanup.run()
        let folder = URL.applicationSupportDirectory.appending(path: AppEnvironment.isUITesting ? "BrilliantRecipezUITests" : "BrilliantRecipez", directoryHint: .isDirectory)
        libraryURL = folder.appending(path: "recipes.json")
        refreshAvailability()
        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            if AppEnvironment.isUITesting && ProcessInfo.processInfo.arguments.contains("-reset-demo-state") {
                if FileManager.default.fileExists(atPath: libraryURL.path) { try FileManager.default.removeItem(at: libraryURL) }
            }
            if FileManager.default.fileExists(atPath: libraryURL.path) {
                savedRecipes = try JSONDecoder().decode([Recipe].self, from: Data(contentsOf: libraryURL))
            }
        } catch {
            libraryReadable = false
            errorMessage = "Saved recipes could not be opened. Your saved file has been kept."
        }
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-show-demo") { presentedRecipe = .demo }
        if ProcessInfo.processInfo.arguments.contains("-seed-demo-library") {
            if !isSaved(.demo) { toggleSave(.demo) }
            selectedTab = 1
        }
        #endif
    }

    func refreshAvailability() {
        availability = AppEnvironment.isUITesting ? .notEnabled : AppleRecipeService.availability
    }

    func identify(_ photo: Data, completion: @escaping ([String]) -> Void) {
        run(message: "Finding ingredients…") {
            let ingredients = try await LocalPhotoService().identifyIngredients(jpegData: photo)
            try Task.checkCancellation()
            completion(ingredients)
        }
    }

    func generate(ingredients: [String], preferences: RecipePreferences, completion: @escaping (Recipe) -> Void) {
        run(message: "Creating recipe…") { [self] in
            let reviewed = try RecipeValidation.reviewedIngredients(ingredients, preferences: preferences)
            refreshAvailability()
            guard availability.isAvailable else { throw AppleRecipeError.availability(availability) }
            let recipe = try await AppleRecipeService().generateRecipe(ingredients: reviewed, preferences: preferences)
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
            errorMessage = "Saving is unavailable because your saved recipes could not be opened. Your existing file has been kept."
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

/// UI automation uses separate local data and deterministic model availability.
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
