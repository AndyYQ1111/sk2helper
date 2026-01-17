import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sk2helper/models.dart';
import 'package:sk2helper/sk2helper.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isLoading = false;
  String _status = '初始化中...';
  List<Product> _products = [];
  final List<Subscription> _subscriptions = [];
  List<RestoredPurchase> _restoredPurchases = [];
  bool _hasActiveSub = false;

  // 测试用产品ID（需要替换为实际的产品ID）
  final List<String> _productIds = [
    'com.example.consumable_product', // 消耗型
    'com.example.nonconsumable_product', // 非消耗型
    'com.example.monthly_subscription', // 月度订阅
    'com.example.yearly_subscription', // 年度订阅
  ];

  @override
  void initState() {
    super.initState();
  }

  // 获取产品列表
  Future<void> _fetchProducts() async {
    setState(() => _isLoading = true);
    _updateStatus('获取产品信息...');

    try {
      _products = await Sk2helper.fetchProducts(_productIds);
      _updateStatus('获取到 ${_products.length} 个产品');

      // 检查每个产品的订阅状态
      for (var product in _products.where((p) => p.type == 'AUTORENEWABLE')) {
        try {
          final status = await Sk2helper.getSubscriptionStatus(product.id);
          if (status != null) {
            _subscriptions.add(status);
          }
        } catch (e) {
          if (kDebugMode) {
            print('检查订阅状态失败: ${product.id} - $e');
          }
        }
      }
    } catch (e) {
      _updateStatus('获取产品失败: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 购买产品
  Future<void> _purchaseProduct(Product product) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    _updateStatus('购买 ${product.name}...');

    try {
      final transaction = await Sk2helper.purchase(product.id);

      if (kDebugMode) {
        print('购买 transaction - $transaction');
      }

      _updateStatus('购买成功: ${product.name}');

      // 如果是订阅产品，刷新订阅状态
      if (product.type == 'AUTORENEWABLE') {
        await _checkSubscriptionStatus(product.id);
      }

      _showSnackBar('购买成功: ${product.name}', isSuccess: true);
    } on StoreKitError catch (e) {
      if (e.code == 'USER_CANCELLED') {
        _updateStatus('用户取消了购买');
      } else {
        _updateStatus('购买失败: ${e.msg}', isError: true);
        _showSnackBar('购买失败: ${e.msg}');
      }
    } catch (e) {
      _updateStatus('购买失败: $e', isError: true);
      _showSnackBar('购买失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 恢复购买
  Future<void> _restorePurchases() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    _updateStatus('恢复购买中...');

    try {
      _restoredPurchases = await Sk2helper.restore();

      if (_restoredPurchases.isEmpty) {
        _updateStatus('没有找到可恢复的购买');
        _showSnackBar('没有可恢复的购买记录');
      } else {
        _updateStatus('恢复成功 ${_restoredPurchases.length} 个购买');
        _showSnackBar('恢复成功 ${_restoredPurchases.length} 个购买', isSuccess: true);

        // 更新订阅状态
        for (var purchase in _restoredPurchases) {
          await _checkSubscriptionStatus(purchase.productId);
        }
      }
    } on StoreKitError catch (e) {
      _updateStatus('恢复失败: ${e.msg}', isError: true);
      _showSnackBar('恢复失败: ${e.msg}');
    } catch (e) {
      _updateStatus('恢复失败: $e', isError: true);
      _showSnackBar('恢复失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 检查订阅状态
  Future<void> _checkSubscriptionStatus(String productId) async {
    try {
      final status = await Sk2helper.getSubscriptionStatus(productId);
      if (status != null) {
        // 移除旧的，添加新的
        _subscriptions.removeWhere((s) => s.productId == productId);
        _subscriptions.add(status);

        // 更新活跃订阅状态
        _hasActiveSub = await Sk2helper.hasActiveSubscription();
        setState(() {});
      }
    } catch (e) {
      if (kDebugMode) {
        print('检查订阅状态失败: $productId - $e');
      }
    }
  }

  // 获取购买历史
  Future<void> _fetchPurchaseHistory() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    _updateStatus('获取购买历史...');

    try {
      final history = await Sk2helper.fetchPurchaseHistory();
      _updateStatus('获取到 ${history.length} 条购买记录');

      // 显示购买历史对话框
      _showPurchaseHistory(history);
    } catch (e) {
      _updateStatus('获取历史失败: $e', isError: true);
      _showSnackBar('获取购买历史失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 显示购买历史
  void _showPurchaseHistory(List<String> history) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('购买历史'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: history.length,
            itemBuilder: (context, index) {
              try {
                final data = json.decode(history[index]);
                return ListTile(
                  title: Text('交易 ${data['transactionId'] ?? ''}'),
                  subtitle: Text('产品: ${data['productId'] ?? ''}'),
                  trailing: const Icon(Icons.receipt),
                );
              } catch (e) {
                return ListTile(
                  title: const Text('无效记录'),
                  subtitle: Text(history[index]),
                );
              }
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  // 显示提示
  void _showSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : null,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // 更新状态
  void _updateStatus(String message, {bool isError = false}) {
    setState(() {
      _status = message;
    });
    if (kDebugMode) {
      print('状态: $message');
    }
  }

  // 构建产品卡片
  Widget _buildProductCard(Product product) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.desc,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      product.localPrice,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    if (product.hasTrial)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '试用',
                          style: TextStyle(fontSize: 12, color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 显示产品详情
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (product.period.isNotEmpty) Text('周期: ${product.period}'),

                if (product.introOffer.isNotEmpty)
                  Text('优惠: ${product.introOffer}'),

                Text('类型: ${_getProductTypeName(product.type)}'),
              ],
            ),

            const SizedBox(height: 12),

            // 购买按钮
            ElevatedButton(
              onPressed: _isLoading ? null : () => _purchaseProduct(product),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text('购买 - ${product.localPrice}'),
            ),
          ],
        ),
      ),
    );
  }

  // 获取产品类型名称
  String _getProductTypeName(String type) {
    switch (type) {
      case 'CONSUMABLE':
        return '消耗型';
      case 'NON_CONSUMABLE':
        return '非消耗型';
      case 'AUTORENEWABLE':
        return '自动续订订阅';
      case 'NON_RENEWING_SUBSCRIPTION':
        return '非续订订阅';
      default:
        return type;
    }
  }

  // 构建订阅状态卡片
  Widget _buildSubscriptionCard(Subscription subscription) {
    return Card(
      color: subscription.isActive ? Colors.green[50] : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '产品: ${subscription.productId}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text('状态: ${subscription.isActive ? '有效' : '无效'}'),
            if (subscription.expireTime > 0)
              Text('到期: ${_formatTime(subscription.expireTime)}'),
            if (subscription.isExpired)
              const Text('已过期', style: TextStyle(color: Colors.red)),
            if (subscription.isRevoked)
              const Text('已撤销', style: TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }

  // 格式化时间
  String _formatTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SK2Helper 示例',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('SK2Helper 示例'),
          actions: [
            if (_hasActiveSub)
              Chip(
                label: const Text('有订阅'),
                backgroundColor: Colors.green,
                labelStyle: const TextStyle(color: Colors.white),
              ),
          ],
        ),
        body: Stack(
          children: [
            // 主内容
            Column(
              children: [
                // 状态栏
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey[100],
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _status,
                          style: TextStyle(
                            color: _status.contains('失败')
                                ? Colors.red
                                : Colors.grey[700],
                          ),
                        ),
                      ),
                      if (_isLoading)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                ),

                // 操作按钮
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _fetchProducts,
                        icon: const Icon(Icons.refresh),
                        label: const Text('刷新产品'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _restorePurchases,
                        icon: const Icon(Icons.restore),
                        label: const Text('恢复购买'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _fetchPurchaseHistory,
                        icon: const Icon(Icons.history),
                        label: const Text('购买历史'),
                      ),
                    ],
                  ),
                ),

                // 订阅状态
                if (_subscriptions.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      '订阅状态',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _subscriptions.length,
                      itemBuilder: (context, index) =>
                          _buildSubscriptionCard(_subscriptions[index]),
                    ),
                  ),
                ],

                // 产品列表
                Expanded(
                  flex: 2,
                  child: RefreshIndicator(
                    onRefresh: _fetchProducts,
                    child: _products.isEmpty
                        ? const Center(
                            child: Text(
                              '暂无产品',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _products.length,
                            itemBuilder: (context, index) =>
                                _buildProductCard(_products[index]),
                          ),
                  ),
                ),

                // 恢复的购买
                if (_restoredPurchases.isNotEmpty) ...[
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '恢复的购买',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ..._restoredPurchases.map((purchase) {
                          return ListTile(
                            title: Text(purchase.productId),
                            subtitle: Text('交易: ${purchase.transactionId}'),
                            trailing: Text(_formatTime(purchase.purchaseTime)),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ],
            ),

            // 加载遮罩
            if (_isLoading)
              Container(
                color: Colors.black54,
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),

        // 底部信息
        bottomNavigationBar: BottomAppBar(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text('产品数: ${_products.length}'),
                Text('订阅数: ${_subscriptions.length}'),
                Text('恢复数: ${_restoredPurchases.length}'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
