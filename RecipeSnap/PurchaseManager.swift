import StoreKit
import Foundation
class PurchaseManager: ObservableObject, @unchecked Sendable {
    @Published var isSubscribed: Bool = false
    @Published var products: [Product] = []
    @Published var error: String?
    @Published var isSubscriptionStatusLoaded: Bool = false
    private let productIDs = ["10"]

    init() {
        Task {
            for await verificationResult in Transaction.updates {
                if case .verified = verificationResult {
                    await checkSubscriptionStatus()
                }
            }
        }

        Task { @MainActor in
            await fetchProducts()
            await checkSubscriptionStatus()
        }
    }

    func fetchProducts() async {
        do {
            let fetchedProducts = try await Product.products(for: productIDs)
            await MainActor.run {
                print("Fetched Products: \(fetchedProducts.map { "\($0.id): \($0.displayName) - \($0.displayPrice)" }.joined(separator: "; "))")
                self.products = fetchedProducts.sorted(by: { $0.price < $1.price })
                self.error = nil
            }
        } catch {
            await MainActor.run {
                self.error = "Failed to load products: \(error.localizedDescription)"
                print("Fetch Products Error: \(error.localizedDescription)")
            }
        }
    }

    func purchase(product: Product) async {
        print("Initiating purchase for product: \(product.id) - \(product.displayName)")
        do {
            let result = try await product.purchase()
            print("Purchase result for \(product.id): \(result)")
            switch result {
            case .success(let verificationResult):
                if case .verified = verificationResult {
                    print("Purchase successful and verified for \(product.id)")
                    await checkSubscriptionStatus()
                } else {
                    print("Purchase verification failed for \(product.id)")
                }
            case .pending:
                await MainActor.run {
                    self.error = "Purchase is pending approval."
                    print("Purchase pending for \(product.id)")
                }
            case .userCancelled:
                print("Purchase cancelled by user for \(product.id)")
            @unknown default:
                print("Unknown purchase result for \(product.id)")
            }
        } catch {
            await MainActor.run {
                self.error = "Purchase failed: \(error.localizedDescription)"
                print("Purchase error for \(product.id): \(error.localizedDescription)")
            }
        }
    }

    func restorePurchases() async {
        var hasRestored = false
        for await verificationResult in Transaction.currentEntitlements {
            if case .verified = verificationResult {
                hasRestored = true
                break
            }
        }
        let finalHasRestored = hasRestored

        await MainActor.run {
            if finalHasRestored {
                Task {
                    await self.checkSubscriptionStatus()
                }
            } else {
                if !self.isSubscribed {
                    self.error = "No active subscriptions found."
                } else {
                    self.error = "No purchases to restore."
                }
            }
        }
    }

    func refreshTransactions() async {
        print("Forcing transaction refresh")
        await checkSubscriptionStatus()
    }

    func checkSubscriptionStatus() async {
        var isActive = false
        var transactionDetails: [String] = []

        for await verificationResult in Transaction.currentEntitlements {
            switch verificationResult {
            case .verified(let transaction):
                let productID = transaction.productID
                let transactionInfo = "Product ID: \(productID), Expiration: \(transaction.expirationDate?.description ?? "None")"
                transactionDetails.append(transactionInfo)
                print("Verified Transaction: \(transactionInfo)")

                if productID == "10" {
                    if let expirationDate = transaction.expirationDate {
                        let now = Date()
                        if now < expirationDate {
                            print("Subscription active: expires \(expirationDate)")
                            isActive = true
                            break
                        } else {
                            print("Subscription expired: expired on \(expirationDate)")
                        }
                    } else {
                        print("No expiration date (likely sandbox); assuming active")
                        isActive = true
                        break
                    }
                }
            case .unverified(let transaction, let error):
                print("Unverified Transaction: Product ID: \(transaction.productID), Error: \(error)")
                transactionDetails.append("Unverified: Product ID: \(transaction.productID), Error: \(error)")
            }
        }

        let finalIsActive = isActive
        let finalTransactionDetails = transactionDetails

        await MainActor.run {
            print("Subscription Status Check Complete: isSubscribed = \(finalIsActive)")
            print("Transactions Found: \(finalTransactionDetails.joined(separator: "; "))")
            self.isSubscribed = finalIsActive
            self.isSubscriptionStatusLoaded = true
        }
    }
}
