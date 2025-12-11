import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter/foundation.dart';

/// Configuration for Razorpay stored in Firestore
class RazorpayConfig {
  final String keyId;
  final String keySecret;
  final bool isTestMode;
  final String companyName;
  final String currency;

  const RazorpayConfig({
    required this.keyId,
    required this.keySecret,
    this.isTestMode = true,
    this.companyName = 'The Eduverse',
    this.currency = 'INR',
  });

  factory RazorpayConfig.fromMap(Map<String, dynamic> map) {
    return RazorpayConfig(
      keyId: map['keyId'] as String? ?? '',
      keySecret: map['keySecret'] as String? ?? '',
      isTestMode: map['isTestMode'] as bool? ?? true,
      companyName: map['companyName'] as String? ?? 'The Eduverse',
      currency: map['currency'] as String? ?? 'INR',
    );
  }

  Map<String, dynamic> toMap() => {
        'keyId': keyId,
        'keySecret': keySecret,
        'isTestMode': isTestMode,
        'companyName': companyName,
        'currency': currency,
      };

  bool get isValid => keyId.isNotEmpty;

  @override
  String toString() =>
      'RazorpayConfig(keyId: ${keyId.isNotEmpty ? "***" : "empty"}, isTestMode: $isTestMode)';
}

/// Payment result from Razorpay
class PaymentResult {
  final bool success;
  final String? paymentId;
  final String? orderId;
  final String? signature;
  final int? errorCode;
  final String? errorMessage;

  const PaymentResult({
    required this.success,
    this.paymentId,
    this.orderId,
    this.signature,
    this.errorCode,
    this.errorMessage,
  });

  factory PaymentResult.success({
    required String paymentId,
    String? orderId,
    String? signature,
  }) {
    return PaymentResult(
      success: true,
      paymentId: paymentId,
      orderId: orderId,
      signature: signature,
    );
  }

  factory PaymentResult.failure({
    required int errorCode,
    required String errorMessage,
  }) {
    return PaymentResult(
      success: false,
      errorCode: errorCode,
      errorMessage: errorMessage,
    );
  }
}

/// Service to handle Razorpay payment integration
class RazorpayService {
  static final RazorpayService _instance = RazorpayService._();
  factory RazorpayService() => _instance;
  RazorpayService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Razorpay? _razorpay;
  RazorpayConfig? _config;
  
  // Callback for current payment
  void Function(PaymentResult)? _onPaymentComplete;

  /// Get the current configuration
  RazorpayConfig? get config => _config;

  /// Initialize Razorpay SDK and load config from Firestore
  Future<void> initialize() async {
    if (_razorpay != null) return;

    debugPrint('[RazorpayService] Initializing...');
    
    _razorpay = Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handleError);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    await loadConfig();
    debugPrint('[RazorpayService] Initialized successfully');
  }

  /// Load configuration from Firestore
  Future<void> loadConfig() async {
    try {
      final doc = await _firestore.collection('config').doc('razorpay').get();
      if (doc.exists && doc.data() != null) {
        _config = RazorpayConfig.fromMap(doc.data()!);
        debugPrint('[RazorpayService] Config loaded: $_config');
      } else {
        debugPrint('[RazorpayService] No config found in Firestore');
        _config = null;
      }
    } catch (e) {
      debugPrint('[RazorpayService] Error loading config: $e');
      _config = null;
      rethrow;
    }
  }

  /// Save configuration to Firestore (admin only)
  Future<void> saveConfig(RazorpayConfig config) async {
    await _firestore.collection('config').doc('razorpay').set(config.toMap());
    _config = config;
    debugPrint('[RazorpayService] Config saved');
  }

  /// Stream of configuration changes
  Stream<RazorpayConfig?> watchConfig() {
    return _firestore
        .collection('config')
        .doc('razorpay')
        .snapshots()
        .map((doc) => doc.exists && doc.data() != null
            ? RazorpayConfig.fromMap(doc.data()!)
            : null);
  }

  /// Start a payment
  /// 
  /// [amount] - Payment amount in INR (will be converted to paise)
  /// [orderId] - Your order reference ID
  /// [customerName] - Customer's name
  /// [customerEmail] - Customer's email
  /// [customerPhone] - Customer's phone number
  /// [description] - Payment description
  /// [onComplete] - Callback when payment completes (success or failure)
  Future<void> startPayment({
    required double amount,
    required String orderId,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    String? description,
    required void Function(PaymentResult) onComplete,
  }) async {
    debugPrint('[RazorpayService] Starting payment for ₹$amount');

    // Initialize if not already done
    if (_razorpay == null) {
      await initialize();
    }

    // Reload config to ensure we have latest
    await loadConfig();

    // Validate config
    if (_config == null || !_config!.isValid) {
      debugPrint('[RazorpayService] Invalid or missing configuration');
      onComplete(PaymentResult.failure(
        errorCode: 0,
        errorMessage: 'Payment configuration not found. Please contact support.',
      ));
      return;
    }

    // Store callback
    _onPaymentComplete = onComplete;

    // Convert to paise
    final amountInPaise = (amount * 100).toInt();

    // Build options
    final options = {
      'key': _config!.keyId,
      'amount': amountInPaise,
      'currency': _config!.currency,
      'name': _config!.companyName,
      'description': description ?? 'Purchase',
      'prefill': {
        'name': customerName,
        'email': customerEmail,
        'contact': customerPhone,
      },
      'notes': {
        'order_id': orderId,
      },
      'theme': {
        'color': '#6200EE',
      },
      // Network reliability options
      'timeout': 300, // 5 minutes
      'retry': {
        'enabled': true,
        'max_count': 3,
      },
    };

    debugPrint('[RazorpayService] Opening checkout with key: ${_config!.keyId.substring(0, 8)}...');

    try {
      _razorpay!.open(options);
    } catch (e) {
      debugPrint('[RazorpayService] Error opening checkout: $e');
      _onPaymentComplete?.call(PaymentResult.failure(
        errorCode: -1,
        errorMessage: 'Failed to open payment screen: $e',
      ));
      _onPaymentComplete = null;
    }
  }

  void _handleSuccess(PaymentSuccessResponse response) {
    debugPrint('[RazorpayService] Payment successful: ${response.paymentId}');
    _onPaymentComplete?.call(PaymentResult.success(
      paymentId: response.paymentId ?? '',
      orderId: response.orderId,
      signature: response.signature,
    ));
    _onPaymentComplete = null;
  }

  void _handleError(PaymentFailureResponse response) {
    debugPrint('[RazorpayService] Payment failed: ${response.code} - ${response.message}');
    _onPaymentComplete?.call(PaymentResult.failure(
      errorCode: response.code ?? -1,
      errorMessage: response.message ?? 'Payment failed',
    ));
    _onPaymentComplete = null;
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('[RazorpayService] External wallet selected: ${response.walletName}');
    // External wallet is just an event, not completion
    // The actual payment result will come via success/error handlers
  }

  /// Clean up resources
  void dispose() {
    _razorpay?.clear();
    _razorpay = null;
    _onPaymentComplete = null;
    debugPrint('[RazorpayService] Disposed');
  }
}
