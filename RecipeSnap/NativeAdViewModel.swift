import Foundation
import SwiftUI
class NativeAdViewModel: NSObject, ObservableObject {
    @Published var loadingProgress: CGFloat = 0.0
    @Published var isAdLoading: Bool = false

    private var progressTimer: Timer?

    override init() {
        super.init()
    }

    func startProgressAnimation() {
        loadingProgress = 0.0

        stopProgressAnimation()

        let duration: TimeInterval = 17.0
        let interval: TimeInterval = 0.0167
        let increment = interval / duration

        progressTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }

            self.loadingProgress += increment
            if self.loadingProgress >= 1.0 {
                self.loadingProgress = 1.0
                timer.invalidate()
                self.progressTimer = nil
            }
        }
    }

    func stopProgressAnimation() {
        progressTimer?.invalidate()
        progressTimer = nil
        loadingProgress = 0.0
    }

    func stopLoading() {
        stopProgressAnimation()
    }
}
