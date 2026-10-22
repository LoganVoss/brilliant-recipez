import SwiftUI
import RecipeCore

struct RecipeDetailView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss
    let recipe: Recipe
    @State private var checkedIngredients: Set<String> = []
    @State private var completedSteps: Set<Int> = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    VStack(alignment: .leading, spacing: 12) {
                        Eyebrow(text: recipe.isDemo ? "Sample recipe" : recipe.cuisine).foregroundStyle(Theme.brass)
                        Text(recipe.title).font(.system(.largeTitle, design: .serif).weight(.medium)).accessibilityIdentifier("recipeDetailTitle")
                        Text(recipe.summary).foregroundStyle(.secondary).lineSpacing(4)
                        HStack(spacing: 22) {
                            Label("\(recipe.minutes) min", systemImage: "clock")
                            Label("\(recipe.servings) servings", systemImage: "person.2")
                        }.font(.subheadline.weight(.medium)).padding(.top, 4)
                    }
                    Divider()
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Ingredients").font(.system(.title2, design: .serif))
                        ForEach(recipe.ingredients) { ingredient in
                            Button {
                                if checkedIngredients.contains(ingredient.id) { checkedIngredients.remove(ingredient.id) }
                                else { checkedIngredients.insert(ingredient.id) }
                            } label: {
                                HStack(spacing: 13) {
                                    Image(systemName: checkedIngredients.contains(ingredient.id) ? "checkmark.circle.fill" : "circle").foregroundStyle(Theme.tint)
                                    Text(ingredient.name).strikethrough(checkedIngredients.contains(ingredient.id)).foregroundStyle(.primary)
                                    Spacer()
                                    Text(ingredient.amount).font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.trailing)
                                }.padding(.vertical, 5).frame(minHeight: 36)
                            }.buttonStyle(.plain).accessibilityValue(checkedIngredients.contains(ingredient.id) ? "Checked" : "Unchecked")
                        }
                    }
                    Divider()
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Steps").font(.system(.title2, design: .serif))
                        ForEach(Array(recipe.steps.enumerated()), id: \.offset) { index, step in
                            Button {
                                if completedSteps.contains(index) { completedSteps.remove(index) } else { completedSteps.insert(index) }
                            } label: {
                                HStack(alignment: .top, spacing: 16) {
                                    Text(completedSteps.contains(index) ? "✓" : String(format: "%02d", index + 1))
                                        .font(.subheadline.bold()).frame(width: 36, height: 36)
                                        .background(Theme.paper, in: Circle())
                                        .overlay(Circle().stroke(Theme.line, lineWidth: 0.5)).foregroundStyle(Theme.brass)
                                    Text(step).lineSpacing(5).foregroundStyle(.primary).frame(maxWidth: .infinity, alignment: .leading)
                                        .opacity(completedSteps.contains(index) ? 0.5 : 1)
                                }
                            }.buttonStyle(.plain).accessibilityLabel("Step \(index + 1). \(step)").accessibilityValue(completedSteps.contains(index) ? "Completed" : "Not completed")
                        }
                    }
                    Text("Check ingredients, allergens, and cooking temperatures before you start.")
                        .font(.footnote).foregroundStyle(.secondary).padding(18).background(Theme.paper, in: RoundedRectangle(cornerRadius: 16))
                }.padding(24).frame(maxWidth: 720).frame(maxWidth: .infinity)
            }.background(Theme.cream)
                .navigationTitle("Recipe").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } }
                    ToolbarItemGroup(placement: .primaryAction) {
                        ShareLink(item: shareText) { Image(systemName: "square.and.arrow.up") }.accessibilityLabel("Share recipe")
                        Button { model.toggleSave(recipe) } label: { Image(systemName: model.isSaved(recipe) ? "bookmark.fill" : "bookmark") }
                            .accessibilityLabel(model.isSaved(recipe) ? "Remove saved recipe" : "Save recipe")
                            .accessibilityIdentifier("saveRecipe").accessibilityValue(model.isSaved(recipe) ? "Saved" : "Not saved")
                    }
                }
                .alert("Saved recipes", isPresented: Binding(get: { model.errorMessage != nil }, set: { if !$0, model.errorMessage != nil { model.errorMessage = nil } })) {
                    Button("OK", role: .cancel) { model.errorMessage = nil }
                } message: { Text(model.errorMessage ?? "") }
        }
    }

    private var shareText: String {
        "\(recipe.title)\n\(recipe.summary)\n\n\(recipe.minutes) minutes · \(recipe.servings) servings\n\nINGREDIENTS\n" +
        recipe.ingredients.map { "• \($0.amount) \($0.name)" }.joined(separator: "\n") +
        "\n\nSTEPS\n" + recipe.steps.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n\n") +
        "\n\nMade with Brilliant! Recipez. \(recipe.isDemo ? "Sample recipe." : "AI-generated; review ingredients, allergens, and cooking safety.")"
    }
}
