import 'dart:async';
import 'dart:convert';

import 'package:anx_reader/utils/log/common.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';

class IAPService {
  // 单例模式
  static final IAPService _instance = IAPService._internal();
  factory IAPService() => _instance;
  IAPService._internal();
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;

  static const String kLifetimeProductId = 'anx_reader_lifetime';

  static const List<String> kOriginalUserVersion = [
    '1.4.0',
    '1.4.1',
    '1.4.2',
    '2077',
    '2084',
    '2086',
    '2092',
  ];

  // 存储购买状态和试用开始时间的键
  static const String kPurchaseStatusKey = 'purchase_status';
  static const String kTrialStartDateKey = 'trial_start_date';

  // 试用期天数
  static const int kTrialDays = 7;

  // 购买状态
  bool _isPurchased = false;
  bool get isPurchased => _isPurchased;

  // 试用剩余天数
  int _trialDaysLeft = 0;
  int get trialDaysLeft => _trialDaysLeft;

  Map<String, dynamic>? _receipt;

  // 初始化方法
  Future<void> initialize() async {
    // 加载购买状态
    await _loadPurchaseStatus();
    await _checkTrialStatus();
    print('@@$_isPurchased@@');
    print('@@_trialDaysLeft@@');
    // print('@@${await _isOriginalUser()}@@');
    // print('@@${await _getOriginalDate()}@@');
  }

  // 加载购买状态
  Future<void> _loadPurchaseStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _isPurchased = false;
  }

  Future<Map<String, dynamic>> _loadReceipt() async {
    if (_receipt != null) {
      return _receipt!;
    }
    final receipt = await _getReceipt();
    _receipt = receipt;
    return receipt;
  }

  Future<Map<String, dynamic>> _getReceipt() async {
    Future<Map<String, dynamic>> verifyReceipt(
        String receiptData, bool isSandbox) async {
      final url = isSandbox
          ? 'https://sandbox.itunes.apple.com/verifyReceipt'
          : 'https://buy.itunes.apple.com/verifyReceipt';

      final body = {
        'receipt-data': receiptData,
        'exclude-old-transactions': true,
      };

      final response = await http.post(
        Uri.parse(url),
        body: jsonEncode(body),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to verify receipt: ${response.statusCode}');
      }

      return jsonDecode(response.body);
    }

    Map<String, dynamic> handleReceiptResponse(Map<String, dynamic> response) {
      AnxLog.info('IAP: handleReceiptResponse: $response');
      final status = response['status'];
      if (status == 0) {
        return response['receipt'];
      }
      throw Exception('Failed to verify receipt: $status');
    }

    try {
      var iosPlatformAddition = _inAppPurchase
          .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
      var receiptBase64 =
          await iosPlatformAddition.refreshPurchaseVerificationData();

      print('@@${receiptBase64?.localVerificationData}@@');

      if (receiptBase64 == null) {
        throw Exception('No receipt data available');
      }

      // First try production environment
      final productionResponse =
          await verifyReceipt(receiptBase64.localVerificationData, false);

      if (productionResponse['status'] == 21007) {
        // If production returns 21007, try sandbox environment
        final sandboxResponse =
            await verifyReceipt(receiptBase64.localVerificationData!, true);
        return handleReceiptResponse(sandboxResponse);
      } else {
        return handleReceiptResponse(productionResponse);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> _isOriginalUser() async {
    final receipt = await _loadReceipt();
    final originalUserVersion = receipt['original_user_version'];
    if (originalUserVersion != null &&
        kOriginalUserVersion.contains(originalUserVersion.toString())) {
      return true;
    }
    return false;
  }

  Future<DateTime> _getOriginalDate() async {
    final receipt = await _loadReceipt();
    final originalDate = receipt['original_purchase_date_ms'];
    if (originalDate != null && originalDate is String) {
      return DateTime.fromMillisecondsSinceEpoch(int.parse(originalDate));
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  // 检查试用状态
  Future<void> _checkTrialStatus() async {
    final prefs = await SharedPreferences.getInstance();

    // 如果已购买，试用天数为0
    if (_isPurchased) {
      _trialDaysLeft = 0;
      return;
    }

    // 获取试用开始日期
    final trialStartDateMillis = prefs.getInt(kTrialStartDateKey);
    if (trialStartDateMillis == null) {
      // 第一次使用，设置试用开始日期
      final now = DateTime.now();
      await prefs.setInt(kTrialStartDateKey, now.millisecondsSinceEpoch);
      _trialDaysLeft = kTrialDays;
    } else {
      // 计算剩余试用天数
      final trialStartDate =
          DateTime.fromMillisecondsSinceEpoch(trialStartDateMillis);
      final now = DateTime.now();
      final difference = now.difference(trialStartDate).inDays;
      final daysLeft = kTrialDays - difference;
      _trialDaysLeft = daysLeft > 0 ? daysLeft : 0;
    }
  }

  // 设置购买状态
  Future<void> setPurchased(bool purchased) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kPurchaseStatusKey, purchased);
    _isPurchased = purchased;
  }

  // 检查功能是否可用（已购买或在试用期内）
  bool isFeatureAvailable() {
    return _isPurchased || _trialDaysLeft > 0;
  }

  // 处理购买完成
  Future<void> handleSuccessfulPurchase(PurchaseDetails purchaseDetails) async {
    if (purchaseDetails.productID == kLifetimeProductId) {
      await setPurchased(true);
    }
  }
}
