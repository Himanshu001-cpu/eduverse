import 'package:flutter/material.dart';

// --- MODELS ---

class ContinueLearningModel {
  final String title;
  final String emoji;
  final double progress; // 0.0 to 1.0

  const ContinueLearningModel({
    required this.title,
    required this.emoji,
    required this.progress,
  });
}

class CourseModel {
  final String id;
  final String title;
  final String subtitle;
  final String emoji;
  final List<Color> gradientColors;
  final int lessonCount;
  final double progress;

  const CourseModel({
    required this.id,
    required this.title,
    required this.subtitle,
    this.emoji = '📚',
    required this.gradientColors,
    this.lessonCount = 0,
    this.progress = 0.0,
  });
}

class DailyPracticeModel {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const DailyPracticeModel({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

class LiveClassModel {
  final String title;
  final DateTime dateTime;
  final String emoji;

  const LiveClassModel({
    required this.title,
    required this.dateTime,
    required this.emoji,
  });
}

class QuestionModel {
  final String id;
  final String text;
  final List<String> options;
  final int answerIndex;
  final String explanation;

  const QuestionModel({
    required this.id,
    required this.text,
    required this.options,
    required this.answerIndex,
    required this.explanation,
  });
}

class TestModel {
  final String id;
  final String title;
  final String duration;
  final String difficulty;
  final int questionCount;
  final int bestScore;
  final List<QuestionModel> questions;

  const TestModel({
    required this.id,
    required this.title,
    required this.duration,
    required this.difficulty,
    this.questionCount = 50,
    this.bestScore = 0,
    this.questions = const [],
  });
}

class TopicNodeModel {
  final String id;
  final String title;
  final String description;
  final Color color;

  const TopicNodeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.color,
  });
}

class TaskModel {
  final String id;
  final String title;
  bool isCompleted;

  TaskModel({
    required this.id,
    required this.title,
    this.isCompleted = false,
  });
}

class WorkbookModel {
  final String id;
  final String title;
  final DateTime dueDate;
  final String status; // Not Started, In Progress, Submitted
  final double progress;
  final List<TaskModel> tasks;

  const WorkbookModel({
    required this.id,
    required this.title,
    required this.dueDate,
    required this.status,
    required this.progress,
    this.tasks = const [],
  });
}

// --- MOCK DATA ---

class StudyData {
  static const List<ContinueLearningModel> continueLearning = [
    ContinueLearningModel(title: 'Polity Basics', emoji: '🏛️', progress: 0.75),
    ContinueLearningModel(title: 'Economy 101', emoji: '💰', progress: 0.30),
    ContinueLearningModel(title: 'Modern History', emoji: '📜', progress: 0.10),
  ];

  static const List<CourseModel> userCourses = [
    CourseModel(
      id: 'c1',
      title: 'UPSC Foundation',
      subtitle: '120 lessons',
      emoji: '🏛️',
      gradientColors: [Colors.blue, Colors.lightBlueAccent],
      lessonCount: 120,
      progress: 0.45,
    ),
    CourseModel(
      id: 'c2',
      title: 'CSAT Mastery',
      subtitle: '45 lessons',
      emoji: '🧮',
      gradientColors: [Colors.orange, Colors.deepOrangeAccent],
      lessonCount: 45,
      progress: 0.10,
    ),
    CourseModel(
      id: 'c3',
      title: 'NCERT Summary',
      subtitle: '60 lessons',
      emoji: '📚',
      gradientColors: [Colors.green, Colors.teal],
      lessonCount: 60,
      progress: 0.80,
    ),
    CourseModel(
      id: 'c4',
      title: 'Ethics & Integrity',
      subtitle: '30 lessons',
      emoji: '⚖️',
      gradientColors: [Colors.purple, Colors.deepPurpleAccent],
      lessonCount: 30,
      progress: 0.0,
    ),
  ];

  static const List<DailyPracticeModel> dailyPractice = [
    DailyPracticeModel(
      title: 'Daily Quiz',
      description: '10 Questions',
      icon: Icons.quiz,
      color: Colors.purple,
    ),
    DailyPracticeModel(
      title: 'Mains Answer',
      description: '1 Question',
      icon: Icons.edit_note,
      color: Colors.blue,
    ),
    DailyPracticeModel(
      title: 'Vocab',
      description: '5 Words',
      icon: Icons.book,
      color: Colors.orange,
    ),
    DailyPracticeModel(
      title: 'Map Work',
      description: 'India Map',
      icon: Icons.map,
      color: Colors.green,
    ),
  ];

  static final List<LiveClassModel> liveClasses = [
    LiveClassModel(
      title: 'Current Affairs Analysis',
      dateTime: DateTime.now().add(const Duration(minutes: 5)),
      emoji: '📰',
    ),
    LiveClassModel(
      title: 'Geography Mapping',
      dateTime: DateTime.now().add(const Duration(hours: 4)),
      emoji: '🌍',
    ),
    LiveClassModel(
      title: 'Ethics Case Studies',
      dateTime: DateTime.now().add(const Duration(days: 1, hours: 10)),
      emoji: '⚖️',
    ),
  ];

  static const List<QuestionModel> _sampleQuestions = [
    QuestionModel(
      id: 'q1',
      text: 'Which Article of the Indian Constitution deals with the Uniform Civil Code?',
      options: ['Article 44', 'Article 45', 'Article 40', 'Article 51A'],
      answerIndex: 0,
      explanation: 'Article 44 of the Directive Principles of State Policy states that the State shall endeavor to secure for the citizens a Uniform Civil Code throughout the territory of India.',
    ),
    QuestionModel(
      id: 'q2',
      text: 'Who is known as the Father of the Indian Constitution?',
      options: ['Mahatma Gandhi', 'Jawaharlal Nehru', 'B.R. Ambedkar', 'Sardar Patel'],
      answerIndex: 2,
      explanation: 'Dr. B.R. Ambedkar was the Chairman of the Drafting Committee and is considered the chief architect of the Indian Constitution.',
    ),
    QuestionModel(
      id: 'q3',
      text: 'Which planet is known as the Red Planet?',
      options: ['Venus', 'Mars', 'Jupiter', 'Saturn'],
      answerIndex: 1,
      explanation: 'Mars appears red due to the presence of iron oxide on its surface.',
    ),
  ];

  static const List<TestModel> mockTests = [
    TestModel(
      id: 't1',
      title: 'Polity Full Test',
      difficulty: 'Hard',
      duration: '2 Hrs',
      questionCount: 100,
      bestScore: 85,
      questions: _sampleQuestions,
    ),
    TestModel(
      id: 't2',
      title: 'Economy Sectional',
      difficulty: 'Medium',
      duration: '1 Hr',
      questionCount: 50,
      bestScore: 0,
      questions: _sampleQuestions,
    ),
    TestModel(
      id: 't3',
      title: 'History Quick Test',
      difficulty: 'Easy',
      duration: '30 Mins',
      questionCount: 25,
      bestScore: 20,
      questions: _sampleQuestions,
    ),
  ];

  static const List<TopicNodeModel> mapTopics = [
    TopicNodeModel(id: 'tp1', title: 'Polity', description: 'Constitution & Governance', color: Colors.blue),
    TopicNodeModel(id: 'tp2', title: 'History', description: 'Ancient, Medieval, Modern', color: Colors.orange),
    TopicNodeModel(id: 'tp3', title: 'Geography', description: 'Physical & Human', color: Colors.green),
    TopicNodeModel(id: 'tp4', title: 'Economy', description: 'Macro & Micro', color: Colors.purple),
    TopicNodeModel(id: 'tp5', title: 'Science', description: 'Physics, Chem, Bio', color: Colors.red),
    TopicNodeModel(id: 'tp6', title: 'Environment', description: 'Ecology & Biodiversity', color: Colors.teal),
  ];

  static final List<WorkbookModel> workbooks = [
    WorkbookModel(
      id: 'w1',
      title: 'Answer Writing Week 1',
      dueDate: DateTime.now().add(const Duration(days: 2)),
      status: 'In Progress',
      progress: 0.4,
      tasks: [TaskModel(id: 'tk1', title: 'Read Chapter 1'), TaskModel(id: 'tk2', title: 'Write Summary')],
    ),
    WorkbookModel(
      id: 'w2',
      title: 'Map Marking Assignment',
      dueDate: DateTime.now().subtract(const Duration(days: 1)),
      status: 'Overdue',
      progress: 0.0,
      tasks: [TaskModel(id: 'tk3', title: 'Mark Rivers'), TaskModel(id: 'tk4', title: 'Mark Mountains')],
    ),
    WorkbookModel(
      id: 'w3',
      title: 'Ethics Case Study 1',
      dueDate: DateTime.now().add(const Duration(days: 5)),
      status: 'Not Started',
      progress: 0.0,
      tasks: [TaskModel(id: 'tk5', title: 'Analyze Case'), TaskModel(id: 'tk6', title: 'Draft Solution')],
    ),
    WorkbookModel(
      id: 'w4',
      title: 'Essay Writing',
      dueDate: DateTime.now().subtract(const Duration(days: 5)),
      status: 'Submitted',
      progress: 1.0,
      tasks: [TaskModel(id: 'tk7', title: 'Brainstorm'), TaskModel(id: 'tk8', title: 'Write Essay', isCompleted: true)],
    ),
  ];
}
