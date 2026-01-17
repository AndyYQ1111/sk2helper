// ios/Classes/SK2Handler.swift
import StoreKit
import Foundation

@available(iOS 15.0, *)
class SK2Handler {
    
    // 初始化
    static func initialize() async {
        for await result in Transaction.updates {
            if case .verified(let transaction) = result {
                await transaction.finish()
            }
        }
    }
    
    // 获取产品列表
    static func fetchProducts(productIds: [String], completion: @escaping (Result<[Product], Error>) -> Void) {
        Task {
            do {
                let products = try await Product.products(for: productIds)
                completion(.success(products))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    // 检查是否有活跃订阅
    static func hasActiveSubscription() async -> Bool {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                return true
            }
        }
        return false
    }
    
    // 购买产品
    static func buyProduct(productId: String, completion: @escaping (Bool, Error?, Transaction?) -> Void) {
        Task {
            do {
                let products = try await Product.products(for: [productId])
                guard let product = products.first else {
                    let error = NSError(domain: "SK2Error", code: 404, 
                                      userInfo: [NSLocalizedDescriptionKey: "Product not found"])
                    completion(false, error, nil)
                    return
                }
                
                let result = try await product.purchase()
                
                switch result {
                case .success(let verification):
                    switch verification {
                    case .verified(let transaction):
                        await transaction.finish()
                        completion(true, nil, transaction)
                    case .unverified(_, let error):
                        completion(false, error, nil)
                    }
                case .pending:
                    let error = NSError(domain: "SK2Error", code: 100, 
                                      userInfo: [NSLocalizedDescriptionKey: "Purchase pending"])
                    completion(false, error, nil)
                case .userCancelled:
                    let error = NSError(domain: "SK2Error", code: 401, 
                                      userInfo: [NSLocalizedDescriptionKey: "Purchase cancelled"])
                    completion(false, error, nil)
                @unknown default:
                    let error = NSError(domain: "SK2Error", code: 999, 
                                      userInfo: [NSLocalizedDescriptionKey: "Unknown error"])
                    completion(false, error, nil)
                }
            } catch {
                completion(false, error, nil)
            }
        }
    }
    
    // 恢复购买
    static func restorePurchases(completion: @escaping (Bool, [[String: Any]]?, Error?) -> Void) {
        Task {
            var restoredItems: [[String: Any]] = []
            
            do {
                for await result in Transaction.currentEntitlements {
                    switch result {
                    case .verified(let transaction):
                        let item: [String: Any] = [
                            "productId": transaction.productID,
                            "transactionId": String(transaction.id),
                            "purchaseTime": Int(transaction.purchaseDate.timeIntervalSince1970 * 1000),
                            "originalPurchaseTime": transaction.originalPurchaseDate.map { 
                                Int($0.timeIntervalSince1970 * 1000) 
                            } ?? 0,
                            "expireTime": transaction.expirationDate.map { 
                                Int($0.timeIntervalSince1970 * 1000) 
                            } ?? 0,
                            "isUpgraded": transaction.isUpgraded,
                            "offerId": transaction.offerID ?? "",
                            "accountToken": transaction.appAccountToken?.uuidString ?? "",
                            "rawJson": String(data: transaction.jsonRepresentation, encoding: .utf8) ?? ""
                        ]
                        restoredItems.append(item)
                        
                    case .unverified(_, let error):
                        print("Unverified: \(error?.localizedDescription ?? "")")
                    }
                }
                
                completion(true, restoredItems.isEmpty ? nil : restoredItems, nil)
                
            } catch {
                completion(false, nil, error)
            }
        }
    }
    
    // 获取购买历史
    static func getPurchaseHistory() async -> [String] {
        var history: [String] = []
        
        for await result in Transaction.all {
            if case .verified(let transaction) = result {
                if let json = String(data: transaction.jsonRepresentation, encoding: .utf8) {
                    history.append(json)
                }
            }
        }
        return history
    }
    
    // 获取订阅状态
    static func getSubscriptionStatus(productId: String) async -> [String: Any]? {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == productId {
                
                var status: [String: Any] = [
                    "productId": transaction.productID,
                    "transactionId": String(transaction.id),
                    "isActive": true,
                    "purchaseTime": Int(transaction.purchaseDate.timeIntervalSince1970 * 1000),
                    "expireTime": 0
                ]
                
                if let expireTime = transaction.expirationDate {
                    status["expireTime"] = Int(expireTime.timeIntervalSince1970 * 1000)
                    status["isExpired"] = expireTime < Date()
                }
                
                if let revokeTime = transaction.revocationDate {
                    status["revokeTime"] = Int(revokeTime.timeIntervalSince1970 * 1000)
                    status["isRevoked"] = true
                }
                
                return status
            }
        }
        return nil
    }
}