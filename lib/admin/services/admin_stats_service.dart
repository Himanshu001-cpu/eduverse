import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// Service to fetch and aggregate admin dashboard statistics
class AdminStatsService {
  static final AdminStatsService _instance = AdminStatsService._internal();
  factory AdminStatsService({FirebaseFirestore? firestore}) {
    if (firestore != null) {
      return AdminStatsService._withFirestore(firestore);
    }
    return _instance;
  }

  AdminStatsService._internal() : _firestore = FirebaseFirestore.instance;
  AdminStatsService._withFirestore(this._firestore);

  final FirebaseFirestore _firestore;

  /// Get dashboard stats as a stream from the cached stats document
  Stream<DashboardStats> getDashboardStatsStream() {
    return _firestore
        .collection('admin_stats')
        .doc('dashboard')
        .snapshots()
        .asyncMap((doc) async {
      if (!doc.exists || doc.data() == null) {
        // Initial setup or fallback: compute once, cache to admin_stats/dashboard, and emit
        try {
          await updateDashboardStats();
          final updatedDoc =
              await _firestore.collection('admin_stats').doc('dashboard').get();
          if (updatedDoc.exists && updatedDoc.data() != null) {
            return DashboardStats.fromJson(updatedDoc.data()!);
          }
        } catch (_) {}
        return DashboardStats.empty();
      }
      return DashboardStats.fromJson(doc.data()!);
    });
  }

  DateTime? _extractDate(Map<String, dynamic> data) {
    final ca = data['createdAt'];
    if (ca is Timestamp) return ca.toDate();
    if (ca is String) {
      final parsed = DateTime.tryParse(ca);
      if (parsed != null) return parsed;
    }
    final ts = data['timestamp'];
    if (ts is Timestamp) return ts.toDate();
    if (ts is String) {
      final parsed = DateTime.tryParse(ts);
      if (parsed != null) return parsed;
    }
    return null;
  }

  /// Save/update dashboard stats to a dedicated collection (for caching)
  Future<void> updateDashboardStats() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    final totalUsers = await _getTotalUsers();
    final activeCourses = await _getActiveCourses();
    final draftCourses = await _getDraftCourses();

    // Resilient aggregation of purchases supporting heterogeneous timestamp & createdAt
    int totalEnrollments = 0;
    int enrollmentsToday = 0;
    double revenueToday = 0.0;
    double totalRevenue = 0.0;

    final Map<String, double> monthMap = {};
    final List<DateTime> months = [];
    for (int i = 5; i >= 0; i--) {
      final d = DateTime(now.year, now.month - i, 1);
      final key = DateFormat('MMM').format(d);
      monthMap[key] = 0.0;
      months.add(d);
    }
    final sixMonthsAgo = months.first;

    try {
      final purchasesSnap = await _firestore.collection('purchases').get();
      totalEnrollments = purchasesSnap.docs.length;

      for (final doc in purchasesSnap.docs) {
        final data = doc.data();
        final amt = (data['amount'] as num?)?.toDouble() ?? 0.0;
        totalRevenue += amt;

        final date = _extractDate(data);
        if (date != null) {
          if (!date.isBefore(startOfDay)) {
            enrollmentsToday++;
            revenueToday += amt;
          }
          if (!date.isBefore(sixMonthsAgo)) {
            final monthKey = DateFormat('MMM').format(date);
            if (monthMap.containsKey(monthKey)) {
              monthMap[monthKey] = (monthMap[monthKey] ?? 0.0) + amt;
            }
          }
        }
      }
    } catch (_) {}

    double maxAmt = 1.0;
    monthMap.forEach((_, val) {
      if (val > maxAmt) maxAmt = val;
    });

    final monthlyRevenue = monthMap.entries.map((e) {
      final isCurrent = e.key == DateFormat('MMM').format(now);
      return MonthlyRevenuePoint(
        month: isCurrent ? '${e.key} (Cur)' : e.key,
        amount: e.value,
        ratio: maxAmt > 0 ? (e.value / maxAmt).clamp(0.08, 1.0) : 0.08,
        isActive: isCurrent,
      );
    }).toList();

    final cohortSaturations = await _getCohortSaturations();

    final stats = DashboardStats(
      totalUsers: totalUsers,
      activeCourses: activeCourses,
      draftCourses: draftCourses,
      enrollmentsToday: enrollmentsToday,
      totalEnrollments: totalEnrollments,
      revenueToday: revenueToday,
      totalRevenue: totalRevenue,
      monthlyRevenue: monthlyRevenue,
      cohortSaturations: cohortSaturations,
    );

    await _firestore.collection('admin_stats').doc('dashboard').set({
      ...stats.toJson(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get total number of registered users
  Future<int> _getTotalUsers() async {
    try {
      final snapshot = await _firestore.collection('users').count().get();
      return snapshot.count ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Get number of active (published) courses
  Future<int> _getActiveCourses() async {
    try {
      final snapshot = await _firestore
          .collection('courses')
          .where('visibility', isEqualTo: 'published')
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Get number of draft courses awaiting review
  Future<int> _getDraftCourses() async {
    try {
      final snapshot = await _firestore
          .collection('courses')
          .where('visibility', isEqualTo: 'draft')
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Get real cohort saturation from courses collection
  Future<List<CohortSaturation>> _getCohortSaturations() async {
    try {
      final coursesSnap = await _firestore
          .collection('courses')
          .where('visibility', isEqualTo: 'published')
          .limit(4)
          .get();

      if (coursesSnap.docs.isEmpty) return [];

      final List<CohortSaturation> saturations = [];
      for (final doc in coursesSnap.docs) {
        final data = doc.data();
        final title = (data['title'] ?? 'Course Batch').toString();
        // Count enrollments for this course
        final enrollCountSnap = await _firestore
            .collection('purchases')
            .where('courseId', isEqualTo: doc.id)
            .count()
            .get();

        final enrolled = enrollCountSnap.count ?? 0;
        const targetCapacity = 200; // Standard cohort baseline capacity
        final ratio = (enrolled / targetCapacity).clamp(0.0, 1.0);

        saturations.add(
          CohortSaturation(
            courseTitle: title,
            enrolledCount: enrolled,
            capacity: targetCapacity,
            ratio: ratio,
          ),
        );
      }

      return saturations;
    } catch (_) {
      return [];
    }
  }
}

/// Monthly revenue data point for trajectory chart
class MonthlyRevenuePoint {
  final String month;
  final double amount;
  final double ratio;
  final bool isActive;

  MonthlyRevenuePoint({
    required this.month,
    required this.amount,
    required this.ratio,
    required this.isActive,
  });

  Map<String, dynamic> toJson() => {
    'month': month,
    'amount': amount,
    'ratio': ratio,
    'isActive': isActive,
  };

  factory MonthlyRevenuePoint.fromJson(Map<String, dynamic> json) => MonthlyRevenuePoint(
    month: json['month'] as String? ?? '',
    amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
    ratio: (json['ratio'] as num?)?.toDouble() ?? 0.0,
    isActive: json['isActive'] as bool? ?? false,
  );
}

/// Cohort saturation model
class CohortSaturation {
  final String courseTitle;
  final int enrolledCount;
  final int capacity;
  final double ratio;

  CohortSaturation({
    required this.courseTitle,
    required this.enrolledCount,
    required this.capacity,
    required this.ratio,
  });

  String get label => '${(ratio * 100).toStringAsFixed(0)}% filled ($enrolledCount/$capacity)';

  Map<String, dynamic> toJson() => {
    'courseTitle': courseTitle,
    'enrolledCount': enrolledCount,
    'capacity': capacity,
    'ratio': ratio,
  };

  factory CohortSaturation.fromJson(Map<String, dynamic> json) => CohortSaturation(
    courseTitle: json['courseTitle'] as String? ?? '',
    enrolledCount: json['enrolledCount'] as int? ?? 0,
    capacity: json['capacity'] as int? ?? 0,
    ratio: (json['ratio'] as num?)?.toDouble() ?? 0.0,
  );
}

/// Comprehensive Dashboard statistics model
class DashboardStats {
  final int totalUsers;
  final int activeCourses;
  final int draftCourses;
  final int enrollmentsToday;
  final int totalEnrollments;
  final double revenueToday;
  final double totalRevenue;
  final List<MonthlyRevenuePoint> monthlyRevenue;
  final List<CohortSaturation> cohortSaturations;

  DashboardStats({
    required this.totalUsers,
    required this.activeCourses,
    this.draftCourses = 0,
    required this.enrollmentsToday,
    this.totalEnrollments = 0,
    required this.revenueToday,
    this.totalRevenue = 0.0,
    this.monthlyRevenue = const [],
    this.cohortSaturations = const [],
  });

  factory DashboardStats.empty() => DashboardStats(
        totalUsers: 0,
        activeCourses: 0,
        draftCourses: 0,
        enrollmentsToday: 0,
        totalEnrollments: 0,
        revenueToday: 0.0,
        totalRevenue: 0.0,
        monthlyRevenue: const [],
        cohortSaturations: const [],
      );

  Map<String, dynamic> toJson() => {
    'totalUsers': totalUsers,
    'activeCourses': activeCourses,
    'draftCourses': draftCourses,
    'enrollmentsToday': enrollmentsToday,
    'totalEnrollments': totalEnrollments,
    'revenueToday': revenueToday,
    'totalRevenue': totalRevenue,
    'monthlyRevenue': monthlyRevenue.map((e) => e.toJson()).toList(),
    'cohortSaturations': cohortSaturations.map((e) => e.toJson()).toList(),
  };

  factory DashboardStats.fromJson(Map<String, dynamic> json) => DashboardStats(
    totalUsers: json['totalUsers'] as int? ?? 0,
    activeCourses: json['activeCourses'] as int? ?? 0,
    draftCourses: json['draftCourses'] as int? ?? 0,
    enrollmentsToday: json['enrollmentsToday'] as int? ?? 0,
    totalEnrollments: json['totalEnrollments'] as int? ?? 0,
    revenueToday: (json['revenueToday'] as num?)?.toDouble() ?? 0.0,
    totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0.0,
    monthlyRevenue: (json['monthlyRevenue'] as List<dynamic>?)
            ?.map((e) => MonthlyRevenuePoint.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [],
    cohortSaturations: (json['cohortSaturations'] as List<dynamic>?)
            ?.map((e) => CohortSaturation.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [],
  );
}
