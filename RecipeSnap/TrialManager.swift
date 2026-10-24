import Foundation
import UIKit
class TrialManager: ObservableObject {
    @Published var remainingUses: Int = 5
    private let totalLimit = 5
    private let usesKeyPrefix = "RecipeSnapUses_"
    private var deviceIdentifier: String {
        return UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString // Fallback to UUID if no vendor ID
    }
    private var usesKey: String {
        return usesKeyPrefix + deviceIdentifier
    }

    init() {
        loadUsage()
    }

    func canGenerateRecipe() -> Bool {
        return remainingUses > 0
    }

    func useRecipe() {
        if remainingUses > 0 {
            remainingUses -= 1
            saveUsage()
        }
    }

    private func saveUsage() {
        UserDefaults.standard.set(remainingUses, forKey: usesKey)
    }

    private func loadUsage() {
        let storedUses = UserDefaults.standard.integer(forKey: usesKey)
        if storedUses == 0 && UserDefaults.standard.object(forKey: usesKey) == nil {
            remainingUses = totalLimit
        } else {
            remainingUses = min(storedUses, totalLimit)
        }
        saveUsage()
    }
}
