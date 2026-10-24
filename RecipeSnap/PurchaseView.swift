import SwiftUI
import StoreKit
import UIKit
struct PurchaseView: View {
    @ObservedObject var purchaseManager: PurchaseManager
    @Binding var showSubscriptionSplash: Bool
    @State private var animateLogo = false
    @State private var animateTitle = false

    private let privacyPolicyURL = URL(string: "https://sites.google.com/view/recipesnap/home")!
    private let termsOfUseURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.white.edgesIgnoringSafeArea(.all)

                VStack(spacing: 20) {
                    Spacer()

                    Image("RecipeSnap")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 236, height: 236)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .scaleEffect(animateLogo ? 1 : 0.5)
                        .opacity(animateLogo ? 1 : 0)

                    Text(purchaseManager.isSubscribed ? "Unlimited" : "Go Unlimited")
                        .font(.custom("SuperJellyfish", size: 56))
                        .foregroundColor(.black)
                        .scaleEffect(animateTitle ? 1 : 0.5)
                        .opacity(animateTitle ? 1 : 0)

                    if !purchaseManager.isSubscribed {
                        Text("Free trial includes 5 recipe generations.")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.black.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                            .scaleEffect(animateTitle ? 1 : 0.5)
                            .opacity(animateTitle ? 1 : 0)

                        Text("Unlock unlimited recipes and instant \"New Recipe\" generations for the same photo!")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.black.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                            .scaleEffect(animateTitle ? 1 : 0.5)
                            .opacity(animateTitle ? 1 : 0)

                        RainbowTextView(text: "Recipe Snap without limits ⤵️")
                            .scaleEffect(animateTitle ? 1 : 0.5)
                            .opacity(animateTitle ? 1 : 0)

                        if purchaseManager.products.isEmpty {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.black)
                                .scaleEffect(1.5)
                        } else {
                            ForEach(purchaseManager.products) { product in
                                Button(action: {
                                    print("Purchase button tapped for product: \(product.id) - \(product.displayName)")
                                    Task {
                                        await purchaseManager.purchase(product: product)
                                    }
                                }) {
                                    Text(product.displayName + " - " + product.displayPrice)
                                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                                        .padding(.vertical, 12)
                                        .padding(.horizontal, 24)
                                        .background(Color.black)
                                        .foregroundColor(.white)
                                        .clipShape(Capsule())
                                        .scaleEffect(animateTitle ? 1 : 0.5)
                                        .opacity(animateTitle ? 1 : 0)
                                }
                            }
                        }

                        Button(action: {
                            print("Restore Purchases button tapped")
                            Task {
                                await purchaseManager.restorePurchases()
                            }
                        }) {
                            Text("Restore Purchases")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.black.opacity(0.7))
                                .scaleEffect(animateTitle ? 1 : 0.5)
                                .opacity(animateTitle ? 1 : 0)
                        }
                        .padding(.vertical, 10)

                        Text("Privacy Policy")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.blue)
                            .onTapGesture {
                                print("Privacy Policy tapped")
                                UIApplication.shared.open(privacyPolicyURL)
                            }
                            .scaleEffect(animateTitle ? 1 : 0.5)
                            .opacity(animateTitle ? 1 : 0)

                        Text("Terms of Use")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.blue)
                            .onTapGesture {
                                print("Terms of Use tapped")
                                UIApplication.shared.open(termsOfUseURL)
                            }
                            .scaleEffect(animateTitle ? 1 : 0.5)
                            .opacity(animateTitle ? 1 : 0)

                        if let error = purchaseManager.error {
                            Text(error)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.red)
                                .padding(.horizontal, 20)
                                .padding(.top, 10)
                        }
                    } else {
                        RainbowTextView(text: "You're subscribed to Recipe Snap Unlimited!")
                            .scaleEffect(animateTitle ? 1 : 0.5)
                            .opacity(animateTitle ? 1 : 0)

                        Text("Manage this subscription in settings.")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.black.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                            .scaleEffect(animateTitle ? 1 : 0.5)
                            .opacity(animateTitle ? 1 : 0)

                        Text("Privacy Policy")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.blue)
                            .onTapGesture {
                                print("Privacy Policy tapped")
                                UIApplication.shared.open(privacyPolicyURL)
                            }
                            .scaleEffect(animateTitle ? 1 : 0.5)
                            .opacity(animateTitle ? 1 : 0)

                        Text("Terms of Use")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.blue)
                            .onTapGesture {
                                print("Terms of Use tapped")
                                UIApplication.shared.open(termsOfUseURL)
                            }
                            .scaleEffect(animateTitle ? 1 : 0.5)
                            .opacity(animateTitle ? 1 : 0)
                    }

                    Spacer()
                }

                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            print("Close button tapped")
                            triggerHaptic()
                            withAnimation(.easeOut(duration: 0.69)) {
                                showSubscriptionSplash = false
                            }
                            print("After setting in PurchaseView, showSubscriptionSplash: \(showSubscriptionSplash)")
                        }) {
                            Image(systemName: "xmark")
                                .foregroundColor(.black)
                                .font(.system(size: 20))
                                .frame(width: 44, height: 44)
                                .background(Color.white.opacity(0.5))
                                .clipShape(Circle())
                        }
                        .padding(.trailing, 7)
                        .padding(.top, 77)
                    }
                    Spacer()
                }
                .ignoresSafeArea(.all, edges: .top)
            }
            .transition(.opacity)
            .animation(.easeOut(duration: 1.0), value: showSubscriptionSplash)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.0)) {
                    animateLogo = true
                }
                withAnimation(.easeInOut(duration: 1.0).delay(0.6)) {
                    animateTitle = true
                }
            }
        }
    }

    private func triggerHaptic() {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }
}
struct RainbowTextView: View {
    let text: String

    var body: some View {
        TimelineView(.animation) { context in
            let time = context.date.timeIntervalSince1970
            let phase = (time.truncatingRemainder(dividingBy: 2)) / 1

            Text(text)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            .red, .orange, .yellow, .green, .blue, .purple, .red
                        ]),
                        startPoint: UnitPoint(x: phase - 1.0, y: 0),
                        endPoint: UnitPoint(x: phase, y: -1)
                    )
                )
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
    }
}
struct PurchaseView_Previews: PreviewProvider {
    static var previews: some View {
        let purchaseManager = PurchaseManager()
        purchaseManager.products = []
        return PurchaseView(purchaseManager: purchaseManager, showSubscriptionSplash: .constant(true))
    }
}
