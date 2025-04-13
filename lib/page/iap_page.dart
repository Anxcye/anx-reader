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

  // Initialize in-app purchase
  Future<void> _initInAppPurchase() async {
    // Initialize IAP service
    _iapService.initialize().then((value) {
      setState(() {});
    });

    // Check if store is available
    final available = await _inAppPurchase.isAvailable();
    setState(() {
      _isAvailable = available;
    });

    if (!available) {
      setState(() {
        _isLoading = false;
        _purchaseError = 'App Store is not available';
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
          _purchaseError =
              'Error connecting to store: ${response.error!.message}';
        });
        return;
      }

      if (response.notFoundIDs.isNotEmpty) {
        setState(() {
          _purchaseError =
              'Product IDs not found: ${response.notFoundIDs.join(", ")}';
        });
        return;
      }

      if (response.productDetails.isEmpty) {
        setState(() {
          _purchaseError =
              'No product information found, please ensure products are correctly configured in App Store';
        });
        return;
      }

      setState(() {
        _products = response.productDetails;
      });
    } catch (e) {
      setState(() {
        _purchaseError = 'Error loading product information: $e';
      });
    }
  }

  // Handle purchase updates
  Future<void> _listenToPurchaseUpdated(
      List<PurchaseDetails> purchaseDetailsList) async {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // Show loading indicator
        setState(() {
          _isLoading = true;
        });
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          // Handle error
          setState(() {
            _purchaseError = purchaseDetails.error?.message ??
                'Unknown error occurred during purchase';
            _isLoading = false;
          });
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          // Purchase or restore successful
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

  // Execute purchase
  Future<void> _buy() async {
    if (_isLoading) {
      return;
    }
    if (_products.isEmpty) {
      setState(() {
        _purchaseError = 'No products available for purchase';
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

  // Restore purchases
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
    List<Map<String, dynamic>> content = [
      {
        'icon': Icons.auto_awesome,
        'title': L10n.of(context).iap_page_feature_ai,
        'desc': L10n.of(context).iap_page_feature_ai_desc,
      },
      {
        'icon': Icons.sync,
        'title': L10n.of(context).iap_page_feature_sync,
        'desc': L10n.of(context).iap_page_feature_sync_desc,
      },
      {
        'icon': Icons.bar_chart,
        'title': L10n.of(context).iap_page_feature_stats,
        'desc': L10n.of(context).iap_page_feature_stats_desc,
      },
      {
        'icon': Icons.color_lens,
        'title': L10n.of(context).iap_page_feature_custom,
        'desc': L10n.of(context).iap_page_feature_custom_desc,
      },
      {
        'icon': Icons.note,
        'title': L10n.of(context).iap_page_feature_note,
        'desc': L10n.of(context).iap_page_feature_note_desc,
      },
      {
        'icon': Icons.more_horiz,
        'title': L10n.of(context).iap_page_feature_rich,
        'desc': L10n.of(context).iap_page_feature_rich_desc,
      },
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // User status card
                  _buildStatusCard(),
                  const SizedBox(height: 20),

                  // Feature introduction
                  Text(
                    L10n.of(context).iap_page_why_choose,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return Wrap(
                        children: content.map((item) => SizedBox(
                          width: constraints.maxWidth / (constraints.maxWidth ~/ 400),
                          child: _buildFeatureItem(
                                item['icon'],
                                item['title'],
                                item['desc'],
                              ),
                        )).toList(),
                      );
                    }
                  ),
                  const SizedBox(height: 30),
                  Text(L10n.of(context).iap_page_restore_hint),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
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
                ],
              ),
            ),
          ),
          SafeArea(
              minimum: const EdgeInsets.only(bottom: 10.0),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!_iapService.isPurchased && _isAvailable)
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Text(
                          L10n.of(context).iap_page_lifetime_hint(
                              _products.isEmpty ? '' : _products.first.price),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
                                ),
                              )
                            : Text(
                                L10n.of(context).iap_page_one_time_purchase,
                                style: const TextStyle(
                                    fontSize: 18, color: Colors.white),
                              ),
                      ),

                    // Display error message
                    if (_purchaseError.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 20.0),
                        child: Text(
                          _purchaseError,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ])),
        ],
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
        // Get purchase date
        final purchaseDate = _iapService.purchaseDate;
        if (purchaseDate != null) {
          timeInfo = L10n.of(context).iap_page_date_purchased(
            _formatDate(purchaseDate),
          );
        }
        break;
      case IAPStatus.trial:
        statusIcon = Icons.access_time;
        statusDescription = L10n.of(context).iap_page_status_trial(
          _iapService.trialDaysLeft.toString(),
        );
        cardColor = Colors.blue;
        // Get trial start date
        final originalDate = _iapService.originalDate;
        if (originalDate.millisecondsSinceEpoch > 0) {
          timeInfo = L10n.of(context).iap_page_date_trial_start(
            _formatDate(originalDate),
          );
        }
        break;
      case IAPStatus.trialExpired:
        statusIcon = Icons.timer_off;
        statusDescription = L10n.of(context).iap_page_status_trial_expired;
        cardColor = Colors.orange;
        // Get trial start date
        final originalDate = _iapService.originalDate;
        if (originalDate.millisecondsSinceEpoch > 0) {
          timeInfo = L10n.of(context).iap_page_date_trial_start(
            _formatDate(originalDate),
          );
        }
        break;
      case IAPStatus.originalUser:
        statusIcon = Icons.stars;
        statusDescription = L10n.of(context).iap_page_status_original;
        cardColor = Colors.purple;
        // Get original user date
        final originalDate = _iapService.originalDate;
        if (originalDate.millisecondsSinceEpoch > 0) {
          timeInfo = L10n.of(context).iap_page_date_original(
            _formatDate(originalDate),
          );
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
