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
}

/// Service to handle Razorpay payments
class RazorpayService {
  static final RazorpayService _instance = RazorpayService._internal();
  factory RazorpayService() => _instance;
  RazorpayService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Razorpay? _razorpay;
  RazorpayConfig? _config;

  // Callbacks
  Function(PaymentSuccessResponse)? _onSuccess;
  Function(PaymentFailureResponse)? _onFailure;
  Function(ExternalWalletResponse)? _onExternalWallet;

  /// Initialize Razorpay with config from Firestore
  Future<void> initialize() async {
    if (_razorpay != null) return;

    _razorpay = Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    await _loadConfig();
  }

  /// Load Razorpay config from Firestore
  Future<void> _loadConfig() async {
    try {
      final doc = await _firestore.collection('config').doc('razorpay').get();
      if (doc.exists) {
        _config = RazorpayConfig.fromJson(doc.data()!);
      } else {
        // Create default config if not exists
        _config = RazorpayConfig(
          keyId: 'rzp_test_Rp7qTUHfNoqRw',
          keySecret: '53ptDBzPDv5WGC5jUD6dOqdA',
          isTestMode: true,
          companyName: 'Eduverse',
          currency: 'INR',
        );
        await _saveConfig(_config!);
      }
    } catch (e) {
      debugPrint('Error loading Razorpay config: $e');
      // Use default test config if error
      _config = RazorpayConfig(
        keyId: 'rzp_test_Rp7qTUHfNoqRw',
        keySecret: '53ptDBzPDv5WGC5jUD6dOqdA',
        isTestMode: true,
        companyName: 'Eduverse',
        currency: 'INR',
      );
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
    
    if (_config == null) {
      debugPrint('RazorpayService: Config is null, loading...');
      await _loadConfig();
    }

    _onSuccess = onSuccess;
    _onFailure = onFailure;
    _onExternalWallet = onExternalWallet;

    // Amount in paise (smallest currency unit)
    final amountInPaise = (amount * 100).toInt();
    debugPrint('RazorpayService: Amount in paise: $amountInPaise');
    debugPrint('RazorpayService: Key ID: ${_config!.keyId}');

    final options = {
      'key': _config!.keyId,
      'amount': amountInPaise,
      'name': _config!.companyName,
      'description': description ?? 'Course Purchase',
      'prefill': {
        'contact': customerPhone.isNotEmpty ? customerPhone : '9999999999',
        'email': customerEmail.isNotEmpty ? customerEmail : 'user@example.com',
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

    debugPrint('RazorpayService: Opening Razorpay with options: $options');

    try {
      _razorpay!.open(options);
      debugPrint('RazorpayService: Razorpay.open() called successfully');
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
    // Detailed error logging
    final errorCode = response.code;
    final errorMessage = response.message ?? 'Unknown error';
    final errorData = response.error;
    
    String errorDescription = '';
    switch (errorCode) {
      case Razorpay.NETWORK_ERROR:
        errorDescription = 'NETWORK_ERROR: No internet connection or network timeout';
        break;
      case Razorpay.INVALID_OPTIONS:
        errorDescription = 'INVALID_OPTIONS: Invalid payment options provided';
        break;
      case Razorpay.PAYMENT_CANCELLED:
        errorDescription = 'PAYMENT_CANCELLED: User cancelled the payment';
        break;
      case Razorpay.TLS_ERROR:
        errorDescription = 'TLS_ERROR: SSL/TLS error';
        break;
      case Razorpay.UNKNOWN_ERROR:
        errorDescription = 'UNKNOWN_ERROR: Something went wrong';
        break;
      default:
        errorDescription = 'Error code: $errorCode';
    }
    
    debugPrint('======== RAZORPAY ERROR ========');
    debugPrint('Error Code: $errorCode');
    debugPrint('Error Description: $errorDescription');
    debugPrint('Error Message: $errorMessage');
    debugPrint('Error Data: $errorData');
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
