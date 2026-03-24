import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../widgets/gradient_text.dart';

class TeamSection extends StatelessWidget {
  const TeamSection({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final crossAxisCount = size.width > 1024
        ? 4
        : size.width > 768
        ? 3
        : size.width > 480
        ? 2
        : 1;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 112, horizontal: 24),
      color: const Color(0xFFf8fafc),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1280),
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
                      color: const Color(0xFFede9fe),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: const Color(0xFFddd6fe)),
                    ),
                    child: Text(
                      '👥 Our Team',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF7c3aed),
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
                        const TextSpan(text: 'Meet the '),
                        WidgetSpan(
                          child: GradientText(
                            'Experts',
                            gradient: const LinearGradient(
                              colors: [Color(0xFF059669), Color(0xFF10b981)],
                            ),
                            style: GoogleFonts.outfit(
                              fontSize: size.width > 768 ? 48 : 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const TextSpan(text: ' behind Eduverse'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 560,
                    child: Text(
                      'A team of educators, engineers, and exam toppers dedicated to revolutionizing competitive exam preparation.',
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

              const SizedBox(height: 64),

              // Team grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 24,
                  mainAxisSpacing: 24,
                  childAspectRatio: 0.85,
                ),
                itemCount: _teamMembers.length,
                itemBuilder: (context, index) {
                  final member = _teamMembers[index];
                  return _TeamCard(member: member, index: index);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeamCard extends StatefulWidget {
  final _TeamMember member;
  final int index;

  const _TeamCard({required this.member, required this.index});

  @override
  State<_TeamCard> createState() => _TeamCardState();
}

class _TeamCardState extends State<_TeamCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            transform: Matrix4.translationValues(0, _isHovered ? -8 : 0, 0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _isHovered
                    ? const Color(0xFF6ee7b7)
                    : const Color(0xFFf1f5f9),
              ),
              boxShadow: [
                BoxShadow(
                  color: _isHovered
                      ? const Color(0xFF10b981).withValues(alpha: 0.15)
                      : Colors.black.withValues(alpha: 0.04),
                  blurRadius: _isHovered ? 30 : 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: const Color(0xFFe2e8f0),
                    backgroundImage: NetworkImage(widget.member.avatar),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.member.name,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0f172a),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.member.role,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF10b981),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.member.description,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF94a3b8),
                      height: 1.4,
                    ),
                  ),
                  const Spacer(),
                  // Social Icons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _socialIcon(LucideIcons.twitter),
                      const SizedBox(width: 12),
                      _socialIcon(LucideIcons.linkedin),
                    ],
                  ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(delay: (100 * widget.index).ms)
        .slideY(begin: 0.15, end: 0);
  }

  Widget _socialIcon(IconData icon) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFFf1f5f9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 16, color: const Color(0xFF64748b)),
    );
  }
}

class _TeamMember {
  final String name;
  final String role;
  final String avatar;
  final String description;

  _TeamMember({
    required this.name,
    required this.role,
    required this.avatar,
    required this.description,
  });
}

final _teamMembers = [
  _TeamMember(
    name: 'Dr. Raghav Mehta',
    role: 'Founder & CEO',
    avatar:
        'https://ui-avatars.com/api/?name=Raghav+Mehta&background=059669&color=fff&size=200',
    description: 'Ex-IAS officer with 15+ years in education technology.',
  ),
  _TeamMember(
    name: 'Kavita Nair',
    role: 'Head of Content',
    avatar:
        'https://ui-avatars.com/api/?name=Kavita+Nair&background=3b82f6&color=fff&size=200',
    description: 'Designed curriculum for 100K+ successful aspirants.',
  ),
  _TeamMember(
    name: 'Arjun Desai',
    role: 'CTO',
    avatar:
        'https://ui-avatars.com/api/?name=Arjun+Desai&background=8b5cf6&color=fff&size=200',
    description: 'Ex-Google engineer building AI-powered learning systems.',
  ),
  _TeamMember(
    name: 'Simran Kaur',
    role: 'Head of AI',
    avatar:
        'https://ui-avatars.com/api/?name=Simran+Kaur&background=f59e0b&color=fff&size=200',
    description: 'PhD in ML, specializing in adaptive learning algorithms.',
  ),
];
