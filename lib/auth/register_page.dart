import 'package:flutter/material.dart';
import 'package:eduverse/core/firebase/auth_service.dart';
import 'package:eduverse/core/theme/eduverse_theme.dart';
import 'phone_verify_dialog.dart';
import 'privacy_policy_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  String? _selectedExam;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _acceptedTerms = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<Map<String, String>> _targetExams = [
    {'value': 'upsc', 'label': 'UPSC Civil Services (IAS / IFS / IPS)'},
    {'value': 'state_psc', 'label': 'State PSC (UPPSC, BPSC, MPPSC, etc.)'},
    {'value': 'ssc_cgl', 'label': 'SSC Combined Graduate Level (CGL)'},
    {'value': 'banking_rbi', 'label': 'Banking & RBI Grade B Officers'},
  ];

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
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  int _calculatePasswordStrength(String password) {
    if (password.isEmpty) return 0;
    int score = 0;
    if (password.length >= 6) score++;
    if (password.length >= 8) score++;
    if (password.contains(RegExp(r'[A-Z]')) && password.contains(RegExp(r'[a-z]'))) score++;
    if (password.contains(RegExp(r'[0-9]')) || password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score++;
    return score;
  }

  Color _getStrengthBarColor(int strength, int barIndex) {
    if (strength == 0) return EduverseColors.surfaceVariant;
    if (barIndex <= strength) {
      if (strength == 1) return EduverseColors.error;
      if (strength == 2) return Colors.orange;
      if (strength == 3) return EduverseColors.secondary;
      return EduverseColors.emeraldVivid;
    }
    return EduverseColors.surfaceVariant;
  }

  String _getStrengthLabel(int strength) {
    switch (strength) {
      case 1:
        return 'Weak cipher';
      case 2:
        return 'Fair strength';
      case 3:
        return 'Strong cipher';
      case 4:
        return 'Excellent protection';
      default:
        return 'Minimum 8 characters';
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptedTerms) {
      _showError('Please accept the Honor Code & Terms of Service');
      return;
    }

    setState(() => _isLoading = true);

    // 1. Sign up with email
    final result = await _authService.signUpWithEmail(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      displayName: _nameController.text.trim(),
    );

    if (!mounted) return;

    if (!result.isSuccess) {
      setState(() => _isLoading = false);
      _showError(result.errorMessage ?? 'Registration failed');
      return;
    }

    final user = result.user;
    if (user != null) {
      final phone = _phoneController.text.trim();
      if (phone.isNotEmpty && phone.length >= 10) {
        // Offer phone verification modal
        final fullPhone = '+91$phone';
        final credential = await PhoneVerifyDialog.show(
          context,
          phoneNumber: fullPhone,
          title: 'Verify Mobile Number',
        );

        if (credential != null) {
          await _authService.linkPhoneToAccount(credential);
        }
      }

      // Save user profile details
      await _authService.saveUserProfile(
        uid: user.uid,
        email: user.email!,
        displayName: _nameController.text.trim(),
        phone: phone.isNotEmpty ? '+91$phone' : null,
      );
    }

    setState(() => _isLoading = false);

    if (mounted) {
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
          // Ambient Academic Futurist Watermark Aura
          Positioned(
            top: -40,
            right: -60,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    EduverseColors.primaryFixed.withValues(alpha: 0.28),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 240,
            left: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    EduverseColors.secondaryFixed.withValues(alpha: 0.20),
                    Colors.transparent,
                  ],
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
                          _buildTopBranding(),
                          const SizedBox(height: 18),
                          _buildTitleSection(),
                          const SizedBox(height: 16),
                          _buildSocialProofBadge(),
                          const SizedBox(height: 20),
                          _buildRegistrationCard(),
                          const SizedBox(height: 22),
                          _buildLoginFooter(),
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

  Widget _buildTopBranding() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded, color: EduverseColors.onSurface),
              tooltip: 'Back',
            ),
            const SizedBox(width: 4),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ACADEMIC EXCELLENCE',
                  style: EduverseTypography.labelSm(color: EduverseColors.secondary).copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
                Text(
                  'The Eduverse',
                  style: EduverseTypography.labelLg(color: EduverseColors.onSurface).copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: EduverseColors.surfaceContainerLowest,
            shape: BoxShape.circle,
            border: Border.all(color: EduverseColors.outlineVariant.withValues(alpha: 0.4)),
            boxShadow: [
              BoxShadow(
                color: EduverseColors.primary.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(4),
          child: ClipOval(
            child: Image.asset(
              'assets/auth/eduverse_crest.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(Icons.school, size: 20, color: EduverseColors.primary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Begin Your Journey',
          style: EduverseTypography.headlineLg(),
        ),
        const SizedBox(height: 6),
        Text(
          'Join 18,000+ serious aspirants preparing for UPSC, State PSC & competitive exams.',
          style: EduverseTypography.bodyMd(),
        ),
      ],
    );
  }

  Widget _buildSocialProofBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: EduverseColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EduverseColors.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          // Overlapping Avatars
          SizedBox(
            width: 72,
            height: 32,
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  child: _buildAvatar('assets/auth/student_avatar_1.png'),
                ),
                Positioned(
                  left: 20,
                  child: _buildAvatar('assets/auth/student_avatar_2.png'),
                ),
                Positioned(
                  left: 40,
                  child: _buildAvatar('assets/auth/student_avatar_3.png'),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        '18,450+ Active Aspirants',
                        style: EduverseTypography.labelSm(color: EduverseColors.primary).copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.star_rounded,
                      size: 15,
                      color: EduverseColors.tertiaryContainer,
                    ),
                  ],
                ),
                Text(
                  'Ranked #1 Civil Prep Community 2024',
                  style: EduverseTypography.labelSm(color: EduverseColors.onSurfaceVariant).copyWith(
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String assetPath) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: ClipOval(
        child: Image.asset(
          assetPath,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: EduverseColors.surfaceContainerHigh,
            child: const Icon(Icons.person, size: 16, color: EduverseColors.primary),
          ),
        ),
      ),
    );
  }

  Widget _buildRegistrationCard() {
    final password = _passwordController.text;
    final strength = _calculatePasswordStrength(password);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: EduverseColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: EduverseColors.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: EduverseColors.deepNavy.withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Full Name
            _buildFieldLabel('Full Name', Icons.badge_outlined),
            const SizedBox(height: 6),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              style: EduverseTypography.bodyMd(color: EduverseColors.onSurface),
              decoration: _buildInputDecoration(hint: 'e.g. Ananya Sharma'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your full name' : null,
            ),
            const SizedBox(height: 16),

            // 2. Email Address
            _buildFieldLabel('Email Address', Icons.mail_outline_rounded),
            const SizedBox(height: 6),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: EduverseTypography.bodyMd(color: EduverseColors.onSurface),
              decoration: _buildInputDecoration(hint: 'aspirant@eduverse.org'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Please enter your email';
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v.trim())) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 3. Mobile Number
            _buildFieldLabel('Mobile Number', Icons.phone_iphone_rounded),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: EduverseColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Text('🇮🇳', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 5),
                      Text('+91', style: EduverseTypography.labelLg()),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    style: EduverseTypography.bodyMd(color: EduverseColors.onSurface),
                    decoration: _buildInputDecoration(hint: '98765 43210').copyWith(counterText: ''),
                    validator: (v) {
                      if (v != null && v.isNotEmpty && v.length < 10) {
                        return 'Enter a 10-digit mobile number';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 4. Target Examination Dropdown
            _buildFieldLabel('Target Examination', Icons.school_outlined),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _selectedExam,
              isExpanded: true,
              style: EduverseTypography.bodyMd(color: EduverseColors.onSurface),
              decoration: _buildInputDecoration(hint: 'Select Your Primary Goal'),
              icon: const Icon(Icons.expand_more_rounded, color: EduverseColors.onSurfaceVariant),
              items: _targetExams.map((exam) {
                return DropdownMenuItem<String>(
                  value: exam['value'],
                  child: Text(
                    exam['label']!,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedExam = val),
            ),
            const SizedBox(height: 16),

            // 5. Password & Strength Meter
            _buildFieldLabel('Create Secure Password', Icons.lock_reset_rounded),
            const SizedBox(height: 6),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              onChanged: (_) => setState(() {}),
              style: EduverseTypography.bodyMd(color: EduverseColors.onSurface),
              decoration: _buildInputDecoration(hint: 'At least 8 characters').copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: EduverseColors.outline,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Please create a password';
                if (v.length < 6) return 'Password must be at least 6 characters';
                return null;
              },
            ),
            const SizedBox(height: 8),

            // 4-bar strength indicator
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: List.generate(4, (i) {
                      return Expanded(
                        child: Container(
                          height: 4,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: _getStrengthBarColor(strength, i + 1),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _getStrengthLabel(strength),
                  style: EduverseTypography.labelSm(color: EduverseColors.onSurfaceVariant).copyWith(
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // 6. Agreement Checkbox
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 22,
                  width: 22,
                  child: Checkbox(
                    value: _acceptedTerms,
                    activeColor: EduverseColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    onChanged: (val) => setState(() => _acceptedTerms = val ?? false),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _acceptedTerms = !_acceptedTerms),
                    child: Wrap(
                      children: [
                        Text(
                          'I pledge adherence to the Academy Honor Code and accept the ',
                          style: EduverseTypography.labelSm(color: EduverseColors.onSurfaceVariant).copyWith(
                            fontSize: 11.5,
                            height: 1.35,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
                            );
                          },
                          child: Text(
                            'Privacy Policy & Terms',
                            style: EduverseTypography.labelSm(color: EduverseColors.primary).copyWith(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        Text(
                          '.',
                          style: EduverseTypography.labelSm(color: EduverseColors.onSurfaceVariant).copyWith(
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // CTA Button: Create Account
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleRegister,
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
                            'Create Account',
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
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: EduverseColors.primary),
        const SizedBox(width: 6),
        Text(
          label,
          style: EduverseTypography.labelLg(),
        ),
      ],
    );
  }

  InputDecoration _buildInputDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: EduverseTypography.bodyMd(color: EduverseColors.outline.withValues(alpha: 0.7)),
      filled: true,
      fillColor: EduverseColors.surfaceContainerLow,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: EduverseColors.primaryContainer, width: 1.8),
      ),
    );
  }

  Widget _buildLoginFooter() {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'Already have an account? ',
          style: EduverseTypography.bodyMd(),
        ),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Text(
            'Login here',
            style: EduverseTypography.labelLg(color: EduverseColors.primary).copyWith(
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}
