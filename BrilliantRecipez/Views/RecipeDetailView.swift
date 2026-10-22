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
                    ZStack(alignment: .bottomLeading) {
                        Theme.green
                        HStack {
                            VStack(alignment: .leading, spacing: 12) {
                                Eyebrow(text: recipe.isDemo ? "From the demo kitchen" : "Your bright idea").foregroundStyle(Theme.citrus)
                                Image(systemName: "sparkles").font(.system(size: 38)).foregroundStyle(Theme.citrus)
                                Text(recipe.isDemo ? "A taste of\npossibility." : "Made for\nyour kitchen.")
                                    .font(.system(.title, design: .serif)).foregroundStyle(.white)
                            }
                            Spacer(minLength: 5)
                            if recipe.isDemo { BowlArtwork().frame(width: 150, height: 150) }
                            else { Image("BrandMark").resizable().frame(width: 130, height: 130).clipShape(RoundedRectangle(cornerRadius: 22)) }
                        }.padding(24)
                    }.frame(minHeight: 200).clipShape(RoundedRectangle(cornerRadius: 25))
                    VStack(alignment: .leading, spacing: 12) {
                        Eyebrow(text: recipe.cuisine).foregroundStyle(.secondary)
                        Text(recipe.title).font(.system(.largeTitle, design: .serif).weight(.medium)).accessibilityIdentifier("recipeDetailTitle")
                        Text(recipe.summary).foregroundStyle(.secondary).lineSpacing(4)
                        HStack(spacing: 22) {
                            Label("\(recipe.minutes) min", systemImage: "clock")
                            Label("\(recipe.servings) servings", systemImage: "person.2")
                        }.font(.subheadline.weight(.medium)).padding(.top, 4)
                    }
                    if recipe.isDemo {
                        Label("Sample recipe · works offline · illustration", systemImage: "info.circle")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Divider()
                    VStack(alignment: .leading, spacing: 16) {
                        HStack { Text("The good stuff").font(.system(.title2, design: .serif).bold()); Spacer(); Text("INGREDIENTS").font(.caption2.bold()).foregroundStyle(.secondary) }
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
                        Text("Let’s make it").font(.system(.title2, design: .serif).bold())
                        ForEach(Array(recipe.steps.enumerated()), id: \.offset) { index, step in
                            Button {
                                if completedSteps.contains(index) { completedSteps.remove(index) } else { completedSteps.insert(index) }
                            } label: {
                                HStack(alignment: .top, spacing: 16) {
                                    Text(completedSteps.contains(index) ? "✓" : String(format: "%02d", index + 1))
                                        .font(.subheadline.bold()).frame(width: 36, height: 36)
                                        .background(Theme.citrus, in: Circle()).foregroundStyle(Theme.green)
                                    Text(step).lineSpacing(5).foregroundStyle(.primary).frame(maxWidth: .infinity, alignment: .leading)
                                        .opacity(completedSteps.contains(index) ? 0.5 : 1)
                                }
                            }.buttonStyle(.plain).accessibilityLabel("Step \(index + 1). \(step)").accessibilityValue(completedSteps.contains(index) ? "Completed" : "Not completed")
                        }
                    }
                    Text("Review before you cook. AI suggestions can miss allergens, safe cooking temperatures, or ingredients mentioned in the steps.")
                        .font(.footnote).foregroundStyle(.secondary).padding(18).background(Theme.paper, in: RoundedRectangle(cornerRadius: 16))
                }.padding(24).frame(maxWidth: 720).frame(maxWidth: .infinity)
            }.background(Theme.cream)
                .navigationTitle("Your recipe").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } }
                    ToolbarItemGroup(placement: .primaryAction) {
                        ShareLink(item: shareText) { Image(systemName: "square.and.arrow.up") }.accessibilityLabel("Share recipe")
                        Button { model.toggleSave(recipe) } label: { Image(systemName: model.isSaved(recipe) ? "bookmark.fill" : "bookmark") }
                            .accessibilityLabel(model.isSaved(recipe) ? "Remove saved recipe" : "Save recipe")
                            .accessibilityIdentifier("saveRecipe").accessibilityValue(model.isSaved(recipe) ? "Saved" : "Not saved")
                    }
                }
                .alert("Recipe box", isPresented: Binding(get: { model.errorMessage != nil }, set: { if !$0 { model.errorMessage = nil } })) {
                    Button("OK", role: .cancel) { model.errorMessage = nil }
                } message: { Text(model.errorMessage ?? "") }
        }
    }

    private var shareText: String {
        "\(recipe.title)\n\(recipe.summary)\n\n\(recipe.minutes) minutes · \(recipe.servings) servings\n\nINGREDIENTS\n" +
        recipe.ingredients.map { "• \($0.amount) \($0.name)" }.joined(separator: "\n") +
        "\n\nMETHOD\n" + recipe.steps.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n\n") +
        "\n\nMade with Brilliant! Recipez. \(recipe.isDemo ? "Offline sample recipe." : "AI-generated; review ingredients, allergens, and cooking safety.")"
    }
}
