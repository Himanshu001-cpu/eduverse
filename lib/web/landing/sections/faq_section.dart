import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../widgets/gradient_text.dart';

class FaqSection extends StatefulWidget {
  const FaqSection({super.key});

  @override
  State<FaqSection> createState() => _FaqSectionState();
}

class _FaqSectionState extends State<FaqSection> {
  int? _expandedIndex;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 112, horizontal: 24),
      color: Colors.white,
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              // Header
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFfef3c7),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: const Color(0xFFfde68a)),
                    ),
                    child: Text(
                      '❓ FAQ',
                      style: GoogleFonts.inter(
                        color: const Color(0xFFd97706),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: GoogleFonts.outfit(
                        fontSize: size.width > 768 ? 48 : 36,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0f172a),
                        height: 1.1,
                      ),
                      children: [
                        const TextSpan(text: 'Frequently Asked '),
                        WidgetSpan(
                          child: GradientText(
                            'Questions',
                            gradient: const LinearGradient(
                              colors: [Color(0xFF059669), Color(0xFF10b981)],
                            ),
                            style: GoogleFonts.outfit(
                              fontSize: size.width > 768 ? 48 : 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 560,
                    child: Text(
                      'Everything you need to know about Eduverse. Can\'t find the answer? Chat with our support team.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        color: const Color(0xFF64748b),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn().slideY(begin: 0.2, end: 0),

              const SizedBox(height: 48),

              // FAQ Items
              ...List.generate(_faqItems.length, (index) {
                final isExpanded = _expandedIndex == index;
                return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _expandedIndex = isExpanded ? null : index;
                            });
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: isExpanded
                                  ? const Color(0xFFecfdf5)
                                  : const Color(0xFFf8fafc),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isExpanded
                                    ? const Color(0xFF6ee7b7)
                                    : const Color(0xFFe2e8f0),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _faqItems[index].question,
                                        style: GoogleFonts.outfit(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF0f172a),
                                        ),
                                      ),
                                    ),
                                    AnimatedRotation(
                                      turns: isExpanded ? 0.5 : 0,
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      child: Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: isExpanded
                                              ? const Color(0xFF10b981)
                                              : const Color(0xFFe2e8f0),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Icon(
                                          LucideIcons.chevronDown,
                                          size: 18,
                                          color: isExpanded
                                              ? Colors.white
                                              : const Color(0xFF64748b),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                AnimatedCrossFade(
                                  firstChild: const SizedBox.shrink(),
                                  secondChild: Padding(
                                    padding: const EdgeInsets.only(top: 16),
                                    child: Text(
                                      _faqItems[index].answer,
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        color: const Color(0xFF64748b),
                                        height: 1.6,
                                      ),
                                    ),
                                  ),
                                  crossFadeState: isExpanded
                                      ? CrossFadeState.showSecond
                                      : CrossFadeState.showFirst,
                                  duration: const Duration(milliseconds: 300),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                    .animate()
                    .fadeIn(delay: (100 * index).ms)
                    .slideY(begin: 0.1, end: 0);
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _FaqItem {
  final String question;
  final String answer;

  _FaqItem({required this.question, required this.answer});
}

final _faqItems = [
  _FaqItem(
    question: 'What exams does Eduverse cover?',
    answer:
        'Eduverse covers a wide range of competitive exams including UPSC, SSC, Banking (SBI PO, IBPS, RBI), Railways, NDA, State PSCs, and more. We are constantly expanding our exam coverage based on student demand.',
  ),
  _FaqItem(
    question: 'Is there a free trial available?',
    answer:
        'Yes! We offer a 7-day free trial with full access to all features including AI-powered study plans, mock tests, video lectures, and performance analytics. No credit card required.',
  ),
  _FaqItem(
    question: 'How does the AI-personalized study plan work?',
    answer:
        'Our AI analyzes your strengths, weaknesses, and learning pace based on your test performance and study patterns. It then creates a dynamic study plan that adapts in real-time, ensuring you focus on areas that need the most improvement.',
  ),
  _FaqItem(
    question: 'Can I access Eduverse on my mobile device?',
    answer:
        'Absolutely! Eduverse is available on Android, iOS, and web. Your progress syncs across all devices, so you can switch between your phone, tablet, and laptop seamlessly.',
  ),
  _FaqItem(
    question: 'How are the mock tests different from other platforms?',
    answer:
        'Our mock tests are designed by toppers and subject experts who have cleared these exams. Each test comes with detailed analytics showing time spent per question, accuracy by topic, and comparison with other students. The AI also identifies your weak areas and suggests targeted practice.',
  ),
  _FaqItem(
    question: 'What is the refund policy?',
    answer:
        'We offer a 30-day money-back guarantee. If you are not satisfied with the platform for any reason, you can request a full refund within 30 days of purchase — no questions asked.',
  ),
];
