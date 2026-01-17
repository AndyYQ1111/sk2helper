import Flutter
import StoreKit
import UIKit

public class SK2Plugin: NSObject, FlutterPlugin {

    // ================= 初始化状态（惰性初始化） =================
    private static var initialized = false
    private static var initializingTask: Task<Void, Never>?

    // 周期映射
    private let periodTitles: [String: String] = [
        "day": "Daily",
        "week": "Weekly",
        "month": "Monthly",
        "year": "Yearly",
    ]

    // MARK: - Flutter Plugin Register
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "sk2helper",
            binaryMessenger: registrar.messenger()
        )
        let instance = SK2Plugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    // MARK: - Entry
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if #available(iOS 15.0, *) {
            handleSK2Call(call, result: result)
        } else {
            result(
                FlutterError(
                    code: "UNSUPPORTED_VERSION",
                    message: "StoreKit2 requires iOS 15.0+",
                    details: nil
                ))
        }
    }

    // MARK: - Lazy Init Guard
    @available(iOS 15.0, *)
    private static func ensureInitialized() async {
        if initialized { return }

        if let task = initializingTask {
            await task.value
            return
        }

        let task = Task {
            await SK2Handler.initialize()
            initialized = true
        }

        initializingTask = task
        await task.value
        initializingTask = nil
    }

    // MARK: - Method Router
    @available(iOS 15.0, *)
    private func handleSK2Call(
        _ call: FlutterMethodCall,
        result: @escaping FlutterResult
    ) {
        switch call.method {

        case "fetchProducts":
            handleFetchProducts(call, result: result)

        case "buyProduct":
            handleBuyProduct(call, result: result)

        case "restorePurchases":
            handleRestorePurchases(result)

        case "hasActiveSubscription":
            handleHasActiveSubscription(result)

        case "getPurchaseHistory":
            handleGetPurchaseHistory(result)

        case "getSubscriptionStatus":
            handleGetSubscriptionStatus(call, result: result)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Fetch Products
    @available(iOS 15.0, *)
    private func handleFetchProducts(
        _ call: FlutterMethodCall,
        result: @escaping FlutterResult
    ) {
        Task {
            await SK2Plugin.ensureInitialized()

            guard let args = call.arguments as? [String: Any],
                let productIds = args["productIds"] as? [String]
            else {
                result(
                    FlutterError(
                        code: "INVALID_ARGS",
                        message: "Missing productIds",
                        details: nil
                    ))
                return
            }

            SK2Handler.fetchProducts(productIds: productIds) { fetchResult in
                switch fetchResult {
                case .success(let products):
                    let list = products.map { self.productToMap($0) }
                    result(list)
                case .failure(let error):
                    result(
                        FlutterError(
                            code: "FETCH_ERROR",
                            message: error.localizedDescription,
                            details: nil
                        ))
                }
            }
        }
    }

    // MARK: - Product Mapping
    @available(iOS 15.0, *)
    private func productToMap(_ product: Product) -> [String: Any] {
        var data: [String: Any] = [
            "id": product.id,
            "name": product.displayName,
            "desc": product.description,
            "price": Double(truncating: product.price as NSNumber),
            "localPrice": product.displayPrice,
            "type": product.type.rawValue,
            "rawJson": String(
                data: product.jsonRepresentation,
                encoding: .utf8
            ) ?? "",
        ]

        if let sub = product.subscription {
            let unit = String(describing: sub.subscriptionPeriod.unit).lowercased()

            data["periodUnit"] = unit
            data["periodValue"] = sub.subscriptionPeriod.value
            data["period"] = periodTitles[unit] ?? ""

            if let intro = sub.introductoryOffer {
                data["introOffer"] = intro.paymentMode.rawValue
                data["introPeriod"] =
                    "\(intro.period.value) \(intro.period.unit)"
                data["hasTrial"] =
                    intro.paymentMode == .free || intro.paymentMode == .payAsYouGo
            } else {
                data["introOffer"] = ""
                data["introPeriod"] = ""
                data["hasTrial"] = false
            }
        } else {
            data["periodUnit"] = ""
            data["periodValue"] = 0
            data["period"] = ""
            data["introOffer"] = ""
            data["introPeriod"] = ""
            data["hasTrial"] = false
        }

        return data
    }

    // MARK: - Buy Product
    @available(iOS 15.0, *)
    private func handleBuyProduct(
        _ call: FlutterMethodCall,
        result: @escaping FlutterResult
    ) {
        Task {
            await SK2Plugin.ensureInitialized()

            guard let args = call.arguments as? [String: Any],
                let productId = args["productId"] as? String
            else {
                result(
                    FlutterError(
                        code: "INVALID_ARGS",
                        message: "Missing productId",
                        details: nil
                    ))
                return
            }

            SK2Handler.buyProduct(productId: productId) {
                success, error, transaction in

                if success, let tx = transaction {
                    let data: [String: Any] = [
                        "id": String(tx.id),
                        "productId": tx.productID,
                        "bundleId": tx.appBundleID,
                        "purchaseTime":
                            Int(tx.purchaseDate.timeIntervalSince1970 * 1000),
                        "originalPurchaseTime":
                            Int(tx.originalPurchaseDate.timeIntervalSince1970 * 1000),
                        "expireTime":
                            tx.expirationDate.map {
                                Int($0.timeIntervalSince1970 * 1000)
                            } ?? 0,
                        "rawJson":
                            String(
                                data: tx.jsonRepresentation,
                                encoding: .utf8
                            ) ?? "",
                    ]
                    result(data)
                } else {
                    result(
                        FlutterError(
                            code: "PURCHASE_FAILED",
                            message: error?.localizedDescription ?? "Purchase failed",
                            details: ["code": (error as NSError?)?.code ?? 999]
                        ))
                }
            }
        }
    }

    // MARK: - Restore
    @available(iOS 15.0, *)
    private func handleRestorePurchases(_ result: @escaping FlutterResult) {
        Task {
            await SK2Plugin.ensureInitialized()

            SK2Handler.restorePurchases { success, items, error in
                if success {
                    result(items ?? [])
                } else {
                    result(
                        FlutterError(
                            code: "RESTORE_FAILED",
                            message: error?.localizedDescription ?? "Restore failed",
                            details: nil
                        ))
                }
            }
        }
    }

    // MARK: - Active Subscription
    @available(iOS 15.0, *)
    private func handleHasActiveSubscription(_ result: @escaping FlutterResult) {
        Task {
            await SK2Plugin.ensureInitialized()
            let active = await SK2Handler.hasActiveSubscription()
            result(active)
        }
    }

    // MARK: - Purchase History
    @available(iOS 15.0, *)
    private func handleGetPurchaseHistory(_ result: @escaping FlutterResult) {
        Task {
            await SK2Plugin.ensureInitialized()
            let history = await SK2Handler.getPurchaseHistory()
            result(history)
        }
    }

    // MARK: - Subscription Status
    @available(iOS 15.0, *)
    private func handleGetSubscriptionStatus(
        _ call: FlutterMethodCall,
        result: @escaping FlutterResult
    ) {
        Task {
            await SK2Plugin.ensureInitialized()

            guard let args = call.arguments as? [String: Any],
                let productId = args["productId"] as? String
            else {
                result(
                    FlutterError(
                        code: "INVALID_ARGS",
                        message: "Missing productId",
                        details: nil
                    ))
                return
            }

            let status =
                await SK2Handler.getSubscriptionStatus(productId: productId)
            result(status)
        }
    }
}
