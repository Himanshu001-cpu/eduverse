import 'package:flutter/material.dart';
import 'package:eduverse/study/models/study_models.dart';

// --- MOCK DATA ---

class StudyData {
  static const List<ContinueLearningModel> continueLearning = [
    ContinueLearningModel(id: 'cl1', title: 'Polity Basics', emoji: '🏛️', progress: 0.75),
    ContinueLearningModel(id: 'cl2', title: 'Economy 101', emoji: '💰', progress: 0.30),
    ContinueLearningModel(id: 'cl3', title: 'Modern History', emoji: '📜', progress: 0.10),
  ];

  static const List<StudyCourseModel> userCourses = [
    StudyCourseModel(
      id: 'c1',
      title: 'UPSC Foundation',
      subtitle: '120 lessons',
      emoji: '🏛️',
      gradientColors: [Colors.blue, Colors.lightBlueAccent],
      lessonCount: 120,
      progress: 0.45,
    ),
    StudyCourseModel(
      id: 'c2',
      title: 'CSAT Mastery',
      subtitle: '45 lessons',
      emoji: '🧮',
      gradientColors: [Colors.orange, Colors.deepOrangeAccent],
      lessonCount: 45,
      progress: 0.10,
    ),
    StudyCourseModel(
      id: 'c3',
      title: 'NCERT Summary',
      subtitle: '60 lessons',
      emoji: '📚',
      gradientColors: [Colors.green, Colors.teal],
      lessonCount: 60,
      progress: 0.80,
    ),
    StudyCourseModel(
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
      id: 'dp1',
      title: 'Daily Quiz',
      description: '10 Questions',
      icon: Icons.quiz,
      colorValue: 0xFF9C27B0, // Colors.purple.value
    ),
    DailyPracticeModel(
      id: 'dp2',
      title: 'Mains Answer',
      description: '1 Question',
      icon: Icons.edit_note,
      colorValue: 0xFF2196F3, // Colors.blue.value
    ),
    DailyPracticeModel(
      id: 'dp3',
      title: 'Vocab',
      description: '5 Words',
      icon: Icons.book,
      colorValue: 0xFFFF9800, // Colors.orange.value
    ),
    DailyPracticeModel(
      id: 'dp4',
      title: 'Map Work',
      description: 'India Map',
      icon: Icons.map,
      colorValue: 0xFF4CAF50, // Colors.green.value
    ),
  ];

  static final List<LiveClassModel> liveClasses = [
    LiveClassModel(
      id: 'lc1',
      title: 'Current Affairs Analysis',
      dateTime: DateTime.now().add(const Duration(minutes: 5)),
      emoji: '📰',
    ),
    LiveClassModel(
      id: 'lc2',
      title: 'Geography Mapping',
      dateTime: DateTime.now().add(const Duration(hours: 4)),
      emoji: '🌍',
    ),
    LiveClassModel(
      id: 'lc3',
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
    TopicNodeModel(id: 'tp1', title: 'Polity', description: 'Constitution & Governance', colorValue: 0xFF2196F3),
    TopicNodeModel(id: 'tp2', title: 'History', description: 'Ancient, Medieval, Modern', colorValue: 0xFFFF9800),
    TopicNodeModel(id: 'tp3', title: 'Geography', description: 'Physical & Human', colorValue: 0xFF4CAF50),
    TopicNodeModel(id: 'tp4', title: 'Economy', description: 'Macro & Micro', colorValue: 0xFF9C27B0),
    TopicNodeModel(id: 'tp5', title: 'Science', description: 'Physics, Chem, Bio', colorValue: 0xFFF44336),
    TopicNodeModel(id: 'tp6', title: 'Environment', description: 'Ecology & Biodiversity', colorValue: 0xFF009688),
  ];

  static final List<WorkbookModel> workbooks = [
    WorkbookModel(
      id: 'w1',
      userId: 'user1',
      title: 'Answer Writing Week 1',
      dueDate: DateTime.now().add(const Duration(days: 2)),
      status: 'In Progress',
      progress: 0.4,
      tasks: [TaskModel(id: 'tk1', title: 'Read Chapter 1'), TaskModel(id: 'tk2', title: 'Write Summary')],
    ),
    WorkbookModel(
      id: 'w2',
      userId: 'user1',
      title: 'Map Marking Assignment',
      dueDate: DateTime.now().subtract(const Duration(days: 1)),
      status: 'Overdue',
      progress: 0.0,
      tasks: [TaskModel(id: 'tk3', title: 'Mark Rivers'), TaskModel(id: 'tk4', title: 'Mark Mountains')],
    ),
    WorkbookModel(
      id: 'w3',
      userId: 'user1',
      title: 'Ethics Case Study 1',
      dueDate: DateTime.now().add(const Duration(days: 5)),
      status: 'Not Started',
      progress: 0.0,
      tasks: [TaskModel(id: 'tk5', title: 'Analyze Case'), TaskModel(id: 'tk6', title: 'Draft Solution')],
    ),
    WorkbookModel(
      id: 'w4',
      userId: 'user1',
      title: 'Essay Writing',
      dueDate: DateTime.now().subtract(const Duration(days: 5)),
      status: 'Submitted',
      progress: 1.0,
      tasks: [TaskModel(id: 'tk7', title: 'Brainstorm'), TaskModel(id: 'tk8', title: 'Write Essay', isCompleted: true)],
    ),
  ];
}
