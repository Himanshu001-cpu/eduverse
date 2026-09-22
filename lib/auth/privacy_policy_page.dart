import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:eduverse/core/theme/eduverse_theme.dart';

class PrivacyPolicyPage extends StatefulWidget {
  const PrivacyPolicyPage({super.key});

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _sectionKeys = {
    0: GlobalKey(),
    1: GlobalKey(),
    2: GlobalKey(),
    3: GlobalKey(),
    4: GlobalKey(),
    5: GlobalKey(),
    6: GlobalKey(),
  };

  int _activeChip = 0;

  final List<String> _chips = [
    '1. Intro',
    '2. Data Collected',
    '3. Usage',
    '4. Third Parties',
    '5. Security',
    '6. Rights',
    '7. Grievance',
  ];

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSection(int index) {
    setState(() => _activeChip = index);
    final key = _sectionKeys[index];
    if (key != null && key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
        alignment: 0.08,
      );
    }
  }

  void _sharePolicy() {
    SharePlus.instance.share(
      ShareParams(
        text: 'The Eduverse Privacy Policy & Trust Protocol: https://theeduverse.org/privacy-policy',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EduverseColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded, color: EduverseColors.primary),
                    tooltip: 'Back',
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: EduverseColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.shield_outlined, size: 14, color: EduverseColors.secondary),
                        const SizedBox(width: 5),
                        Text(
                          'TRUST & PRIVACY',
                          style: EduverseTypography.labelSm(color: EduverseColors.secondary).copyWith(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _sharePolicy,
                    icon: const Icon(Icons.share_outlined, color: EduverseColors.primary),
                    tooltip: 'Share Document',
                  ),
                ],
              ),
            ),

            // Sticky Quick-Jump Navigation Chips
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: EduverseColors.surface.withValues(alpha: 0.95),
                border: Border(
                  bottom: BorderSide(
                    color: EduverseColors.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
              ),
              child: SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _chips.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final isSelected = _activeChip == i;
                    return GestureDetector(
                      onTap: () => _scrollToSection(i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? EduverseColors.primary
                              : EduverseColors.surfaceContainer,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: EduverseColors.primary.withValues(alpha: 0.25),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            _chips[i],
                            style: EduverseTypography.labelSm(
                              color: isSelected ? EduverseColors.onPrimary : EduverseColors.onSurfaceVariant,
                            ).copyWith(
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Scrollable Sections
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Banner & Emblem Showcase
                        _buildHeroBanner(),
                        const SizedBox(height: 20),

                        // Section 1: Introduction
                        _buildSection1(key: _sectionKeys[0]!),
                        const SizedBox(height: 16),

                        // Section 2: Information We Collect
                        _buildSection2(key: _sectionKeys[1]!),
                        const SizedBox(height: 16),

                        // Visual Divider Image
                        _buildImageBanner(),
                        const SizedBox(height: 16),

                        // Section 3: How We Use Your Data
                        _buildSection3(key: _sectionKeys[2]!),
                        const SizedBox(height: 16),

                        // Section 4: Third Parties
                        _buildSection4(key: _sectionKeys[3]!),
                        const SizedBox(height: 16),

                        // Section 5: Data Security & DRM
                        _buildSection5(key: _sectionKeys[4]!),
                        const SizedBox(height: 16),

                        // Section 6: Student Rights
                        _buildSection6(key: _sectionKeys[5]!),
                        const SizedBox(height: 16),

                        // Section 7: Grievance Officer
                        _buildSection7(key: _sectionKeys[6]!),
                        const SizedBox(height: 24),

                        // Bottom Copyright & Certification
                        Center(
                          child: Text(
                            '© 2026 The Eduverse Academic Platform. All Rights Reserved.',
                            style: EduverseTypography.labelSm(color: EduverseColors.outline).copyWith(
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            EduverseColors.primary,
            EduverseColors.primaryContainer,
            EduverseColors.secondary,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: EduverseColors.primary.withValues(alpha: 0.22),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.verified_user_rounded,
                size: 20,
                color: EduverseColors.secondaryFixed,
              ),
              const SizedBox(width: 6),
              Text(
                'THE EDUVERSE TRUST PROTOCOL',
                style: EduverseTypography.labelSm(color: EduverseColors.secondaryFixed).copyWith(
                  letterSpacing: 1.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Privacy Policy',
            style: EduverseTypography.headlineLg(color: EduverseColors.onPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Safeguarding the learning journey, scholarly privacy, and digital rights of our global student community.',
            style: EduverseTypography.bodyMd(color: EduverseColors.primaryFixed).copyWith(
              fontSize: 14.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'v2.1',
                  style: EduverseTypography.labelSm(color: EduverseColors.primaryFixed),
                ),
              ),
              const Text('•', style: TextStyle(color: Colors.white70)),
              Text(
                'Effective: Oct 2024',
                style: EduverseTypography.labelSm(color: Colors.white70),
              ),
              const Text('•', style: TextStyle(color: Colors.white70)),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.shield_rounded, size: 13, color: EduverseColors.secondaryFixed),
                  const SizedBox(width: 4),
                  Text(
                    'India DPDPA Compliant',
                    style: EduverseTypography.labelSm(color: EduverseColors.secondaryFixed),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection1({required GlobalKey key}) {
    return Container(
      key: key,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            sectionNumber: '01',
            title: 'Commitment to Privacy',
            icon: Icons.menu_book_rounded,
          ),
          const SizedBox(height: 12),
          Text(
            'The Eduverse values your academic trust. We architect our learning environments with privacy-by-design standards, prioritizing student anonymity wherever public forums operate and preserving the integrity of academic metrics without invasive commercial telemetry.',
            style: EduverseTypography.bodyMd().copyWith(height: 1.55),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: EduverseColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.verified_rounded,
                  color: EduverseColors.emeraldVivid,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'We never monetize or trade aspirant test performance, biometric study telemetry, or notes to third-party ad networks.',
                    style: EduverseTypography.bodyMd(color: EduverseColors.onSurfaceVariant).copyWith(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection2({required GlobalKey key}) {
    return Container(
      key: key,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            sectionNumber: '02',
            title: 'Information We Collect',
            icon: Icons.fact_check_rounded,
          ),
          const SizedBox(height: 12),
          Text(
            'We collect only data pertinent to pedagogical improvement, certification verifiability, and syllabus pacing.',
            style: EduverseTypography.bodyMd().copyWith(height: 1.55),
          ),
          const SizedBox(height: 14),
          _buildCollectionItem(
            icon: Icons.badge_outlined,
            title: 'Identity & Profile Data',
            desc: 'Name, educational level, phone, verified email, and profile avatar.',
          ),
          const SizedBox(height: 10),
          _buildCollectionItem(
            icon: Icons.insights_rounded,
            title: 'Academic Telemetry',
            desc: 'Quiz scores, mock percentile trends, video playback retention, notes authored.',
          ),
          const SizedBox(height: 10),
          _buildCollectionItem(
            icon: Icons.devices_rounded,
            title: 'Hardware & DRM Diagnostics',
            desc: 'OS version, device UUID, IP address, and screen resolution for DRM compliance.',
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionItem({required IconData icon, required String title, required String desc}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: EduverseColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: EduverseColors.secondary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: EduverseTypography.labelLg()),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: EduverseTypography.bodyMd(color: EduverseColors.onSurfaceVariant).copyWith(
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageBanner() {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/auth/privacy_banner.png',
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [EduverseColors.deepNavy, EduverseColors.primary],
                  ),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    EduverseColors.deepNavy.withValues(alpha: 0.92),
                    EduverseColors.primary.withValues(alpha: 0.80),
                    Colors.transparent,
                  ],
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ACADEMIC EXCELLENCE',
                    style: EduverseTypography.labelSm(color: EduverseColors.tertiaryFixed).copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Knowledge Protected',
                    style: EduverseTypography.headlineMd(color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection3({required GlobalKey key}) {
    return Container(
      key: key,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            sectionNumber: '03',
            title: 'How We Use Your Data',
            icon: Icons.psychology_rounded,
          ),
          const SizedBox(height: 12),
          Text(
            'All telemetry processes feed our adaptive learning algorithms to tailor your study sessions:',
            style: EduverseTypography.bodyMd(),
          ),
          const SizedBox(height: 14),
          _buildBulletItem(
            icon: Icons.auto_graph_rounded,
            boldText: 'Custom Study Pacing: ',
            normalText: 'Recalibrating module target dates when mock exam scores fall below targets.',
          ),
          const SizedBox(height: 10),
          _buildBulletItem(
            icon: Icons.smart_display_rounded,
            boldText: 'Predictive Lecture Prompts: ',
            normalText: 'Suggesting prerequisite remedial videos before live doubt-clearing sessions.',
          ),
          const SizedBox(height: 10),
          _buildBulletItem(
            icon: Icons.school_rounded,
            boldText: 'Scholarship Qualification: ',
            normalText: 'Evaluating merit indicators for fee reduction and grant endowments.',
          ),
        ],
      ),
    );
  }

  Widget _buildSection4({required GlobalKey key}) {
    return Container(
      key: key,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            sectionNumber: '04',
            title: 'Third-Party Disclosures',
            icon: Icons.hub_outlined,
          ),
          const SizedBox(height: 12),
          Text(
            'We strictly restrict integrations to certified enterprise infrastructure providers under strict Data Protection Agreements:',
            style: EduverseTypography.bodyMd(),
          ),
          const SizedBox(height: 12),
          _buildBulletItem(
            icon: Icons.cloud_done_outlined,
            boldText: 'Firebase & Google Cloud: ',
            normalText: 'Encrypted databases, serverless functions, and secure hosting with ISO 27001 certification.',
          ),
          const SizedBox(height: 10),
          _buildBulletItem(
            icon: Icons.payment_rounded,
            boldText: 'Payment Gateways (Razorpay): ',
            normalText: 'PCI-DSS Level 1 certified handling of course fees. We never store debit/credit card CVV or pins.',
          ),
        ],
      ),
    );
  }

  Widget _buildSection5({required GlobalKey key}) {
    return Container(
      key: key,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            sectionNumber: '05',
            title: 'Security & DRM Protections',
            icon: Icons.enhanced_encryption_rounded,
          ),
          const SizedBox(height: 12),
          Text(
            'To prevent academic piracy and protect intellectual property:',
            style: EduverseTypography.bodyMd(),
          ),
          const SizedBox(height: 12),
          _buildBulletItem(
            icon: Icons.screen_lock_portrait_rounded,
            boldText: 'Screen Leak Protection: ',
            normalText: 'Dynamic watermark and screen recording detection on mobile devices to prevent leaks.',
          ),
          const SizedBox(height: 10),
          _buildBulletItem(
            icon: Icons.lock_outline_rounded,
            boldText: '256-Bit SSL/TLS Encryption: ',
            normalText: 'All communications between your client device and our server cluster are encrypted in transit and at rest.',
          ),
        ],
      ),
    );
  }

  Widget _buildSection6({required GlobalKey key}) {
    return Container(
      key: key,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            sectionNumber: '06',
            title: 'Student Rights Under DPDPA',
            icon: Icons.policy_rounded,
          ),
          const SizedBox(height: 12),
          Text(
            'In full accordance with the Digital Personal Data Protection Act (DPDPA), you retain the following rights:',
            style: EduverseTypography.bodyMd(),
          ),
          const SizedBox(height: 12),
          _buildBulletItem(
            icon: Icons.visibility_outlined,
            boldText: 'Right to Access: ',
            normalText: 'Request a comprehensive machine-readable dossier of all personal records.',
          ),
          const SizedBox(height: 10),
          _buildBulletItem(
            icon: Icons.edit_note_rounded,
            boldText: 'Right to Correction: ',
            normalText: 'Update inaccurate names, phone contacts, or academic category profiles at any time.',
          ),
          const SizedBox(height: 10),
          _buildBulletItem(
            icon: Icons.delete_forever_outlined,
            boldText: 'Right to Erasure: ',
            normalText: 'Request permanent deletion of your account and related telemetry via the Account Settings panel.',
          ),
        ],
      ),
    );
  }

  Widget _buildSection7({required GlobalKey key}) {
    return Container(
      key: key,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            sectionNumber: '07',
            title: 'Grievance Redressal',
            icon: Icons.gavel_rounded,
          ),
          const SizedBox(height: 12),
          Text(
            'For any questions, compliance verification, or grievance redressal regarding personal data protection, contact our designated Data Protection Officer:',
            style: EduverseTypography.bodyMd(),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: EduverseColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.person_outline_rounded, size: 18, color: EduverseColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text('Data Protection Officer: ', style: EduverseTypography.labelLg()),
                          Text('Adv. Rajesh Kumar', style: EduverseTypography.bodyMd(color: EduverseColors.onSurface)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.email_outlined, size: 18, color: EduverseColors.secondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text('Email: ', style: EduverseTypography.labelLg()),
                          Text('privacy@eduverse.org', style: EduverseTypography.bodyMd(color: EduverseColors.primary)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.timer_outlined, size: 18, color: EduverseColors.tertiary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text('Turnaround: ', style: EduverseTypography.labelLg()),
                          Text('Within 48 academic working hours', style: EduverseTypography.bodyMd(color: EduverseColors.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String sectionNumber,
    required String title,
    required IconData icon,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: EduverseColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: EduverseColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SECTION $sectionNumber',
              style: EduverseTypography.labelSm(color: EduverseColors.secondary).copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
            ),
            Text(
              title,
              style: EduverseTypography.headlineMd().copyWith(fontSize: 18),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBulletItem({
    required IconData icon,
    required String boldText,
    required String normalText,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: EduverseColors.emeraldVivid),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: EduverseTypography.bodyMd().copyWith(fontSize: 13.5),
              children: [
                TextSpan(
                  text: boldText,
                  style: EduverseTypography.labelLg().copyWith(fontSize: 13.5),
                ),
                TextSpan(text: normalText),
              ],
            ),
          ),
        ),
      ],
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: EduverseColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: EduverseColors.outlineVariant.withValues(alpha: 0.3)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }
}
