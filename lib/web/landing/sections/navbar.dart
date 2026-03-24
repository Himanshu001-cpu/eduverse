import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../auth/login_page.dart';
import '../../../auth/register_page.dart';

class NavBar extends StatelessWidget {
  final VoidCallback? onFeatures;
  final VoidCallback? onExams;
  final VoidCallback? onTestimonials;
  final VoidCallback? onPricing;

  const NavBar({
    super.key,
    this.onFeatures,
    this.onExams,
    this.onTestimonials,
    this.onPricing,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        color: const Color(0xFFf8fafc).withValues(alpha: 0.95),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1280),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Logo
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        'assets/icon.png',
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Eduverse',
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0f172a),
                      ),
                    ),
                  ],
                ),

                // Desktop Menu
                if (MediaQuery.of(context).size.width > 768)
                  Row(
                    children: [
                      _NavLink(title: 'Features', onTap: onFeatures),
                      const SizedBox(width: 32),
                      _NavLink(title: 'Exams', onTap: onExams),
                      const SizedBox(width: 32),
                      _NavLink(title: 'Testimonials', onTap: onTestimonials),
                      const SizedBox(width: 32),
                      _NavLink(title: 'Pricing', onTap: onPricing),
                    ],
                  ),

                // CTA Buttons
                Row(
                  children: [
                    if (MediaQuery.of(context).size.width > 768) ...[
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const LoginPage(),
                            ),
                          );
                        },
                        child: Text(
                          'Log in',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF64748b),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF059669), Color(0xFF047857)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF10b981,
                            ).withValues(alpha: 0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const RegisterPage(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Get Started',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
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
    );
  }
}

class _NavLink extends StatefulWidget {
  final String title;
  final VoidCallback? onTap;

  const _NavLink({required this.title, this.onTap});

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w500,
            color: _isHovered
                ? const Color(0xFF059669)
                : const Color(0xFF64748b),
            fontSize: 15,
          ),
          child: Text(widget.title),
        ),
      ),
    );
  }
}
