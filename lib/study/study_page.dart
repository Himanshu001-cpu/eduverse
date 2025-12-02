// file: lib/study/study_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:eduverse/study/study_data.dart';
import 'package:eduverse/study/widgets/study_header.dart';
import 'package:eduverse/study/widgets/study_section.dart';
import 'package:eduverse/study/widgets/study_card.dart';
import 'package:eduverse/study/screens/my_courses_page.dart';
import 'package:eduverse/study/screens/test_detail_page.dart';
import 'package:eduverse/study/screens/practice_question_page.dart';
import 'package:eduverse/study/screens/map_work_page.dart';
import 'package:eduverse/study/screens/workbooks_page.dart';

/*
QA CHECKLIST:
1. No RenderBox/Layout errors (Fixed by removing IntrinsicHeight)
2. Header stays at top, content scrolls
3. No overflow on small screens
*/

class StudyPage extends StatelessWidget {
  const StudyPage({Key? key}) : super(key: key);

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    // Robust layout: Column with Header + Expanded Scrollable Content
    // This avoids IntrinsicHeight/LayoutBuilder issues completely
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          const StudyHeader(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  
                  // Continue Learning
                  StudySection(
                    title: 'Continue Learning',
                    onSeeAll: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WorkbooksPage())),
                    child: SizedBox(
                      height: 160,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        scrollDirection: Axis.horizontal,
                        itemCount: StudyData.continueLearning.length,
                        itemBuilder: (context, index) {
                          final item = StudyData.continueLearning[index];
                          return StudyCard(
                            width: 140,
                            onTap: () => _showSnack(context, 'Resuming ${item.title}'),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.emoji, style: const TextStyle(fontSize: 32)),
                                const Spacer(),
                                Text(
                                  item.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value: item.progress,
                                  backgroundColor: Colors.grey[200],
                                  minHeight: 4,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Resume',
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Your Courses
                  StudySection(
                    title: 'Your Courses',
                    onSeeAll: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyCoursesPage())),
                    child: SizedBox(
                      height: 180,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        scrollDirection: Axis.horizontal,
                        itemCount: StudyData.userCourses.length,
                        itemBuilder: (context, index) {
                          final item = StudyData.userCourses[index];
                          return StudyCard(
                            width: 260,
                            padding: EdgeInsets.zero,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyCoursesPage())),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: item.gradientColors,
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.subtitle,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const Spacer(),
                                  Align(
                                    alignment: Alignment.bottomRight,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Text(
                                        'Open',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Daily Practice
                  StudySection(
                    title: 'Daily Practice',
                    child: GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 1.1,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: StudyData.dailyPractice.length,
                      itemBuilder: (context, index) {
                        final item = StudyData.dailyPractice[index];
                        return StudyCard(
                          onTap: () {
                            if (item.title.contains('Map')) {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const MapWorkPage()));
                            } else {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const PracticeQuestionPage()));
                            }
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(item.icon, color: item.color, size: 28),
                              const SizedBox(height: 8),
                              Text(
                                item.title,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.description,
                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Upcoming Live Classes
                  StudySection(
                    title: 'Upcoming Live Classes',
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: StudyData.liveClasses.length,
                      itemBuilder: (context, index) {
                        final item = StudyData.liveClasses[index];
                        final isStartingSoon = item.dateTime.difference(DateTime.now()).inMinutes < 10;
                        
                        return StudyCard(
                          onTap: () => _showSnack(context, 'Class Details: ${item.title}'),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(item.emoji, style: const TextStyle(fontSize: 24)),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormat('EEE, d MMM • h:mm a').format(item.dateTime),
                                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 100,
                                child: ElevatedButton(
                                  onPressed: () {
                                    _showSnack(context, isStartingSoon ? 'Joining Class...' : 'Reminder Set');
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isStartingSoon ? Colors.red : Theme.of(context).primaryColor,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                  ),
                                  child: Text(
                                    isStartingSoon ? 'Join Now' : 'Remind Me',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Mock Tests
                  StudySection(
                    title: 'Mock Tests',
                    child: SizedBox(
                      height: 180,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        scrollDirection: Axis.horizontal,
                        itemCount: StudyData.mockTests.length,
                        itemBuilder: (context, index) {
                          final item = StudyData.mockTests[index];
                          return StudyCard(
                            width: 200,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TestDetailPage(test: item))),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getDifficultyColor(item.difficulty).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        item.difficulty,
                                        style: TextStyle(
                                          color: _getDifficultyColor(item.difficulty),
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Icon(Icons.timer, size: 16, color: Colors.grey[600]),
                                  ],
                                ),
                                const Spacer(),
                                Text(
                                  item.title,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.duration,
                                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TestDetailPage(test: item))),
                                    style: OutlinedButton.styleFrom(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      padding: EdgeInsets.zero,
                                    ),
                                    child: const Text('Start Test'),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy': return Colors.green;
      case 'medium': return Colors.orange;
      case 'hard': return Colors.red;
      default: return Colors.blue;
    }
  }
}
