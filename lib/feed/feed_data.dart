import 'package:flutter/material.dart';
import 'models.dart';

class FeedData {
  // ============================================================
  // TRENDING POSTS
  // ============================================================
  static final List<TrendingPost> trending = [
    TrendingPost(
      title: 'Master Essay Writing: Complete Guide for Civil Services',
      likes: '2.5k',
      comments: '384',
      emoji: '✍️',
      color: Colors.deepPurple,
    ),
    TrendingPost(
      title: 'India\'s Digital Revolution: Current Affairs Analysis',
      likes: '1.8k',
      comments: '256',
      emoji: '📱',
      color: Colors.blue,
    ),
    TrendingPost(
      title: 'Climate Change & Sustainable Development Goals',
      likes: '3.2k',
      comments: '512',
      emoji: '🌍',
      color: Colors.green,
    ),
    TrendingPost(
      title: 'Indian Economy: Budget Analysis 2025',
      likes: '2.1k',
      comments: '445',
      emoji: '💰',
      color: Colors.orange,
    ),
    TrendingPost(
      title: 'Constitution Day Special: Fundamental Rights',
      likes: '1.9k',
      comments: '298',
      emoji: '⚖️',
      color: Colors.indigo,
    ),
  ];

  // ============================================================
  // FEED ITEMS
  // ============================================================
  static final List<FeedItem> feedItems = [
    // ------------------------------
    // Answer Writing
    // ------------------------------
    FeedItem(
      type: ContentType.answerWriting,
      title: 'How to Write 250-word Answers Effectively',
      description:
      'Learn the art of structuring your UPSC mains answers with proper introduction, body, and conclusion. Master time management techniques.',
      categoryLabel: 'Answer Writing',
      emoji: '📝',
      color: Colors.purple,
    ),
    FeedItem(
      type: ContentType.answerWriting,
      title: 'Ethics Case Study: Dilemma Resolution Strategy',
      description:
      'Approach ethical dilemmas systematically using stakeholder analysis, ethical frameworks, and balanced recommendations.',
      categoryLabel: 'Answer Writing',
      emoji: '🤔',
      color: Colors.purple,
    ),

    // ------------------------------
    // Current Affairs
    // ------------------------------
    FeedItem(
      type: ContentType.currentAffairs,
      title: 'India\'s G20 Presidency: Key Outcomes',
      description:
      'Comprehensive analysis of India\'s successful G20 presidency, major achievements, and its global economic impact.',
      categoryLabel: 'Current Affairs',
      emoji: '🌐',
      color: Colors.blue,
    ),
    FeedItem(
      type: ContentType.currentAffairs,
      title: 'New Education Policy Implementation Update',
      description:
      'Latest developments in NEP 2020 rollout across states, challenges faced, and success stories from different institutions.',
      categoryLabel: 'Current Affairs',
      emoji: '📚',
      color: Colors.blue,
    ),

    // ------------------------------
    // Articles
    // ------------------------------
    FeedItem(
      type: ContentType.articles,
      title: 'Understanding India\'s Federal Structure',
      description:
      'Deep dive into constitutional provisions governing Centre-State relations, fiscal federalism, and cooperative federalism.',
      categoryLabel: 'Article',
      emoji: '📄',
      color: Colors.teal,
    ),
    FeedItem(
      type: ContentType.articles,
      title: 'Women Empowerment: Progress & Challenges',
      description:
      'Analyzing government initiatives, social changes, and persistent challenges in achieving gender equality in India.',
      categoryLabel: 'Article',
      emoji: '👩',
      color: Colors.teal,
    ),

    // ------------------------------
    // Videos
    // ------------------------------
    FeedItem(
      type: ContentType.videos,
      title: 'Ancient Indian History Crash Course',
      description:
      'Complete video series covering Indus Valley Civilization to Gupta Period. Includes maps and diagrams.',
      categoryLabel: 'Video',
      emoji: '🎥',
      color: Colors.red,
    ),
    FeedItem(
      type: ContentType.videos,
      title: 'Geography: Climate Patterns of India',
      description:
      'Visual explanation of monsoon mechanism, climate zones, and their impact on agriculture and economy.',
      categoryLabel: 'Video',
      emoji: '🌦️',
      color: Colors.red,
    ),

    // ------------------------------
    // Quizzes
    // ------------------------------
    FeedItem(
      type: ContentType.quizzes,
      title: 'Daily Current Affairs Quiz - Week 45',
      description:
      '20 questions covering national and international events. Includes solutions and concepts.',
      categoryLabel: 'Quiz',
      emoji: '❓',
      color: Colors.amber,
    ),
    FeedItem(
      type: ContentType.quizzes,
      title: 'Indian Polity: Fundamental Rights Quiz',
      description:
      'Practice MCQs on Articles 12-35 with case law references. Good for prelims revision.',
      categoryLabel: 'Quiz',
      emoji: '⚖️',
      color: Colors.amber,
    ),

    // ------------------------------
    // Jobs
    // ------------------------------
    FeedItem(
      type: ContentType.jobs,
      title: 'UPSC Civil Services 2025: Notification Out',
      description:
      '1000+ vacancies announced. Eligibility criteria, exam dates, syllabus changes, all in one place.',
      categoryLabel: 'Job Alert',
      emoji: '💼',
      color: Colors.green,
    ),
    FeedItem(
      type: ContentType.jobs,
      title: 'State PSC Combined Exam: Apply Now',
      description:
      'Multiple state PSC notifications released. Check exam pattern and preparation strategy.',
      categoryLabel: 'Job Alert',
      emoji: '📋',
      color: Colors.green,
    ),
  ];
}
