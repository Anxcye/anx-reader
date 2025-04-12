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

  StreamSubscription<List<PurchaseDetails>>? _subscription;
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
    _iapService.initialize().then((value) {
      setState(() {});
    });

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

    await _loadProducts();

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadProducts() async {
    final Set<String> productIds = {IAPService.kLifetimeProductId};

    try {
      final ProductDetailsResponse response =
          await _inAppPurchase.queryProductDetails(productIds);

      if (response.error != null) {
        setState(() {
          _purchaseError = '连接商店时出错: ${response.error!.message}';
        });
        return;
      }

      if (response.notFoundIDs.isNotEmpty) {
        setState(() {
          _purchaseError = '商品ID不存在: ${response.notFoundIDs.join(", ")}';
        });
        return;
      }

      if (response.productDetails.isEmpty) {
        setState(() {
          _purchaseError = '没有找到产品信息，请确保产品已在App Store配置正确';
        });
        return;
      }

      setState(() {
        _products = response.productDetails;
      });
    } catch (e) {
      setState(() {
        _purchaseError = '加载产品信息时出错: $e';
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
          await _iapService.refresh();
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
    if (_isLoading) {
      return;
    }
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
          TextButton(
            onPressed: _restorePurchases,
            child: const Text('恢复购买'),
          ),
        ],
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 用户状态卡片
            _buildStatusCard(),
            const SizedBox(height: 20),

            // 特性介绍
            const Text(
              'AnxReader 提供功能',
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

            // 仅当用户未购买且商店可用时显示购买按钮
            if (!_iapService.isPurchased &&
                _isAvailable &&
                _products.isNotEmpty)
              ElevatedButton(
                onPressed: _buy,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Text(
                        '一次性付费 ${_products.first.price} 永久使用',
                        style:
                            const TextStyle(fontSize: 18, color: Colors.white),
                      ),
              ),

            if (!_iapService.isPurchased && _isAvailable)
              const Padding(
                padding: EdgeInsets.only(top: 10.0),
                child: Text(
                  '* 一次性付费，无订阅，终身使用',
                  textAlign: TextAlign.center,
                ),
              ),

            // 显示错误信息
            if (_purchaseError.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: Text(
                  _purchaseError,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    Color cardColor;
    IconData statusIcon;
    String statusDescription;
    String? timeInfo;

    switch (_iapService.iapStatus) {
      case IAPStatus.purchased:
        statusIcon = Icons.verified;
        statusDescription = '感谢您的支持！您可以使用所有高级功能';
        cardColor = Colors.green.shade50;
        // 获取购买时间
        final purchaseDate = _iapService.purchaseDate;
        if (purchaseDate != null) {
          timeInfo = '购买时间：${_formatDate(purchaseDate)}';
        }
        break;
      case IAPStatus.trial:
        statusIcon = Icons.access_time;
        statusDescription = '您还有 ${_iapService.trialDaysLeft} 天试用期';
        cardColor = Colors.blue.shade50;
        // 获取试用开始时间
        final originalDate = _iapService.originalDate;
        if (originalDate.millisecondsSinceEpoch > 0) {
          timeInfo = '试用开始：${_formatDate(originalDate)}';
        }
        break;
      case IAPStatus.trialExpired:
        statusIcon = Icons.timer_off;
        statusDescription = '购买永久版以继续使用高级功能';
        cardColor = Colors.orange.shade50;
        // 获取试用开始时间
        final originalDate = _iapService.originalDate;
        if (originalDate.millisecondsSinceEpoch > 0) {
          timeInfo = '试用开始：${_formatDate(originalDate)}';
        }
        break;
      case IAPStatus.originalUser:
        statusIcon = Icons.stars;
        statusDescription = '您是我们的早期用户，感谢您的支持！';
        cardColor = Colors.purple.shade50;
        // 获取原始用户时间
        final originalDate = _iapService.originalDate;
        if (originalDate.millisecondsSinceEpoch > 0) {
          timeInfo = '加入时间：${_formatDate(originalDate)}';
        }
        break;
      case IAPStatus.unknown:
        statusIcon = Icons.help_outline;
        statusDescription = '无法确定您的会员状态';
        cardColor = Colors.grey.shade50;
        break;
    }

    return Card(
      elevation: 4,
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(
              statusIcon,
              size: 50,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 10),
            Text(
              _iapService.statusTitle,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              statusDescription,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            if (timeInfo != null) ...[
              const SizedBox(height: 5),
              Text(
                timeInfo,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (_iapService.iapStatus == IAPStatus.trial)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: LinearProgressIndicator(
                  value: _iapService.trialDaysLeft / IAPService.kTrialDays,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日';
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
