import StoreKit

enum SubscriptionStatus {
    case active(expirationDate: Date?, isTrialPeriod: Bool, willAutoRenew: Bool)
    case inactive
    case unknown

    var isActive: Bool {
        if case .active = self { return true }
        return false
    }

    func toDictionary() -> [String: Any] {
        switch self {
        case .active(let expDate, let isTrial, let willRenew):
            var dict: [String: Any] = [
                "isActive": true,
                "isTrialPeriod": isTrial,
                "willAutoRenew": willRenew
            ]
            if let date = expDate {
                dict["expirationDate"] = ISO8601DateFormatter().string(from: date)
            }
            return dict
        case .inactive:
            return ["isActive": false, "isTrialPeriod": false, "willAutoRenew": false]
        case .unknown:
            return ["isActive": false, "isTrialPeriod": false, "willAutoRenew": false]
        }
    }
}

enum PurchaseResult {
    case success
    case userCancelled
    case pending
    case failed(String)

    func toDictionary() -> [String: Any] {
        switch self {
        case .success:
            return ["status": "success"]
        case .userCancelled:
            return ["status": "cancelled"]
        case .pending:
            return ["status": "pending"]
        case .failed(let message):
            return ["status": "failed", "error": message]
        }
    }
}

protocol SubscriptionStatusDelegate: AnyObject {
    func subscriptionStatusDidChange(_ status: SubscriptionStatus)
}

actor SubscriptionManager {
    static let productID = "com.nilehanov.realestateexam.premium.monthly"

    private var updateListenerTask: Task<Void, Error>?
    weak var delegate: SubscriptionStatusDelegate?

    init() {}

    func startListeningForTransactions() {
        updateListenerTask = Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard let self = self else { return }
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    let status = await self.checkSubscriptionStatus()
                    let currentDelegate = await self.delegate
                    await MainActor.run {
                        currentDelegate?.subscriptionStatusDidChange(status)
                    }
                }
            }
        }
    }

    func stopListening() {
        updateListenerTask?.cancel()
        updateListenerTask = nil
    }

    func getProducts() async throws -> [Product] {
        return try await Product.products(for: [Self.productID])
    }

    func purchase() async throws -> PurchaseResult {
        let products = try await getProducts()
        guard let product = products.first else {
            return .failed("Product not found")
        }

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            switch verification {
            case .verified(let transaction):
                await transaction.finish()
                return .success
            case .unverified(_, let error):
                return .failed("Verification failed: \(error.localizedDescription)")
            }
        case .userCancelled:
            return .userCancelled
        case .pending:
            return .pending
        @unknown default:
            return .failed("Unknown purchase result")
        }
    }

    func restorePurchases() async throws -> SubscriptionStatus {
        try await AppStore.sync()
        return await checkSubscriptionStatus()
    }

    func checkSubscriptionStatus() async -> SubscriptionStatus {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.productID == Self.productID {
                    if transaction.revocationDate != nil {
                        continue
                    }
                    if let expirationDate = transaction.expirationDate,
                       expirationDate < Date() {
                        continue
                    }

                    let isTrial: Bool
                    if #available(iOS 17.2, *) {
                        if let offer = transaction.offer {
                            isTrial = (offer.type == .introductory)
                        } else {
                            isTrial = false
                        }
                    } else {
                        isTrial = transaction.offerType == .introductory
                    }

                    // If the transaction has a future expiration and isn't revoked,
                    // assume auto-renew is active (no direct API on Transaction)
                    let willAutoRenew = transaction.expirationDate != nil
                        && transaction.revocationDate == nil

                    return .active(
                        expirationDate: transaction.expirationDate,
                        isTrialPeriod: isTrial,
                        willAutoRenew: willAutoRenew
                    )
                }
            }
        }
        return .inactive
    }
}
