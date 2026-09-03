import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eduverse/study/domain/models/study_entities.dart';
import 'package:eduverse/study/presentation/providers/study_controller.dart';
import 'package:eduverse/study/presentation/screens/lecture_player_screen.dart';
import 'package:eduverse/study/presentation/screens/study_quiz_screen.dart';
import 'package:eduverse/study/presentation/screens/secure_pdf_viewer_screen.dart';

class RecordedBatchDetailScreen extends StatefulWidget {
  final String courseId;
  final StudyRecordedBatch batch;

  const RecordedBatchDetailScreen({
    super.key,
    required this.courseId,
    required this.batch,
  });

  @override
  State<RecordedBatchDetailScreen> createState() => _RecordedBatchDetailScreenState();
}

class _RecordedBatchDetailScreenState extends State<RecordedBatchDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<StudyLecture> _lectures = [];
  List<StudyNote> _notes = [];
  List<StudyDpp> _dpps = [];
  List<StudyQuiz> _quizzes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadContent();
  }

  Future<void> _loadContent() async {
    try {
      final controller = Provider.of<StudyController>(context, listen: false);
      final lectures = await controller.getRecordedBatchLectures(widget.courseId, widget.batch.id);
      final notes = await controller.getRecordedBatchNotes(widget.courseId, widget.batch.id);
      final dpps = await controller.getRecordedBatchDpps(widget.courseId, widget.batch.id);
      final quizzes = await controller.getRecordedBatchQuizzes(widget.courseId, widget.batch.id);

      if (mounted) {
        setState(() {
          _lectures = lectures;
          _notes = notes;
          _dpps = dpps;
          _quizzes = quizzes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.batch.title),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildHeader(),
                TabBar(
                  controller: _tabController,
                  labelColor: Theme.of(context).primaryColor,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Theme.of(context).primaryColor,
                  tabs: const [
                    Tab(text: 'Lectures'),
                    Tab(text: 'Notes'),
                    Tab(text: 'DPPs'),
                    Tab(text: 'Quizzes'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildLecturesTab(),
                      _buildNotesTab(),
                      _buildDppsTab(),
                      _buildQuizzesTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.teal, Colors.tealAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.video_library, color: Colors.white, size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.batch.title,
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          if (widget.batch.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              widget.batch.description,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatChip(Icons.play_circle_outline, '${_lectures.where((l) => l.type != "folder").length} Lectures'),
              const SizedBox(width: 8),
              _buildStatChip(Icons.description_outlined, '${_notes.length} Notes'),
              const SizedBox(width: 8),
              _buildStatChip(Icons.assignment_outlined, '${_dpps.length} DPPs'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildLecturesTab() {
    final validLectures = _lectures.where((l) => l.type != 'folder').toList();

    if (validLectures.isEmpty) {
      return const Center(child: Text('No lectures available in this recorded batch yet.'));
    }

    // Group lectures by subject
    final Map<String, List<StudyLecture>> subjectGroups = {};
    for (final lec in validLectures) {
      final subject = lec.subject.isEmpty ? 'General' : lec.subject;
      subjectGroups.putIfAbsent(subject, () => []).add(lec);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: subjectGroups.keys.length,
      itemBuilder: (context, index) {
        final subject = subjectGroups.keys.elementAt(index);
        final lecs = subjectGroups[subject]!;

        return ExpansionTile(
          initiallyExpanded: index == 0,
          leading: const Icon(Icons.folder, color: Colors.teal),
          title: Text(subject, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('${lecs.length} video${lecs.length > 1 ? "s" : ""}'),
          children: lecs.map((lec) => ListTile(
            leading: CircleAvatar(
              backgroundColor: lec.isWatched ? Colors.green.withValues(alpha: 0.1) : Colors.teal.withValues(alpha: 0.1),
              child: Icon(
                lec.isWatched ? Icons.check_circle : Icons.play_arrow,
                color: lec.isWatched ? Colors.green : Colors.teal,
              ),
            ),
            title: Text(lec.title, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(lec.chapter.isNotEmpty ? lec.chapter : 'Chapter content'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => ChangeNotifierProvider.value(
                    value: Provider.of<StudyController>(context, listen: false),
                    child: LecturePlayerScreen(
                      courseId: widget.courseId,
                      batchId: widget.batch.id,
                      lecture: lec,
                    ),
                  ),
                ),
              );
            },
          )).toList(),
        );
      },
    );
  }

  Widget _buildNotesTab() {
    if (_notes.isEmpty) {
      return const Center(child: Text('No notes available in this recorded batch yet.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _notes.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final note = _notes[index];
        return ListTile(
          leading: const CircleAvatar(
            backgroundColor: Colors.orangeAccent,
            child: Icon(Icons.picture_as_pdf, color: Colors.white),
          ),
          title: Text(note.title, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(note.subject.isNotEmpty ? '${note.subject} • ${note.chapter}' : 'Study Material'),
          trailing: const Icon(Icons.download),
          onTap: () {
            if (note.fileUrl != null && note.fileUrl!.isNotEmpty) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SecurePdfViewerScreen(
                    args: SecurePdfViewerArgs(
                      pdfUrl: note.fileUrl!,
                      title: note.title,
                      isProtected: false,
                    ),
                  ),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('File URL not available')),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildDppsTab() {
    if (_dpps.isEmpty) {
      return const Center(child: Text('No DPPs available in this recorded batch yet.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _dpps.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final dpp = _dpps[index];
        return ListTile(
          leading: const CircleAvatar(
            backgroundColor: Colors.deepPurple,
            child: Icon(Icons.assignment, color: Colors.white),
          ),
          title: Text(dpp.title, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(dpp.subject.isNotEmpty ? '${dpp.subject} • ${dpp.chapter}' : 'Practice Paper'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            if (dpp.dppPdfUrl.isNotEmpty) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SecurePdfViewerScreen(
                    args: SecurePdfViewerArgs(
                      pdfUrl: dpp.dppPdfUrl,
                      title: dpp.title,
                      isProtected: false,
                    ),
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildQuizzesTab() {
    if (_quizzes.isEmpty) {
      return const Center(child: Text('No quizzes available in this recorded batch yet.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _quizzes.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final quiz = _quizzes[index];
        return ListTile(
          leading: const CircleAvatar(
            backgroundColor: Colors.purple,
            child: Icon(Icons.quiz, color: Colors.white),
          ),
          title: Text(quiz.title, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('${quiz.questionCount} Questions • ${quiz.durationMinutes} mins'),
          trailing: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StudyQuizScreen(
                    courseId: widget.courseId,
                    batchId: widget.batch.id,
                    quizId: quiz.id,
                    quizTitle: quiz.title,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
            child: const Text('Start'),
          ),
        );
      },
    );
  }
}
