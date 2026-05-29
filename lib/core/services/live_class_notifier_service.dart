import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:eduverse/study/domain/models/study_entities.dart';

class ActiveLiveClass {
  final StudyLiveClass liveClass;
  final String courseId;
  final String batchId;

  ActiveLiveClass({
    required this.liveClass,
    required this.courseId,
    required this.batchId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActiveLiveClass &&
          runtimeType == other.runtimeType &&
          liveClass.id == other.liveClass.id &&
          courseId == other.courseId &&
          batchId == other.batchId;

  @override
  int get hashCode => liveClass.id.hashCode ^ courseId.hashCode ^ batchId.hashCode;
}

class LiveClassNotifierService extends ChangeNotifier {
  static final LiveClassNotifierService _instance = LiveClassNotifierService._internal();
  factory LiveClassNotifierService() => _instance;
  LiveClassNotifierService._internal() {
    _init();
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  StreamSubscription? _authSubscription;
  StreamSubscription? _enrollmentSubscription;
  final Map<String, StreamSubscription> _liveClassSubscriptions = {};

  List<ActiveLiveClass> _activeClasses = [];
  List<ActiveLiveClass> get activeClasses => _activeClasses;

  void _init() {
    _authSubscription = _auth.authStateChanges().listen((user) {
      if (user == null) {
        _cleanup();
      } else {
        _listenToEnrollments(user.uid);
      }
    });
  }

  void _listenToEnrollments(String uid) {
    _enrollmentSubscription?.cancel();
    _enrollmentSubscription = _firestore
        .collection('users')
        .doc(uid)
        .collection('enrolledCourses')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .listen((enrollmentSnap) {
      final Set<String> activeKeys = {};
      
      for (final doc in enrollmentSnap.docs) {
        final data = doc.data();
        final courseId = data['courseId'] as String?;
        final batchId = data['batchId'] as String?;
        if (courseId == null || batchId == null) continue;

        final key = '${courseId}___$batchId';
        activeKeys.add(key);

        if (!_liveClassSubscriptions.containsKey(key)) {
          _subscribeToLiveClasses(courseId, batchId, key);
        }
      }

      // Cancel subscriptions for batches the user is no longer enrolled in
      final keysToRemove = _liveClassSubscriptions.keys.where((k) => !activeKeys.contains(k)).toList();
      for (final key in keysToRemove) {
        _liveClassSubscriptions[key]?.cancel();
        _liveClassSubscriptions.remove(key);
        // Clear active classes associated with this batch
        _activeClasses.removeWhere((ac) => '${ac.courseId}___${ac.batchId}' == key);
      }
      notifyListeners();
    });
  }

  void _subscribeToLiveClasses(String courseId, String batchId, String key) {
    _liveClassSubscriptions[key] = _firestore
        .collection('courses')
        .doc(courseId)
        .collection('batches')
        .doc(batchId)
        .collection('live_classes')
        .where('status', isEqualTo: 'live')
        .snapshots()
        .listen((classSnap) {
      // Remove previous active classes for this batch
      _activeClasses.removeWhere((ac) => ac.courseId == courseId && ac.batchId == batchId);

      for (final doc in classSnap.docs) {
        final data = doc.data();
        final liveClass = _mapToStudyLiveClass(doc.id, data);
        _activeClasses.add(ActiveLiveClass(
          liveClass: liveClass,
          courseId: courseId,
          batchId: batchId,
        ));
      }

      notifyListeners();
    });
  }

  StudyLiveClass _mapToStudyLiveClass(String id, Map<String, dynamic> data) {
    return StudyLiveClass(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      instructorName: data['instructorName'] ?? '',
      startTime: (data['startTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      durationMinutes: data['durationMinutes'] ?? 60,
      status: data['status'] ?? 'upcoming',
      youtubeUrl: data['youtubeUrl'],
      thumbnailUrl: data['thumbnailUrl'] ?? '',
      subject: data['subject'] ?? '',
      chapter: data['chapter'] ?? '',
    );
  }

  void _cleanup() {
    _enrollmentSubscription?.cancel();
    _enrollmentSubscription = null;
    for (final sub in _liveClassSubscriptions.values) {
      sub.cancel();
    }
    _liveClassSubscriptions.clear();
    _activeClasses.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _cleanup();
    super.dispose();
  }
}
