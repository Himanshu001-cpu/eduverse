import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/admin_scaffold.dart';
import '../services/admin_stats_service.dart';
import '../models/admin_models.dart';
import '../../web/landing/theme/academic_futurist_theme.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;

    return AdminScaffold(
      title: 'Dean of Academic Affairs',
      body: StreamBuilder<DashboardStats>(
        stream: AdminStatsService().getDashboardStatsStream(),
        builder: (context, snapshot) {
          final stats = snapshot.data;
          final isLoading = !snapshot.hasData;

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 32.0 : 16.0,
              vertical: 24.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Command & Executive Bar
                _buildExecutiveHeader(context, isDesktop),
                const SizedBox(height: 24),

                // KPI Quadrant (4 Cards Grid)
                _buildKpiQuadrant(context, stats, isLoading, isDesktop),
                const SizedBox(height: 28),

                // Main Asymmetric Grid Split (2:1 Desktop Layout)
                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Column: Analytical & Transactional Operations (2/3 width)
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTrajectoryCard(stats),
                            const SizedBox(height: 24),
                            _buildRecentTransactionsCard(context),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),

                      // Right Column: Security Sentinel & Queue (1/3 width)
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSecuritySentinelCard(),
                            const SizedBox(height: 24),
                            _buildModerationQueueCard(context, stats),
                            const SizedBox(height: 24),
                            _buildCohortSaturationCard(stats),
                          ],
                        ),
                      ),
                    ],
                  )
                else
                  // Mobile / Tablet single column stacked layout
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTrajectoryCard(stats),
                      const SizedBox(height: 20),
                      _buildSecuritySentinelCard(),
                      const SizedBox(height: 20),
                      _buildRecentTransactionsCard(context),
                      const SizedBox(height: 20),
                      _buildModerationQueueCard(context, stats),
                      const SizedBox(height: 20),
                      _buildCohortSaturationCard(stats),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildExecutiveHeader(BuildContext context, bool isDesktop) {
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, MMMM d, y').format(now);

    return Container(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: EduverseTheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'ACADEMIC COMMAND CENTER',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: EduverseTheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Text('|', style: TextStyle(color: EduverseTheme.outlineVariant)),
              const SizedBox(width: 10),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: EduverseTheme.emeraldVivid,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Realtime Academic Feed',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: EduverseTheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Dean of Academic Affairs',
            style: EduverseTheme.headlineLg(color: EduverseTheme.deepNavy).copyWith(
              fontSize: isDesktop ? 30 : 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$dateStr • Live Synchronized Firestore Dashboard',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: EduverseTheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiQuadrant(
    BuildContext context,
    DashboardStats? stats,
    bool isLoading,
    bool isDesktop,
  ) {
    final currencyFormat = NumberFormat('#,###');
    final grossRevenueStr = isLoading
        ? '...'
        : '₹${currencyFormat.format(stats!.totalRevenue)}';
    final activeUsersStr = isLoading
        ? '...'
        : currencyFormat.format(stats!.totalUsers);
    final enrollmentsStr = isLoading
        ? '...'
        : currencyFormat.format(stats!.totalEnrollments);
    final activeCoursesStr = isLoading
        ? '...'
        : stats!.activeCourses.toString();

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = isDesktop
            ? (constraints.maxWidth - 48) / 4
            : (constraints.maxWidth - 16) / 2;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _kpiCard(
              title: 'Gross Revenue',
              value: grossRevenueStr,
              badgeText: stats != null && stats.revenueToday > 0
                  ? '+₹${currencyFormat.format(stats.revenueToday)} today'
                  : 'Live Total',
              badgePositive: true,
              icon: Icons.payments_outlined,
              iconBg: EduverseTheme.primaryFixed,
              iconColor: EduverseTheme.primary,
              width: cardWidth,
            ),
            _kpiCard(
              title: 'Total Active Aspirants',
              value: activeUsersStr,
              badgeText: 'Verified Users',
              badgePositive: true,
              icon: Icons.groups_outlined,
              iconBg: EduverseTheme.secondaryFixed,
              iconColor: EduverseTheme.secondary,
              width: cardWidth,
            ),
            _kpiCard(
              title: 'Course Enrollments',
              value: enrollmentsStr,
              badgeText: stats != null && stats.enrollmentsToday > 0
                  ? '+${stats.enrollmentsToday} today'
                  : 'All Cohorts',
              badgePositive: true,
              icon: Icons.school_outlined,
              iconBg: EduverseTheme.tertiaryFixed,
              iconColor: EduverseTheme.tertiary,
              width: cardWidth,
            ),
            _kpiCard(
              title: 'Active Modules & Live',
              value: activeCoursesStr,
              badgeText: 'Published',
              badgePositive: true,
              icon: Icons.live_tv_outlined,
              iconBg: EduverseTheme.surfaceContainerHigh,
              iconColor: EduverseTheme.primary,
              width: cardWidth,
            ),
          ],
        );
      },
    );
  }

  Widget _kpiCard({
    required String title,
    required String value,
    required String badgeText,
    required bool badgePositive,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: EduverseTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: EduverseTheme.outlineVariant.withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgePositive
                      ? EduverseTheme.emeraldVivid.withValues(alpha: 0.12)
                      : Colors.red.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: badgePositive ? EduverseTheme.emeraldVivid : Colors.red,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Playfair Display',
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: EduverseTheme.deepNavy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: EduverseTheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrajectoryCard(DashboardStats? stats) {
    final points = stats?.monthlyRevenue ?? [];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: EduverseTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: EduverseTheme.outlineVariant.withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Revenue & Enrollment Trajectory',
                    style: EduverseTheme.headlineMd(color: EduverseTheme.deepNavy).copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Monthly actual admissions from live purchases',
                    style: TextStyle(fontSize: 12, color: EduverseTheme.onSurfaceVariant),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: EduverseTheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Fiscal ${DateTime.now().year}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: EduverseTheme.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Monthly Bars Visualization
          if (points.isNotEmpty)
            SizedBox(
              height: 180,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: points.map((p) {
                  final label = p.amount > 0 ? '₹${NumberFormat.compact().format(p.amount)}' : '₹0';
                  return _barItem(p.month, p.ratio, label, isActive: p.isActive);
                }).toList(),
              ),
            )
          else
            Container(
              height: 140,
              alignment: Alignment.center,
              child: const Text(
                'Awaiting first transactional intake to generate trajectory curve',
                style: TextStyle(fontSize: 13, color: EduverseTheme.onSurfaceVariant),
              ),
            ),
        ],
      ),
    );
  }

  Widget _barItem(String month, double ratio, String label, {bool isActive = false}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? EduverseTheme.primary : EduverseTheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 36,
          height: (120 * ratio).clamp(8.0, 120.0),
          decoration: BoxDecoration(
            color: isActive ? EduverseTheme.primary : EduverseTheme.primaryFixedDim.withValues(alpha: 0.65),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          month,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? EduverseTheme.primary : EduverseTheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTransactionsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: EduverseTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: EduverseTheme.outlineVariant.withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Transactions & Admissions',
                style: EduverseTheme.headlineMd(color: EduverseTheme.deepNavy).copyWith(fontSize: 18),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/purchases'),
                child: const Text('View All Transactions →', style: TextStyle(color: EduverseTheme.primary, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const _RecentTransactionsContent(),
        ],
      ),
    );
  }

  Widget _buildSecuritySentinelCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: EduverseTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: EduverseTheme.outlineVariant.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined, color: EduverseTheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Security Sentinel',
                style: EduverseTheme.headlineMd(color: EduverseTheme.deepNavy).copyWith(fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _sentinelMetric('DRM Content Armor', 'Hardware L1 Active', Icons.lock_outline, Colors.green),
          _sentinelMetric('Firebase App Check', 'Attested & Enforced', Icons.verified_user_outlined, Colors.green),
          _sentinelMetric('Dynamic Watermarking', 'Phone + UID Watermark', Icons.fingerprint, EduverseTheme.primary),
        ],
      ),
    );
  }

  Widget _sentinelMetric(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontSize: 12, color: EduverseTheme.onSurfaceVariant)),
            ],
          ),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _buildModerationQueueCard(BuildContext context, DashboardStats? stats) {
    final pendingCount = stats?.draftCourses ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: EduverseTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: EduverseTheme.outlineVariant.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pending Review Queue',
                style: EduverseTheme.headlineMd(color: EduverseTheme.deepNavy).copyWith(fontSize: 16),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: pendingCount > 0 ? EduverseTheme.tertiaryFixed : EduverseTheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$pendingCount Pending',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: pendingCount > 0 ? EduverseTheme.onTertiaryFixed : EduverseTheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (pendingCount > 0) ...[
            _queueItem(
              '$pendingCount Draft Course Modules',
              'Awaiting curriculum authorization',
              'Review',
              onPressed: () => Navigator.pushNamed(context, '/courses'),
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: EduverseTheme.emeraldVivid, size: 18),
                  const SizedBox(width: 8),
                  const Text('All curriculum drafts reviewed & approved', style: TextStyle(fontSize: 12, color: EduverseTheme.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _queueItem(String title, String subtitle, String actionText, {VoidCallback? onPressed}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: EduverseTheme.onSurfaceVariant)),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: const Size(60, 28),
              side: const BorderSide(color: EduverseTheme.primary),
            ),
            child: Text(actionText, style: const TextStyle(fontSize: 11, color: EduverseTheme.primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildCohortSaturationCard(DashboardStats? stats) {
    final saturations = stats?.cohortSaturations ?? [];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: EduverseTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: EduverseTheme.outlineVariant.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cohort Saturation',
            style: EduverseTheme.headlineMd(color: EduverseTheme.deepNavy).copyWith(fontSize: 16),
          ),
          const SizedBox(height: 12),
          if (saturations.isNotEmpty) ...[
            for (final item in saturations)
              _saturationRow(item.courseTitle, item.ratio, item.label),
          ] else ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: const Text(
                'Publish courses to monitor active intake saturation',
                style: TextStyle(fontSize: 12, color: EduverseTheme.onSurfaceVariant),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _saturationRow(String name, double progress, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: EduverseTheme.primary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: EduverseTheme.surfaceContainerHigh,
              color: EduverseTheme.primary,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentTransactionsContent extends StatefulWidget {
  const _RecentTransactionsContent();

  @override
  State<_RecentTransactionsContent> createState() =>
      _RecentTransactionsContentState();
}

class _RecentTransactionsContentState
    extends State<_RecentTransactionsContent> {
  final Map<String, String> _userDisplayNames = {};
  final Set<String> _requestedUserIds = {};

  void _resolveUser(String userId) {
    if (userId.isEmpty || _requestedUserIds.contains(userId)) return;
    _requestedUserIds.add(userId);
    FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get()
        .then((doc) {
      if (!mounted) return;
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final name = (data['name'] as String?)?.trim();
        final email = (data['email'] as String?)?.trim();
        final displayName = (name != null && name.isNotEmpty)
            ? name
            : ((email != null && email.isNotEmpty)
                ? email
                : 'User ${userId.substring(0, userId.length > 5 ? 5 : userId.length)}');
        setState(() {
          _userDisplayNames[userId] = displayName;
        });
      }
    }).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('purchases').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          final isPermissionDenied =
              snapshot.error.toString().contains('permission-denied');
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            alignment: Alignment.center,
            child: Column(
              children: [
                Icon(
                  isPermissionDenied ? Icons.lock_outline : Icons.error_outline,
                  size: 32,
                  color: EduverseTheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 8),
                Text(
                  isPermissionDenied
                      ? 'Admin session authentication required'
                      : 'Unable to synchronize transaction records',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: EduverseTheme.deepNavy),
                ),
                const SizedBox(height: 4),
                Text(
                  isPermissionDenied
                      ? 'Sign in with institutional Dean/Admin credentials to view live transactional streams.'
                      : '${snapshot.error}',
                  style: const TextStyle(
                      fontSize: 12, color: EduverseTheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 32),
            alignment: Alignment.center,
            child: Column(
              children: [
                Icon(Icons.receipt_long_outlined,
                    size: 36,
                    color:
                        EduverseTheme.onSurfaceVariant.withValues(alpha: 0.4)),
                const SizedBox(height: 8),
                const Text(
                  'No transactions recorded yet',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: EduverseTheme.deepNavy),
                ),
                const SizedBox(height: 4),
                const Text(
                  'New student enrollments and fee payments will appear here in real-time.',
                  style: TextStyle(
                      fontSize: 12, color: EduverseTheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final purchases = snapshot.data!.docs
            .map((doc) => AdminPurchase.fromMap(doc.data(), doc.id))
            .toList();

        purchases.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final recentPurchases = purchases.take(5).toList();

        for (final p in recentPurchases) {
          if (p.userId.isNotEmpty && !_userDisplayNames.containsKey(p.userId)) {
            _resolveUser(p.userId);
          }
        }

        return Column(
          children: recentPurchases.map((purchase) {
            final userName = _userDisplayNames[purchase.userId] ??
                (purchase.userId.isNotEmpty
                    ? 'Student (${purchase.userId.substring(0, purchase.userId.length > 6 ? 6 : purchase.userId.length)})'
                    : 'Scholar Candidate');

            final itemTitle = purchase.items.isNotEmpty
                ? purchase.items.map((e) => e.title).join(', ')
                : 'Eduverse Program Enrollment';

            final amount = '₹${purchase.amount.toStringAsFixed(0)}';
            final time =
                DateFormat('dd MMM, hh:mm a').format(purchase.createdAt);

            Color statusColor;
            Color statusBg;
            String statusLabel;
            final s = purchase.status.toLowerCase();
            if (s == 'completed' || s == 'paid' || s == 'success') {
              statusColor = EduverseTheme.emeraldVivid;
              statusBg = EduverseTheme.emeraldVivid.withValues(alpha: 0.12);
              statusLabel = 'Settled';
            } else if (s == 'manual') {
              statusColor = EduverseTheme.primary;
              statusBg = EduverseTheme.primary.withValues(alpha: 0.12);
              statusLabel = 'Manual';
            } else if (s == 'refunded') {
              statusColor = Colors.orange.shade800;
              statusBg = Colors.orange.shade50;
              statusLabel = 'Refunded';
            } else if (s == 'failed') {
              statusColor = Colors.red.shade700;
              statusBg = Colors.red.shade50;
              statusLabel = 'Failed';
            } else {
              statusColor = EduverseTheme.onSurfaceVariant;
              statusBg = EduverseTheme.outlineVariant.withValues(alpha: 0.2);
              statusLabel = purchase.status.isNotEmpty
                  ? '${purchase.status[0].toUpperCase()}${purchase.status.substring(1)}'
                  : 'Pending';
            }

            return _txRow(
              userName,
              itemTitle,
              amount,
              time,
              statusLabel,
              statusColor,
              statusBg,
            );
          }).toList(),
        );
      },
    );
  }

  Widget _txRow(
    String user,
    String course,
    String amount,
    String time,
    String status,
    Color statusColor,
    Color statusBg,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: EduverseTheme.outlineVariant.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: EduverseTheme.primaryFixed,
            child: Text(
              user.isNotEmpty ? user[0].toUpperCase() : 'U',
              style: const TextStyle(
                  color: EduverseTheme.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: EduverseTheme.deepNavy),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  course,
                  style: const TextStyle(
                      fontSize: 12, color: EduverseTheme.onSurfaceVariant),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: EduverseTheme.deepNavy),
              ),
              Text(
                time,
                style:
                    const TextStyle(fontSize: 11, color: EduverseTheme.outline),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              status,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: statusColor),
            ),
          ),
        ],
      ),
    );
  }
}
