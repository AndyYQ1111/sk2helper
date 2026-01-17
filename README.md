# SK2Helper

[![pub package](https://img.shields.io/pub/v/sk2helper.svg)](https://pub.dev/packages/sk2helper)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-3.19-blue.svg)](https://flutter.dev)
[![iOS](https://img.shields.io/badge/iOS-15%2B-black.svg)](https://developer.apple.com/ios/)

🚀 **SK2Helper** 是一个基于 **StoreKit 2** 的 Flutter 插件  
用于在 **iOS（iOS 15+）** 上实现 **订阅型应用内购买** 的完整解决方案。

插件通过 `MethodChannel` 与 iOS 原生 StoreKit 2 交互，并在 Flutter 层提供**类型安全、易用的 API**。

---

## ✨ 特性

- ✅ 基于 **StoreKit 2（iOS 15+）**
- 🔌 Flutter ↔ iOS 原生桥接（MethodChannel）
- 🔄 自动监听交易更新（Transaction.updates）
- 📦 获取商品信息
- 💳 购买订阅
- 🔁 恢复购买
- 🧾 查询历史交易
- 🟢 判断是否存在活跃订阅
- 📊 获取订阅状态详情
- 🛡 内置初始化锁，防止重复初始化

---

## 📱 支持平台

| 平台 | 支持 |
|----|----|
| iOS | ✅ iOS 15.0+ |
| Android | ❌ |
| Web | ❌ |
| macOS | ❌ |

> ⚠️ 本插件 **仅支持 iOS StoreKit 2**

---

## 📦 安装

在 `pubspec.yaml` 中添加：

```
dependencies:
  sk2helper: ^0.0.4
```
## 然后执行：
```
flutter pub get
```

## 🚀 快速开始
### 1️⃣ 初始化（必须）

插件在首次调用 API 时会 自动初始化，无需手动调用：
```
await Sk2helper.fetchProducts([...]);
```

内部使用 _ensureInitialized()
自动保证 StoreKit 只初始化一次（线程安全）

### 2️⃣ 获取商品列表
```
final products = await Sk2helper.fetchProducts([
  'com.example.sub.monthly',
  'com.example.sub.yearly',
]);

for (final product in products) {
  print(product.id);
  print(product.price);
}
```
### 3️⃣ 购买订阅
```
try {
  final transaction = await Sk2helper.purchase(
    'com.example.sub.monthly',
  );

  print('购买成功：${transaction.id}');
} on StoreKitError catch (e) {
  print('购买失败：${e.message}');
}
```

### 4️⃣ 恢复购买
```
final restored = await Sk2helper.restore();

if (restored.isNotEmpty) {
  print('已恢复 ${restored.length} 个购买');
}
```
### 5️⃣ 是否存在活跃订阅
```
final hasSub = await Sk2helper.hasActiveSubscription();

if (hasSub) {
  // 用户是订阅用户
}
```

### 6️⃣ 获取订阅状态
```
final status = await Sk2helper.getSubscriptionStatus(
  'com.example.sub.monthly',
);

if (status != null) {
  print(status.isActive);
  print(status.expireTime);
}
```

### 7️⃣ 获取购买历史
```
final history = await Sk2helper.fetchPurchaseHistory();

for (final json in history) {
  print(json);
}
```