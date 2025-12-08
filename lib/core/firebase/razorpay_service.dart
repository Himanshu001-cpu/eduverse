import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter/material.dart';

/// Model for Razorpay configuration stored in Firestore
class RazorpayConfig {
  final String keyId;
  final String keySecret;
  final bool isTestMode;
  final String companyName;
  final String currency;

  RazorpayConfig({
    required this.keyId,
    required this.keySecret,
    required this.isTestMode,
    required this.companyName,
    required this.currency,
  });

  factory RazorpayConfig.fromJson(Map<String, dynamic> json) {
    return RazorpayConfig(
      keyId: json['keyId'] ?? '',
      keySecret: json['keySecret'] ?? '',
      isTestMode: json['isTestMode'] ?? true,
      companyName: json['companyName'] ?? 'Eduverse',
      currency: json['currency'] ?? 'INR',
    );
  }

  Map<String, dynamic> toJson() => {
    'keyId': keyId,
    'keySecret': keySecret,
    'isTestMode': isTestMode,
    'companyName': companyName,
    'currency': currency,
  };

  bool get isValid => keyId.isNotEmpty;
}

/// Service to handle Razorpay payments
class RazorpayService {
  static final RazorpayService _instance = RazorpayService._internal();
  factory RazorpayService() => _instance;
  RazorpayService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Razorpay? _razorpay;
  RazorpayConfig? _config;
  bool _isInitializing = false;

  // Callbacks
  Function(PaymentSuccessResponse)? _onSuccess;
  Function(PaymentFailureResponse)? _onFailure;
  Function(ExternalWalletResponse)? _onExternalWallet;

  /// Initialize Razorpay with config from Firestore
  Future<void> initialize() async {
    if (_razorpay != null) return;
    if (_isInitializing) return;

    _isInitializing = true;
    try {
      _razorpay = Razorpay();
      _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
      _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
      _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

      await _loadConfig();
    } catch (e) {
      debugPrint('Error initializing RazorpayService: $e');
    } finally {
      _isInitializing = false;
    }
  }

  /// Load Razorpay config from Firestore
  Future<void> _loadConfig() async {
    try {
      final doc = await _firestore.collection('config').doc('razorpay').get();
      if (doc.exists && doc.data() != null) {
        _config = RazorpayConfig.fromJson(doc.data()!);
      } else {
        debugPrint('Razorpay config not found in Firestore');
        _config = null;
      }
    } catch (e) {
      debugPrint('Error loading Razorpay config: $e');
      _config = null;
    }
  }

  /// Save config to Firestore
  Future<void> _saveConfig(RazorpayConfig config) async {
    await _firestore.collection('config').doc('razorpay').set(config.toJson());
  }

  /// Get current config
  RazorpayConfig? get config => _config;

  /// Open Razorpay checkout
  Future<void> openCheckout({
    required double amount,
    required String orderId,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    String? description,
    Function(PaymentSuccessResponse)? onSuccess,
    Function(PaymentFailureResponse)? onFailure,
    Function(ExternalWalletResponse)? onExternalWallet,
  }) async {
    debugPrint('RazorpayService: openCheckout called');
    
    if (_razorpay == null) {
      debugPrint('RazorpayService: Razorpay not initialized, initializing now...');
      await initialize();
    }
    
    // Refresh config to ensure we have latest keys
    await _loadConfig();

    if (_config == null || !_config!.isValid) {
      debugPrint('RazorpayService: Invalid or missing config');
      if (onFailure != null) {
        onFailure(PaymentFailureResponse(
          Razorpay.UNKNOWN_ERROR,
          'Payment gateway configuration missing. Please contact support.',
          null,
        ));
      }
      return;
    }

    _onSuccess = onSuccess;
    _onFailure = onFailure;
    _onExternalWallet = onExternalWallet;

    // Amount in paise (smallest currency unit)
    final amountInPaise = (amount * 100).toInt();
    
    final options = {
      'key': _config!.keyId,
      'amount': amountInPaise,
      'name': _config!.companyName,
      'description': description ?? 'Course Purchase',
      'prefill': {
        'contact': customerPhone,
        'email': customerEmail,
        'name': customerName,
      },
      'notes': {
        'order_id': orderId,
      },
      'theme': {
        'color': '#6200EE',
      },
      'currency': _config!.currency,
    };

    debugPrint('RazorpayService: Opening Razorpay');

    try {
      _razorpay!.open(options);
    } catch (e) {
      debugPrint('RazorpayService: Error opening Razorpay: $e');
      if (_onFailure != null) {
        _onFailure!(PaymentFailureResponse(
          Razorpay.UNKNOWN_ERROR,
          'Failed to open payment gateway: $e',
          null,
        ));
      }
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    debugPrint('Payment Success: ${response.paymentId}');
    if (_onSuccess != null) {
      _onSuccess!(response);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    final errorCode = response.code;
    final errorMessage = response.message ?? 'Unknown error';
    
    debugPrint('======== RAZORPAY ERROR ========');
    debugPrint('Error Code: $errorCode');
    debugPrint('Error Message: $errorMessage');
    debugPrint('================================');
    
    if (_onFailure != null) {
      _onFailure!(response);
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('External Wallet: ${response.walletName}');
    if (_onExternalWallet != null) {
      _onExternalWallet!(response);
    }
  }

  /// Dispose Razorpay instance
  void dispose() {
    _razorpay?.clear();
    _razorpay = null;
  }

  /// Update Razorpay config (admin only)
  Future<void> updateConfig(RazorpayConfig newConfig) async {
    await _saveConfig(newConfig);
    _config = newConfig;
  }

  /// Stream config for admin settings
  Stream<RazorpayConfig?> configStream() {
    return _firestore
        .collection('config')
        .doc('razorpay')
        .snapshots()
        .map((doc) => doc.exists ? RazorpayConfig.fromJson(doc.data()!) : null);
  }
}
