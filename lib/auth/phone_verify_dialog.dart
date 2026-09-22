import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:eduverse/core/firebase/auth_service.dart';
import 'package:eduverse/core/theme/eduverse_theme.dart';

/// Reusable bottom sheet for phone OTP verification matching Stitch Screen 4.
/// Used during registration (phone linking) and profile editing (phone update).
class PhoneVerifyDialog {
  static Future<PhoneAuthCredential?> show(
    BuildContext context, {
    required String phoneNumber,
    String title = 'Verify Mobile Number',
  }) async {
    return showModalBottomSheet<PhoneAuthCredential?>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PhoneVerifySheet(
        phoneNumber: phoneNumber,
        title: title,
      ),
    );
  }
}

class _PhoneVerifySheet extends StatefulWidget {
  final String phoneNumber;
  final String title;

  const _PhoneVerifySheet({
    required this.phoneNumber,
    required this.title,
  });

  @override
  State<_PhoneVerifySheet> createState() => _PhoneVerifySheetState();
}

class _PhoneVerifySheetState extends State<_PhoneVerifySheet> {
  final List<TextEditingController> _otpDigitControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());
  final _authService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  Timer? _countdownTimer;
  int _secondsRemaining = 28;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _sendOTP();
    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    for (final c in _otpDigitControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() {
      _secondsRemaining = 28;
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
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    await _authService.verifyPhoneForLinking(
      phoneNumber: widget.phoneNumber,
      onCodeSent: (verificationId) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _successMessage = 'OTP code dispatched to ${widget.phoneNumber}';
        });
        _startCountdown();
      },
      onError: (error) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage = error;
        });
      },
      onAutoVerified: (credential) {
        if (!mounted) return;
        Navigator.pop(context, credential);
      },
    );
  }

  void _verifyOTP() {
    final otp = _otpDigitControllers.map((c) => c.text).join();
    if (otp.length != 6) {
      setState(() => _errorMessage = 'Please enter a valid 6-digit OTP');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final credential = _authService.getLinkingCredential(otp);
    if (credential != null) {
      Navigator.pop(context, credential);
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Invalid verification session. Please request a new OTP.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Container(
            margin: const EdgeInsets.only(top: 24),
            decoration: BoxDecoration(
              color: EduverseColors.surfaceContainerLowest,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: [
                BoxShadow(
                  color: EduverseColors.deepNavy.withValues(alpha: 0.16),
                  blurRadius: 36,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top Drag Handle
                  Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: EduverseColors.outlineVariant.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Header row: Brand pill + Close
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: EduverseColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.verified_user_rounded,
                              size: 16,
                              color: EduverseColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'eeScholar Auth',
                              style: EduverseTypography.labelSm(color: EduverseColors.primary).copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context, null),
                        icon: const Icon(Icons.close_rounded, color: EduverseColors.onSurfaceVariant),
                        tooltip: 'Dismiss',
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Center Dialpad Icon Badge
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [EduverseColors.primary, EduverseColors.emeraldVivid],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: EduverseColors.emeraldVivid.withValues(alpha: 0.28),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(2.5),
                    child: Container(
                      decoration: BoxDecoration(
                        color: EduverseColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.dialpad_rounded,
                          size: 32,
                          color: EduverseColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title & Subtitle
                  Text(
                    widget.title,
                    style: EduverseTypography.headlineMd(),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We sent a 6-digit one-time passcode (OTP) to\n${widget.phoneNumber}',
                    style: EduverseTypography.bodyMd(),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // Wrong number? Edit
                  GestureDetector(
                    onTap: () => Navigator.pop(context, null),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Wrong number? Edit',
                          style: EduverseTypography.labelSm(color: EduverseColors.emeraldVivid).copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.edit_outlined,
                          size: 14,
                          color: EduverseColors.emeraldVivid,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Error / Success message banners
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: EduverseColors.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, size: 18, color: EduverseColors.error),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: EduverseTypography.labelSm(color: EduverseColors.error),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  if (_successMessage != null && _errorMessage == null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: EduverseColors.primaryFixed.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline_rounded, size: 18, color: EduverseColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _successMessage!,
                              style: EduverseTypography.labelSm(color: EduverseColors.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // 6 OTP Digit Boxes
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
                  const SizedBox(height: 18),

                  // Resend Timer Row
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
                  const SizedBox(height: 18),

                  // Primary Button: VERIFY & CONTINUE
                  SizedBox(
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
                                  'VERIFY & CONTINUE',
                                  style: EduverseTypography.labelLg(color: EduverseColors.onPrimary).copyWith(
                                    letterSpacing: 0.8,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward_rounded, size: 19),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Support Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.support_agent_rounded,
                        size: 16,
                        color: EduverseColors.secondary,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Need help? Contact Scholar Support',
                          style: EduverseTypography.labelSm(color: EduverseColors.secondary).copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Footer security note
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: EduverseColors.surfaceContainerLow.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.lock_outline_rounded,
                          size: 14,
                          color: EduverseColors.emeraldVivid,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'End-to-End Encrypted Verification • UIDAI & DPDPA Compliant',
                            style: EduverseTypography.labelSm(color: EduverseColors.onSurfaceVariant).copyWith(
                              fontSize: 10.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
