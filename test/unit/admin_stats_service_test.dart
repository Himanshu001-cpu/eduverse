import 'package:flutter_test/flutter_test.dart';
import 'package:eduverse/admin/services/admin_stats_service.dart';
import '../e2e/harness/fake_firebase_firestore.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late AdminStatsService statsService;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    statsService = AdminStatsService(firestore: fakeFirestore);
  });

  group('AdminStatsService - Dashboard Stats Tests', () {
    test('getDashboardStatsStream emits cached stats from admin_stats/dashboard directly', () async {
      // Seed pre-computed dashboard document
      fakeFirestore.setDoc('admin_stats/dashboard', {
        'totalUsers': 1500,
        'activeCourses': 12,
        'enrollmentsToday': 45,
        'revenueToday': 2250.0,
      });

      final stream = statsService.getDashboardStatsStream();
      final stats = await stream.first;

      expect(stats.totalUsers, 1500);
      expect(stats.activeCourses, 12);
      expect(stats.enrollmentsToday, 45);
      expect(stats.revenueToday, 2250.0);
    });

    test('getDashboardStatsStream receives real-time updates when admin_stats/dashboard is updated', () async {
      fakeFirestore.setDoc('admin_stats/dashboard', {
        'totalUsers': 10,
        'activeCourses': 2,
        'enrollmentsToday': 1,
        'revenueToday': 50.0,
      });

      final stream = statsService.getDashboardStatsStream();
      final initialStats = await stream.first;
      expect(initialStats.totalUsers, 10);

      // Update doc
      fakeFirestore.setDoc('admin_stats/dashboard', {
        'totalUsers': 11,
        'activeCourses': 2,
        'enrollmentsToday': 2,
        'revenueToday': 100.0,
      });

      final updatedStats = await stream.first;
      expect(updatedStats.totalUsers, 11);
      expect(updatedStats.enrollmentsToday, 2);
      expect(updatedStats.revenueToday, 100.0);
    });

    test('updateDashboardStats aggregates totals and writes to admin_stats/dashboard', () async {
      // Seed raw data
      for (int i = 0; i < 5; i++) {
        fakeFirestore.setDoc('users/u_$i', {'name': 'User $i'});
      }
      fakeFirestore.setDoc('courses/c_1', {'title': 'Course 1', 'visibility': 'published'});
      fakeFirestore.setDoc('courses/c_2', {'title': 'Course 2', 'visibility': 'draft'});

      await statsService.updateDashboardStats();

      final doc = await fakeFirestore.collection('admin_stats').doc('dashboard').get();
      expect(doc.exists, isTrue);
      expect(doc.data()!['totalUsers'], 5);
      expect(doc.data()!['activeCourses'], 1);
    });
  });
}
