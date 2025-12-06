import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eduverse/study/domain/models/study_entities.dart';
import 'package:eduverse/study/presentation/providers/study_controller.dart';
import 'package:video_player/video_player.dart'; // Ensure dependecy is added or use placeholder

class LecturePlayerScreen extends StatefulWidget {
  final String courseId;
  final StudyLecture lecture;

  const LecturePlayerScreen({
    Key? key,
    required this.courseId,
    required this.lecture,
  }) : super(key: key);

  @override
  State<LecturePlayerScreen> createState() => _LecturePlayerScreenState();
}

class _LecturePlayerScreenState extends State<LecturePlayerScreen> {
  bool _isWatched = false;

  @override
  void initState() {
    super.initState();
    _isWatched = widget.lecture.isWatched;
  }

  void _markAsWatched() {
    final controller = Provider.of<StudyController>(context, listen: false);
    controller.markLectureWatched(widget.courseId, widget.lecture.id, !_isWatched);
    
    setState(() {
      _isWatched = !_isWatched;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isWatched ? 'Marked as Watched' : 'Marked as Unwatched')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        leading: const BackButton(color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Video Player Placeholder
            Expanded(
              child: Center(
                child: Container(
                  width: double.infinity,
                  color: Colors.black,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                       const Icon(Icons.play_circle_fill, color: Colors.white, size: 64),
                       const SizedBox(height: 16),
                       Text(
                         widget.lecture.title,
                         style: const TextStyle(color: Colors.white, fontSize: 18),
                         textAlign: TextAlign.center,
                       ),
                       const SizedBox(height: 8),
                       if (widget.lecture.videoUrl.isNotEmpty) 
                         Text(
                           "Video URL: ${widget.lecture.videoUrl}", 
                           style: const TextStyle(color: Colors.grey, fontSize: 12)
                         ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Controls
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.lecture.title,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.lecture.description.isNotEmpty 
                      ? widget.lecture.description 
                      : "No description available.",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _markAsWatched,
                      icon: Icon(_isWatched ? Icons.check_circle : Icons.radio_button_unchecked),
                      label: Text(_isWatched ? 'Completed' : 'Mark as Watched'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isWatched ? Colors.green : Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
