import SwiftUI
struct RecipeCollectionView: View {
    let onBack: () -> Void
    @EnvironmentObject private var bookmarkManager: BookmarkManager
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @StateObject private var viewModel = RecipeViewModel()
    @State private var selectedRecipe: Recipe?

    var body: some View {
        ZStack {
            Color.white.edgesIgnoringSafeArea(.all)

            if let selectedRecipe = selectedRecipe {
                RecipeCardView(
                    recipe: selectedRecipe,
                    isFromBookmarks: true,
                    onBack: {
                        withAnimation {
                            triggerHaptic()
                            self.selectedRecipe = nil
                        }
                    },
                    onNewRecipe: { },
                    isSubscribed: purchaseManager.isSubscribed
                )
                .environmentObject(viewModel)
                .transition(.opacity)
            } else {
                VStack(spacing: 20) {
                    HStack {
                        Text("Recipe Collection")
                            .font(.custom("SuperJellyfish", size: 36))
                            .foregroundColor(.black)
                        Spacer()
                        Button(action: {
                            withAnimation(.easeOut(duration: 0.69)) {
                                triggerHaptic()
                                onBack()
                            }
                        }) {
                            Image(systemName: "xmark")
                                .foregroundColor(.black)
                                .font(.system(size: 20))
                        }
                    }
                    .padding(.horizontal)

                    if bookmarkManager.bookmarkedRecipes.isEmpty {
                        Text("No saved recipes yet.")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.black.opacity(0.7))
                            .padding(.top, 20)
                    } else {
                        List {
                            ForEach(bookmarkManager.bookmarkedRecipes) { recipe in
                                Button(action: {
                                    triggerHaptic()
                                    selectedRecipe = recipe
                                }) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(recipe.title)
                                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                                            .foregroundColor(.black)
                                        Text(recipe.description)
                                            .font(.system(size: 14, weight: .regular, design: .rounded))
                                            .foregroundColor(.black.opacity(0.7))
                                            .lineLimit(2)
                                    }
                                    .padding(.vertical, 4)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .listRowBackground(Color.white)
                                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                            }
                        }
                        .listStyle(.plain)
                    }

                    Spacer()
                }
                .padding(.top, 20)
            }
        }
        .animation(.easeOut(duration: 0.69), value: selectedRecipe != nil)
    }

    private func triggerHaptic() {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }
}
struct RecipeCollectionView_Previews: PreviewProvider {
    static var previews: some View {
        RecipeCollectionView(onBack: {})
            .environmentObject(BookmarkManager())
            .environmentObject(PurchaseManager())
    }
}
