import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eduverse/admin/models/scheduler_models.dart';
import 'package:eduverse/admin/models/admin_models.dart';
import 'package:eduverse/admin/services/firebase_admin_service.dart';
import 'package:eduverse/core/notifications/notification_model.dart';
import 'package:eduverse/core/notifications/notification_repository.dart';
import '../e2e/harness/fake_firebase_firestore.dart';
import '../e2e/harness/fake_firebase_auth.dart';

class FakeNotificationRepository extends Fake implements NotificationRepository {
  final List<Map<String, dynamic>> sentNotifications = [];

  @override
  Future<void> createCourseNotification({
    required String title,
    required String body,
    required NotificationTargetType targetType,
    required String targetId,
    required String courseId,
    String? imageUrl,
  }) async {
    sentNotifications.add({
      'title': title,
      'body': body,
      'targetType': targetType,
      'targetId': targetId,
      'courseId': courseId,
      'imageUrl': imageUrl,
    });
  }
}

void main() {
  group('Recurring Class Rules & Generation Tests (R1)', () {
    late FakeFirebaseFirestore db;
    late FakeFirebaseAuth auth;
    late FakeNotificationRepository notificationRepo;
    late FirebaseAdminService service;
    const courseId = 'course_test_123';

    setUp(() async {
      db = FakeFirebaseFirestore();
      auth = FakeFirebaseAuth();
      notificationRepo = FakeNotificationRepository();
      auth.changeCurrentUser(FakeUser(uid: 'admin_user'));
      
      service = FirebaseAdminService(
        auth: auth,
        db: db,
        notificationRepo: notificationRepo,
      );

      // Seed course data
      await db.collection('courses').doc(courseId).set({
        'title': 'Test Flutter Course',
        'visibility': 'published',
      });
    });

    test('CRUD operations for scheduler_rules', () async {
      final rule = RecurringClassRule(
        id: 'rule_1',
        courseId: courseId,
        title: 'Weekly Flutter Live',
        description: 'Learn Flutter live every Monday and Wednesday',
        instructorId: 'inst_1',
        instructorName: 'John Doe',
        weekdays: [1, 3], // Monday, Wednesday
        startTime: '18:30',
        durationMinutes: 90,
        startDate: DateTime(2026, 7, 1),
        endDate: DateTime(2026, 7, 31),
      );

      // 1. Create (Save)
      await service.saveRecurringRule(courseId, rule);

      // Verify rule in db
      final doc = await db
          .collection('courses')
          .doc(courseId)
          .collection('scheduler_rules')
          .doc(rule.id)
          .get();
      expect(doc.exists, isTrue);
      expect(doc.data()?['title'], equals('Weekly Flutter Live'));
      expect(doc.data()?['weekdays'], equals([1, 3]));

      // 2. Read (Get)
      final rules = await service.getRecurringRules(courseId);
      expect(rules.length, equals(1));
      expect(rules[0].id, equals(rule.id));
      expect(rules[0].durationMinutes, equals(90));

      // 3. Update
      final updatedRule = rule.copyWith(title: 'Updated Weekly Flutter Live', durationMinutes: 120);
      await service.saveRecurringRule(courseId, updatedRule);

      final rulesAfterUpdate = await service.getRecurringRules(courseId);
      expect(rulesAfterUpdate.length, equals(1));
      expect(rulesAfterUpdate[0].title, equals('Updated Weekly Flutter Live'));
      expect(rulesAfterUpdate[0].durationMinutes, equals(120));

      // 4. Delete
      await service.deleteRecurringRule(courseId, rule.id);
      final rulesAfterDelete = await service.getRecurringRules(courseId);
      expect(rulesAfterDelete.isEmpty, isTrue);
    });

    test('generateLiveClasses correctly schedules classes based on active weekdays and dates within range', () async {
      // Rule active from July 1st to July 15th, 2026
      // Start time: 10:00 AM
      // Weekdays: [1, 5] (Monday, Friday)
      final rule = RecurringClassRule(
        id: 'rule_weekly_m_f',
        courseId: courseId,
        title: 'Flutter Monday Friday Live',
        description: 'Monday and Friday morning lectures',
        instructorId: 'inst_1',
        instructorName: 'John Doe',
        weekdays: [1, 5],
        startTime: '10:00',
        durationMinutes: 60,
        startDate: DateTime(2026, 7, 1), // July 1st is Wednesday
        endDate: DateTime(2026, 7, 15),   // July 15th is Wednesday
      );

      await service.saveRecurringRule(courseId, rule);

      // Generate classes for the period of July 1st to July 20th
      // Weekdays in active range (July 1st to July 15th):
      // July 3 (Friday) - 1st class
      // July 6 (Monday) - 2nd class
      // July 10 (Friday) - 3rd class
      // July 13 (Monday) - 4th class
      // (July 17 (Friday) is outside active period since rule ends on July 15)
      await service.generateLiveClasses(
        courseId,
        rule.id,
        DateTime(2026, 7, 1),
        DateTime(2026, 7, 20),
      );

      final liveClassesSnap = await db
          .collection('courses')
          .doc(courseId)
          .collection('live_classes')
          .get();

      expect(liveClassesSnap.docs.length, equals(4));

      final List<DateTime> startTimes = liveClassesSnap.docs
          .map((doc) => (doc.data()['startTime'] as Timestamp).toDate())
          .toList()
        ..sort();

      expect(startTimes[0], equals(DateTime(2026, 7, 3, 10, 0)));
      expect(startTimes[1], equals(DateTime(2026, 7, 6, 10, 0)));
      expect(startTimes[2], equals(DateTime(2026, 7, 10, 10, 0)));
      expect(startTimes[3], equals(DateTime(2026, 7, 13, 10, 0)));

      // Check date strings
      final dateStrings = liveClassesSnap.docs
          .map((doc) => doc.data()['generatedDateString'] as String)
          .toSet();
      expect(dateStrings, containsAll(['2026-07-03', '2026-07-06', '2026-07-10', '2026-07-13']));

      // Check notification sent for this batch
      expect(notificationRepo.sentNotifications.length, equals(1));
      final notification = notificationRepo.sentNotifications.first;
      expect(notification['title'], equals('📺 New Classes Scheduled'));
      expect(notification['body'], contains('Test Flutter Course'));
      expect(notification['targetType'], equals(NotificationTargetType.liveClass));
      
      // Target ID should be the first class ID
      final firstClassId = liveClassesSnap.docs
          .firstWhere((doc) => doc.data()['generatedDateString'] == '2026-07-03')
          .id;
      expect(notification['targetId'], equals(firstClassId));
    });

    test('generateLiveClasses prevents duplicate class generation', () async {
      final rule = RecurringClassRule(
        id: 'rule_weekly_sat',
        courseId: courseId,
        title: 'Saturday Live Class',
        description: 'Saturday special',
        instructorId: 'inst_1',
        instructorName: 'John Doe',
        weekdays: [6], // Saturday
        startTime: '15:00',
        durationMinutes: 120,
        startDate: DateTime(2026, 7, 1),
        endDate: DateTime(2026, 7, 31),
      );

      await service.saveRecurringRule(courseId, rule);

      // First run: July 1 to July 15
      // Sat in July 1..15 are: July 4, July 11
      await service.generateLiveClasses(courseId, rule.id, DateTime(2026, 7, 1), DateTime(2026, 7, 15));

      final firstSnap = await db
          .collection('courses')
          .doc(courseId)
          .collection('live_classes')
          .get();
      expect(firstSnap.docs.length, equals(2));

      // Second run: July 1 to July 31
      // Sat in July 1..31 are: July 4, July 11, July 18, July 25
      // Run generation again. It should only generate classes for July 18 and July 25.
      await service.generateLiveClasses(courseId, rule.id, DateTime(2026, 7, 1), DateTime(2026, 7, 31));

      final secondSnap = await db
          .collection('courses')
          .doc(courseId)
          .collection('live_classes')
          .get();
      expect(secondSnap.docs.length, equals(4));

      final dateStrings = secondSnap.docs
          .map((doc) => doc.data()['generatedDateString'] as String)
          .toList()
        ..sort();
      expect(dateStrings, equals(['2026-07-04', '2026-07-11', '2026-07-18', '2026-07-25']));
    });

    test('updateLiveClassInstance reschedules individual instance and leaves others untouched', () async {
      final rule = RecurringClassRule(
        id: 'rule_weekly_sun',
        courseId: courseId,
        title: 'Sunday Live Class',
        description: 'Sunday special',
        instructorId: 'inst_1',
        instructorName: 'John Doe',
        weekdays: [7], // Sunday
        startTime: '11:00',
        durationMinutes: 60,
        startDate: DateTime(2026, 7, 1),
        endDate: DateTime(2026, 7, 31),
      );

      await service.saveRecurringRule(courseId, rule);

      // Sundays in July 2026: July 5, July 12, July 19, July 26
      await service.generateLiveClasses(courseId, rule.id, DateTime(2026, 7, 1), DateTime(2026, 7, 31));

      final snap = await db
          .collection('courses')
          .doc(courseId)
          .collection('live_classes')
          .get();
      expect(snap.docs.length, equals(4));

      // Find the class for July 12
      final july12Doc = snap.docs.firstWhere((doc) => doc.data()['generatedDateString'] == '2026-07-12');
      final classIdToUpdate = july12Doc.id;

      // Reschedule July 12 class to 2:00 PM and status to 'live'
      final newTime = DateTime(2026, 7, 12, 14, 0);
      await service.updateLiveClassInstance(
        courseId,
        classIdToUpdate,
        newStartTime: newTime,
        status: 'live',
      );

      // Verify updated class
      final updatedSnap = await db
          .collection('courses')
          .doc(courseId)
          .collection('live_classes')
          .doc(classIdToUpdate)
          .get();
      expect((updatedSnap.data()?['startTime'] as Timestamp).toDate(), equals(newTime));
      expect(updatedSnap.data()?['status'], equals('live'));

      // Verify another class (e.g. July 5) remains untouched
      final july5Doc = snap.docs.firstWhere((doc) => doc.data()['generatedDateString'] == '2026-07-05');
      final july5DocFresh = await db
          .collection('courses')
          .doc(courseId)
          .collection('live_classes')
          .doc(july5Doc.id)
          .get();
      expect((july5DocFresh.data()?['startTime'] as Timestamp).toDate(), equals(DateTime(2026, 7, 5, 11, 0)));
      expect(july5DocFresh.data()?['status'], equals('scheduled'));
    });

    test('generateLiveClasses correctly handles DST transitions without duplicate or skipped classes', () async {
      // DST transition (e.g., late October: October 20 to November 2, 2026)
      final rule = RecurringClassRule(
        id: 'rule_dst',
        courseId: courseId,
        title: 'DST Test Class',
        description: 'Testing DST transition boundaries',
        instructorId: 'inst_1',
        instructorName: 'John Doe',
        weekdays: [1, 2, 3, 4, 5, 6, 7], // Every day of the week
        startTime: '09:00',
        durationMinutes: 60,
        startDate: DateTime(2026, 10, 20),
        endDate: DateTime(2026, 11, 2),
      );

      await service.saveRecurringRule(courseId, rule);

      // Generate classes from Oct 20 to Nov 2 (14 days total)
      await service.generateLiveClasses(
        courseId,
        rule.id,
        DateTime(2026, 10, 20),
        DateTime(2026, 11, 2),
      );

      final liveClassesSnap = await db
          .collection('courses')
          .doc(courseId)
          .collection('live_classes')
          .get();

      // Filter classes generated by this rule
      final ruleClasses = liveClassesSnap.docs
          .where((doc) => doc.data()['parentRuleId'] == 'rule_dst')
          .toList();

      expect(ruleClasses.length, equals(14));

      final dateStrings = ruleClasses
          .map((doc) => doc.data()['generatedDateString'] as String)
          .toList()
        ..sort();

      final expectedDateStrings = [
        '2026-10-20',
        '2026-10-21',
        '2026-10-22',
        '2026-10-23',
        '2026-10-24',
        '2026-10-25', // Sunday (DST switch day usually)
        '2026-10-26',
        '2026-10-27',
        '2026-10-28',
        '2026-10-29',
        '2026-10-30',
        '2026-10-31',
        '2026-11-01',
        '2026-11-02',
      ];

      expect(dateStrings, equals(expectedDateStrings));
    });

    test('updateLiveClassInstance with status completed deletes live class and migrates to a lesson', () async {
      // 1. Setup: Create a live class instance in db
      const classId = 'live_class_complete_test';
      final classStartTime = DateTime(2026, 7, 12, 10, 0);
      
      final liveClass = AdminLiveClass(
        id: classId,
        title: 'Complete Me Class',
        description: 'This class will be completed',
        instructorName: 'John Doe',
        startTime: classStartTime,
        durationMinutes: 60,
        youtubeUrl: 'https://youtube.com/watch?v=123',
        thumbnailUrl: 'https://img.youtube.com/123.jpg',
        status: 'scheduled',
        createdAt: DateTime.now(),
        parentRuleId: 'rule_123',
        generatedDateString: '2026-07-12',
        linkedCourses: [courseId],
        subject: 'Physics',
        chapter: 'Kinematics',
        lectureNo: 5,
      );

      await db
          .collection('courses')
          .doc(courseId)
          .collection('live_classes')
          .doc(classId)
          .set(liveClass.toMap());

      // Verify it exists before completion
      final beforeSnap = await db
          .collection('courses')
          .doc(courseId)
          .collection('live_classes')
          .doc(classId)
          .get();
      expect(beforeSnap.exists, isTrue);

      // Verify no lessons exist initially
      final initialLessons = await db
          .collection('courses')
          .doc(courseId)
          .collection('lessons')
          .get();
      expect(initialLessons.docs.isEmpty, isTrue);

      // 2. Action: Call updateLiveClassInstance with status 'completed'
      await service.updateLiveClassInstance(
        courseId,
        classId,
        status: 'completed',
        newStartTime: DateTime(2026, 7, 12, 10, 5), // slightly updated time
      );

      // 3. Verification:
      // A. The live class document should be deleted from courses/{courseId}/live_classes
      final afterSnap = await db
          .collection('courses')
          .doc(courseId)
          .collection('live_classes')
          .doc(classId)
          .get();
      expect(afterSnap.exists, isFalse);

      // B. A lesson should be created under courses/{courseId}/lessons with correct fields mapped
      final afterLessons = await db
          .collection('courses')
          .doc(courseId)
          .collection('lessons')
          .get();
      expect(afterLessons.docs.length, equals(1));
      
      final lessonDoc = afterLessons.docs.first;
      expect(lessonDoc.data()['title'], equals('Complete Me Class'));
      expect(lessonDoc.data()['description'], equals('This class will be completed'));
      expect(lessonDoc.data()['type'], equals('video'));
      expect(lessonDoc.data()['storagePath'], equals('https://youtube.com/watch?v=123'));
      expect(lessonDoc.data()['subject'], equals('Physics'));
      expect(lessonDoc.data()['chapter'], equals('Kinematics'));
      expect(lessonDoc.data()['lectureNo'], equals(5));
      expect(lessonDoc.data()['orderIndex'], equals(0));
    });
  });
}
