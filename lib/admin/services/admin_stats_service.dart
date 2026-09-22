import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// Service to fetch and aggregate admin dashboard statistics from real Firestore collections
class AdminStatsService {
  static final AdminStatsService _instance = AdminStatsService._internal();
  factory AdminStatsService() => _instance;
  AdminStatsService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get dashboard stats as a stream with real-time updates
  Stream<DashboardStats> getDashboardStatsStream() async* {
    while (true) {
      try {
        final now = DateTime.now();
        final startOfDay = DateTime(now.year, now.month, now.day);
        final startOfDayTimestamp = Timestamp.fromDate(startOfDay);

        // Fetch all stats in parallel
        final results = await Future.wait([
          _getTotalUsers(),
          _getActiveCourses(),
          _getDraftCourses(),
          _getEnrollmentsToday(startOfDayTimestamp),
          _getTotalEnrollments(),
          _getRevenueToday(startOfDayTimestamp),
          _getTotalRevenue(),
          _getMonthlyRevenue(),
          _getCohortSaturations(),
        ]);

        yield DashboardStats(
          totalUsers: results[0] as int,
          activeCourses: results[1] as int,
          draftCourses: results[2] as int,
          enrollmentsToday: results[3] as int,
          totalEnrollments: results[4] as int,
          revenueToday: results[5] as double,
          totalRevenue: results[6] as double,
          monthlyRevenue: results[7] as List<MonthlyRevenuePoint>,
          cohortSaturations: results[8] as List<CohortSaturation>,
        );
      } catch (e) {
        // Return baseline non-dummy stats on error
        yield DashboardStats.empty();
      }

      // Refresh every 15 seconds
      await Future.delayed(const Duration(seconds: 15));
    }
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

  /// Get number of draft/pending courses needing review
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

  /// Get number of purchases/enrollments made today
  Future<int> _getEnrollmentsToday(Timestamp startOfDay) async {
    try {
      final snapshot = await _firestore
          .collection('purchases')
          .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Get total all-time purchases/enrollments
  Future<int> _getTotalEnrollments() async {
    try {
      final snapshot = await _firestore.collection('purchases').count().get();
      return snapshot.count ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Get total revenue from today's purchases
  Future<double> _getRevenueToday(Timestamp startOfDay) async {
    try {
      final snapshot = await _firestore
          .collection('purchases')
          .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
          .get();

      double total = 0;
      for (final doc in snapshot.docs) {
        final amount = doc.data()['amount'];
        if (amount != null) {
          total += (amount as num).toDouble();
        }
      }
      return total;
    } catch (_) {
      return 0.0;
    }
  }

  /// Get total all-time gross revenue
  Future<double> _getTotalRevenue() async {
    try {
      final snapshot = await _firestore.collection('purchases').get();
      double total = 0;
      for (final doc in snapshot.docs) {
        final amount = doc.data()['amount'];
        if (amount != null) {
          total += (amount as num).toDouble();
        }
      }
      return total;
    } catch (_) {
      return 0.0;
    }
  }

  /// Aggregate last 6 calendar months of revenue from real purchases
  Future<List<MonthlyRevenuePoint>> _getMonthlyRevenue() async {
    try {
      final now = DateTime.now();
      // Initialize map for the last 6 months
      final Map<String, double> monthMap = {};
      final List<DateTime> months = [];

      for (int i = 5; i >= 0; i--) {
        final d = DateTime(now.year, now.month - i, 1);
        final key = DateFormat('MMM').format(d);
        monthMap[key] = 0.0;
        months.add(d);
      }

      final sixMonthsAgo = months.first;
      final snapshot = await _firestore
          .collection('purchases')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(sixMonthsAgo))
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final ts = data['timestamp'] as Timestamp?;
        final amt = (data['amount'] as num?)?.toDouble() ?? 0.0;
        if (ts != null) {
          final monthKey = DateFormat('MMM').format(ts.toDate());
          if (monthMap.containsKey(monthKey)) {
            monthMap[monthKey] = (monthMap[monthKey] ?? 0.0) + amt;
          }
        }
      }

      double maxAmt = 1.0;
      monthMap.forEach((_, val) {
        if (val > maxAmt) maxAmt = val;
      });

      return monthMap.entries.map((e) {
        final isCurrent = e.key == DateFormat('MMM').format(now);
        return MonthlyRevenuePoint(
          month: isCurrent ? '${e.key} (Cur)' : e.key,
          amount: e.value,
          ratio: maxAmt > 0 ? (e.value / maxAmt).clamp(0.08, 1.0) : 0.08,
          isActive: isCurrent,
        );
      }).toList();
    } catch (_) {
      return [];
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
        final targetCapacity = 200; // Standard cohort baseline capacity
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
    required this.draftCourses,
    required this.enrollmentsToday,
    required this.totalEnrollments,
    required this.revenueToday,
    required this.totalRevenue,
    required this.monthlyRevenue,
    required this.cohortSaturations,
  });

  factory DashboardStats.empty() => DashboardStats(
        totalUsers: 0,
        activeCourses: 0,
        draftCourses: 0,
        enrollmentsToday: 0,
        totalEnrollments: 0,
        revenueToday: 0.0,
        totalRevenue: 0.0,
        monthlyRevenue: [],
        cohortSaturations: [],
      );
}
