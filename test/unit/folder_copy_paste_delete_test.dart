import 'package:flutter_test/flutter_test.dart';
import 'package:eduverse/admin/services/firebase_admin_service.dart';
import '../e2e/harness/fake_firebase_firestore.dart';
import '../e2e/harness/fake_firebase_auth.dart';

void main() {
  group('Folder Copy, Paste, and Delete Tests', () {
    late FakeFirebaseFirestore db;
    late FakeFirebaseAuth auth;
    late FirebaseAdminService service;

    setUp(() {
      db = FakeFirebaseFirestore();
      auth = FakeFirebaseAuth();
      auth.changeCurrentUser(FakeUser(uid: 'admin_123'));
      service = FirebaseAdminService(auth: auth, db: db);
    });

    test('recursivelyDeleteFolder deletes all nested contents and the folder placeholder itself', () async {
      final courseId = 'course1';
      final subject = 'Physics';

      // 1. Create a parent folder placeholder
      final folderRef = db.collection('courses').doc(courseId).collection('lessons').doc('physics_folder');
      await folderRef.set({
        'title': 'Physics',
        'type': 'folder',
        'subject': subject,
        'chapter': '', // root
        'orderIndex': 0,
      });

      // 2. Create nested lecture video
      final lectureRef = db.collection('courses').doc(courseId).collection('lessons').doc('physics_lec1');
      await lectureRef.set({
        'title': 'Electrostatics Lec 1',
        'type': 'video',
        'subject': subject,
        'chapter': 'Physics',
        'orderIndex': 1,
      });

      // 3. Create a subfolder inside Physics
      final subFolderRef = db.collection('courses').doc(courseId).collection('lessons').doc('electrostatics_folder');
      await subFolderRef.set({
        'title': 'Electrostatics',
        'type': 'folder',
        'subject': subject,
        'chapter': 'Physics',
        'orderIndex': 2,
      });

      // 4. Create nested note under electrostatics_folder
      final noteRef = db.collection('courses').doc(courseId).collection('notes').doc('physics_note1');
      await noteRef.set({
        'title': 'Electrostatics Notes',
        'subject': subject,
        'chapter': 'Physics/Electrostatics',
        'lectureId': 'physics_lec1',
      });

      // 5. Create nested dpp under electrostatics_folder
      final dppRef = db.collection('courses').doc(courseId).collection('dpps').doc('physics_dpp1');
      await dppRef.set({
        'title': 'Electrostatics DPP',
        'subject': subject,
        'chapter': 'Physics/Electrostatics',
        'lectureId': 'physics_lec1',
      });

      // Assert they exist in firestore
      expect(db.data.containsKey('courses/$courseId/lessons/physics_folder'), isTrue);
      expect(db.data.containsKey('courses/$courseId/lessons/physics_lec1'), isTrue);
      expect(db.data.containsKey('courses/$courseId/lessons/electrostatics_folder'), isTrue);
      expect(db.data.containsKey('courses/$courseId/notes/physics_note1'), isTrue);
      expect(db.data.containsKey('courses/$courseId/dpps/physics_dpp1'), isTrue);

      // Now call recursivelyDeleteFolder on 'Physics'
      await service.recursivelyDeleteFolder(
        courseId: courseId,
        subject: subject,
        folderPath: 'Physics',
      );

      // Assert they are all deleted
      expect(db.data.containsKey('courses/$courseId/lessons/physics_folder'), isFalse);
      expect(db.data.containsKey('courses/$courseId/lessons/physics_lec1'), isFalse);
      expect(db.data.containsKey('courses/$courseId/lessons/electrostatics_folder'), isFalse);
      expect(db.data.containsKey('courses/$courseId/notes/physics_note1'), isFalse);
      expect(db.data.containsKey('courses/$courseId/dpps/physics_dpp1'), isFalse);
    });

    test('pasteFolder performs deep copy, maps linked IDs, and suppresses notifications', () async {
      final sourceCourseId = 'course_source';
      final targetCourseId = 'course_target';
      final sourceSubject = 'Chemistry';
      final targetSubject = 'Organic Chemistry';

      // Create initial folder structure in source course
      // Folder: Organic
      await db.collection('courses').doc(sourceCourseId).collection('lessons').doc('src_folder').set({
        'title': 'Organic',
        'type': 'folder',
        'subject': sourceSubject,
        'chapter': '',
        'orderIndex': 0,
      });

      // Lecture inside: src_lec (linked to src_note)
      await db.collection('courses').doc(sourceCourseId).collection('lessons').doc('src_lec').set({
        'title': 'Alkanes',
        'type': 'video',
        'subject': sourceSubject,
        'chapter': 'Organic',
        'orderIndex': 1,
        'linkedNoteIds': ['src_note'],
      });

      // Note inside: src_note (linked to src_lec)
      await db.collection('courses').doc(sourceCourseId).collection('notes').doc('src_note').set({
        'title': 'Alkanes Notes',
        'subject': sourceSubject,
        'chapter': 'Organic',
        'lectureId': 'src_lec',
      });

      // DPP inside: src_dpp (linked to src_lec)
      await db.collection('courses').doc(sourceCourseId).collection('dpps').doc('src_dpp').set({
        'title': 'Alkanes DPP',
        'subject': sourceSubject,
        'chapter': 'Organic',
        'lectureId': 'src_lec',
      });

      // Listen to course notifications collection to ensure notification suppression
      bool hasNotification = false;
      db.listeners.add(() {
        db.data.forEach((path, val) {
          if (path.contains('notifications')) {
            hasNotification = true;
          }
        });
      });

      // Perform paste
      await service.pasteFolder(
        sourceCourseId: sourceCourseId,
        sourceSubject: sourceSubject,
        sourceFolderPath: '',
        sourceFolderName: 'Organic',
        targetCourseId: targetCourseId,
        targetSubject: targetSubject,
        targetFolderPath: '',
        targetFolderName: 'Organic Copy',
      );

      // Verify notification suppression (no notifications document should be added)
      expect(hasNotification, isFalse);

      // Verify the copied documents exist in targetCourseId
      final targetLessons = db.data.entries.where((e) => e.key.startsWith('courses/$targetCourseId/lessons/')).toList();
      final targetNotes = db.data.entries.where((e) => e.key.startsWith('courses/$targetCourseId/notes/')).toList();
      final targetDpps = db.data.entries.where((e) => e.key.startsWith('courses/$targetCourseId/dpps/')).toList();

      expect(targetLessons.length, 2); // 1 folder placeholder + 1 lecture
      expect(targetNotes.length, 1);
      expect(targetDpps.length, 1);

      // Find the folder placeholder and lecture in target
      final copiedFolder = targetLessons.firstWhere((e) => e.value['type'] == 'folder').value;
      final copiedLecEntry = targetLessons.firstWhere((e) => e.value['type'] == 'video');
      final copiedLec = copiedLecEntry.value;
      final copiedLecId = copiedLecEntry.key.split('/').last;

      final copiedNoteEntry = targetNotes.first;
      final copiedNote = copiedNoteEntry.value;
      final copiedNoteId = copiedNoteEntry.key.split('/').last;

      final copiedDppEntry = targetDpps.first;
      final copiedDpp = copiedDppEntry.value;
      final copiedDppId = copiedDppEntry.key.split('/').last;

      expect(copiedDppId, isNotEmpty);

      // Verify folder details
      expect(copiedFolder['title'], 'Organic Copy');
      expect(copiedFolder['chapter'], '');
      expect(copiedFolder['subject'], targetSubject);

      // Verify lecture details
      expect(copiedLec['title'], 'Alkanes');
      expect(copiedLec['chapter'], 'Organic Copy');
      expect(copiedLec['subject'], targetSubject);
      // It should NOT reference the old note ID, but rather the newly mapped note ID
      expect(copiedLec['linkedNoteIds'], [copiedNoteId]);

      // Verify note details
      expect(copiedNote['title'], 'Alkanes Notes');
      expect(copiedNote['chapter'], 'Organic Copy');
      expect(copiedNote['subject'], targetSubject);
      expect(copiedNote['lectureId'], copiedLecId);

      // Verify DPP details
      expect(copiedDpp['title'], 'Alkanes DPP');
      expect(copiedDpp['chapter'], 'Organic Copy');
      expect(copiedDpp['subject'], targetSubject);
      expect(copiedDpp['lectureId'], copiedLecId);
    });

    test('deleteSubjectRecursive deletes all nested lessons, notes, and DPPs of that subject', () async {
      final courseId = 'course1';
      final subject = 'Physics';

      // Seed lessons, notes, and DPPs under 'Physics'
      await db.collection('courses').doc(courseId).collection('lessons').doc('phys_lec').set({
        'title': 'Mechanics Lec 1',
        'type': 'video',
        'subject': subject,
        'chapter': 'Mechanics',
        'orderIndex': 1,
      });

      await db.collection('courses').doc(courseId).collection('notes').doc('phys_note').set({
        'title': 'Mechanics Notes',
        'subject': subject,
        'chapter': 'Mechanics',
        'lectureId': 'phys_lec',
      });

      await db.collection('courses').doc(courseId).collection('dpps').doc('phys_dpp').set({
        'title': 'Mechanics DPP',
        'subject': subject,
        'chapter': 'Mechanics',
        'lectureId': 'phys_lec',
      });

      // Verify they exist
      expect(db.data.containsKey('courses/$courseId/lessons/phys_lec'), isTrue);
      expect(db.data.containsKey('courses/$courseId/notes/phys_note'), isTrue);
      expect(db.data.containsKey('courses/$courseId/dpps/phys_dpp'), isTrue);

      // Perform deletion
      await service.deleteSubjectRecursive(
        courseId: courseId,
        subject: subject,
      );

      // Verify they are deleted
      expect(db.data.containsKey('courses/$courseId/lessons/phys_lec'), isFalse);
      expect(db.data.containsKey('courses/$courseId/notes/phys_note'), isFalse);
      expect(db.data.containsKey('courses/$courseId/dpps/phys_dpp'), isFalse);
    });

    test('pasteSubject duplicates all items under the target subject, maps linked IDs, and registers the subject', () async {
      final sourceCourseId = 'course_src';
      final targetCourseId = 'course_tgt';
      final sourceSubject = 'Biology';
      final targetSubject = 'Genetics';

      // Seed source items
      await db.collection('courses').doc(sourceCourseId).collection('lessons').doc('bio_lec').set({
        'title': 'Mitosis',
        'type': 'video',
        'subject': sourceSubject,
        'chapter': 'Cell Division',
        'orderIndex': 1,
        'linkedNoteIds': ['bio_note'],
      });

      await db.collection('courses').doc(sourceCourseId).collection('notes').doc('bio_note').set({
        'title': 'Mitosis Notes',
        'subject': sourceSubject,
        'chapter': 'Cell Division',
        'lectureId': 'bio_lec',
      });

      await db.collection('courses').doc(sourceCourseId).collection('dpps').doc('bio_dpp').set({
        'title': 'Mitosis DPP',
        'subject': sourceSubject,
        'chapter': 'Cell Division',
        'lectureId': 'bio_lec',
      });

      // Perform paste
      await service.pasteSubject(
        sourceCourseId: sourceCourseId,
        sourceSubject: sourceSubject,
        targetCourseId: targetCourseId,
        targetSubject: targetSubject,
      );

      // Verify global subject registration
      final globalSubjectDoc = await db.collection('quiz_subjects').doc(targetSubject).get();
      expect(globalSubjectDoc.exists, isTrue);

      // Verify duplicated items in targetCourseId
      final targetLessons = db.data.entries.where((e) => e.key.startsWith('courses/$targetCourseId/lessons/')).toList();
      final targetNotes = db.data.entries.where((e) => e.key.startsWith('courses/$targetCourseId/notes/')).toList();
      final targetDpps = db.data.entries.where((e) => e.key.startsWith('courses/$targetCourseId/dpps/')).toList();

      expect(targetLessons.length, 1);
      expect(targetNotes.length, 1);
      expect(targetDpps.length, 1);

      final copiedLecEntry = targetLessons.first;
      final copiedLec = copiedLecEntry.value;
      final copiedLecId = copiedLecEntry.key.split('/').last;

      final copiedNoteEntry = targetNotes.first;
      final copiedNote = copiedNoteEntry.value;
      final copiedNoteId = copiedNoteEntry.key.split('/').last;

      final copiedDppEntry = targetDpps.first;
      final copiedDpp = copiedDppEntry.value;

      expect(copiedLec['subject'], targetSubject);
      expect(copiedLec['chapter'], 'Cell Division');
      expect(copiedLec['linkedNoteIds'], [copiedNoteId]);

      expect(copiedNote['subject'], targetSubject);
      expect(copiedNote['chapter'], 'Cell Division');
      expect(copiedNote['lectureId'], copiedLecId);

      expect(copiedDpp['subject'], targetSubject);
      expect(copiedDpp['chapter'], 'Cell Division');
      expect(copiedDpp['lectureId'], copiedLecId);
    });
  });
}
