import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IAPService {
  // 单例模式
  static final IAPService _instance = IAPService._internal();
  factory IAPService() => _instance;
  IAPService._internal();

  // 产品ID - 需要在应用商店后台配置相同的ID
  static const String kLifetimeProductId = 'anx_reader_lifetime';

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

  // 初始化方法
  Future<void> initialize() async {
    // 加载购买状态
    await _loadPurchaseStatus();
    await _checkTrialStatus();
  }

  // 加载购买状态
  Future<void> _loadPurchaseStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _isPurchased = prefs.getBool(kPurchaseStatusKey) ?? false;
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
