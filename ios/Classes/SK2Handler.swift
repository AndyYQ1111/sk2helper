import StoreKit
import Foundation

@available(iOS 15.0, *)
class SK2Handler {

    // ================= 全局监听状态 =================
    private static var updatesTask: Task<Void, Never>?

    // MARK: - Initialize (NON-BLOCKING)
    static func initialize() async {
        guard updatesTask == nil else { return }

        updatesTask = Task.detached(priority: .background) {
            for await result in Transaction.updates {
                guard case .verified(let transaction) = result else {
                    continue
                }

                // 自动完成交易（订阅 / 非消耗）
                await transaction.finish()
            }
        }
    }

    // MARK: - Fetch Products
    static func fetchProducts(
        productIds: [String],
        completion: @escaping (Result<[Product], Error>) -> Void
    ) {
        Task {
            do {
                let products = try await Product.products(for: productIds)
                completion(.success(products))
            } catch {
                completion(.failure(error))
            }
        }
    }

    // MARK: - Active Subscription Check
    static func hasActiveSubscription() async -> Bool {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.revocationDate == nil {
                return true
            }
        }
        return false
    }

    // MARK: - Buy Product
    static func buyProduct(
        productId: String,
        completion: @escaping (Bool, Error?, Transaction?) -> Void
    ) {
        Task {
            do {
                let products = try await Product.products(for: [productId])
                guard let product = products.first else {
                    completion(false,
                               NSError(
                                domain: "SK2Error",
                                code: 404,
                                userInfo: [NSLocalizedDescriptionKey: "Product not found"]
                               ),
                               nil)
                    return
                }

                let result = try await product.purchase()

                switch result {
                case .success(let verification):
                    guard case .verified(let transaction) = verification else {
                        completion(false,
                                   NSError(
                                    domain: "SK2Error",
                                    code: 403,
                                    userInfo: [NSLocalizedDescriptionKey: "Transaction unverified"]
                                   ),
                                   nil)
                        return
                    }

                    await transaction.finish()
                    completion(true, nil, transaction)

                case .pending:
                    completion(false,
                               NSError(
                                domain: "SK2Error",
                                code: 100,
                                userInfo: [NSLocalizedDescriptionKey: "Purchase pending"]
                               ),
                               nil)

                case .userCancelled:
                    completion(false,
                               NSError(
                                domain: "SK2Error",
                                code: 401,
                                userInfo: [NSLocalizedDescriptionKey: "Purchase cancelled"]
                               ),
                               nil)

                @unknown default:
                    completion(false,
                               NSError(
                                domain: "SK2Error",
                                code: 999,
                                userInfo: [NSLocalizedDescriptionKey: "Unknown purchase result"]
                               ),
                               nil)
                }
            } catch {
                completion(false, error, nil)
            }
        }
    }

    // MARK: - Restore Purchases
    static func restorePurchases(
        completion: @escaping (Bool, [[String: Any]]?, Error?) -> Void
    ) {
        Task {
            var restored: [[String: Any]] = []

            for await result in Transaction.currentEntitlements {
                guard case .verified(let tx) = result else { continue }

                restored.append([
                    "productId": tx.productID,
                    "transactionId": String(tx.id),
                    "purchaseTime":
                        Int(tx.purchaseDate.timeIntervalSince1970 * 1000),
                    "originalPurchaseTime":
                        Int(tx.originalPurchaseDate.timeIntervalSince1970 * 1000),
                    "expireTime":
                        tx.expirationDate.map {
                            Int($0.timeIntervalSince1970 * 1000)
                        } ?? 0,
                    "isUpgraded": tx.isUpgraded,
                    "offerId": tx.offerID ?? "",
                    "accountToken": tx.appAccountToken?.uuidString ?? "",
                    "rawJson":
                        String(
                            data: tx.jsonRepresentation,
                            encoding: .utf8
                        ) ?? ""
                ])
            }

            completion(true, restored.isEmpty ? nil : restored, nil)
        }
    }

    // MARK: - Purchase History
    static func getPurchaseHistory() async -> [String] {
        var history: [String] = []

        for await result in Transaction.all {
            guard case .verified(let tx) = result else { continue }
            if let json = String(data: tx.jsonRepresentation, encoding: .utf8) {
                history.append(json)
            }
        }
        return history
    }

    // MARK: - Subscription Status
    static func getSubscriptionStatus(
        productId: String
    ) async -> [String: Any]? {

        for await result in Transaction.currentEntitlements {
            guard case .verified(let tx) = result,
                  tx.productID == productId else { continue }

            var status: [String: Any] = [
                "productId": tx.productID,
                "transactionId": String(tx.id),
                "isActive": tx.revocationDate == nil,
                "purchaseTime":
                    Int(tx.purchaseDate.timeIntervalSince1970 * 1000),
                "expireTime": 0
            ]

            if let expire = tx.expirationDate {
                status["expireTime"] =
                    Int(expire.timeIntervalSince1970 * 1000)
                status["isExpired"] = expire < Date()
            }

            if let revoke = tx.revocationDate {
                status["revokeTime"] =
                    Int(revoke.timeIntervalSince1970 * 1000)
                status["isRevoked"] = true
            }

            return status
        }

        return nil
    }
}
