import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:eduverse/study/data/repositories/study_repository_impl.dart';
import 'package:eduverse/study/presentation/providers/study_controller.dart';
import 'package:eduverse/study/presentation/screens/study_home_screen.dart';

class StudyPage extends StatelessWidget {
  const StudyPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Composition Root for Study Section
    // We inject dependencies here.
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return ChangeNotifierProvider<StudyController>(
      create: (_) => StudyController(
        repository: StudyRepositoryImpl(), // Data Layer
        userId: userId,
      ),
      child: const StudyHomeScreen(), // Presentation Layer
    );
  }
}
