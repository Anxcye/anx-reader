import 'dart:async';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:anx_reader/service/iap_service.dart';


class IAPPage extends StatefulWidget {
  const IAPPage({super.key});

  @override
  State<IAPPage> createState() => _IAPPageState();
}

class _IAPPageState extends State<IAPPage> {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  final IAPService _iapService = IAPService();

  late StreamSubscription<List<PurchaseDetails>> _subscription;
  List<ProductDetails> _products = [];
  bool _isAvailable = false;
  bool _isLoading = true;
  String _purchaseError = '';

  @override
  void initState() {
    super.initState();
    _initInAppPurchase();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  // 初始化应用内购买
  Future<void> _initInAppPurchase() async {
    // 初始化IAP服务

    // 如果已购买，不需要继续初始化IAP
    if (_iapService.isPurchased) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // 检查商店是否可用
    final available = await _inAppPurchase.isAvailable();
    setState(() {
      _isAvailable = available;
    });

    if (!available) {
      setState(() {
        _isLoading = false;
        _purchaseError = '应用商店不可用';
      });
      return;
    }

    // 监听购买更新
    _subscription = _inAppPurchase.purchaseStream.listen(
      _listenToPurchaseUpdated,
      onDone: () => _subscription?.cancel(),
      onError: (error) {
        setState(() {
          _purchaseError = error.toString();
          _isLoading = false;
        });
      },
    );

    // 获取商品信息
    await _loadProducts();
  }

  // 加载产品信息
  Future<void> _loadProducts() async {
    final Set<String> productIds = {IAPService.kLifetimeProductId};
    print('Querying product IDs: $productIds');

    try {
      final ProductDetailsResponse response =
          await _inAppPurchase.queryProductDetails(productIds);

      if (response.error != null) {
        setState(() {
          _purchaseError = '连接商店时出错: ${response.error!.message}';
          _isLoading = false;
        });
        return;
      }

      if (response.notFoundIDs.isNotEmpty) {
        setState(() {
          _purchaseError = '商品ID不存在: ${response.notFoundIDs.join(", ")}';
          _isLoading = false;
        });
        return;
      }

      if (response.productDetails.isEmpty) {
        setState(() {
          _purchaseError = '没有找到产品信息，请确保产品已在App Store配置正确';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _products = response.productDetails;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading products: $e');
      setState(() {
        _purchaseError = '加载产品信息时出错: $e';
        _isLoading = false;
      });
    }
  }

  // 处理购买更新
  Future<void> _listenToPurchaseUpdated(
      List<PurchaseDetails> purchaseDetailsList) async {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // 显示加载指示器
        setState(() {
          _isLoading = true;
        });
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          // 处理错误
          setState(() {
            _purchaseError = purchaseDetails.error?.message ?? '购买时发生未知错误';
            _isLoading = false;
          });
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          // 购买或恢复成功
          await _iapService.handleSuccessfulPurchase(purchaseDetails);
          setState(() {
            _isLoading = false;
          });
        }

        if (purchaseDetails.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchaseDetails);
        }
      }
    }
  }

  // 执行购买
  Future<void> _buy() async {
    if (_products.isEmpty) {
      setState(() {
        _purchaseError = '没有可购买的商品';
      });
      return;
    }

    final ProductDetails productDetails = _products.first;
    final PurchaseParam purchaseParam = PurchaseParam(
      productDetails: productDetails,
    );

    try {
      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      setState(() {
        _purchaseError = e.toString();
      });
    }
  }

  // 恢复购买
  Future<void> _restorePurchases() async {
    try {
      await _inAppPurchase.restorePurchases();
    } catch (e) {
      setState(() {
        _purchaseError = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('高级会员'),
        actions: [
          if (!_iapService.isPurchased)
            TextButton(
              onPressed: _restorePurchases,
              child: const Text('恢复购买', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_iapService.isPurchased) {
      return _buildPurchasedContent();
    } else if (!_isAvailable) {
      return _buildErrorContent('商店不可用，请稍后再试');
    } else if (_purchaseError.isNotEmpty) {
      return _buildErrorContent(_purchaseError);
    } else {
      return _buildPurchaseContent();
    }
  }

  Widget _buildPurchasedContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.verified,
            size: 100,
            color: Colors.green,
          ),
          const SizedBox(height: 20),
          const Text(
            '您已购买永久高级版',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            '感谢您的支持',
            style: TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorContent(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red,
            ),
            const SizedBox(height: 20),
            Text(
              error,
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 试用信息卡片
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      '试用期',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _iapService.trialDaysLeft > 0
                        ? Text(
                            '您还有 ${_iapService.trialDaysLeft} 天试用期',
                            style: const TextStyle(fontSize: 18),
                          )
                        : const Text(
                            '试用期已结束',
                            style: TextStyle(fontSize: 18, color: Colors.red),
                          ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 特性介绍
            const Text(
              '我们提供',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            _buildFeatureItem(Icons.format_quote, '无限书籍导入', '无书籍数量限制'),
            _buildFeatureItem(Icons.color_lens, '全部主题', '任意主题和定制选项'),
            _buildFeatureItem(Icons.auto_awesome, '高级功能', '包括批注、同步和更多功能'),
            _buildFeatureItem(Icons.support_agent, '特色功能', 'AI、同步、朗读'),

            const SizedBox(height: 30),

            // 购买按钮
            if (_products.isNotEmpty)
              ElevatedButton(
                onPressed: _buy,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: Text(
                  '一次性付费 ${_products.first.price} 永久使用',
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            const SizedBox(height: 10),
            const Text(
              '* 一次性付费，无订阅，终身使用',
              textAlign: TextAlign.center,
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 30, color: Theme.of(context).primaryColor),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
