import 'dart:async';
import 'dart:convert';

import 'package:anx_reader/utils/log/common.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:asn1lib/asn1lib.dart';
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';

class IAPService {
  // 单例模式
  static final IAPService _instance = IAPService._internal();
  factory IAPService() {
    if (_instance._parsedReceipt == null) {
      _instance._initialize();
    }
    return _instance;
  }
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

  late Map<String, dynamic> _receipt;

  // 存储解析后的收据数据
  Map<String, dynamic>? _parsedReceipt;
  Map<String, dynamic> get receiptData => _parsedReceipt ?? {};

  // 初始化方法
  Future<void> _initialize() async {
    _parsedReceipt = _parseReceiptLocally(await _getReceiptBase64());
  }

  // 加载购买状态
  Future<void> _loadPurchaseStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _isPurchased = false;
  }

  Future<String> _getReceiptBase64() async {
    final start = DateTime.now().millisecondsSinceEpoch;
    var iosPlatformAddition = _inAppPurchase
        .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
    var receiptBase64 =
        await iosPlatformAddition.refreshPurchaseVerificationData();
    final end = DateTime.now().millisecondsSinceEpoch;
    AnxLog.info('IAP: _getReceiptBase64: ${end - start}@@@');
    return receiptBase64?.localVerificationData ?? '';
  }

  Future<Map<String, dynamic>> _parseReceiptViaServer(
      String receiptBase64) async {
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
      // First try production environment
      final productionResponse = await verifyReceipt(receiptBase64, false);

      if (productionResponse['status'] == 21007) {
        // If production returns 21007, try sandbox environment
        final sandboxResponse = await verifyReceipt(receiptBase64, true);
        return handleReceiptResponse(sandboxResponse);
      } else {
        return handleReceiptResponse(productionResponse);
      }
    } catch (e) {
      rethrow;
    }
  }

  Map<String, dynamic> _parseReceiptLocally(String receipt) {
    DateTime formatDate(String isoDate) {
      try {
        isoDate = isoDate
            .replaceAll(String.fromCharCode(20), '')
            .replaceAll(String.fromCharCode(22), '');
        return DateTime.parse(isoDate);
      } catch (e) {
        return DateTime.fromMillisecondsSinceEpoch(0);
      }
    }

    String formatDatePST(String isoDate) {
      return formatDate(isoDate)
          .toLocal()
          .toIso8601String()
          .replaceAll('T', ' ')
          .replaceAll('Z', '')
          .replaceAll(' ', 'PST');
    }

    String getMillisFromDate(String isoDate) {
      return formatDate(isoDate).toLocal().millisecondsSinceEpoch.toString();
    }

    String getFieldValue(ASN1Object obj) {
      if (obj is ASN1OctetString) {
        if (obj.tag == 12) {
          // UTF8String
          return utf8.decode(obj.octets);
        } else if (obj.tag == 22) {
          // IA5String
          return String.fromCharCodes(obj.octets);
        } else if (obj.tag == 4) {
          return obj.stringValue.trim();
        } else {
          return obj.valueBytes().toString().trim();
        }
      } else if (obj is ASN1Integer) {
        return obj.intValue.toString();
      } else {
        return obj.toString();
      }
    }

    void parseReceipt(ASN1Set set, Map<String, dynamic> result) {
      void parseInAppPurchase(ASN1Parser parser, Map<String, dynamic> result) {
        void parseInappPurchaseField(
            ASN1Sequence fieldSeq, Map<String, dynamic> purchase) {
          if (fieldSeq.elements.length >= 3) {
            var element0 = fieldSeq.elements[0];
            var fieldType = 0;
            if (element0 is ASN1Integer) {
              fieldType = element0.intValue;
            }
            var fieldValue = fieldSeq.elements[2];
            var value = getFieldValue(fieldValue);

            switch (fieldType) {
              case 1701: // quantity
                purchase["quantity"] = value;
                break;
              case 1702: // product_id
                purchase["product_id"] = value;
                break;
              case 1703: // transaction_id
                purchase["transaction_id"] = value;
                break;
              case 1705: // original_transaction_id
                purchase["original_transaction_id"] = value;
                break;
              case 1704: // purchase_date
                purchase["purchase_date"] = formatDate(value);
                purchase["purchase_date_ms"] = getMillisFromDate(value);
                purchase["purchase_date_pst"] = formatDatePST(value);
                break;
              case 1706: // original_purchase_date
                purchase["original_purchase_date"] = formatDate(value);
                purchase["original_purchase_date_ms"] =
                    getMillisFromDate(value);
                purchase["original_purchase_date_pst"] = formatDatePST(value);
                break;
            }
          }
        }

        Map<String, dynamic> purchase = {};

        while (parser.hasNext()) {
          var obj = parser.nextObject();
          List<ASN1Object> set = (obj as ASN1Set).elements.toList();
          for (var field in set) {
            if (field is ASN1Sequence) {
              parseInappPurchaseField(field, purchase);
            }
          }

          if (purchase.isNotEmpty) {
            purchase["in_app_ownership_type"] = "PURCHASED";
            result["receipt"]["in_app"].add(purchase);
          }
        }
      }

      void extractFieldValue(
          ASN1Sequence fieldSeq, Map<String, dynamic> result) {
        if (fieldSeq.elements.length < 3) return;

        var element0 = fieldSeq.elements[0];
        var fieldType = 0;

        if (element0 is ASN1Integer) {
          fieldType = element0.intValue;
        }
        var fieldValue = fieldSeq.elements[2];

        if (fieldType == 17 && fieldValue is ASN1OctetString) {
          parseInAppPurchase(ASN1Parser(fieldValue.valueBytes()), result);
          return;
        }

        var value = getFieldValue(fieldValue);

        switch (fieldType) {
          case 2: // bundle_id
            result["receipt"]["bundle_id"] = value;
            break;
          case 3: // application_version
            result["receipt"]["application_version"] = value;
            break;
          case 0: // receipt_type
            result["receipt"]["receipt_type"] = value;
            if (value.contains("Production")) {
              result["environment"] = "Production";
            } else {
              result["environment"] = "Sandbox";
            }
            break;
          case 12: // receipt_creation_date
            result["receipt"]["receipt_creation_date"] = formatDate(value);
            result["receipt"]["receipt_creation_date_ms"] =
                getMillisFromDate(value);
            result["receipt"]["receipt_creation_date_pst"] =
                formatDatePST(value);
            break;
          case 18: // original_purchase_date
            result["receipt"]["original_purchase_date"] = formatDate(value);
            result["receipt"]["original_purchase_date_ms"] =
                getMillisFromDate(value);
            result["receipt"]["original_purchase_date_pst"] =
                formatDatePST(value);
            break;
          case 19: // original_application_version
            result["receipt"]["original_application_version"] = value;
            break;
        }
      }

      for (var field in set.elements) {
        if (field is ASN1Sequence) {
          extractFieldValue(field, result);
        }
      }
    }

    // Decode the base64 receipt
    final receiptData = base64.decode(receipt);
    final parser = ASN1Parser(receiptData);

    // Initialize result structure
    Map<String, dynamic> result = {
      "receipt": <String, dynamic>{
        "in_app": [],
      },
      "environment": "Sandbox",
      "status": 0
    };

    ASN1Sequence contentInfo = parser.nextObject() as ASN1Sequence;
    ASN1Object content = contentInfo.elements[1];
    ASN1Sequence signedData =
        ASN1Parser(content.valueBytes()).nextObject() as ASN1Sequence;
    ASN1Sequence encapContentInfo = signedData.elements[2] as ASN1Sequence;
    ASN1Object eContent = encapContentInfo.elements[1];
    ASN1OctetString octetString =
        ASN1Parser(eContent.valueBytes()).nextObject() as ASN1OctetString;
    ASN1Set set = ASN1Parser(octetString.valueBytes()).nextObject() as ASN1Set;

    parseReceipt(set, result);

    return result;
  }

  Future<bool> _isOriginalUser() async {
    final receipt = _receipt;
    final originalUserVersion = receipt['original_user_version'];
    if (originalUserVersion != null &&
        kOriginalUserVersion.contains(originalUserVersion.toString())) {
      return true;
    }
    return false;
  }

  Future<DateTime> _getOriginalDate() async {
    final receipt = _receipt;
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
