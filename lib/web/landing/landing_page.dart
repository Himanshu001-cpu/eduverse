import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'sections/navbar.dart';
import 'sections/hero_section.dart';
import 'sections/stats_section.dart';
import 'sections/featured_programs_section.dart';
import 'sections/bento_advantage_section.dart';
import 'sections/testimonials_section.dart';
import 'sections/cta_section.dart';
import 'sections/footer_section.dart';
import 'theme/academic_futurist_theme.dart';
import '../../auth/login_page.dart';

/// Official Eduverse Homescreen & Web Portal
/// Designed with the Academic Futurist design system based on Stitch designs.
class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final _programsKey = GlobalKey();
  final _advantageKey = GlobalKey();
  final _testimonialsKey = GlobalKey();

  void _scrollTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _navigateToLogin() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  Future<void> _openDemoVideo() async {
    const videoUrl = 'https://youtube.com/@theeduverse-01?si=ZmDDrkWQJPoXd8ua';
    final uri = Uri.parse(videoUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EduverseTheme.surface,
      body: Stack(
        children: [
          // Scrollable Sections
          SingleChildScrollView(
            child: Column(
              children: [
                // Hero Section
                HeroSection(
                  onExploreCourses: () => _scrollTo(_programsKey),
                  onWatchVideo: _openDemoVideo,
                ),

                // Statistics Strip (overlaps Hero with -mt-12 transform)
                const StatsSection(),

                // Featured Programs
                FeaturedProgramsSection(
                  key: _programsKey,
                  onViewAll: () => _scrollTo(_programsKey),
                  onProgramSelected: (_) => _navigateToLogin(),
                ),

                // The Eduverse Advantage (Bento Grid)
                BentoAdvantageSection(key: _advantageKey),

                // Student Testimonials
                TestimonialsSection(key: _testimonialsKey),

                // Final Call to Action
                CtaSection(onJoin: _navigateToLogin),

                // Footer
                FooterSection(
                  onStudy: () => _scrollTo(_programsKey),
                  onFeed: _navigateToLogin,
                  onStore: () => _scrollTo(_programsKey),
                  onProfile: _navigateToLogin,
                ),
              ],
            ),
          ),

          // Glassmorphic Fixed Top Navigation Bar
          NavBar(
            onStudy: () => _scrollTo(_programsKey),
            onFeed: _navigateToLogin,
            onStore: () => _scrollTo(_programsKey),
            onProfile: _navigateToLogin,
          ),
        ],
      ),
    );
  }
}
