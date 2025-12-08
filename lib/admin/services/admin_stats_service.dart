import 'package:cloud_firestore/cloud_firestore.dart';

/// Service to fetch and aggregate admin dashboard statistics
class AdminStatsService {
  static final AdminStatsService _instance = AdminStatsService._internal();
  factory AdminStatsService() => _instance;
  AdminStatsService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get dashboard stats as a stream
  Stream<DashboardStats> getDashboardStatsStream() async* {
    // Get start of today for filtering
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final startOfDayTimestamp = Timestamp.fromDate(startOfDay);

    while (true) {
      try {
        // Fetch all stats in parallel
        final results = await Future.wait([
          _getTotalUsers(),
          _getActiveCourses(),
          _getEnrollmentsToday(startOfDayTimestamp),
          _getRevenueToday(startOfDayTimestamp),
        ]);

        yield DashboardStats(
          totalUsers: results[0] as int,
          activeCourses: results[1] as int,
          enrollmentsToday: results[2] as int,
          revenueToday: results[3] as double,
        );
      } catch (e) {
        // Return default stats on error
        yield DashboardStats(
          totalUsers: 0,
          activeCourses: 0,
          enrollmentsToday: 0,
          revenueToday: 0,
        );
      }

      // Refresh every 30 seconds
      await Future.delayed(const Duration(seconds: 30));
    }
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
