import 'package:flutter/material.dart';
import 'models/store_models.dart';

class StoreData {
  // -------------------------
  // BANNERS
  // -------------------------
  static final List<StoreBanner> banners = [
    StoreBanner(
      title: 'New Batch Alert!',
      subtitle: 'UPSC 2027 Foundation Course Starting Soon',
      emoji: '🎯',
      colors: [
        Colors.purpleAccent,
        Colors.deepPurple,
      ],
    ),
    StoreBanner(
      title: 'Limited Seats',
      subtitle: 'Prelims 2025 Crash Course - Enroll Now',
      emoji: '⚡',
      colors: [
        Colors.orange,
        Colors.deepOrange,
      ],
    ),
    StoreBanner(
      title: 'Expert Faculty',
      subtitle: 'Optional Subjects with Top Rankers',
      emoji: '👨‍🏫',
      colors: [
        Colors.blueAccent,
        Colors.indigo,
      ],
    ),
    StoreBanner(
      title: 'Study Anytime',
      subtitle: 'Record + Live Classes Available',
      emoji: '📱',
      colors: [
        Colors.teal,
        Colors.green,
      ],
    ),
  ];

  // -------------------------
  // HINGLISH BATCHES
  // -------------------------
  static final List<Course> hinglishBatches = [
    Course(
      title: 'UPSC CSE 2026 - Complete Foundation to Advanced',
      batchInfo: 'Hinglish Medium | Live + Recorded',
      metadata: 'Batch Starting: 1st Dec 2025',
      emoji: '📚',
      colors: [Colors.purple, Colors.deepPurple],
      tag: 'NEW',
    ),
    Course(
      title: 'Prelims to Mains Complete Course',
      batchInfo: 'GS + CSAT + Optional',
      metadata: 'Admissions Closing: 25th Nov 2025',
      emoji: '🎓',
      colors: [Colors.indigo, Colors.blue],
    ),
    Course(
      title: 'Foundation Batch for Beginners',
      batchInfo: 'Hinglish Medium | 18 Months Program',
      metadata: 'Batch Starting: 15th Dec 2025',
      emoji: '🌟',
      colors: [Colors.pink, Colors.purple],
    ),
  ];

  // -------------------------
  // TARGET 2027
  // -------------------------
  static final List<Course> target2027 = [
    Course(
      title: 'UPSC 2027 Long Term Strategy Course',
      batchInfo: 'Comprehensive 24 Months Mentorship',
      metadata: 'Early Bird Offer Till: 30th Nov',
      emoji: '🎯',
      colors: [Colors.orange, Colors.deepOrange],
      tag: 'POPULAR',
    ),
    Course(
      title: 'Foundation + Current Affairs 2027',
      batchInfo: 'Daily Updates + Weekly Tests',
      metadata: 'Batch Starting: 5th Jan 2026',
      emoji: '📰',
      colors: [Colors.blue, Colors.indigo],
    ),
    Course(
      title: 'Complete Prelims + Mains 2027',
      batchInfo: 'All Subjects Covered | Expert Faculty',
      metadata: 'Registrations Open Now',
      emoji: '✍️',
      colors: [Colors.teal, Colors.green],
    ),
  ];

  // -------------------------
  // OPTIONAL BATCHES
  // -------------------------
  static final List<Course> optionalBatches = [
    Course(
      title: 'Geography Optional - Complete Course',
      batchInfo: 'Paper 1 + Paper 2 | Maps Included',
      metadata: 'Batch Starting: 10th Dec 2025',
      emoji: '🗺️',
      colors: [Colors.green, Colors.teal],
      tag: 'TOP RATED',
    ),
    Course(
      title: 'Public Administration Optional',
      batchInfo: 'Theory + Case Studies',
      metadata: 'Admissions Closing: 20th Nov',
      emoji: '🏛️',
      colors: [Colors.blue, Colors.lightBlue],
    ),
    Course(
      title: 'History Optional - Ancient to Modern',
      batchInfo: 'Comprehensive Coverage | Notes',
      metadata: 'Batch Starting: 1st Jan 2026',
      emoji: '📜',
      colors: [Colors.amber, Colors.orange],
    ),
  ];
}
