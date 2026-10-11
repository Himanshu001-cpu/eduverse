import 'package:flutter/material.dart';
import 'package:eduverse/core/firebase/auth_service.dart';
import 'package:eduverse/core/theme/eduverse_theme.dart';
import 'register_page.dart';
import 'forgot_password_page.dart';
import 'phone_login_page.dart';
import 'widgets/google_logo.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = true;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = await _authService.signInWithEmailOrPhone(
      identifier: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (!result.isSuccess) {
      _showError(result.errorMessage ?? 'Authentication failed');
    } else {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isGoogleLoading = true);

    final result = await _authService.signInWithGoogle();

    if (!mounted) return;
    setState(() => _isGoogleLoading = false);

    if (!result.isSuccess) {
      if (result.errorMessage != null && !result.errorMessage!.toLowerCase().contains('cancel')) {
        _showError(result.errorMessage!);
      }
    } else {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
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
          // Subtle Ambient Academic Glow Backdrop
          Positioned(
            top: -60,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 340,
                height: 340,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      EduverseColors.primaryFixed.withValues(alpha: 0.35),
                      EduverseColors.secondaryFixed.withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildBrandHeader(),
                          const SizedBox(height: 24),
                          _buildFormCard(),
                          const SizedBox(height: 24),
                          _buildFooter(),
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

  Widget _buildBrandHeader() {
    return Column(
      children: [
        // Crest Emblem with glow & auto_awesome badge
        Stack(
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
                    color: EduverseColors.primary.withValues(alpha: 0.15),
                    blurRadius: 28,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
            ),
            Container(
              width: 80,
              height: 80,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: EduverseColors.surfaceContainerLowest,
                shape: BoxShape.circle,
                border: Border.all(
                  color: EduverseColors.outlineVariant.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/auth/eduverse_crest.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: EduverseColors.surfaceContainerLow,
                    child: const Icon(
                      Icons.school_rounded,
                      color: EduverseColors.primary,
                      size: 38,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  color: EduverseColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: EduverseColors.onPrimary,
                  size: 15,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Aspirant Portal Pill Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: EduverseColors.surfaceContainer,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: EduverseColors.secondary.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.school_rounded,
                size: 15,
                color: EduverseColors.secondary,
              ),
              const SizedBox(width: 6),
              Text(
                'ASPIRANT PORTAL',
                style: EduverseTypography.labelSm(color: EduverseColors.secondary).copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Headline & Subtitle
        Text(
          'Welcome Back',
          style: EduverseTypography.headlineLg(),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          'Enter your credentials to continue your academic journey',
          style: EduverseTypography.bodyMd(),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: EduverseColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: EduverseColors.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: EduverseColors.deepNavy.withValues(alpha: 0.06),
            blurRadius: 32,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Field 1: Email or Academic ID
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Email or Mobile Number',
                    style: EduverseTypography.labelLg(),
                  ),
                ),
                Text(
                  'Academic ID',
                  style: EduverseTypography.labelSm(color: EduverseColors.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: EduverseTypography.bodyMd(color: EduverseColors.onSurface),
              decoration: InputDecoration(
                hintText: 'scholar@eduverse.edu or +91',
                hintStyle: EduverseTypography.bodyMd(
                  color: EduverseColors.outline.withValues(alpha: 0.7),
                ),
                prefixIcon: const Icon(
                  Icons.alternate_email_rounded,
                  color: EduverseColors.outline,
                  size: 20,
                ),
                filled: true,
                fillColor: EduverseColors.surfaceContainerLow,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: EduverseColors.primaryContainer,
                    width: 1.8,
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your email or phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),

            // Field 2: Password
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Master Password',
                    style: EduverseTypography.labelLg(),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ForgotPasswordPage()),
                    );
                  },
                  child: Text(
                    'Forgot Password?',
                    style: EduverseTypography.labelSm(color: EduverseColors.secondary).copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: EduverseTypography.bodyMd(color: EduverseColors.onSurface),
              decoration: InputDecoration(
                hintText: 'Enter institutional cipher',
                hintStyle: EduverseTypography.bodyMd(
                  color: EduverseColors.outline.withValues(alpha: 0.7),
                ),
                prefixIcon: const Icon(
                  Icons.key_rounded,
                  color: EduverseColors.outline,
                  size: 20,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: EduverseColors.outline,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                filled: true,
                fillColor: EduverseColors.surfaceContainerLow,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: EduverseColors.primaryContainer,
                    width: 1.8,
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your password';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Remember Me
            Row(
              children: [
                SizedBox(
                  height: 22,
                  width: 22,
                  child: Checkbox(
                    value: _rememberMe,
                    activeColor: EduverseColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    onChanged: (val) => setState(() => _rememberMe = val ?? false),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Remember this Device',
                  style: EduverseTypography.bodyMd(color: EduverseColors.onSurfaceVariant).copyWith(
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Primary Action Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: (_isLoading || _isGoogleLoading) ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: EduverseColors.primaryContainer,
                  foregroundColor: EduverseColors.onPrimary,
                  elevation: 0,
                  shadowColor: EduverseColors.primary.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Sign In to Portal',
                            style: EduverseTypography.labelLg(color: EduverseColors.onPrimary).copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 19),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 22),

            // Divider: OR CONTINUE WITH
            Row(
              children: [
                Expanded(
                  child: Divider(
                    color: EduverseColors.outlineVariant.withValues(alpha: 0.4),
                    thickness: 1,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'OR CONTINUE WITH',
                    style: EduverseTypography.labelSm(
                      color: EduverseColors.outline,
                    ).copyWith(letterSpacing: 1.2, fontSize: 11),
                  ),
                ),
                Expanded(
                  child: Divider(
                    color: EduverseColors.outlineVariant.withValues(alpha: 0.4),
                    thickness: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Secondary Option 1: Phone OTP
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: (_isLoading || _isGoogleLoading)
                    ? null
                    : () {
                        final currentText = _emailController.text.trim();
                        final isPhoneLike = RegExp(r'^[0-9+ ]{4,}$').hasMatch(currentText);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PhoneLoginPage(
                              initialPhone: isPhoneLike ? currentText : null,
                            ),
                          ),
                        );
                      },
                icon: const Icon(
                  Icons.smartphone_rounded,
                  color: EduverseColors.secondary,
                  size: 19,
                ),
                label: Text(
                  'Login with OTP / Phone Number',
                  style: EduverseTypography.labelLg().copyWith(fontSize: 13.5),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: EduverseColors.surfaceContainerLow,
                  side: BorderSide(
                    color: EduverseColors.outlineVariant.withValues(alpha: 0.3),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Secondary Option 2: Google SSO
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: (_isLoading || _isGoogleLoading) ? null : _handleGoogleSignIn,
                style: OutlinedButton.styleFrom(
                  backgroundColor: EduverseColors.surfaceContainerLow,
                  side: BorderSide(
                    color: EduverseColors.outlineVariant.withValues(alpha: 0.3),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isGoogleLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: EduverseColors.primary,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const GoogleLogo(),
                          const SizedBox(width: 10),
                          Text(
                            'Continue with Google',
                            style: EduverseTypography.labelLg().copyWith(fontSize: 13.5),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'New aspirant? ',
              style: EduverseTypography.bodyMd(),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterPage()),
                );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Register Now',
                    style: EduverseTypography.labelLg(color: EduverseColors.primary).copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.north_east_rounded,
                    size: 14,
                    color: EduverseColors.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.verified_user_outlined,
              size: 13,
              color: EduverseColors.outline,
            ),
            const SizedBox(width: 5),
            Text(
              '256-bit Encrypted Academic Protocol',
              style: EduverseTypography.labelSm(color: EduverseColors.outline).copyWith(
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
