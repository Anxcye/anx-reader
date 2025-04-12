import 'dart:async';
import 'dart:convert';

import 'package:anx_reader/utils/log/common.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:asn1lib/asn1lib.dart';
enum IAPStatus {
  purchased,
  trial,
  trialExpired,
  originalUser
}
class IAPService {
  static final IAPService _instance = IAPService._internal();
  factory IAPService() {
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

  static const int kTrialDays = 7;
  late Map<String, dynamic> _parsedReceipt;

  bool get isPurchased =>
      _parsedReceipt['receipt']['in_app'].isNotEmpty || _isOriginalUser();
  int get trialDaysLeft =>
      kTrialDays - DateTime.now().difference(_getOriginalDate()).inDays;
  bool get isFeatureAvailable => isPurchased || trialDaysLeft > 0;
  IAPStatus get iapStatus{
    if(_parsedReceipt['receipt']['in_app'].isNotEmpty){
      return IAPStatus.purchased;
    }
    if(_isOriginalUser()){
      return IAPStatus.originalUser;
    }
    if(trialDaysLeft > 0){
      return IAPStatus.trial;
    }
    return IAPStatus.trialExpired;
  }

  Future<void> refresh() async {
    _parsedReceipt = _parseReceiptLocally(await _getReceiptBase64());
  }

  Future<void> initialize() async {
    _parsedReceipt = _parseReceiptLocally(await _getReceiptBase64());
    AnxLog.info('IAP: initialize: ${jsonEncode(_parsedReceipt, toEncodable: (object) {
      if (object is DateTime) {
        return object.toIso8601String();
      }
      return object;
    })}');
  }

  Future<String> _getReceiptBase64() async {
    var iosPlatformAddition = _inAppPurchase
        .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
    var receiptBase64 =
        await iosPlatformAddition.refreshPurchaseVerificationData();
    return receiptBase64?.localVerificationData ?? '';
  }

  Future<Map<String, dynamic>> parseReceiptViaServer(
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
      final parser = ASN1Parser(obj.valueBytes());
      if (!parser.hasNext()) {
        return '';
      }
      dynamic value;
      try {
        value = parser.nextObject();
      } catch (e) {
        return '';
      }

      if (value is ASN1UTF8String) {
        return value.utf8StringValue;
      } else if (value is ASN1Integer) {
        return value.intValue.toString();
      } else if (value is ASN1IA5String) {
        return value.stringValue;
      } else {
        return value.toString();
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
            if (value.contains("Sandbox")) {
              result["environment"] = "Sandbox";
            } else {
              result["environment"] = "Production";
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

  bool _isOriginalUser() {
    final receipt = _parsedReceipt;
    final originalUserVersion = receipt['original_user_version'];
    if (originalUserVersion != null &&
        kOriginalUserVersion.contains(originalUserVersion.toString())) {
      return true;
    }
    return false;
  }

  DateTime _getOriginalDate() {
    final receipt = _parsedReceipt;
    final originalDate = receipt['original_purchase_date'];
    if (originalDate == null || originalDate is! DateTime) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
    return originalDate;
  }
}
