import 'package:flutter/material.dart';
import 'package:eduverse/core/firebase/auth_service.dart';
import 'package:eduverse/core/theme/eduverse_theme.dart';
import 'phone_login_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _authService = AuthService();

  String _recoveryMethod = 'email'; // 'email' or 'phone'
  bool _isLoading = false;
  bool _dispatchedSuccess = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleDispatch() async {
    if (!_formKey.currentState!.validate()) return;

    if (_recoveryMethod == 'phone') {
      // Direct user to phone login / verification
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PhoneLoginPage()),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await _authService.resetPassword(_emailController.text.trim());

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.isSuccess) {
      setState(() => _dispatchedSuccess = true);
    } else {
      _showError(result.errorMessage ?? 'Failed to send reset instructions');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EduverseColors.background,
      body: Stack(
        children: [
          // Subtle Ambient Academic Watermark Layer
          Positioned(
            top: -40,
            right: -40,
            child: Opacity(
              opacity: 0.05,
              child: Container(
                width: 260,
                height: 260,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: EduverseColors.primary,
                ),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Back Button
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back_rounded, color: EduverseColors.onSurface),
                            tooltip: 'Back',
                          ),
                          const SizedBox(height: 10),

                          // Hero Visual: Academic Emblem & Key Recovery Motif
                          _buildHeroEmblem(),
                          const SizedBox(height: 16),

                          // Title and Subtitle
                          Center(
                            child: Column(
                              children: [
                                Text(
                                  'Reset Password',
                                  style: EduverseTypography.headlineLg(),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Enter the credential linked with your scholar profile and we will dispatch recovery instructions.',
                                  style: EduverseTypography.bodyMd(),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),

                          // Segmented Switcher / Tabs
                          _buildSegmentedSwitcher(),
                          const SizedBox(height: 20),

                          // Form
                          _buildForm(),
                          const SizedBox(height: 16),

                          // Success Banner (if dispatched)
                          if (_dispatchedSuccess) ...[
                            _buildSuccessBanner(),
                            const SizedBox(height: 16),
                          ],

                          // Academic Advisory Note Card
                          _buildAdvisoryCard(),
                          const SizedBox(height: 18),

                          // Security & Support Bento Cards
                          _buildBentoBadges(),
                          const SizedBox(height: 28),

                          // Return Link Navigation
                          _buildReturnLink(),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroEmblem() {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: EduverseColors.primary.withValues(alpha: 0.12),
                  blurRadius: 28,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
          ),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: EduverseColors.surfaceContainerLowest,
              shape: BoxShape.circle,
              border: Border.all(
                color: EduverseColors.outlineVariant.withValues(alpha: 0.35),
                width: 1.5,
              ),
            ),
            padding: const EdgeInsets.all(8),
            child: Container(
              decoration: const BoxDecoration(
                color: EduverseColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_reset_rounded,
                color: EduverseColors.primaryFixed,
                size: 34,
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: EduverseColors.tertiaryFixed,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.school_rounded,
                size: 16,
                color: EduverseColors.deepNavy,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedSwitcher() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: EduverseColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _recoveryMethod = 'email';
                _dispatchedSuccess = false;
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _recoveryMethod == 'email'
                      ? EduverseColors.surfaceContainerLowest
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _recoveryMethod == 'email'
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.alternate_email_rounded,
                      size: 17,
                      color: _recoveryMethod == 'email'
                          ? EduverseColors.primary
                          : EduverseColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Via Email',
                        overflow: TextOverflow.ellipsis,
                        style: EduverseTypography.labelLg(
                          color: _recoveryMethod == 'email'
                              ? EduverseColors.primary
                              : EduverseColors.onSurfaceVariant,
                        ).copyWith(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _recoveryMethod = 'phone';
                _dispatchedSuccess = false;
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _recoveryMethod == 'phone'
                      ? EduverseColors.surfaceContainerLowest
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _recoveryMethod == 'phone'
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.smartphone_rounded,
                      size: 17,
                      color: _recoveryMethod == 'phone'
                          ? EduverseColors.primary
                          : EduverseColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Via Mobile OTP',
                        overflow: TextOverflow.ellipsis,
                        style: EduverseTypography.labelLg(
                          color: _recoveryMethod == 'phone'
                              ? EduverseColors.primary
                              : EduverseColors.onSurfaceVariant,
                        ).copyWith(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_recoveryMethod == 'email') ...[
            // Email Input Block
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          'Institutional Email',
                          style: EduverseTypography.labelLg(),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text('*', style: TextStyle(color: EduverseColors.emeraldVivid, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.verified_user_outlined, size: 13, color: EduverseColors.secondary),
                    const SizedBox(width: 4),
                    Text(
                      'EduID Portal',
                      style: EduverseTypography.labelSm(color: EduverseColors.secondary).copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: EduverseTypography.bodyMd(color: EduverseColors.onSurface),
              decoration: _buildInputDecoration(
                hint: 'scholar@eduverse.edu',
                prefixIcon: Icons.mail_outline_rounded,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Please enter your registered email';
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v.trim())) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 14, color: EduverseColors.secondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Make sure this matches the email registered during batch enrollment.',
                    style: EduverseTypography.labelSm(color: EduverseColors.onSurfaceVariant).copyWith(
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            // Phone Input Block
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          'Registered Mobile',
                          style: EduverseTypography.labelLg(),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text('*', style: TextStyle(color: EduverseColors.emeraldVivid, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Text(
                  'SMS Verification',
                  style: EduverseTypography.labelSm(color: EduverseColors.secondary).copyWith(fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              style: EduverseTypography.bodyMd(color: EduverseColors.onSurface),
              decoration: _buildInputDecoration(
                hint: '+91 (987) 654-3210',
                prefixIcon: Icons.call_outlined,
              ).copyWith(counterText: ''),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Please enter your mobile number';
                return null;
              },
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.sms_outlined, size: 14, color: EduverseColors.secondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'A one-time 6-digit cryptographic passcode will be transmitted instantly.',
                    style: EduverseTypography.labelSm(color: EduverseColors.onSurfaceVariant).copyWith(
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 18),

          // Dispatch Action Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleDispatch,
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
                          _recoveryMethod == 'email' ? 'Send Reset Link' : 'Send Reset OTP',
                          style: EduverseTypography.labelLg(color: EduverseColors.onPrimary).copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.send_rounded, size: 18),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration({required String hint, required IconData prefixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: EduverseTypography.bodyMd(color: EduverseColors.outline.withValues(alpha: 0.7)),
      prefixIcon: Icon(prefixIcon, color: EduverseColors.outline, size: 20),
      filled: true,
      fillColor: EduverseColors.surfaceContainerLowest,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: EduverseColors.primaryContainer, width: 1.8),
      ),
    );
  }

  Widget _buildSuccessBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: EduverseColors.primaryFixed.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: EduverseColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: EduverseColors.emeraldVivid,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Instructions Dispatched!',
                  style: EduverseTypography.labelLg(color: EduverseColors.primary).copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Please verify your inbox or device. The link remains valid for precisely 15 minutes.',
                  style: EduverseTypography.labelSm(color: EduverseColors.onSurfaceVariant).copyWith(
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvisoryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EduverseColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EduverseColors.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: EduverseColors.tertiaryFixed.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mark_email_unread_outlined,
              size: 18,
              color: EduverseColors.deepNavy,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Scholar Spam Advisory',
                  style: EduverseTypography.labelLg(),
                ),
                const SizedBox(height: 4),
                Text(
                  'Check your spam or institutional promotions folder if the recovery link doesn\'t arrive within 2 minutes.',
                  style: EduverseTypography.labelSm(color: EduverseColors.onSurfaceVariant).copyWith(
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBentoBadges() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: EduverseColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: EduverseColors.outlineVariant.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: EduverseColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.verified_rounded, size: 17, color: EduverseColors.primary),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '256-Bit',
                        style: EduverseTypography.labelSm(color: EduverseColors.onSurface).copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'SSO Protocol',
                        style: EduverseTypography.labelSm(color: EduverseColors.onSurfaceVariant).copyWith(
                          fontSize: 10.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: EduverseColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: EduverseColors.outlineVariant.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: EduverseColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.support_agent_rounded, size: 17, color: EduverseColors.primary),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Need Help?',
                        style: EduverseTypography.labelSm(color: EduverseColors.onSurface).copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Dean Desk 24/7',
                        style: EduverseTypography.labelSm(color: EduverseColors.onSurfaceVariant).copyWith(
                          fontSize: 10.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReturnLink() {
    return Center(
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.arrow_back_rounded,
              size: 16,
              color: EduverseColors.primary,
            ),
            const SizedBox(width: 6),
            Text(
              'Back to Scholar Login',
              style: EduverseTypography.labelLg(color: EduverseColors.primary).copyWith(
                decoration: TextDecoration.underline,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
