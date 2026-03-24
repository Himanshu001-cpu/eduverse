import 'package:flutter/material.dart';
import 'sections/navbar.dart';
import 'sections/hero_section.dart';
import 'sections/stats_section.dart';
import 'sections/features_section.dart';
import 'sections/exam_categories_section.dart';
import 'sections/content_section.dart';
import 'sections/trending_courses_section.dart';
import 'sections/testimonials_section.dart';
import 'sections/faq_section.dart';
import 'sections/team_section.dart';
import 'sections/cta_section.dart';
import 'sections/footer_section.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  // Section keys for scroll-to navigation
  final _featuresKey = GlobalKey();
  final _examsKey = GlobalKey();
  final _contentKey = GlobalKey();
  final _testimonialsKey = GlobalKey();
  final _pricingKey = GlobalKey();

  void _scrollToSection(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf8fafc),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 80), // Spacer for fixed navbar
                HeroSection(
                  onStartLearning: () => _scrollToSection(_featuresKey),
                  onWatchDemo: () => _scrollToSection(_contentKey),
                ),
                const StatsSection(),
                FeaturesSection(key: _featuresKey),
                ExamCategoriesSection(key: _examsKey),
                ContentSection(key: _contentKey),
                const TrendingCoursesSection(),
                TestimonialsSection(key: _testimonialsKey),
                const FaqSection(),
                const TeamSection(),
                CtaSection(key: _pricingKey),
                const FooterSection(),
              ],
            ),
          ),
          NavBar(
            onFeatures: () => _scrollToSection(_featuresKey),
            onExams: () => _scrollToSection(_examsKey),
            onTestimonials: () => _scrollToSection(_testimonialsKey),
            onPricing: () => _scrollToSection(_pricingKey),
          ),
        ],
      ),
    );
  }
}
