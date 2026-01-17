// ios/Classes/SK2Plugin.swift
import Flutter
import UIKit
import StoreKit

public class SK2Plugin: NSObject, FlutterPlugin {
    
    // 周期映射
    let periodTitles: [String: String] = [
        "Day": "Daily",
        "Week": "Weekly", 
        "Month": "Monthly",
        "Year": "Yearly"
    ]
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "storekit2helper", 
                                          binaryMessenger: registrar.messenger())
        let instance = SK2Plugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if #available(iOS 15.0, *) {
            handleSK2Call(call, result: result)
        } else {
            result(FlutterError(code: "UNSUPPORTED_VERSION",
                              message: "Requires iOS 15.0+",
                              details: nil))
        }
    }
    
    @available(iOS 15.0, *)
    private func handleSK2Call(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initialize":
            Task {
                await SK2Handler.initialize()
                result(nil)
            }
            
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
    
    @available(iOS 15.0, *)
    private func handleFetchProducts(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let productIds = args["productIds"] as? [String] else {
            result(FlutterError(code: "INVALID_ARGS",
                              message: "Missing productIds",
                              details: nil))
            return
        }
        
        SK2Handler.fetchProducts(productIds: productIds) { fetchResult in
            switch fetchResult {
            case .success(let products):
                let productDetails = products.map { self.productToMap($0) }
                result(productDetails)
                
            case .failure(let error):
                result(FlutterError(code: "FETCH_ERROR",
                                  message: error.localizedDescription,
                                  details: nil))
            }
        }
    }
    
    @available(iOS 15.0, *)
    private func productToMap(_ product: Product) -> [String: Any] {
        var data: [String: Any] = [
            "id": product.id,
            "name": product.displayName,
            "desc": product.description,
            "price": Double(truncating: product.price as NSNumber),
            "localPrice": product.displayPrice,
            "type": product.type.rawValue,
            "rawJson": String(data: product.jsonRepresentation, encoding: .utf8) ?? ""
        ]
        
        if let sub = product.subscription {
            data["periodUnit"] = String(describing: sub.subscriptionPeriod.unit)
            data["periodValue"] = sub.subscriptionPeriod.value
            data["period"] = periodTitles[String(describing: sub.subscriptionPeriod.unit)] ?? ""
            
            if let intro = sub.introductoryOffer {
                data["introOffer"] = intro.paymentMode.rawValue
                data["introPeriod"] = "\(intro.period.value) \(intro.period.unit)"
                data["hasTrial"] = intro.paymentMode == .free || intro.paymentMode == .payAsYouGo
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
    
    @available(iOS 15.0, *)
    private func handleBuyProduct(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let productId = args["productId"] as? String else {
            result(FlutterError(code: "INVALID_ARGS",
                              message: "Missing productId",
                              details: nil))
            return
        }
        
        SK2Handler.buyProduct(productId: productId) { success, error, transaction in
            if success, let transaction = transaction {
                let details: [String: Any] = [
                    "id": String(transaction.id),
                    "productId": transaction.productID,
                    "bundleId": transaction.appBundleID,
                    "purchaseTime": Int(transaction.purchaseDate.timeIntervalSince1970 * 1000),
                    "originalPurchaseTime": Int(transaction.originalPurchaseDate.timeIntervalSince1970 * 1000),
                    "expireTime": transaction.expirationDate.map { 
                        Int($0.timeIntervalSince1970 * 1000) 
                    } ?? 0,
                    "rawJson": String(data: transaction.jsonRepresentation, encoding: .utf8) ?? ""
                ]
                result(details)
            } else {
                result(FlutterError(code: "PURCHASE_FAILED",
                                  message: error?.localizedDescription ?? "Purchase failed",
                                  details: ["code": (error as NSError?)?.code ?? 999]))
            }
        }
    }
    
    @available(iOS 15.0, *)
    private func handleRestorePurchases(_ result: @escaping FlutterResult) {
        SK2Handler.restorePurchases { success, items, error in
            if success {
                result(items ?? [])
            } else {
                result(FlutterError(code: "RESTORE_FAILED",
                                  message: error?.localizedDescription ?? "Restore failed",
                                  details: nil))
            }
        }
    }
    
    @available(iOS 15.0, *)
    private func handleHasActiveSubscription(_ result: @escaping FlutterResult) {
        Task {
            let hasActive = await SK2Handler.hasActiveSubscription()
            result(hasActive)
        }
    }
    
    @available(iOS 15.0, *)
    private func handleGetPurchaseHistory(_ result: @escaping FlutterResult) {
        Task {
            let history = await SK2Handler.getPurchaseHistory()
            result(history)
        }
    }
    
    @available(iOS 15.0, *)
    private func handleGetSubscriptionStatus(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let productId = args["productId"] as? String else {
            result(FlutterError(code: "INVALID_ARGS",
                              message: "Missing productId",
                              details: nil))
            return
        }
        
        Task {
            if let status = await SK2Handler.getSubscriptionStatus(productId: productId) {
                result(status)
            } else {
                result(nil)
            }
        }
    }
}