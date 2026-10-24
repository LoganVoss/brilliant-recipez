import SwiftUI
struct HeaderHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
struct NativeAdView: View {
    @Binding var isRecipeReady: Bool
    let isSubscribed: Bool
    @EnvironmentObject private var adViewModel: NativeAdViewModel
    @State private var headerHeight: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            let safeAreaTop = geometry.safeAreaInsets.top
            let safeAreaBottom = geometry.safeAreaInsets.bottom
            let topBuffer: CGFloat = 40
            let initialOffsetFactor: CGFloat = 0.33

            ZStack(alignment: .top) {
                Color.white.ignoresSafeArea()

                if isSubscribed {
                    ZStack {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [.red, .orange, .yellow, .green, .blue, .purple, .red]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: geometry.size.width, height: (geometry.size.height + safeAreaTop + safeAreaBottom + topBuffer) * adViewModel.loadingProgress)
                            .offset(y: (geometry.size.height + safeAreaBottom - (geometry.size.height * initialOffsetFactor)) * (1 - adViewModel.loadingProgress))
                            .animation(.linear(duration: 17), value: adViewModel.loadingProgress)
                            .ignoresSafeArea(.all, edges: .all)

                        Text("Your recipe is loading...")
                            .font(.custom("SuperJellyfish", size: 36))
                            .foregroundColor(.black)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                    }
                } else {
                }
            }
            .onAppear {
                adViewModel.startProgressAnimation()
            }
            .onChange(of: isRecipeReady) { oldValue, newValue in
                if newValue {
                    withAnimation {
                        adViewModel.stopLoading()
                    }
                }
            }
        }
    }
}
struct NativeAdView_Previews: PreviewProvider {
    static var previews: some View {
        NativeAdView(isRecipeReady: .constant(false), isSubscribed: true)
            .environmentObject(NativeAdViewModel())
    }
}
