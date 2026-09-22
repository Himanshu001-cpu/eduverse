import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/academic_futurist_theme.dart';

class FooterSection extends StatelessWidget {
  final VoidCallback? onStudy;
  final VoidCallback? onFeed;
  final VoidCallback? onStore;
  final VoidCallback? onProfile;

  const FooterSection({
    super.key,
    this.onStudy,
    this.onFeed,
    this.onStore,
    this.onProfile,
  });

  static const String _phone = '8959884118';
  static const String _email = 'hello@theeduverse.co.in';
  static const String _address = 'Gwalior & New Delhi, India';

  static const String _youtubeUrl = 'https://youtube.com/@theeduverse-01?si=ZmDDrkWQJPoXd8ua';
  static const String _telegramUrl = 'https://t.me/+VItJaG3hKRNiZWM9';
  static const String _instagramUrl = 'https://www.instagram.com/theeduverse01?igsh=enpzam9xeG45ZTVr';

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isTablet = screenWidth >= 640 && screenWidth < 1024;

    return Container(
      width: double.infinity,
      color: EduverseTheme.deepNavy,
      padding: EdgeInsets.symmetric(
        vertical: EduverseTheme.sectionGap,
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: EduverseTheme.containerMax),
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? EduverseTheme.marginDesktop : EduverseTheme.marginMobile,
          ),
          child: Column(
            children: [
              // Main Columns
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _buildBrandBlock()),
                    const SizedBox(width: 32),
                    Expanded(flex: 2, child: _buildModulesBlock()),
                    const SizedBox(width: 32),
                    Expanded(flex: 3, child: _buildContactBlock()),
                    const SizedBox(width: 32),
                    Expanded(flex: 2, child: _buildSocialBlock()),
                  ],
                )
              else if (isTablet)
                Wrap(
                  spacing: 32,
                  runSpacing: 40,
                  children: [
                    SizedBox(width: (screenWidth - 32 - 32) / 2, child: _buildBrandBlock()),
                    SizedBox(width: (screenWidth - 32 - 32) / 2, child: _buildModulesBlock()),
                    SizedBox(width: (screenWidth - 32 - 32) / 2, child: _buildContactBlock()),
                    SizedBox(width: (screenWidth - 32 - 32) / 2, child: _buildSocialBlock()),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBrandBlock(),
                    const SizedBox(height: 36),
                    _buildModulesBlock(),
                    const SizedBox(height: 36),
                    _buildContactBlock(),
                    const SizedBox(height: 36),
                    _buildSocialBlock(),
                  ],
                ),

              const SizedBox(height: 56),

              // Bottom Bar
              Container(
                padding: const EdgeInsets.only(top: 24),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: Center(
                  child: Text(
                    '© 2024-2026 The Eduverse. Built for the future of learning.',
                    style: EduverseTheme.labelSm(
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBrandBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/icon.png',
                height: 36,
                width: 36,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'The Eduverse',
              style: EduverseTheme.headlineMd(color: Colors.white).copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Text(
            'Pioneering the future of education through technology and competitive exam excellence.',
            style: EduverseTheme.bodyMd(color: Colors.white.withValues(alpha: 0.7)),
          ),
        ),
      ],
    );
  }

  Widget _buildModulesBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'App Modules',
          style: EduverseTheme.labelLg(color: EduverseTheme.tertiaryFixed).copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        _FooterLink(title: 'Study', onTap: onStudy),
        const SizedBox(height: 10),
        _FooterLink(title: 'Feed', onTap: onFeed),
        const SizedBox(height: 10),
        _FooterLink(title: 'Store', onTap: onStore),
        const SizedBox(height: 10),
        _FooterLink(title: 'Profile', onTap: onProfile),
      ],
    );
  }

  Widget _buildContactBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Get in Touch',
          style: EduverseTheme.labelLg(color: EduverseTheme.tertiaryFixed).copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        _ContactRow(
          icon: Icons.mail_outline,
          text: _email,
          onTap: () => _openUrl('mailto:$_email'),
        ),
        const SizedBox(height: 12),
        _ContactRow(
          icon: Icons.call,
          text: '+91 $_phone',
          onTap: () => _openUrl('tel:$_phone'),
        ),
        const SizedBox(height: 12),
        _ContactRow(
          icon: Icons.location_on,
          text: _address,
        ),
      ],
    );
  }

  Widget _buildSocialBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Follow Us',
          style: EduverseTheme.labelLg(color: EduverseTheme.tertiaryFixed).copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _SocialIcon(
              icon: Icons.play_circle_outline,
              tooltip: 'YouTube',
              onTap: () => _openUrl(_youtubeUrl),
            ),
            const SizedBox(width: 12),
            _SocialIcon(
              icon: Icons.hub,
              tooltip: 'Telegram',
              onTap: () => _openUrl(_telegramUrl),
            ),
            const SizedBox(width: 12),
            _SocialIcon(
              icon: Icons.public,
              tooltip: 'Instagram',
              onTap: () => _openUrl(_instagramUrl),
            ),
          ],
        ),
      ],
    );
  }
}

class _FooterLink extends StatefulWidget {
  final String title;
  final VoidCallback? onTap;

  const _FooterLink({required this.title, this.onTap});

  @override
  State<_FooterLink> createState() => _FooterLinkState();
}

class _FooterLinkState extends State<_FooterLink> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Text(
          widget.title,
          style: EduverseTheme.labelSm(
            color: _isHovered
                ? EduverseTheme.tertiaryFixed
                : Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback? onTap;

  const _ContactRow({required this.icon, required this.text, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.white.withValues(alpha: 0.8)),
          const SizedBox(width: 10),
          Text(
            text,
            style: EduverseTheme.labelSm(color: Colors.white.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }
}

class _SocialIcon extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _SocialIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  State<_SocialIcon> createState() => _SocialIconState();
}

class _SocialIconState extends State<_SocialIcon> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isHovered
                  ? EduverseTheme.tertiaryFixed
                  : Colors.transparent,
              border: Border.all(
                color: _isHovered
                    ? EduverseTheme.tertiaryFixed
                    : Colors.white.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Icon(
              widget.icon,
              size: 20,
              color: _isHovered
                  ? EduverseTheme.onTertiaryFixed
                  : Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ),
      ),
    );
  }
}
