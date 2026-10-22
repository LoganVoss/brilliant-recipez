import SwiftUI
import RecipeCore

struct ComposerView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss
    let photo: Data?
    @State private var ingredients: [String] = []
    @State private var entry = ""
    @State private var servings = 2
    @State private var minutes = 30
    @State private var direction = "Surprise me"
    @State private var includeStaples = true
    @State private var finishedRecipe: Recipe?
    @State private var didIdentify = false
    @FocusState private var editing: Bool

    var body: some View {
        NavigationStack {
            Form {
                if let photo, let image = UIImage(data: photo) {
                    Section {
                        Image(uiImage: image).resizable().scaledToFit().frame(maxHeight: 230)
                            .frame(maxWidth: .infinity).clipShape(RoundedRectangle(cornerRadius: 15))
                        if !didIdentify {
                            Button { editing = false; model.identify(photo) { detected in
                                let merged = IngredientNormalizer.normalize(ingredients + detected)
                                ingredients = Array(merged.prefix(30))
                                didIdentify = true
                                if merged.count > 30 { model.errorMessage = "The combined list exceeded 30 ingredients. Your existing ingredients were kept first. Review the list before cooking." }
                            } } label: {
                                Label("Identify with Grok", systemImage: "sparkles")
                            }.disabled(model.busyMessage != nil)
                        } else {
                            Label(ingredients.isEmpty ? "No clear ingredients found. Add them below." : "Photo reviewed. Check the list below.", systemImage: "checkmark.circle").foregroundStyle(.secondary)
                        }
                    } header: { Text("Your ingredients, in focus") } footer: {
                        Text("Identify sends this photo to xAI using your API key. Only upload images you want to share. You can also type ingredients below without uploading the photo.")
                    }
                }
                Section {
                    HStack {
                        TextField("Tomatoes, chickpeas, spinach…", text: $entry).focused($editing)
                            .submitLabel(.done).onSubmit { addIngredients() }.accessibilityIdentifier("ingredientInput")
                        Button { addIngredients() } label: { Image(systemName: "plus.circle.fill").font(.title2) }
                            .accessibilityLabel("Add ingredients").disabled(entry.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    ForEach(ingredients, id: \.self) { ingredient in
                        HStack {
                            Image(systemName: "checkmark").foregroundStyle(Theme.green)
                            Text(ingredient)
                            Spacer()
                            Button { ingredients.removeAll { $0 == ingredient } } label: { Image(systemName: "minus.circle").foregroundStyle(.secondary) }
                                .buttonStyle(.borderless).accessibilityLabel("Remove \(ingredient)")
                        }
                    }
                } header: { Text("Review your ingredients · \(ingredients.count)") } footer: {
                    Text("Add up to 30 ingredients, separated by commas or new lines. Correct anything the camera missed before creating your recipe.")
                }
                Section {
                    Stepper("\(servings) servings", value: $servings, in: 1...12)
                    Picker("Time budget", selection: $minutes) {
                        ForEach([15, 20, 30, 45, 60], id: \.self) { Text("\($0) minutes").tag($0) }
                    }
                    Picker("In the mood for", selection: $direction) {
                        ForEach(["Surprise me", "One-pan comfort", "Fresh & bright", "Mediterranean-inspired", "Quick & cozy"], id: \.self) { Text($0).tag($0) }
                    }
                    Toggle("Include pantry basics", isOn: $includeStaples)
                } header: { Text("Make it yours") } footer: {
                    Text("Pantry basics: olive oil, salt, black pepper, and water. These are optional additions, never items claimed to be in your photo.")
                }
                Section {
                    if let message = model.busyMessage {
                        VStack(spacing: 16) {
                            ProgressView(message).frame(maxWidth: .infinity)
                            Button("Cancel request", role: .cancel) { model.cancel() }
                        }.padding(.vertical, 12)
                    } else {
                        Button {
                            editing = false
                            guard addIngredients() else { return }
                            model.generate(ingredients: ingredients, preferences: RecipePreferences(servings: servings, maximumMinutes: minutes, direction: direction, includeStaples: includeStaples)) {
                                finishedRecipe = $0
                            }
                        } label: { Label("Make something brilliant", systemImage: "bolt.fill") }
                            .buttonStyle(PrimaryButtonStyle()).disabled(ingredients.isEmpty && entry.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            .listRowInsets(EdgeInsets()).listRowBackground(Color.clear)
                            .accessibilityIdentifier("generateRecipe")
                    }
                } footer: {
                    Text("Creating a recipe sends your ingredient list and preferences to xAI and may incur API charges. AI can make mistakes; check ingredients, allergens, and cooking instructions.")
                }
            }
            .scrollContentBackground(.hidden).background(Theme.cream)
            .navigationTitle("A fresh start").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { model.cancel(); dismiss() } } }
            .interactiveDismissDisabled(model.busyMessage != nil)
            .sheet(item: $finishedRecipe) { RecipeDetailView(recipe: $0) }
            .onDisappear { model.cancel() }
            .alert("Couldn’t finish this recipe", isPresented: Binding(get: { model.errorMessage != nil && finishedRecipe == nil }, set: { if !$0 { model.errorMessage = nil } })) {
                Button("OK", role: .cancel) { model.errorMessage = nil }
            } message: { Text(model.errorMessage ?? "") }
        }
    }

    @discardableResult
    private func addIngredients() -> Bool {
        let new = entry.components(separatedBy: CharacterSet(charactersIn: ",\n"))
        let combined = IngredientNormalizer.normalize(ingredients + new)
        guard combined.count <= 30, combined.allSatisfy({ $0.count <= 80 }) else {
            model.errorMessage = "Use at most 30 ingredients, with a short name of up to 80 characters for each."
            return false
        }
        ingredients = combined
        entry = ""
        return true
    }
}
