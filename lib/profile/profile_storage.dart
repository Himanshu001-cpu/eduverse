import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/*
QA CHECKLIST for Edit Profile & StudyIQ AI Removal:

1. Edit Profile:
   - Launch app, go to Profile -> Edit Profile.
   - Change Name, Bio, and Avatar. Tap Save.
   - Verify Profile Header updates immediately with new data.
   - Restart app and verify changes persist.

2. Reset Profile:
   - Go to Edit Profile -> Tap "Reset to Defaults".
   - Verify Profile Header reverts to default name and avatar.

3. Firebase Sync:
   - Profile changes should sync to Firestore users/{uid}/profile
   - Profile should load from Firebase on app start
*/

class ProfileModel {
  final String fullName;
  final String headline;
  final String bio;
  final String medium; // Hinglish, Hindi, English
  final String avatarType; // 'emoji' or 'url'
  final String avatarValue; // emoji char or url string
  final int avatarColor; // color value for emoji background
  final String? email;
  final String? phone;

  const ProfileModel({
    required this.fullName,
    required this.headline,
    required this.bio,
    required this.medium,
    required this.avatarType,
    required this.avatarValue,
    required this.avatarColor,
    this.email,
    this.phone,
  });

  static ProfileModel defaultProfile = ProfileModel(
    fullName: FirebaseAuth.instance.currentUser?.displayName ?? 'User',
    headline: 'Welcome to the Learning App',
    bio: '',
    medium: 'Hinglish',
    avatarType: 'emoji',
    avatarValue: '👤',
    avatarColor: 0xFFD1C4E9, // Colors.deepPurple[100]
    email: FirebaseAuth.instance.currentUser?.email,
    phone: FirebaseAuth.instance.currentUser?.phoneNumber,
  );

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'headline': headline,
      'bio': bio,
      'medium': medium,
      'avatarType': avatarType,
      'avatarValue': avatarValue,
      'avatarColor': avatarColor,
      'email': email,
      'phone': phone,
    };
  }

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    final user = FirebaseAuth.instance.currentUser;
    return ProfileModel(
      fullName: json['fullName'] ?? user?.displayName ?? 'User',
      headline: json['headline'] ?? 'Welcome to the Learning App',
      bio: json['bio'] ?? '',
      medium: json['medium'] ?? 'Hinglish',
      avatarType: json['avatarType'] ?? 'emoji',
      avatarValue: json['avatarValue'] ?? '👤',
      avatarColor: json['avatarColor'] ?? 0xFFD1C4E9,
      email: json['email'] ?? user?.email,
      phone: json['phone'] ?? user?.phoneNumber,
    );
  }
}

class ProfileStorage {
  static const _localKey = 'user_profile_data';
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Save profile to Firebase Firestore
  static Future<void> saveProfile(ProfileModel model) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Save to Firestore
        await _firestore.collection('users').doc(user.uid).set(
          {'profile': model.toJson()},
          SetOptions(merge: true),
        );
      }
      
      // Also save locally as cache/fallback
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(model.toJson());
      await prefs.setString(_localKey, jsonString);
    } catch (e) {
      debugPrint('Error saving profile: $e');
      rethrow;
    }
  }

  /// Load profile from Firebase Firestore (with local fallback)
  static Future<ProfileModel?> loadProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      
      // Try to load from Firestore first
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists && doc.data()?['profile'] != null) {
          final profileData = doc.data()!['profile'] as Map<String, dynamic>;
          return ProfileModel.fromJson(profileData);
        }
        
        // No profile in Firestore - create one from Firebase Auth data
        return ProfileModel(
          fullName: user.displayName ?? 'User',
          headline: 'Welcome to the Learning App',
          bio: '',
          medium: 'Hinglish',
          avatarType: 'emoji',
          avatarValue: '👤',
          avatarColor: 0xFFD1C4E9,
          email: user.email,
          phone: user.phoneNumber,
        );
      }
      
      // Fallback to local storage if not logged in
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_localKey);
      if (jsonString != null) {
        return ProfileModel.fromJson(jsonDecode(jsonString));
      }
      return null;
    } catch (e) {
      debugPrint('Error loading profile: $e');
      return null;
    }
  }

  /// Stream profile changes from Firestore
  static Stream<ProfileModel?> profileStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.value(null);
    }
    
    return _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data()?['profile'] != null) {
        return ProfileModel.fromJson(doc.data()!['profile']);
      }
      return ProfileModel(
        fullName: user.displayName ?? 'User',
        headline: 'Welcome to the Learning App',
        bio: '',
        medium: 'Hinglish',
        avatarType: 'emoji',
        avatarValue: '👤',
        avatarColor: 0xFFD1C4E9,
        email: user.email,
        phone: user.phoneNumber,
      );
    });
  }

  static Future<void> clearProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_localKey);
    } catch (e) {
      debugPrint('Error clearing profile: $e');
    }
  }
}
