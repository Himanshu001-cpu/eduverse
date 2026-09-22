import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../auth/login_page.dart';
import '../theme/academic_futurist_theme.dart';

class NavBar extends StatelessWidget {
  final VoidCallback? onStudy;
  final VoidCallback? onFeed;
  final VoidCallback? onStore;
  final VoidCallback? onProfile;

  const NavBar({
    super.key,
    this.onStudy,
    this.onFeed,
    this.onStore,
    this.onProfile,
  });

  void _navigateToLogin(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isTablet = screenWidth >= 640 && screenWidth < 1024;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              color: EduverseTheme.surfaceBright.withValues(alpha: 0.85),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  offset: const Offset(0, 1),
                  blurRadius: 8,
                ),
              ],
              border: Border(
                bottom: BorderSide(
                  color: EduverseTheme.outlineVariant.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
            ),
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: EduverseTheme.containerMax),
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? EduverseTheme.marginDesktop : EduverseTheme.marginMobile,
                ),
                child: Row(
                  children: [
                    // Brand Logo & Title
                    InkWell(
                      onTap: () {},
                      borderRadius: BorderRadius.circular(12),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.asset(
                              'assets/icon.png',
                              height: 40,
                              width: 40,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'The Eduverse',
                            style: EduverseTheme.headlineMd(color: EduverseTheme.primary).copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Search input (Desktop)
                    if (isDesktop) ...[
                      const SizedBox(width: 24),
                      Expanded(
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 340),
                          height: 42,
                          decoration: BoxDecoration(
                            color: EduverseTheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: EduverseTheme.outlineVariant.withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Row(
                            children: [
                              Icon(
                                Icons.search,
                                size: 20,
                                color: EduverseTheme.onSurfaceVariant.withValues(alpha: 0.8),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  style: EduverseTheme.bodyMd(color: EduverseTheme.onSurface),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    border: InputBorder.none,
                                    hintText: 'Search courses, certifications...',
                                    hintStyle: EduverseTheme.labelSm(
                                      color: EduverseTheme.onSurfaceVariant.withValues(alpha: 0.7),
                                    ),
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else
                      const Spacer(),

                    // Nav links (Desktop)
                    if (isDesktop) ...[
                      const SizedBox(width: 32),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _NavItem(title: 'Study', onTap: onStudy),
                          const SizedBox(width: 28),
                          _NavItem(title: 'Feed', onTap: onFeed),
                          const SizedBox(width: 28),
                          _NavItem(title: 'Store', onTap: onStore),
                          const SizedBox(width: 28),
                          _NavItem(title: 'Profile', onTap: onProfile),
                        ],
                      ),
                      const SizedBox(width: 32),
                    ],

                    // Right Actions (Login & Profile Avatar)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isDesktop || isTablet) ...[
                          TextButton(
                            onPressed: () => _navigateToLogin(context),
                            style: TextButton.styleFrom(
                              foregroundColor: EduverseTheme.primary,
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                            ),
                            child: Text(
                              'Login',
                              style: EduverseTheme.labelLg(color: EduverseTheme.primary).copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        InkWell(
                          onTap: () => _navigateToLogin(context),
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: EduverseTheme.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: EduverseTheme.primary.withValues(alpha: 0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.person_outline,
                              color: EduverseTheme.onPrimary,
                              size: 20,
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
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final String title;
  final VoidCallback? onTap;

  const _NavItem({required this.title, this.onTap});

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 180),
          style: EduverseTheme.labelLg(
            color: _isHovered ? EduverseTheme.primary : EduverseTheme.onSurfaceVariant,
          ).copyWith(
            fontWeight: _isHovered ? FontWeight.w700 : FontWeight.w600,
          ),
          child: Text(widget.title),
        ),
      ),
    );
  }
}
