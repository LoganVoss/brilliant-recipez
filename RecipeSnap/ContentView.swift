import SwiftUI
import UIKit
struct ContentView: View {
    @StateObject private var viewModel = RecipeViewModel()
    @StateObject private var trialManager = TrialManager()
    @StateObject private var purchaseManager = PurchaseManager()
    @StateObject private var adViewModel = NativeAdViewModel()
    @State private var showCamera = false
    @State private var showRecipe = false
    @State private var showCollection = false
    @State private var showNativeAd = false
    @State private var showSubscriptionSplash = false
    @State private var hasShownSubscriptionSplash = false
    @State private var animateLogo = false
    @State private var animateBookmark = false
    @State private var animateTitle = false
    @State private var animateDescription = false
    @State private var animateButton = false
    @State private var animateSubscriptionText = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.white.edgesIgnoringSafeArea(.all)

                if showRecipe, let recipe = viewModel.recipe {
                    RecipeCardView(
                        recipe: recipe,
                        isFromBookmarks: false,
                        onBack: {
                            withAnimation {
                                triggerHaptic()
                                showRecipe = false
                                viewModel.recipe = nil
                                if !purchaseManager.isSubscribed && trialManager.remainingUses == 0 && !hasShownSubscriptionSplash {
                                    print("Showing subscription splash from RecipeCardView onBack")
                                    showSubscriptionSplash = true
                                    hasShownSubscriptionSplash = true
                                }
                            }
                        },
                        onNewRecipe: {
                            if let lastImageData = viewModel.lastImageData {
                                withAnimation {
                                    adViewModel.startProgressAnimation()
                                    showNativeAd = true
                                    viewModel.processPhoto(lastImageData) { result in
                                        DispatchQueue.main.async {
                                            showNativeAd = false
                                            if !result {
                                                showRecipe = false
                                                viewModel.recipe = nil
                                                if !purchaseManager.isSubscribed && trialManager.remainingUses == 0 && !hasShownSubscriptionSplash {
                                                    print("Showing subscription splash from RecipeCardView onNewRecipe")
                                                    showSubscriptionSplash = true
                                                    hasShownSubscriptionSplash = true
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        },
                        isSubscribed: purchaseManager.isSubscribed
                    )
                    .environmentObject(viewModel)
                    .transition(.opacity)
                } else if showCollection {
                    RecipeCollectionView(onBack: {
                        withAnimation(.easeOut(duration: 0.69)) {
                            triggerHaptic()
                            showCollection = false
                            if !purchaseManager.isSubscribed && trialManager.remainingUses == 0 && !hasShownSubscriptionSplash {
                                print("Showing subscription splash from RecipeCollectionView onBack")
                                showSubscriptionSplash = true
                                hasShownSubscriptionSplash = true
                            }
                        }
                    })
                    .transition(.opacity)
                    .animation(.easeOut(duration: 0.69), value: showCollection)
                } else if showSubscriptionSplash {
                    PurchaseView(
                        purchaseManager: purchaseManager,
                        showSubscriptionSplash: $showSubscriptionSplash
                    )
                    .environmentObject(viewModel)
                    .background(Color.white)
                    .transition(.opacity)
                    .animation(.easeOut(duration: 0.69), value: showSubscriptionSplash)
                    .zIndex(1)
                    .onDisappear {
                        print("PurchaseView disappeared, resetting hasShownSubscriptionSplash")
                        hasShownSubscriptionSplash = false
                    }
                } else {
                    VStack(spacing: 20) {
                        Spacer()

                        VStack(spacing: 10) {
                            Image("RecipeSnap")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 236, height: 236)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .scaleEffect(animateLogo ? 1 : 0.5)
                                .opacity(animateLogo ? 1 : 0)

                            Text("Recipe Snap")
                                .font(.custom("SuperJellyfish", size: 36))
                                .foregroundColor(.black)
                                .scaleEffect(animateTitle ? 1 : 0.5)
                                .opacity(animateTitle ? 1 : 0)

                            RainbowTextView(text: "Snap ingredients to get a delicious recipe!")
                                .scaleEffect(animateTitle ? 1 : 0.5)
                                .opacity(animateTitle ? 1 : 0)
                                .padding(.bottom, 30)

                            Button(action: {
                                triggerHaptic()
                                if purchaseManager.isSubscribed || trialManager.canGenerateRecipe() {
                                    adViewModel.startProgressAnimation()
                                    showCamera = true
                                } else {
                                    print("Showing subscription splash from Snap Photo button")
                                    showSubscriptionSplash = true
                                    hasShownSubscriptionSplash = true
                                }
                            }) {
                                Text("Snap Photo")
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 24)
                                    .background(Color.black)
                                    .foregroundColor(.white)
                                    .clipShape(Capsule())
                                    .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
                            }
                            .fullScreenCover(isPresented: $showCamera) {
                                ZStack {
                                    Color.black
                                        .ignoresSafeArea(.all)
                                    CameraPicker { imageData in
                                        if let imageData = imageData {
                                            withAnimation {
                                                adViewModel.startProgressAnimation()
                                                showNativeAd = true
                                                viewModel.lastImageData = imageData
                                                viewModel.processPhoto(imageData) { result in
                                                    DispatchQueue.main.async {
                                                        showNativeAd = false
                                                        if result {
                                                            showRecipe = true
                                                            if !purchaseManager.isSubscribed {
                                                                trialManager.useRecipe()
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    .ignoresSafeArea(.all)
                                }
                                .background(Color.black)
                                .animation(.easeInOut(duration: 0.3), value: showCamera)
                            }
                            .scaleEffect(animateButton ? 1 : 0.5)
                            .opacity(animateButton ? 1 : 0)

                            if purchaseManager.isSubscriptionStatusLoaded && !purchaseManager.isSubscribed {
                                Text("Recipes Remaining: \(trialManager.remainingUses)")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(.black.opacity(0.7))
                                    .opacity(animateSubscriptionText ? 1 : 0)
                            }

                            if viewModel.isLoading && !showNativeAd {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(.black)
                                    .scaleEffect(1.5)
                            }

                            if let error = viewModel.errorMessage {
                                Text(error)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.black.opacity(0.8))
                                    .padding(.horizontal, 20)
                                    .padding(.top, 10)
                            }
                        }
                        .padding(20)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                        .padding(.horizontal, 16)

                        Spacer()
                    }
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1.0)) {
                            animateLogo = true
                        }
                        withAnimation(.easeInOut(duration: 1.0).delay(0.3)) {
                            animateBookmark = true
                        }
                        withAnimation(.easeInOut(duration: 1.0).delay(0.6)) {
                            animateTitle = true
                        }
                        withAnimation(.easeInOut(duration: 1.0).delay(0.9)) {
                            animateDescription = true
                        }
                        withAnimation(.easeInOut(duration: 1.0).delay(1.2)) {
                            animateButton = true
                        }
                        if purchaseManager.isSubscriptionStatusLoaded {
                            withAnimation(.easeInOut(duration: 1.0).delay(1.5)) {
                                animateSubscriptionText = true
                            }
                        }
                        if purchaseManager.isSubscriptionStatusLoaded && !purchaseManager.isSubscribed && trialManager.remainingUses == 0 && !hasShownSubscriptionSplash {
                            print("Showing subscription splash from onAppear")
                            showSubscriptionSplash = true
                            hasShownSubscriptionSplash = true
                        }
                    }
                    .onChange(of: purchaseManager.isSubscriptionStatusLoaded) { _, isLoaded in
                        if isLoaded {
                            withAnimation(.easeInOut(duration: 1.0).delay(1.5)) {
                                animateSubscriptionText = true
                            }
                            if !purchaseManager.isSubscribed && trialManager.remainingUses == 0 && !hasShownSubscriptionSplash {
                                print("Showing subscription splash from onChange")
                                showSubscriptionSplash = true
                                hasShownSubscriptionSplash = true
                            }
                        }
                    }
                }

                if !showCollection && !showSubscriptionSplash && !showRecipe {
                    VStack {
                        HStack {
                            Button(action: {
                                triggerHaptic()
                                showCollection = true
                            }) {
                                Image(systemName: "bookmark")
                                    .foregroundColor(.black)
                                    .font(.system(size: 20))
                                    .frame(height: 165)
                            }
                            .padding(.leading, 20)
                            .scaleEffect(animateBookmark ? 1 : 0.5)
                            .opacity(animateBookmark ? 1 : 0)

                            Spacer()

                            Button(action: {
                                triggerHaptic()
                                print("Showing subscription splash from cart button")
                                showSubscriptionSplash = true
                                hasShownSubscriptionSplash = true
                            }) {
                                Image(systemName: "cart")
                                    .foregroundColor(.black)
                                    .font(.system(size: 20))
                                    .frame(height: 165)
                            }
                            .padding(.trailing, 20)
                            .scaleEffect(animateBookmark ? 1 : 0.5)
                            .opacity(animateBookmark ? 1 : 0)
                        }
                        .padding(.top, 20)
                        .ignoresSafeArea(.all, edges: .top)
                        Spacer()
                    }
                }

                if showNativeAd {
                    NativeAdView(
                        isRecipeReady: Binding(
                            get: { viewModel.recipe != nil && !viewModel.isLoading },
                            set: { _ in }
                        ),
                        isSubscribed: true
                    )
                    .environmentObject(adViewModel)
                    .transition(.opacity)
                }
            }
        }
        .animation(.easeOut(duration: 0.69), value: showRecipe || showCollection || showNativeAd)
        .environmentObject(BookmarkManager())
    }

    private func triggerHaptic() {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }
}
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
