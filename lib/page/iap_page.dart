import 'dart:async';

import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:anx_reader/service/iap_service.dart';
import 'package:url_launcher/url_launcher.dart';

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
        title: Text(L10n.of(context).iap_page_title),
        actions: [
          TextButton(
            onPressed: _restorePurchases,
            child: Text(L10n.of(context).iap_page_restore),
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
            Text(
              L10n.of(context).iap_page_why_choose,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            _buildFeatureItem(Icons.auto_awesome, L10n.of(context).iap_page_feature_ai, L10n.of(context).iap_page_feature_ai_desc),
            _buildFeatureItem(Icons.sync, L10n.of(context).iap_page_feature_sync, L10n.of(context).iap_page_feature_sync_desc),
            _buildFeatureItem(Icons.bar_chart, L10n.of(context).iap_page_feature_stats, L10n.of(context).iap_page_feature_stats_desc),
            _buildFeatureItem(Icons.color_lens, L10n.of(context).iap_page_feature_custom, L10n.of(context).iap_page_feature_custom_desc),
            _buildFeatureItem(Icons.more_horiz, L10n.of(context).iap_page_feature_rich, L10n.of(context).iap_page_feature_rich_desc),

            const SizedBox(height: 30),
            Text(L10n.of(context).iap_page_restore_hint),
         
            Row(
              children: [
                TextButton(
                  child: Text(L10n.of(context).about_privacy_policy),
                  onPressed: () async {
                    launchUrl(
                      Uri.parse('https://anx.anxcye.com/privacy.html'),
                      mode: LaunchMode.externalApplication,
                    );
                  },
                ),
            TextButton(
              child: Text(L10n.of(context).about_terms_of_use),
              onPressed: () async {
                launchUrl(
                  Uri.parse('https://anx.anxcye.com/terms.html'),
                  mode: LaunchMode.externalApplication,
                );
              },
            ),
              ],
            ),

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
                    ? Center(
                        child: CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      )
                    : Text(
                        L10n.of(context).iap_page_one_time_purchase(_products.first.price),
                        style:
                            const TextStyle(fontSize: 18, color: Colors.white),
                      ),
              ),

            if (!_iapService.isPurchased && _isAvailable)
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Text(
                  L10n.of(context).iap_page_lifetime_hint,
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
        statusDescription = L10n.of(context).iap_page_status_purchased;
        cardColor = Colors.green;
        // 获取购买时间
        final purchaseDate = _iapService.purchaseDate;
        if (purchaseDate != null) {
          timeInfo = L10n.of(context).iap_page_date_purchased (_formatDate(purchaseDate));
        }
        break;
      case IAPStatus.trial:
        statusIcon = Icons.access_time;
        statusDescription = L10n.of(context).iap_page_status_trial(_iapService.trialDaysLeft.toString());
        cardColor = Colors.blue;
        // 获取试用开始时间
        final originalDate = _iapService.originalDate;
        if (originalDate.millisecondsSinceEpoch > 0) {
          timeInfo = L10n.of(context).iap_page_date_trial_start(_formatDate(originalDate));
        }
        break;
      case IAPStatus.trialExpired:
        statusIcon = Icons.timer_off;
        statusDescription = L10n.of(context).iap_page_status_trial_expired;
        cardColor = Colors.orange;
        // 获取试用开始时间
        final originalDate = _iapService.originalDate;
        if (originalDate.millisecondsSinceEpoch > 0) {
          timeInfo = L10n.of(context).iap_page_date_trial_start(_formatDate(originalDate));
        }
        break;
      case IAPStatus.originalUser:
        statusIcon = Icons.stars;
        statusDescription = L10n.of(context).iap_page_status_original;
        cardColor = Colors.purple;
        // 获取原始用户时间
        final originalDate = _iapService.originalDate;
        if (originalDate.millisecondsSinceEpoch > 0) {
          timeInfo = L10n.of(context).iap_page_date_original(_formatDate(originalDate));
        }
        break;
      case IAPStatus.unknown:
        statusIcon = Icons.help_outline;
        statusDescription = L10n.of(context).iap_page_status_unknown;
        cardColor = Colors.grey;
        break;
    }

    return Card(
      elevation: 4,
      color:
          cardColor.blend(Theme.of(context).colorScheme.surfaceContainer, 85),
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
              _iapService.statusTitle(context),
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
    return date.toIso8601String().substring(0, 10);
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
