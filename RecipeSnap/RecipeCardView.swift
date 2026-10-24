import SwiftUI
import UIKit
struct RecipeCardView: View {
    let recipe: Recipe
    let isFromBookmarks: Bool
    let onBack: () -> Void
    let onNewRecipe: () -> Void
    let isSubscribed: Bool
    @State private var recipeImage: Image?
    @State private var isBookmarked = false
    @EnvironmentObject private var bookmarkManager: BookmarkManager
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                imageSection
                titleSection
                contentSection
                buttonSection
            }
            .padding(.vertical, 20)
        }
        .background(Color.white)
        .onAppear {
            loadImage()
            isBookmarked = bookmarkManager.isBookmarked(recipe)
        }
    }
    private var imageSection: some View {
        Group {
            if let recipeImage = recipeImage {
                recipeImage
                    .resizable()
                    .scaledToFill()
                    .frame(width: 400)
                    .frame(height: 250)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .clipped()
            } else {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.black)
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity)
                    .frame(height: 250)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color.black.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
    private var titleSection: some View {
        VStack(spacing: 8) {
            Text(recipe.title)
                .font(.custom("SuperJellyfish", size: 36))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Text(recipe.description)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.black.opacity(0.8))
                .padding(.horizontal)
        }
    }
    private var contentSection: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Ingredients")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(.black)
                ForEach(recipe.ingredients.components(separatedBy: ", ").map { $0.trimmingCharacters(in: .whitespaces) }, id: \.self) { ingredient in
                    Text("• \(ingredient)")
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundColor(.black.opacity(0.7))
                        .padding(.vertical, 2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            VStack(alignment: .leading, spacing: 8) {
                Text("Preparation")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(.black)
                ForEach(Array(recipe.instructions.enumerated()), id: \.offset) { index, step in
                    Text("\(index + 1).) \(step)")
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundColor(.black.opacity(0.7))
                        .padding(.vertical, 2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        .padding(.horizontal, 16)
    }
    private var buttonSection: some View {
        VStack(spacing: 10) {
            if !isFromBookmarks {
                Button(action: {
                    triggerHaptic()
                    isBookmarked.toggle()
                    if isBookmarked {
                        bookmarkManager.addRecipe(recipe)
                    } else {
                        bookmarkManager.removeRecipe(recipe)
                    }
                }) {
                    Text(isBookmarked ? "Remove Bookmark" : "Bookmark Recipe")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .padding(.vertical, 12)
                        .padding(.horizontal, 24)
                        .background(Color.black)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
            } else {
                Button(action: {
                    triggerHaptic()
                    bookmarkManager.removeRecipe(recipe)
                    onBack()
                }) {
                    Text("Remove Bookmark")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .padding(.vertical, 12)
                        .padding(.horizontal, 24)
                        .background(Color.black)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
            }
            if isSubscribed && !isFromBookmarks {
                Button(action: {
                    triggerHaptic()
                    onNewRecipe()
                }) {
                    Text("New Recipe")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .padding(.vertical, 12)
                        .padding(.horizontal, 24)
                        .background(Color.black)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
                Button(action: {
                    triggerHaptic()
                    onBack()
                }) {
                    Text("Home")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .padding(.vertical, 12)
                        .padding(.horizontal, 24)
                        .background(Color.black)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
            } else {
                Button(action: {
                    triggerHaptic()
                    onBack()
                }) {
                    Text(isFromBookmarks ? "Back" : "New Recipe")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .padding(.vertical, 12)
                        .padding(.horizontal, 24)
                        .background(Color.black)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
                .padding(.vertical, 10)
            }
        }
    }
    private func triggerHaptic() {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }
    private func loadImage() {
        if let data = Data(base64Encoded: recipe.imageBase64),
           let uiImage = UIImage(data: data) {
            recipeImage = Image(uiImage: uiImage)
        } else {
            recipeImage = Image(systemName: "photo")
        }
    }
}
struct RecipeCardView_Previews: PreviewProvider {
    static var previews: some View {
        RecipeCardView(
            recipe: Recipe(
                id: UUID(),
                title: "Sample Recipe",
                description: "A delicious dish!",
                ingredients: "Ingredient 1, Ingredient 2",
                instructions: ["Step 1: Do this.", "Step 2: Do that."],
                imageBase64: "",
                createdAt: Date()
            ),
            isFromBookmarks: false,
            onBack: {},
            onNewRecipe: {},
            isSubscribed: false
        )
        .environmentObject(BookmarkManager())
    }
}
