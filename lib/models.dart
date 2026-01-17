class Product {
  final String id;
  final String name;
  final String desc;
  final double price;
  final String localPrice;
  final String type;
  final String rawJson;
  final String periodUnit;
  final int periodValue;
  final String period;
  final String introOffer;
  final String introPeriod;
  final bool hasTrial;

  Product({
    required this.id,
    required this.name,
    required this.desc,
    required this.price,
    required this.localPrice,
    required this.type,
    required this.rawJson,
    required this.periodUnit,
    required this.periodValue,
    required this.period,
    required this.introOffer,
    required this.introPeriod,
    required this.hasTrial,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      desc: map['desc'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      localPrice: map['localPrice'] ?? '',
      type: map['type'] ?? '',
      rawJson: map['rawJson'] ?? '',
      periodUnit: map['periodUnit'] ?? '',
      periodValue: map['periodValue'] ?? 0,
      period: map['period'] ?? '',
      introOffer: map['introOffer'] ?? '',
      introPeriod: map['introPeriod'] ?? '',
      hasTrial: map['hasTrial'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'desc': desc,
      'price': price,
      'localPrice': localPrice,
      'type': type,
      'rawJson': rawJson,
      'periodUnit': periodUnit,
      'periodValue': periodValue,
      'period': period,
      'introOffer': introOffer,
      'introPeriod': introPeriod,
      'hasTrial': hasTrial,
    };
  }
}

class Transaction {
  final String id;
  final String productId;
  final String bundleId;
  final int purchaseTime;
  final int originalPurchaseTime;
  final int expireTime;
  final String rawJson;

  Transaction({
    required this.id,
    required this.productId,
    required this.bundleId,
    required this.purchaseTime,
    required this.originalPurchaseTime,
    required this.expireTime,
    required this.rawJson,
  });

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] ?? '',
      productId: map['productId'] ?? '',
      bundleId: map['bundleId'] ?? '',
      purchaseTime: map['purchaseTime'] ?? 0,
      originalPurchaseTime: map['originalPurchaseTime'] ?? 0,
      expireTime: map['expireTime'] ?? 0,
      rawJson: map['rawJson'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'bundleId': bundleId,
      'purchaseTime': purchaseTime,
      'originalPurchaseTime': originalPurchaseTime,
      'expireTime': expireTime,
      'rawJson': rawJson,
    };
  }
}

class RestoredPurchase {
  final String productId;
  final String transactionId;
  final int purchaseTime;
  final int originalPurchaseTime;
  final int expireTime;
  final bool isUpgraded;
  final String offerId;
  final String accountToken;
  final String rawJson;

  RestoredPurchase({
    required this.productId,
    required this.transactionId,
    required this.purchaseTime,
    required this.originalPurchaseTime,
    required this.expireTime,
    required this.isUpgraded,
    required this.offerId,
    required this.accountToken,
    required this.rawJson,
  });

  factory RestoredPurchase.fromMap(Map<String, dynamic> map) {
    return RestoredPurchase(
      productId: map['productId'] ?? '',
      transactionId: map['transactionId'] ?? '',
      purchaseTime: map['purchaseTime'] ?? 0,
      originalPurchaseTime: map['originalPurchaseTime'] ?? 0,
      expireTime: map['expireTime'] ?? 0,
      isUpgraded: map['isUpgraded'] ?? false,
      offerId: map['offerId'] ?? '',
      accountToken: map['accountToken'] ?? '',
      rawJson: map['rawJson'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'transactionId': transactionId,
      'purchaseTime': purchaseTime,
      'originalPurchaseTime': originalPurchaseTime,
      'expireTime': expireTime,
      'isUpgraded': isUpgraded,
      'offerId': offerId,
      'accountToken': accountToken,
      'rawJson': rawJson,
    };
  }
}

class Subscription {
  final String productId;
  final String transactionId;
  final bool isActive;
  final int purchaseTime;
  final int expireTime;
  final bool isExpired;
  final int? revokeTime;
  final bool isRevoked;

  Subscription({
    required this.productId,
    required this.transactionId,
    required this.isActive,
    required this.purchaseTime,
    required this.expireTime,
    required this.isExpired,
    this.revokeTime,
    required this.isRevoked,
  });

  factory Subscription.fromMap(Map<String, dynamic> map) {
    return Subscription(
      productId: map['productId'] ?? '',
      transactionId: map['transactionId'] ?? '',
      isActive: map['isActive'] ?? false,
      purchaseTime: map['purchaseTime'] ?? 0,
      expireTime: map['expireTime'] ?? 0,
      isExpired: map['isExpired'] ?? false,
      revokeTime: map['revokeTime'],
      isRevoked: map['isRevoked'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'transactionId': transactionId,
      'isActive': isActive,
      'purchaseTime': purchaseTime,
      'expireTime': expireTime,
      'isExpired': isExpired,
      'revokeTime': revokeTime,
      'isRevoked': isRevoked,
    };
  }
}

class StoreKitError implements Exception {
  final String code;
  final String? msg;
  final dynamic data;

  StoreKitError(this.code, this.msg, {this.data});

  @override
  String toString() {
    return 'StoreKitError{code: $code, msg: $msg, data: $data}';
  }
}