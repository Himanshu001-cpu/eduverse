import 'package:flutter/material.dart';
import '../theme/academic_futurist_theme.dart';

class StatsSection extends StatelessWidget {
  const StatsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 768;

    return Center(
      child: Transform.translate(
        offset: const Offset(0, -48),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1000),
          margin: EdgeInsets.symmetric(
            horizontal: isDesktop ? EduverseTheme.marginDesktop : EduverseTheme.marginMobile,
          ),
          decoration: BoxDecoration(
            color: EduverseTheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: EduverseTheme.deepNavy.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
            border: Border.all(
              color: EduverseTheme.outlineVariant.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: isDesktop
              ? Row(
                  children: [
                    Expanded(
                      child: _StatItem(
                        value: '50K+',
                        label: 'Active Learners',
                        valueColor: EduverseTheme.primary,
                      ),
                    ),
                    _Divider(),
                    Expanded(
                      child: _StatItem(
                        value: '260+',
                        label: 'Study Modules',
                        valueColor: EduverseTheme.tertiaryContainer,
                      ),
                    ),
                    _Divider(),
                    Expanded(
                      child: _StatItem(
                        value: 'Live',
                        label: 'Classes & Timetable',
                        valueColor: EduverseTheme.secondary,
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    _StatItem(
                      value: '50K+',
                      label: 'Active Learners',
                      valueColor: EduverseTheme.primary,
                    ),
                    const Divider(height: 32, color: Color(0x22BEC9C6)),
                    _StatItem(
                      value: '260+',
                      label: 'Study Modules',
                      valueColor: EduverseTheme.tertiaryContainer,
                    ),
                    const Divider(height: 32, color: Color(0x22BEC9C6)),
                    _StatItem(
                      value: 'Live',
                      label: 'Classes & Timetable',
                      valueColor: EduverseTheme.secondary,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 60,
      color: EduverseTheme.outlineVariant.withValues(alpha: 0.35),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final Color valueColor;

  const _StatItem({
    required this.value,
    required this.label,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          style: EduverseTheme.displayLg(color: valueColor).copyWith(
            fontSize: 44,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(),
          textAlign: TextAlign.center,
          style: EduverseTheme.labelSm(
            color: EduverseTheme.onSurfaceVariant,
            letterSpacing: 1.5,
          ).copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
