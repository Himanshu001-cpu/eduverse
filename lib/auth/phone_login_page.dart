import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:eduverse/core/firebase/auth_service.dart';
import 'package:eduverse/core/theme/eduverse_theme.dart';
import 'login_page.dart';

class PhoneLoginPage extends StatefulWidget {
  final String? initialPhone;
  const PhoneLoginPage({super.key, this.initialPhone});

  @override
  State<PhoneLoginPage> createState() => _PhoneLoginPageState();
}

class _PhoneLoginPageState extends State<PhoneLoginPage> with SingleTickerProviderStateMixin {
  final _phoneController = TextEditingController();
  final List<TextEditingController> _otpDigitControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());
  final _authService = AuthService();

  bool _isLoading = false;
  bool _codeSent = false;
  String _selectedCountry = '+91';
  String _deliveryChannel = 'sms'; // 'sms' or 'whatsapp'

  Timer? _countdownTimer;
  int _secondsRemaining = 30;
  bool _canResend = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<Map<String, String>> _countries = [
    {'code': '+91', 'name': 'India', 'flag': '🇮🇳'},
    {'code': '+1', 'name': 'USA', 'flag': '🇺🇸'},
    {'code': '+44', 'name': 'UK', 'flag': '🇬🇧'},
    {'code': '+61', 'name': 'Australia', 'flag': '🇦🇺'},
    {'code': '+971', 'name': 'UAE', 'flag': '🇦🇪'},
    {'code': '+65', 'name': 'Singapore', 'flag': '🇸🇬'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialPhone != null && widget.initialPhone!.isNotEmpty) {
      final clean = widget.initialPhone!.replaceAll(RegExp(r'[^0-9]'), '');
      if (clean.length >= 10) {
        _phoneController.text = clean.substring(clean.length - 10);
      } else {
        _phoneController.text = clean;
      }
    }
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _phoneController.dispose();
    for (final c in _otpDigitControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    _animationController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _countdownTimer?.cancel();
    setState(() {
      _secondsRemaining = 30;
      _canResend = false;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        setState(() => _canResend = true);
        timer.cancel();
      }
    });
  }

  Future<void> _sendOTP() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length < 10) {
      _showError('Please enter a valid 10-digit mobile number');
      return;
    }

    setState(() => _isLoading = true);

    final fullPhoneNumber = '$_selectedCountry$phone';

    await _authService.verifyPhoneNumber(
      phoneNumber: fullPhoneNumber,
      onCodeSent: (verificationId) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _codeSent = true;
        });
        _startResendTimer();
        _showSuccess('OTP code sent to $fullPhoneNumber');
      },
      onError: (error) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        _showError(error);
      },
      onAutoVerified: (credential) async {
        if (!mounted) return;
        setState(() => _isLoading = true);
        final result = await _authService.signInWithPhoneCredential(credential);

        if (!mounted) return;
        if (result.isSuccess && result.user != null) {
          await _handleNewUserProfile(result.user!);
          if (!mounted) return;
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        } else {
          setState(() => _isLoading = false);
          _showError(result.errorMessage ?? 'Automatic verification failed');
        }
      },
    );
  }

  Future<void> _verifyOTP() async {
    final otp = _otpDigitControllers.map((c) => c.text).join();
    if (otp.length != 6) {
      _showError('Please enter the full 6-digit verification code');
      return;
    }

    setState(() => _isLoading = true);

    final result = await _authService.verifyOTP(otp);

    if (!mounted) return;

    if (result.isSuccess && result.user != null) {
      await _handleNewUserProfile(result.user!);
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    } else {
      setState(() => _isLoading = false);
      _showError(result.errorMessage ?? 'Invalid verification code');
    }
  }

  Future<void> _handleNewUserProfile(User user) async {
    final exists = await _authService.userProfileExists(user.uid);
    if (!exists) {
      await _authService.saveUserProfile(
        uid: user.uid,
        email: user.email ?? '${user.phoneNumber}@eduverse.app',
        displayName: 'Scholar',
        phone: user.phoneNumber,
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: EduverseColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: EduverseColors.emeraldVivid,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showInfo(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: EduverseColors.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EduverseColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  // App Bar / Top Navigation
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color: EduverseColors.onSurface,
                          ),
                          tooltip: 'Back to Login',
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: EduverseColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.shield_outlined,
                                size: 14,
                                color: EduverseColors.primary,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'SECURE OTP',
                                style: EduverseTypography.labelSm(color: EduverseColors.primary).copyWith(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Main Scrollable Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title & Subtitle
                          Text(
                            _codeSent ? 'Verify Phone Code' : 'Phone Login',
                            style: EduverseTypography.headlineLg(),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _codeSent
                                ? 'Enter the 6-digit verification code transmitted to $_selectedCountry ${_phoneController.text.trim()}'
                                : 'Enter your registered mobile number to receive a 6-digit verification code (OTP) via SMS or WhatsApp.',
                            style: EduverseTypography.bodyMd(),
                          ),
                          const SizedBox(height: 28),

                          // Phone Input or OTP Verification Step
                          if (!_codeSent) ...[
                            _buildPhoneInputSection(),
                            const SizedBox(height: 20),
                            _buildDeliveryChannelSelector(),
                            const SizedBox(height: 24),
                            _buildSendOtpButton(),
                            const SizedBox(height: 24),
                            _buildDividerOr(),
                            const SizedBox(height: 20),
                            _buildEmailLoginButton(),
                          ] else ...[
                            _buildOtpVerificationSection(),
                            const SizedBox(height: 24),
                            _buildVerifyButton(),
                            const SizedBox(height: 16),
                            _buildChangeNumberButton(),
                          ],
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Trust Badge Footer
                  _buildTrustFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneInputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MOBILE NUMBER',
          style: EduverseTypography.labelSm(color: EduverseColors.onSurface).copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: EduverseColors.surfaceBright,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: EduverseColors.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              // Country Selector
              GestureDetector(
                onTap: _showCountryPicker,
                child: Container(
                  height: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: EduverseColors.surfaceContainerLow,
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(13)),
                    border: Border(
                      right: BorderSide(
                        color: EduverseColors.outlineVariant.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _countries.firstWhere((c) => c['code'] == _selectedCountry)['flag']!,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _selectedCountry,
                        style: EduverseTypography.labelLg(color: EduverseColors.onSurface),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.expand_more_rounded,
                        size: 18,
                        color: EduverseColors.outline,
                      ),
                    ],
                  ),
                ),
              ),

              // Number Input Field
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  style: EduverseTypography.bodyLg(color: EduverseColors.onSurface).copyWith(
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: '98765 43210',
                    hintStyle: EduverseTypography.bodyMd(
                      color: EduverseColors.outline.withValues(alpha: 0.6),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: EduverseColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Select Country Code', style: EduverseTypography.labelLg()),
              ),
              const Divider(height: 1),
              ..._countries.map((c) => ListTile(
                    leading: Text(c['flag']!, style: const TextStyle(fontSize: 22)),
                    title: Text(c['name']!, style: EduverseTypography.bodyMd(color: EduverseColors.onSurface)),
                    trailing: Text(c['code']!, style: EduverseTypography.labelLg(color: EduverseColors.secondary)),
                    onTap: () {
                      setState(() => _selectedCountry = c['code']!);
                      Navigator.pop(context);
                    },
                  )),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDeliveryChannelSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DELIVERY CHANNEL',
          style: EduverseTypography.labelSm(color: EduverseColors.onSurfaceVariant).copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // SMS Option
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _deliveryChannel = 'sms'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  decoration: BoxDecoration(
                    color: _deliveryChannel == 'sms'
                        ? EduverseColors.primaryFixed.withValues(alpha: 0.25)
                        : EduverseColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _deliveryChannel == 'sms'
                          ? EduverseColors.primary
                          : EduverseColors.outlineVariant.withValues(alpha: 0.8),
                      width: _deliveryChannel == 'sms' ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.sms_rounded,
                        size: 18,
                        color: _deliveryChannel == 'sms'
                            ? EduverseColors.primary
                            : EduverseColors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Send via SMS',
                          overflow: TextOverflow.ellipsis,
                          style: EduverseTypography.labelSm(
                            color: _deliveryChannel == 'sms'
                                ? EduverseColors.primary
                                : EduverseColors.onSurfaceVariant,
                          ).copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // WhatsApp Option
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() => _deliveryChannel = 'whatsapp');
                  _showInfo('WhatsApp delivery fallback enabled. Default SMS channel will also activate.');
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  decoration: BoxDecoration(
                    color: _deliveryChannel == 'whatsapp'
                        ? EduverseColors.primaryFixed.withValues(alpha: 0.25)
                        : EduverseColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _deliveryChannel == 'whatsapp'
                          ? EduverseColors.primary
                          : EduverseColors.outlineVariant.withValues(alpha: 0.8),
                      width: _deliveryChannel == 'whatsapp' ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 18,
                        color: EduverseColors.emeraldVivid,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Send via WhatsApp',
                          overflow: TextOverflow.ellipsis,
                          style: EduverseTypography.labelSm(
                            color: _deliveryChannel == 'whatsapp'
                                ? EduverseColors.primary
                                : EduverseColors.onSurfaceVariant,
                          ).copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSendOtpButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _sendOTP,
        style: ElevatedButton.styleFrom(
          backgroundColor: EduverseColors.primaryContainer,
          foregroundColor: EduverseColors.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Request OTP Code',
                    style: EduverseTypography.labelLg(color: EduverseColors.onPrimary).copyWith(
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 19),
                ],
              ),
      ),
    );
  }

  Widget _buildDividerOr() {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: EduverseColors.outlineVariant.withValues(alpha: 0.6),
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'OR',
            style: EduverseTypography.labelSm(color: EduverseColors.outline).copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: EduverseColors.outlineVariant.withValues(alpha: 0.6),
            thickness: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildEmailLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginPage()),
          );
        },
        icon: const Icon(Icons.mail_outline_rounded, color: EduverseColors.secondary, size: 19),
        label: Text(
          'Login with Email & Password',
          style: EduverseTypography.labelLg().copyWith(fontSize: 13.5),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: EduverseColors.surfaceContainerLowest,
          side: BorderSide(color: EduverseColors.outlineVariant.withValues(alpha: 0.8)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _buildOtpVerificationSection() {
    return Column(
      children: [
        // 6-box OTP entry
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (index) {
            return SizedBox(
              width: 46,
              height: 54,
              child: TextField(
                controller: _otpDigitControllers[index],
                focusNode: _otpFocusNodes[index],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 1,
                style: EduverseTypography.headlineMd(color: EduverseColors.onSurface),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: EduverseColors.surfaceContainerLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: EduverseColors.primary,
                      width: 2,
                    ),
                  ),
                ),
                onChanged: (value) {
                  if (value.isNotEmpty && index < 5) {
                    _otpFocusNodes[index + 1].requestFocus();
                  } else if (value.isEmpty && index > 0) {
                    _otpFocusNodes[index - 1].requestFocus();
                  }
                  if (index == 5 && value.isNotEmpty) {
                    _verifyOTP();
                  }
                },
              ),
            );
          }),
        ),
        const SizedBox(height: 20),

        // Timer & Resend
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    size: 16,
                    color: EduverseColors.tertiary,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      _canResend
                          ? 'Code expired'
                          : 'Resend code in 0:${_secondsRemaining.toString().padLeft(2, '0')}',
                      style: EduverseTypography.labelSm(color: EduverseColors.onSurfaceVariant),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: _canResend ? _sendOTP : null,
              child: Text(
                'Resend OTP',
                style: EduverseTypography.labelSm(
                  color: _canResend ? EduverseColors.emeraldVivid : EduverseColors.outline,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVerifyButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _verifyOTP,
        style: ElevatedButton.styleFrom(
          backgroundColor: EduverseColors.primary,
          foregroundColor: EduverseColors.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Verify & Continue',
                    style: EduverseTypography.labelLg(color: EduverseColors.onPrimary).copyWith(
                      letterSpacing: 0.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 19),
                ],
              ),
      ),
    );
  }

  Widget _buildChangeNumberButton() {
    return Center(
      child: TextButton.icon(
        onPressed: () {
          _countdownTimer?.cancel();
          setState(() {
            _codeSent = false;
            for (final c in _otpDigitControllers) {
              c.clear();
            }
          });
        },
        icon: const Icon(Icons.edit_outlined, size: 15, color: EduverseColors.emeraldVivid),
        label: Text(
          'Wrong number? Edit',
          style: EduverseTypography.labelSm(color: EduverseColors.emeraldVivid).copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildTrustFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: EduverseColors.surfaceContainerLow.withValues(alpha: 0.7),
        border: Border(
          top: BorderSide(
            color: EduverseColors.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.security_rounded,
            size: 16,
            color: EduverseColors.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Secured by Eduverse Authentication Shield • Single-device session protection',
              style: EduverseTypography.labelSm(color: EduverseColors.onSurfaceVariant).copyWith(
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
