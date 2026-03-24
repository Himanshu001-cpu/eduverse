import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class FooterSection extends StatelessWidget {
  const FooterSection({super.key});

  static const _footerLinks = {
    'Platform': [
      'Courses',
      'Mock Tests',
      'Live Classes',
      'Mentorship',
      'Pricing',
      'Free Resources',
    ],
    'Resources': [
      'Blog',
      'Current Affairs',
      'Previous Papers',
      'Toppers Talk',
      'Study Plans',
      'Syllabus',
    ],
    'Company': [
      'About Us',
      'Careers',
      'Press Kit',
      'Partners',
      'Contact',
      'Investor Relations',
    ],
    'Legal': [
      'Privacy Policy',
      'Terms of Service',
      'Refund Policy',
      'Cookie Policy',
    ],
  };

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Stack(
      children: [
        // Background
        Positioned.fill(child: Container(color: const Color(0xFF020617))),
        // Background decorations
        Positioned(
          bottom: 0,
          left: size.width * 0.2,
          child: Container(
            width: 256,
            height: 256,
            decoration: BoxDecoration(
              color: const Color(0xFF059669).withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          right: size.width * 0.2,
          child: Container(
            width: 256,
            height: 256,
            decoration: BoxDecoration(
              color: const Color(0xFF0d9488).withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Column(
          children: [
            // Top gradient line
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    const Color(0xFF10b981).withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),

            // Newsletter bar
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFF0f172a), width: 1),
                ),
              ),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1280),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 48,
                  ),
                  child: Flex(
                    direction: size.width > 992
                        ? Axis.horizontal
                        : Axis.vertical,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: size.width > 992
                        ? CrossAxisAlignment.center
                        : CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Stay ahead of the competition',
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Get weekly study tips, exam notifications & current affairs in your inbox.',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              color: const Color(0xFF64748b),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: size.width > 992 ? 0 : 24,
                        width: size.width > 992 ? 24 : 0,
                      ),
                      // Email form
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: size.width > 992 ? 288 : 220,
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Enter your email',
                                hintStyle: GoogleFonts.inter(
                                  color: const Color(0xFF64748b),
                                ),
                                filled: true,
                                fillColor: const Color(0xFF0f172a),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF1e293b),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF1e293b),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF10b981),
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 14,
                                ),
                              ),
                              style: GoogleFonts.inter(color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF059669), Color(0xFF047857)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Subscribe',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    LucideIcons.send,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Main footer
            Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1280),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 64,
                ),
                child: Column(
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 768;
                        return Flex(
                          direction: isWide ? Axis.horizontal : Axis.vertical,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Brand column
                            SizedBox(
                              width: isWide
                                  ? constraints.maxWidth * 0.3
                                  : constraints.maxWidth,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Logo
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFF059669),
                                              Color(0xFF0d9488),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            'E',
                                            style: GoogleFonts.outfit(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      RichText(
                                        text: TextSpan(
                                          style: GoogleFonts.outfit(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                          children: [
                                            const TextSpan(text: 'Edu'),
                                            TextSpan(
                                              text: 'verse',
                                              style: GoogleFonts.outfit(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                foreground: Paint()
                                                  ..shader =
                                                      const LinearGradient(
                                                        colors: [
                                                          Color(0xFF34d399),
                                                          Color(0xFF2dd4bf),
                                                        ],
                                                      ).createShader(
                                                        const Rect.fromLTWH(
                                                          0,
                                                          0,
                                                          100,
                                                          20,
                                                        ),
                                                      ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    width: 280,
                                    child: Text(
                                      'India\'s #1 AI-powered exam preparation platform. Master UPSC, SSC, Banking & more with personalized learning.',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: const Color(0xFF94a3b8),
                                        height: 1.6,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                  // Social icons
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _SocialIcon(
                                        icon: Icons.facebook,
                                        hoverColor: const Color(0xFF2563eb),
                                      ),
                                      const SizedBox(width: 12),
                                      _SocialIcon(
                                        icon: LucideIcons.twitter,
                                        hoverColor: const Color(0xFF0ea5e9),
                                      ),
                                      const SizedBox(width: 12),
                                      _SocialIcon(
                                        icon: LucideIcons.instagram,
                                        hoverColor: const Color(0xFFdb2777),
                                      ),
                                      const SizedBox(width: 12),
                                      _SocialIcon(
                                        icon: LucideIcons.linkedin,
                                        hoverColor: const Color(0xFF1d4ed8),
                                      ),
                                      const SizedBox(width: 12),
                                      _SocialIcon(
                                        icon: LucideIcons.youtube,
                                        hoverColor: const Color(0xFFdc2626),
                                      ),
                                    ],
                                  ),
                                  if (!isWide) const SizedBox(height: 48),
                                ],
                              ),
                            ),

                            // Link columns
                            Expanded(
                              child: Wrap(
                                spacing: isWide ? 0 : 48,
                                runSpacing: 32,
                                children: _footerLinks.entries.map((entry) {
                                  return SizedBox(
                                    width: isWide
                                        ? (constraints.maxWidth *
                                              0.7 /
                                              _footerLinks.length)
                                        : 150,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          entry.key.toUpperCase(),
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            letterSpacing: 1.5,
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        ...entry.value.map(
                                          (link) => Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 12,
                                            ),
                                            child: _FooterLink(text: link),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 64),

                    // Bottom bar
                    Container(
                      padding: const EdgeInsets.only(top: 32),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Color(0xFF0f172a)),
                        ),
                      ),
                      child: Flex(
                        direction: size.width > 600
                            ? Axis.horizontal
                            : Axis.vertical,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '© 2026 Eduverse Technologies Pvt Ltd. All rights reserved.',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: const Color(0xFF64748b),
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Made with ',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: const Color(0xFF64748b),
                                ),
                              ),
                              const Text(
                                '❤',
                                style: TextStyle(
                                  color: Color(0xFFf87171),
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                ' in India 🇮🇳',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: const Color(0xFF64748b),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SocialIcon extends StatefulWidget {
  final IconData icon;
  final Color hoverColor;

  const _SocialIcon({required this.icon, required this.hoverColor});

  @override
  State<_SocialIcon> createState() => _SocialIconState();
}

class _SocialIconState extends State<_SocialIcon> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _isHovered ? widget.hoverColor : const Color(0xFF0f172a),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isHovered ? Colors.transparent : const Color(0xFF1e293b),
          ),
        ),
        child: Center(
          child: Icon(
            widget.icon,
            size: 16,
            color: _isHovered ? Colors.white : const Color(0xFF94a3b8),
          ),
        ),
      ),
    );
  }
}

class _FooterLink extends StatefulWidget {
  final String text;

  const _FooterLink({required this.text});

  @override
  State<_FooterLink> createState() => _FooterLinkState();
}

class _FooterLinkState extends State<_FooterLink> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.text,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: _isHovered
                  ? const Color(0xFF34d399)
                  : const Color(0xFF94a3b8),
            ),
          ),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: _isHovered ? 1.0 : 0.0,
            child: const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Icon(
                Icons.arrow_outward,
                size: 12,
                color: Color(0xFF34d399),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
