import Capacitor
import StoreKit

@objc(StoreKitPlugin)
public class StoreKitPlugin: CAPPlugin, CAPBridgedPlugin, SubscriptionStatusDelegate {
    public let identifier = "StoreKitPlugin"
    public let jsName = "StoreKit"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "getProducts", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "purchase", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "restorePurchases", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "getSubscriptionStatus", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "isDebugBuild", returnType: CAPPluginReturnPromise),
    ]

    private let manager = SubscriptionManager()

    override public func load() {
        Task {
            await manager.setDelegate(self)
            await manager.startListeningForTransactions()
        }
    }

    @objc func getProducts(_ call: CAPPluginCall) {
        Task {
            do {
                let products = try await manager.getProducts()
                let productList = products.map { product -> [String: Any] in
                    var dict: [String: Any] = [
                        "id": product.id,
                        "displayName": product.displayName,
                        "description": product.description,
                        "displayPrice": product.displayPrice,
                        "price": NSDecimalNumber(decimal: product.price).doubleValue
                    ]

                    if let subscription = product.subscription {
                        dict["subscriptionPeriod"] = [
                            "unit": String(describing: subscription.subscriptionPeriod.unit),
                            "value": subscription.subscriptionPeriod.value
                        ]

                        if let intro = subscription.introductoryOffer {
                            dict["introductoryOffer"] = [
                                "type": String(describing: intro.type),
                                "period": [
                                    "unit": String(describing: intro.period.unit),
                                    "value": intro.period.value
                                ],
                                "displayPrice": intro.displayPrice
                            ]
                        }
                    }
                    return dict
                }
                call.resolve(["products": productList])
            } catch {
                call.reject("Failed to fetch products: \(error.localizedDescription)")
            }
        }
    }

    @objc func purchase(_ call: CAPPluginCall) {
        Task {
            do {
                let result = try await manager.purchase()
                call.resolve(result.toDictionary())
            } catch {
                call.reject("Purchase failed: \(error.localizedDescription)")
            }
        }
    }

    @objc func restorePurchases(_ call: CAPPluginCall) {
        Task {
            do {
                let status = try await manager.restorePurchases()
                call.resolve(status.toDictionary())
            } catch {
                call.reject("Restore failed: \(error.localizedDescription)")
            }
        }
    }

    @objc func getSubscriptionStatus(_ call: CAPPluginCall) {
        Task {
            let status = await manager.checkSubscriptionStatus()
            call.resolve(status.toDictionary())
        }
    }

    @objc func isDebugBuild(_ call: CAPPluginCall) {
        #if DEBUG
        call.resolve(["isDebug": true])
        #else
        call.resolve(["isDebug": false])
        #endif
    }

    // MARK: - SubscriptionStatusDelegate

    nonisolated func subscriptionStatusDidChange(_ status: SubscriptionStatus) {
        notifyListeners("subscriptionStatusChanged", data: status.toDictionary())
    }
}

// Extension to allow setting delegate from outside the actor
extension SubscriptionManager {
    func setDelegate(_ delegate: SubscriptionStatusDelegate) {
        self.delegate = delegate
    }
}
