import 'package:eduverse/study/models/study_models.dart';

// Data is now fetched from Firestore - this file only contains empty lists for compatibility

class StudyData {
  // Continue learning items now come from user progress in Firestore
  static const List<ContinueLearningModel> continueLearning = [];

  // User courses now come from purchases/enrollments in Firestore
  static const List<StudyCourseModel> userCourses = [];

  // Daily practice items - can be managed via Firestore
  static const List<DailyPracticeModel> dailyPractice = [
    DailyPracticeModel(
      id: 'dp1',
      title: 'Daily Quiz',
      description: '10 Questions',
      iconName: 'quiz',
      colorValue: 0xFF9C27B0,
    ),
    DailyPracticeModel(
      id: 'dp2',
      title: 'Mains Answer',
      description: '1 Question',
      iconName: 'edit',
      colorValue: 0xFF2196F3,
    ),
    DailyPracticeModel(
      id: 'dp3',
      title: 'Vocab',
      description: '5 Words',
      iconName: 'book',
      colorValue: 0xFFFF9800,
    ),
    DailyPracticeModel(
      id: 'dp4',
      title: 'Map Work',
      description: 'India Map',
      iconName: 'extension',
      colorValue: 0xFF4CAF50,
    ),
  ];

  // Live classes now come from Firestore
  static final List<LiveClassModel> liveClasses = [];

  // Mock tests now come from Firestore
  static const List<TestModel> mockTests = [];

  // Map topics now come from Firestore
  static const List<TopicNodeModel> mapTopics = [];

  // Workbooks are user-specific and stored in Firestore
  static final List<WorkbookModel> workbooks = [];
}
