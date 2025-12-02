import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/*
QA CHECKLIST for Edit Profile & StudyIQ AI Removal:

1. Edit Profile:
   - Launch app, go to Profile -> Edit Profile.
   - Change Name, Bio, and Avatar. Tap Save.
   - Verify Profile Header updates immediately with new data.
   - Restart app and verify changes persist.

2. Reset Profile:
   - Go to Edit Profile -> Tap "Reset to Defaults".
   - Verify Profile Header reverts to "Hi, Himanshu" and default avatar.

3. StudyIQ AI Removal:
   - Check Menu Grid: "StudyIQ AI" card should be gone.
   - Verify `lib/profile/screens/studyiq_ai_page.dart` is deleted.
   - Search codebase for "StudyIQ" - should only appear in this checklist or comments, not as functional code.
*/

class ProfileModel {
  final String fullName;
  final String headline;
  final String bio;
  final String medium; // Hinglish, Hindi, English
  final String avatarType; // 'emoji' or 'url'
  final String avatarValue; // emoji char or url string
  final int avatarColor; // color value for emoji background

  const ProfileModel({
    required this.fullName,
    required this.headline,
    required this.bio,
    required this.medium,
    required this.avatarType,
    required this.avatarValue,
    required this.avatarColor,
  });

  static const ProfileModel defaultProfile = ProfileModel(
    fullName: 'Hi, Himanshu',
    headline: 'Welcome to the Learning App',
    bio: '',
    medium: 'Hinglish',
    avatarType: 'emoji',
    avatarValue: '👤',
    avatarColor: 0xFFD1C4E9, // Colors.deepPurple[100]
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
    };
  }

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      fullName: json['fullName'] ?? defaultProfile.fullName,
      headline: json['headline'] ?? defaultProfile.headline,
      bio: json['bio'] ?? defaultProfile.bio,
      medium: json['medium'] ?? defaultProfile.medium,
      avatarType: json['avatarType'] ?? defaultProfile.avatarType,
      avatarValue: json['avatarValue'] ?? defaultProfile.avatarValue,
      avatarColor: json['avatarColor'] ?? defaultProfile.avatarColor,
    );
  }
}

class ProfileStorage {
  static const _key = 'user_profile_data';

  // TODO: Replace with backend API call
  static Future<void> saveProfile(ProfileModel model) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(model.toJson());
      await prefs.setString(_key, jsonString);
    } catch (e) {
      debugPrint('Error saving profile: $e');
      rethrow;
    }
  }

  // TODO: Replace with backend API call
  static Future<ProfileModel?> loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_key);
      if (jsonString != null) {
        return ProfileModel.fromJson(jsonDecode(jsonString));
      }
      return null;
    } catch (e) {
      debugPrint('Error loading profile: $e');
      return null;
    }
  }

  static Future<void> clearProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (e) {
      debugPrint('Error clearing profile: $e');
    }
  }
}
