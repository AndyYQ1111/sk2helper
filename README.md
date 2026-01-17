# SK2Helper

[![pub package](https://img.shields.io/pub/v/sk2helper.svg)](https://pub.dev/packages/sk2helper)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-3.19-blue.svg)](https://flutter.dev)

一个功能强大的 Flutter 插件，用于在 iOS 上使用 StoreKit 2 实现应用内购买功能。

## ✨ 特性

- ✅ 支持 StoreKit 2 (iOS 15+)
- ✅ 完整的购买流程
- ✅ 订阅管理
- ✅ 购买恢复
- ✅ 错误处理
- ✅ 类型安全
- ✅ 易于使用

## 📱 支持平台

- iOS 15.0+

## 📦 安装

在 `pubspec.yaml` 中添加依赖：
yaml

dependencies:

sk2helper: ^1.0.0
复制
然后运行：
bash

flutter pub get
复制
## 🚀 快速开始

### 初始化
dart

import 'package:sk2helper/sk2helper.dart';

void main() async {

// 初始化 StoreKit

await StoreKit.init();

runApp(MyApp());

}
复制
### 获取产品
dart

final products = await StoreKit.fetchProducts([

'com.example.product1',

'com.example.product2',

]);
复制
### 购买产品
dart

try {

final transaction = await StoreKit.purchase(productId);

print('购买成功: ${transaction.id}');

} on StoreKitError catch (e) {

print('购买失败: ${e.msg}');

}
复制
### 恢复购买
dart

final restored = await StoreKit.restore();

if (restored.isNotEmpty) {

print('恢复成功 ${restored.length} 个购买');

}
复制
## 📖 文档

### 数据模型

- `Product`: 产品信息
- `Transaction`: 交易信息
- `RestoredPurchase`: 恢复的购买
- `Subscription`: 订阅状态
- `StoreKitError`: 错误信息

### API 参考

| 方法 | 描述 |
|------|------|
| `init()` | 初始化 StoreKit |
| `fetchProducts()` | 获取产品列表 |
| `purchase()` | 购买产品 |
| `restore()` | 恢复购买 |
| `hasActiveSubscription()` | 检查活跃订阅 |
| `getSubscriptionStatus()` | 获取订阅状态 |
| `getPurchaseHistory()` | 获取购买历史 |

## 🎯 示例

查看 [example](https://github.com/AndyYQ1111/sk2helper/tree/main/example) 目录获取完整示例。

## 🔧 配置

### iOS 配置

在 `Info.plist` 中添加应用内购买权限：
xml

<key>SKAdNetworkItems</key>

<array>

<dict>

<key>SKAdNetworkIdentifier</key>

<string>cstr6suwn9.skadnetwork</string>

</dict>

</array>
复制
## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📄 许可证

MIT License