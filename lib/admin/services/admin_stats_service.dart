import 'package:cloud_firestore/cloud_firestore.dart';

/// Service to fetch and aggregate admin dashboard statistics
class AdminStatsService {
  final FirebaseFirestore _firestore;

  AdminStatsService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

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
        return DashboardStats(
          totalUsers: 0,
          activeCourses: 0,
          enrollmentsToday: 0,
          revenueToday: 0,
        );
      }
      return DashboardStats.fromJson(doc.data()!);
    });
  }

  /// Get total number of users
  Future<int> _getTotalUsers() async {
    final snapshot = await _firestore.collection('users').count().get();
    return snapshot.count ?? 0;
  }

  /// Get number of active (published) courses
  Future<int> _getActiveCourses() async {
    final snapshot = await _firestore
        .collection('courses')
        .where('visibility', isEqualTo: 'published')
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  /// Get number of purchases/enrollments made today
  Future<int> _getEnrollmentsToday(Timestamp startOfDay) async {
    final snapshot = await _firestore
        .collection('purchases')
        .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  /// Get total revenue from today's purchases
  Future<double> _getRevenueToday(Timestamp startOfDay) async {
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
  }

  /// Save/update dashboard stats to a dedicated collection (for caching)
  Future<void> updateDashboardStats() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final startOfDayTimestamp = Timestamp.fromDate(startOfDay);

    final stats = DashboardStats(
      totalUsers: await _getTotalUsers(),
      activeCourses: await _getActiveCourses(),
      enrollmentsToday: await _getEnrollmentsToday(startOfDayTimestamp),
      revenueToday: await _getRevenueToday(startOfDayTimestamp),
    );

    await _firestore.collection('admin_stats').doc('dashboard').set({
      ...stats.toJson(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

/// Dashboard statistics model
class DashboardStats {
  final int totalUsers;
  final int activeCourses;
  final int enrollmentsToday;
  final double revenueToday;

  DashboardStats({
    required this.totalUsers,
    required this.activeCourses,
    required this.enrollmentsToday,
    required this.revenueToday,
  });

  Map<String, dynamic> toJson() => {
    'totalUsers': totalUsers,
    'activeCourses': activeCourses,
    'enrollmentsToday': enrollmentsToday,
    'revenueToday': revenueToday,
  };

  factory DashboardStats.fromJson(Map<String, dynamic> json) => DashboardStats(
    totalUsers: json['totalUsers'] ?? 0,
    activeCourses: json['activeCourses'] ?? 0,
    enrollmentsToday: json['enrollmentsToday'] ?? 0,
    revenueToday: (json['revenueToday'] ?? 0).toDouble(),
  );
}
