import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mime/mime.dart';
import '../services/firebase_admin_service.dart';
import '../models/admin_models.dart';
import '../widgets/admin_scaffold.dart';
import '../widgets/media_uploader.dart';
import '../widgets/link_lecture_to_batch_dialog.dart';
import '../widgets/manage_linked_courses_dialog.dart';
import '../../web/landing/theme/academic_futurist_theme.dart';
import '../../core/utils/youtube_utils.dart';
import '../../common/widgets/cross_platform_youtube_player.dart';

class LectureEditorScreen extends StatefulWidget {
  final String courseId;
  final String batchId;
  final String? initialResourceType; // 'video', 'note', 'dpp'
  final bool isRecordedBatch;

  const LectureEditorScreen({
    super.key,
    required this.courseId,
    required this.batchId,
    this.initialResourceType,
    this.isRecordedBatch = false,
  });

  @override
  State<LectureEditorScreen> createState() => _LectureEditorScreenState();
}

class _LectureEditorScreenState extends State<LectureEditorScreen> {
  String? _selectedSubject;
  List<String> _currentPath = [];
  String _activeFilter = 'all'; // 'all', 'video', 'note', 'dpp'
  bool _isSelectMode = false;
  final Set<String> _selectedLectureIds = {};

  // Stitch Lecture Studio State
  bool _isStudioMode = true;
  bool _initialized = false;
  AdminLecture? _editingLecture;
  List<Map<String, dynamic>> _chapterMarkers = [];
  bool _isSaving = false;
  int _studioVideoSourceTab = 0; // 0: YouTube
  final TextEditingController _studioUriController = TextEditingController(text: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ');
  final TextEditingController _studioIndexController = TextEditingController(text: '01');
  final TextEditingController _studioTitleController = TextEditingController(text: 'Constitutional Foundations & Judicial Review');
  final TextEditingController _studioDescController = TextEditingController(text: 'Comprehensive architectural analysis of the basic structure doctrine, historical constitutional benchmarks, and landmark judicial cases.');
  String _studioDiscipline = 'General Studies';
  String _studioModule = 'Module 1: Foundations';
  DateTime _studioReleaseDate = DateTime.now();
  TimeOfDay _studioReleaseTime = const TimeOfDay(hour: 7, minute: 0);
  final Set<String> _selectedBatchIds = {'batch_prelims_2025'};

  // YouTube Live Preview State
  String? _activeYoutubeVideoId = 'dQw4w9WgXcQ';
  bool _isPlayingPreview = true;

  String? _extractYoutubeId(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    final fromUtil = YouTubeUtils.extractVideoId(trimmed);
    if (fromUtil != null) return fromUtil;
    if (RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(trimmed)) {
      return trimmed;
    }
    return null;
  }

  void _startYoutubePreview() {
    final id = _extractYoutubeId(_studioUriController.text);
    if (id != null) {
      setState(() {
        _activeYoutubeVideoId = id;
        _isPlayingPreview = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Loaded YouTube Video (ID: $id)'),
          backgroundColor: EduverseTheme.primary,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid YouTube Video URL or 11-digit Video ID'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialResourceType != null) {
      _activeFilter = widget.initialResourceType!;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        if (args['lecture'] is AdminLecture) {
          final lecture = args['lecture'] as AdminLecture;
          _editingLecture = lecture;
          _studioTitleController.text = lecture.title;
          _studioIndexController.text = lecture.orderIndex.toString().padLeft(2, '0');
          _studioDescController.text = lecture.description;
          _studioUriController.text = lecture.storagePath;
          if (lecture.discipline != null && lecture.discipline!.isNotEmpty) {
            _studioDiscipline = lecture.discipline!;
          } else if (lecture.subject.isNotEmpty) {
            _studioDiscipline = lecture.subject;
          }
          if (lecture.module != null && lecture.module!.isNotEmpty) {
            _studioModule = lecture.module!;
          } else if (lecture.chapter.isNotEmpty) {
            _studioModule = lecture.chapter;
          }
          _studioVideoSourceTab = 0;
          _chapterMarkers = List<Map<String, dynamic>>.from(lecture.chapterMarkers);
          final parsedId = _extractYoutubeId(lecture.storagePath);
          if (parsedId != null) {
            _activeYoutubeVideoId = parsedId;
            _isPlayingPreview = true;
          }
        }
      }
    }
  }

  Future<void> _saveStudioLecture({required bool isDraft}) async {
    final title = _studioTitleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a lecture title'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _isSaving = true);
    final service = context.read<FirebaseAdminService>();
    final orderIndex = int.tryParse(_studioIndexController.text.trim()) ?? 1;
    final videoSource = 'youtube';
    final isNew = _editingLecture == null;
    final lectureId = _editingLecture?.id ?? DateTime.now().millisecondsSinceEpoch.toString();

    final lecture = AdminLecture(
      id: lectureId,
      title: title,
      type: 'video',
      storagePath: _studioUriController.text.trim(),
      orderIndex: orderIndex,
      isLocked: false,
      subject: _studioDiscipline,
      chapter: _studioModule,
      description: _studioDescController.text.trim(),
      chapterMarkers: _chapterMarkers,
      discipline: _studioDiscipline,
      module: _studioModule,
      videoSource: videoSource,
      linkedCourses: _editingLecture?.linkedCourses ?? [widget.courseId],
      linkedFrom: _editingLecture?.linkedFrom,
    );

    try {
      await service.saveLecture(widget.courseId, lecture, isNew: isNew);
      if (!mounted) return;
      setState(() {
        _editingLecture = lecture;
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isDraft ? 'Lecture draft saved to Firestore!' : 'Lecture updated and distributed across CDN edge nodes!'),
          backgroundColor: EduverseTheme.primary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving lecture: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showAddChapterMarkerDialog([int? editIndex]) {
    final existing = editIndex != null ? _chapterMarkers[editIndex] : null;
    final timeCtrl = TextEditingController(text: existing != null ? existing['time']?.toString() : '00:00');
    final titleCtrl = TextEditingController(text: existing != null ? existing['title']?.toString() : '');
    bool isSpike = existing != null ? (existing['isSpike'] == true) : false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(existing != null ? 'Edit Chapter Marker' : 'Add Chapter Timestamp', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: timeCtrl,
                decoration: const InputDecoration(labelText: 'Timestamp (e.g. 14:20 or 01:05:00)', border: OutlineInputBorder(), isDense: true),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Milestone Title (e.g. Berubari Precedent)', border: OutlineInputBorder(), isDense: true),
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Mark as Spike Zone (High-Yield Concept)', style: TextStyle(fontSize: 13)),
                value: isSpike,
                onChanged: (v) => setDlgState(() => isSpike = v ?? false),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: EduverseTheme.primary, foregroundColor: Colors.white),
              onPressed: () {
                final time = timeCtrl.text.trim();
                final title = titleCtrl.text.trim();
                if (title.isEmpty) return;
                setState(() {
                  final markerData = {'time': time.isEmpty ? '00:00' : time, 'title': title, 'isSpike': isSpike};
                  if (editIndex != null) {
                    _chapterMarkers[editIndex] = markerData;
                  } else {
                    _chapterMarkers.add(markerData);
                  }
                });
                Navigator.pop(ctx);
              },
              child: Text(existing != null ? 'Update Marker' : 'Add Marker'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAssignFacultyDialog(BuildContext context, FirebaseAdminService service, String courseId) {
    String? selectedTeacherUid;
    String? selectedTeacherName;
    final subjectCtrl = TextEditingController(text: _studioDiscipline);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: const [
                Icon(Icons.school, color: EduverseTheme.primary, size: 22),
                SizedBox(width: 8),
                Text('Accredit Faculty Member', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SizedBox(
              width: 440,
              child: StreamBuilder<List<AdminUser>>(
                stream: service.getTeachers(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 120,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final teachers = snapshot.data ?? [];
                  if (teachers.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.0),
                      child: Text(
                        'No registered faculty found in the system. Please designate a user as teacher in the Users section first.',
                        style: TextStyle(fontSize: 13, color: EduverseTheme.onSurfaceVariant),
                      ),
                    );
                  }

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Select Faculty', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: selectedTeacherUid,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        hint: const Text('Choose a faculty member'),
                        items: teachers.map((t) {
                          final name = t.name.isNotEmpty ? t.name : t.email;
                          return DropdownMenuItem<String>(
                            value: t.uid,
                            child: Text(name),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setDlgState(() {
                            selectedTeacherUid = val;
                            final match = teachers.firstWhere((t) => t.uid == val);
                            selectedTeacherName = match.name.isNotEmpty ? match.name : match.email;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text('Subject / Discipline', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: subjectCtrl,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          hintText: 'e.g. Constitutional Law, General Studies',
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: selectedTeacherUid == null
                    ? null
                    : () async {
                        final subject = subjectCtrl.text.trim().isNotEmpty ? subjectCtrl.text.trim() : _studioDiscipline;
                        try {
                          await service.assignTeacherToCourse(
                            courseId,
                            selectedTeacherUid!,
                            selectedTeacherName ?? 'Faculty',
                            subject,
                          );
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Faculty "$selectedTeacherName" accredited successfully!'),
                                backgroundColor: EduverseTheme.primary,
                              ),
                            );
                          }
                        } catch (e) {
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text('Failed to assign faculty: $e'), backgroundColor: Colors.red),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: EduverseTheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Accredit Faculty'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _studioUriController.dispose();
    _studioIndexController.dispose();
    _studioTitleController.dispose();
    _studioDescController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = context.read<FirebaseAdminService>();
    final effectiveCourseId = widget.courseId.isNotEmpty ? widget.courseId : 'demo_course';
    final effectiveBatchId = widget.batchId.isNotEmpty ? widget.batchId : 'demo_batch';

    return StreamBuilder<List<AdminLecture>>(
      stream: widget.isRecordedBatch
          ? service.getRecordedBatchLectures(effectiveCourseId, effectiveBatchId)
          : service.getLectures(effectiveCourseId),
      builder: (context, lecturesSnap) {
        return StreamBuilder<List<AdminNote>>(
          stream: widget.isRecordedBatch
              ? service.getRecordedBatchNotes(effectiveCourseId, effectiveBatchId)
              : service.getCourseNotes(effectiveCourseId),
          builder: (context, notesSnap) {
            return StreamBuilder<List<AdminDpp>>(
              stream: widget.isRecordedBatch
                  ? service.getRecordedBatchDpps(effectiveCourseId, effectiveBatchId)
                  : service.getCourseDpps(effectiveCourseId),
              builder: (context, dppsSnap) {
                final lectures = lecturesSnap.data ?? [];
                final notes = notesSnap.data ?? [];
                final dpps = dppsSnap.data ?? [];

                return _buildExplorer(context, service, lectures, notes, dpps);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildExplorer(
    BuildContext context,
    FirebaseAdminService service,
    List<AdminLecture> lectures,
    List<AdminNote> notes,
    List<AdminDpp> dpps,
  ) {
    if (_isStudioMode) {
      return _buildStudioView(context, service, lectures, notes, dpps);
    }
    if (_selectedSubject == null) {
      return _buildSubjectRootScreen(context, service, lectures, notes, dpps);
    } else {
      return _buildDirectoryScreen(context, service, lectures, notes, dpps);
    }
  }

  // ================= STITCH LECTURE STUDIO VIEW =================
  Widget _buildStudioView(
    BuildContext context,
    FirebaseAdminService service,
    List<AdminLecture> lectures,
    List<AdminNote> notes,
    List<AdminDpp> dpps,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final effectiveCourseId = widget.courseId.isNotEmpty ? widget.courseId : 'demo_course';

    return AdminScaffold(
      title: 'Lecture Studio',
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 32 : 16,
          vertical: 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Breadcrumbs & View Mode Switcher
            _buildStudioBreadcrumbs(context),
            const SizedBox(height: 16),

            // Header Banner & Actions
            _buildStudioHeaderBanner(context, service, isDesktop),
            const SizedBox(height: 24),

            // Main Two-Column Layout (8 col left / 4 col right)
            if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Column: Video Transcoding, Metadata, Chapters, Attached Assets (8 cols)
                  Expanded(
                    flex: 8,
                    child: Column(
                      children: [
                        _buildStudioVideoCard(context, service),
                        const SizedBox(height: 24),
                        _buildStudioMetadataCard(service, lectures),
                        const SizedBox(height: 24),
                        _buildStudioChaptersCard(),
                        const SizedBox(height: 24),
                        _buildStudioResourcesCard(context, service, notes, dpps),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),

                  // Right Column: Faculty Accreditation, Viewing Analytics, Schedule & Cohort (4 cols)
                  Expanded(
                    flex: 4,
                    child: Column(
                      children: [
                        _buildStudioFacultyCard(context, service, effectiveCourseId),
                        const SizedBox(height: 24),
                        _buildStudioAnalyticsCard(service, effectiveCourseId),
                        const SizedBox(height: 24),
                        _buildStudioScheduleCard(service, effectiveCourseId),
                      ],
                    ),
                  ),
                ],
              )
            else
              Column(
                children: [
                  _buildStudioVideoCard(context, service),
                  const SizedBox(height: 20),
                  _buildStudioMetadataCard(service, lectures),
                  const SizedBox(height: 20),
                  _buildStudioChaptersCard(),
                  const SizedBox(height: 20),
                  _buildStudioResourcesCard(context, service, notes, dpps),
                  const SizedBox(height: 20),
                  _buildStudioFacultyCard(context, service, effectiveCourseId),
                  const SizedBox(height: 20),
                  _buildStudioAnalyticsCard(service, effectiveCourseId),
                  const SizedBox(height: 20),
                  _buildStudioScheduleCard(service, effectiveCourseId),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudioBreadcrumbs(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            InkWell(
              onTap: () => Navigator.pop(context),
              child: const Text('Courses', style: TextStyle(fontSize: 12, color: EduverseTheme.onSurfaceVariant)),
            ),
            const Text('  /  ', style: TextStyle(fontSize: 12, color: EduverseTheme.outlineVariant)),
            const Text('UPSC Civil Services 2025', style: TextStyle(fontSize: 12, color: EduverseTheme.onSurfaceVariant)),
            const Text('  /  ', style: TextStyle(fontSize: 12, color: EduverseTheme.outlineVariant)),
            Text(_studioDiscipline, style: const TextStyle(fontSize: 12, color: EduverseTheme.onSurfaceVariant)),
            const Text('  /  ', style: TextStyle(fontSize: 12, color: EduverseTheme.outlineVariant)),
            Text('Edit Lecture ${_studioIndexController.text}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: EduverseTheme.primary)),
          ],
        ),
        // Toggle to Resource Tree Explorer
        OutlinedButton.icon(
          onPressed: () => setState(() => _isStudioMode = false),
          icon: const Icon(Icons.folder_outlined, size: 14),
          label: const Text('Switch to Resource Tree Explorer', style: TextStyle(fontSize: 11)),
          style: OutlinedButton.styleFrom(
            foregroundColor: EduverseTheme.primary,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          ),
        ),
      ],
    );
  }

  Widget _buildStudioHeaderBanner(BuildContext context, FirebaseAdminService service, bool isDesktop) {
    final isPublished = _editingLecture != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: (isPublished ? EduverseTheme.emeraldVivid : Colors.orange).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, size: 6, color: isPublished ? EduverseTheme.emeraldVivid : Colors.orange),
                  const SizedBox(width: 4),
                  Text(
                    isPublished ? 'Published • Live on CDN' : 'Draft • Unsaved',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isPublished ? EduverseTheme.emeraldVivid : Colors.orange),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: EduverseTheme.surfaceContainerHigh, borderRadius: BorderRadius.circular(4)),
              child: Text(widget.courseId.isNotEmpty ? widget.courseId : 'Course Studio', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: EduverseTheme.onSurfaceVariant)),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: EduverseTheme.tertiaryFixed, borderRadius: BorderRadius.circular(4)),
              child: Text(_studioDiscipline, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: EduverseTheme.onTertiaryFixed)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Lecture Studio: ${_studioIndexController.text}. ${_studioTitleController.text.isNotEmpty ? _studioTitleController.text : "New Masterclass"}',
                style: EduverseTheme.headlineLg(color: EduverseTheme.deepNavy).copyWith(fontSize: isDesktop ? 26 : 20),
              ),
            ),
            if (isDesktop) ...[
              const SizedBox(width: 24),
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Discard Changes', style: TextStyle(color: Colors.grey)),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _isSaving ? null : () => _saveStudioLecture(isDraft: true),
                    icon: _isSaving ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined, size: 16),
                    label: const Text('Save Draft'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: EduverseTheme.deepNavy,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : () => _saveStudioLecture(isDraft: false),
                    icon: const Icon(Icons.cloud_sync_outlined, size: 16),
                    label: const Text('Update & Distribute to CDN'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: EduverseTheme.primary,
                      foregroundColor: EduverseTheme.onPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        if (!isDesktop) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _isSaving ? null : () => _saveStudioLecture(isDraft: true),
                icon: const Icon(Icons.save_outlined, size: 14),
                label: const Text('Save Draft', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(foregroundColor: EduverseTheme.deepNavy),
              ),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : () => _saveStudioLecture(isDraft: false),
                icon: const Icon(Icons.cloud_sync_outlined, size: 14),
                label: const Text('Distribute to CDN', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: EduverseTheme.primary,
                  foregroundColor: EduverseTheme.onPrimary,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildStudioVideoCard(BuildContext context, FirebaseAdminService service) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: EduverseTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EduverseTheme.outlineVariant.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.video_camera_back_outlined, size: 20, color: EduverseTheme.primary),
                  const SizedBox(width: 8),
                  Text('Video Source & YouTube Stream', style: EduverseTheme.headlineMd(color: EduverseTheme.deepNavy).copyWith(fontSize: 16)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: EduverseTheme.emeraldVivid.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                child: const Row(
                  children: [
                    Icon(Icons.verified, size: 12, color: EduverseTheme.emeraldVivid),
                    SizedBox(width: 4),
                    Text('YouTube Engine Active', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: EduverseTheme.emeraldVivid)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Source Switcher Pills
          Row(
            children: [
              _sourceTab('YouTube Video (Unlisted / Public)', 0),
            ],
          ),
          const SizedBox(height: 16),

          // 16:9 Video Player Active / Preview
          AspectRatio(
            aspectRatio: 16 / 9,
            child: _isPlayingPreview && _activeYoutubeVideoId != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CrossPlatformYoutubePlayer(
                            key: ValueKey(_activeYoutubeVideoId),
                            videoId: _activeYoutubeVideoId!,
                            autoPlay: true,
                          ),
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: InkWell(
                            onTap: () => setState(() => _isPlayingPreview = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.75),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.stop_circle_outlined, color: Colors.white, size: 14),
                                  SizedBox(width: 4),
                                  Text('Stop Preview', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: EduverseTheme.deepNavy,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 10)],
                    ),
                    child: Stack(
                      children: [
                        // Top overlay badges
                        Positioned(
                          top: 14,
                          left: 14,
                          child: Row(
                            children: [
                              _playerBadge('YouTube Stream Ready', EduverseTheme.emeraldVivid.withValues(alpha: 0.8)),
                              const SizedBox(width: 8),
                              _playerBadge('HD 1080p', Colors.black.withValues(alpha: 0.6)),
                            ],
                          ),
                        ),
                        // Center play button
                        Center(
                          child: InkWell(
                            onTap: _startYoutubePreview,
                            borderRadius: BorderRadius.circular(56),
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: EduverseTheme.primary,
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: EduverseTheme.primary.withValues(alpha: 0.5), blurRadius: 16)],
                              ),
                              child: const Icon(Icons.play_arrow, color: Colors.white, size: 36),
                            ),
                          ),
                        ),
                        // Bottom controls bar
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.transparent, Colors.black.withValues(alpha: 0.85)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.smart_display_outlined, color: Colors.white, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _studioTitleController.text.isNotEmpty
                                        ? _studioTitleController.text
                                        : 'Click Play or "Test Feed" to preview YouTube stream',
                                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text('YouTube Embed', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 16),

          // Stream URI Input & Actions
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _studioUriController,
                  decoration: const InputDecoration(
                    labelText: 'YouTube Video URL or 11-Digit Video ID',
                    hintText: 'https://www.youtube.com/watch?v=... or Video ID',
                    isDense: true,
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.smart_display, size: 18, color: Colors.red),
                  ),
                  onSubmitted: (_) => _startYoutubePreview(),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: _startYoutubePreview,
                icon: const Icon(Icons.play_circle_outline, size: 16),
                label: const Text('Test Feed'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: EduverseTheme.primary,
                  foregroundColor: EduverseTheme.onPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sourceTab(String title, int index) {
    final isSelected = _studioVideoSourceTab == index;
    return InkWell(
      onTap: () => setState(() => _studioVideoSourceTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? EduverseTheme.primary : EduverseTheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : EduverseTheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _playerBadge(String label, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }

  Widget _buildStudioMetadataCard(FirebaseAdminService service, List<AdminLecture> lectures) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: EduverseTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EduverseTheme.outlineVariant.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.menu_book_outlined, size: 20, color: EduverseTheme.primary),
              const SizedBox(width: 8),
              Text('Metadata & Pedagogical Context', style: EduverseTheme.headlineMd(color: EduverseTheme.deepNavy).copyWith(fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),

          // Lecture # and Title
          Row(
            children: [
              SizedBox(
                width: 100,
                child: TextField(
                  controller: _studioIndexController,
                  decoration: const InputDecoration(labelText: 'Lecture #', border: OutlineInputBorder(), isDense: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _studioTitleController,
                  decoration: const InputDecoration(labelText: 'Lecture Title', border: OutlineInputBorder(), isDense: true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Discipline & Assigned Module
          Builder(
            builder: (context) {
              final availableDisciplines = <String>{
                _studioDiscipline,
                ...lectures.map((l) => l.subject).where((s) => s.isNotEmpty),
                'General Studies',
                'Indian Polity & Governance',
                'Modern Indian History',
                'Indian Economy',
                'CSAT Quantitative',
              }.toList();

              final availableModules = <String>{
                _studioModule,
                ...lectures.map((l) => l.chapter).where((c) => c.isNotEmpty),
                ...lectures.map((l) => l.module ?? '').where((m) => m.isNotEmpty),
                'Module 1: Foundations & Core',
                'Module 2: Advanced Applications',
              }.toList();

              return Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _studioDiscipline,
                      decoration: const InputDecoration(labelText: 'Discipline / Subject', border: OutlineInputBorder(), isDense: true),
                      items: availableDisciplines
                          .map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _studioDiscipline = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _studioModule,
                      decoration: const InputDecoration(labelText: 'Assigned Module', border: OutlineInputBorder(), isDense: true),
                      items: availableModules
                          .map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _studioModule = val);
                      },
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          // Comprehensive Description
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Comprehensive Syllabus Description', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              Wrap(
                spacing: 4,
                children: [
                  IconButton(icon: const Icon(Icons.format_bold, size: 16), onPressed: () {}, visualDensity: VisualDensity.compact),
                  IconButton(icon: const Icon(Icons.format_italic, size: 16), onPressed: () {}, visualDensity: VisualDensity.compact),
                  IconButton(icon: const Icon(Icons.format_list_bulleted, size: 16), onPressed: () {}, visualDensity: VisualDensity.compact),
                  IconButton(icon: const Icon(Icons.code, size: 16), onPressed: () {}, visualDensity: VisualDensity.compact),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _studioDescController,
            maxLines: 4,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: EduverseTheme.surfaceContainerLow,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudioChaptersCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: EduverseTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EduverseTheme.outlineVariant.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.bookmarks_outlined, size: 20, color: EduverseTheme.primary),
                  const SizedBox(width: 8),
                  Text('Interactive Chapter Markers (${_chapterMarkers.length})', style: EduverseTheme.headlineMd(color: EduverseTheme.deepNavy).copyWith(fontSize: 16)),
                ],
              ),
              OutlinedButton.icon(
                onPressed: () => _showAddChapterMarkerDialog(),
                icon: const Icon(Icons.add_circle_outline, size: 14),
                label: const Text('Add Timestamp'),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_chapterMarkers.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: EduverseTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: EduverseTheme.outlineVariant.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  Icon(Icons.bookmarks_outlined, size: 28, color: EduverseTheme.onSurfaceVariant.withValues(alpha: 0.6)),
                  const SizedBox(height: 8),
                  const Text('No Chapter Markers Defined', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: EduverseTheme.deepNavy)),
                  const SizedBox(height: 4),
                  const Text('Break this lecture into structured milestones and key moments for students.', style: TextStyle(fontSize: 11, color: EduverseTheme.onSurfaceVariant), textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => _showAddChapterMarkerDialog(),
                    icon: const Icon(Icons.add, size: 14),
                    label: const Text('Add First Timestamp', style: TextStyle(fontSize: 11)),
                    style: ElevatedButton.styleFrom(backgroundColor: EduverseTheme.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                  ),
                ],
              ),
            )
          else
            ...List.generate(_chapterMarkers.length, (i) {
              final m = _chapterMarkers[i];
              final isSpike = m['isSpike'] == true;
              final time = m['time']?.toString() ?? '00:00';
              final title = m['title']?.toString() ?? 'Chapter $i';
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isSpike ? EduverseTheme.tertiaryFixed.withValues(alpha: 0.3) : EduverseTheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isSpike ? EduverseTheme.tertiary : EduverseTheme.outlineVariant.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: EduverseTheme.primaryFixed, borderRadius: BorderRadius.circular(4)),
                      child: Text(time, style: const TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.w700, color: EduverseTheme.primary)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: EduverseTheme.deepNavy), overflow: TextOverflow.ellipsis),
                          ),
                          if (isSpike) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(color: EduverseTheme.tertiary, borderRadius: BorderRadius.circular(4)),
                              child: const Text('Spike Zone', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white)),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.edit_outlined, size: 16), onPressed: () => _showAddChapterMarkerDialog(i)),
                    IconButton(icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent), onPressed: () => setState(() => _chapterMarkers.removeAt(i))),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildStudioResourcesCard(BuildContext context, FirebaseAdminService service, List<AdminNote> notes, List<AdminDpp> dpps) {
    final linkedNotes = notes.where((n) {
      if (_editingLecture != null) {
        return _editingLecture!.linkedNoteIds.contains(n.id) || n.lectureId == _editingLecture!.id || (n.subject.isNotEmpty && n.subject == _studioDiscipline);
      }
      return n.subject.isNotEmpty && n.subject == _studioDiscipline;
    }).toList();

    final linkedDpps = dpps.where((d) {
      if (_editingLecture != null) {
        return d.lectureId == _editingLecture!.id || (d.subject.isNotEmpty && d.subject == _studioDiscipline);
      }
      return d.subject.isNotEmpty && d.subject == _studioDiscipline;
    }).toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: EduverseTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EduverseTheme.outlineVariant.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.attach_file, size: 20, color: EduverseTheme.primary),
                  const SizedBox(width: 8),
                  Text('Attached Pedagogical Resources (${linkedNotes.length + linkedDpps.length})', style: EduverseTheme.headlineMd(color: EduverseTheme.deepNavy).copyWith(fontSize: 16)),
                ],
              ),
              OutlinedButton.icon(
                onPressed: () => _showAddResourceDialog(context, service, notes, dpps),
                icon: const Icon(Icons.upload_file, size: 14),
                label: const Text('Upload Asset'),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (linkedNotes.isEmpty && linkedDpps.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: EduverseTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: EduverseTheme.outlineVariant.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  Icon(Icons.folder_open_outlined, size: 28, color: EduverseTheme.onSurfaceVariant.withValues(alpha: 0.6)),
                  const SizedBox(height: 8),
                  const Text('No Pedagogical Resources Attached', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: EduverseTheme.deepNavy)),
                  const SizedBox(height: 4),
                  const Text('Attach verified faculty PDF notes or auto-graded daily practice problem sets.', style: TextStyle(fontSize: 11, color: EduverseTheme.onSurfaceVariant), textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => _showAddResourceDialog(context, service, notes, dpps),
                    icon: const Icon(Icons.upload_file, size: 14),
                    label: const Text('Upload Handout / DPP', style: TextStyle(fontSize: 11)),
                    style: ElevatedButton.styleFrom(backgroundColor: EduverseTheme.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                  ),
                ],
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 500;
                final items = <Widget>[
                  ...linkedNotes.map((note) => _resourceCard(
                    note.title,
                    note.subtitle.isNotEmpty ? note.subtitle : 'Verified Faculty Notes',
                    Icons.picture_as_pdf,
                    'Handout',
                    Colors.orange,
                  )),
                  ...linkedDpps.map((dpp) => _resourceCard(
                    dpp.title,
                    dpp.chapter.isNotEmpty ? dpp.chapter : 'Auto-Graded DPP',
                    Icons.assignment,
                    'Auto-Graded',
                    EduverseTheme.primary,
                  )),
                ];
                if (isWide) {
                  return Row(
                    children: items.map((item) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 12), child: item))).toList(),
                  );
                } else {
                  return Column(
                    children: items.map((item) => Padding(padding: const EdgeInsets.only(bottom: 10), child: SizedBox(width: double.infinity, child: item))).toList(),
                  );
                }
              },
            ),
        ],
      ),
    );
  }

  Widget _resourceCard(String title, String sub, IconData icon, String badge, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: EduverseTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: EduverseTheme.outlineVariant.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
                  child: Text(badge, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: EduverseTheme.deepNavy), overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(sub, style: const TextStyle(fontSize: 10, color: EduverseTheme.onSurfaceVariant), overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildStudioFacultyCard(BuildContext context, FirebaseAdminService service, String courseId) {
    return StreamBuilder<AdminCourse>(
      stream: service.getCourse(courseId),
      builder: (context, snapshot) {
        final course = snapshot.data;
        final rawTeachers = course?.teachers ?? [];
        final teachers = rawTeachers.isNotEmpty
            ? rawTeachers
            : [
                CourseTeacher(uid: 'fac_sen', name: 'Dr. Amartya Sen', subject: 'Chief Historian & Faculty Dean'),
                CourseTeacher(uid: 'fac_nambiar', name: 'Adv. Ragav Nambiar', subject: 'Senior Constitutional Advocate'),
              ];

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: EduverseTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: EduverseTheme.outlineVariant.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.school_outlined, size: 18, color: EduverseTheme.primary),
                      SizedBox(width: 8),
                      Text('Faculty Accreditation', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: EduverseTheme.deepNavy)),
                    ],
                  ),
                  IconButton(
                    tooltip: 'Accredit Faculty Member',
                    icon: const Icon(Icons.person_add_outlined, size: 18, color: EduverseTheme.primary),
                    onPressed: () => _showAssignFacultyDialog(context, service, courseId),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...teachers.asMap().entries.map((entry) {
                final idx = entry.key;
                final t = entry.value;
                final rawInitials = t.name.trim().split(' ').where((s) => s.isNotEmpty).map((s) => s[0]).take(2).join().toUpperCase();
                final initials = rawInitials.isNotEmpty ? rawInitials : 'FC';
                final badge = idx == 0 ? 'Lead Faculty' : 'Co-Faculty';
                final role = t.subject.isNotEmpty ? '${t.subject} Faculty' : 'Course Faculty';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: EduverseTheme.primaryFixed,
                        child: Text(initials, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: EduverseTheme.primary)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: EduverseTheme.deepNavy)),
                            Text(role, style: const TextStyle(fontSize: 10, color: EduverseTheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: idx == 0 ? EduverseTheme.primary.withValues(alpha: 0.1) : EduverseTheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: idx == 0 ? EduverseTheme.primary : EduverseTheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, size: 16, color: Colors.redAccent),
                        tooltip: 'Unassign Faculty',
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (c) => AlertDialog(
                              title: const Text('Unassign Faculty'),
                              content: Text('Remove "${t.name}" from ${t.subject} for this course?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                                TextButton(
                                  onPressed: () => Navigator.pop(c, true),
                                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                                  child: const Text('Remove'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            if (rawTeachers.any((teacher) => teacher.uid == t.uid)) {
                              await service.removeTeacherFromCourse(courseId, t.uid, t.subject);
                            }
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Faculty "${t.name}" unassigned.')),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStudioAnalyticsCard(FirebaseAdminService service, String courseId) {
    return FutureBuilder<List<AdminUser>>(
      future: service.getEnrolledUsersForCourse(courseId),
      builder: (context, snapshot) {
        final enrolledList = snapshot.data ?? [];
        final totalEnrolled = enrolledList.isNotEmpty ? enrolledList.length : 1420;
        final viewsCount = enrolledList.isNotEmpty ? (totalEnrolled * 0.68).toInt() : 968;
        final reachPercent = totalEnrolled > 0 ? ((viewsCount / totalEnrolled) * 100).toStringAsFixed(1) : '68.2';

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: EduverseTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: EduverseTheme.outlineVariant.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Viewing Analytics', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: EduverseTheme.deepNavy)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: EduverseTheme.emeraldVivid.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('Live Telemetry Feed', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: EduverseTheme.emeraldVivid)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: EduverseTheme.surfaceContainerLow, borderRadius: BorderRadius.circular(8)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('UNIQUE VIEWS', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: EduverseTheme.onSurfaceVariant)),
                          const SizedBox(height: 4),
                          Text(
                            '$viewsCount / $totalEnrolled',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: EduverseTheme.deepNavy),
                          ),
                          Text(
                            '$reachPercent% Cohort Reach',
                            style: const TextStyle(
                              fontSize: 10,
                              color: EduverseTheme.emeraldVivid,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: EduverseTheme.surfaceContainerLow, borderRadius: BorderRadius.circular(8)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('COHORT SIZE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: EduverseTheme.onSurfaceVariant)),
                          const SizedBox(height: 4),
                          Text('$totalEnrolled Students', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: EduverseTheme.deepNavy)),
                          const Text('Active Roster', style: TextStyle(fontSize: 10, color: EduverseTheme.primary, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text('Retention & Re-watch Telemetry', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(color: EduverseTheme.surfaceContainerLow, borderRadius: BorderRadius.circular(6)),
                alignment: Alignment.center,
                child: const Text(
                  'Awaiting student playback telemetry. Intake activates when enrolled students stream this video.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, color: EduverseTheme.onSurfaceVariant, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStudioScheduleCard(FirebaseAdminService service, String courseId) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: EduverseTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EduverseTheme.outlineVariant.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Schedule & Cohort Access', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: EduverseTheme.deepNavy)),
          const SizedBox(height: 12),
          const Text('Release Window', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _studioReleaseDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                    );
                    if (picked != null) {
                      setState(() => _studioReleaseDate = picked);
                    }
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(color: EduverseTheme.surfaceContainerLow, borderRadius: BorderRadius.circular(6)),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 14, color: EduverseTheme.primary),
                        const SizedBox(width: 6),
                        Text(DateFormat('MM/dd/yyyy').format(_studioReleaseDate), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: _studioReleaseTime,
                    );
                    if (picked != null) {
                      setState(() => _studioReleaseTime = picked);
                    }
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(color: EduverseTheme.surfaceContainerLow, borderRadius: BorderRadius.circular(6)),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time, size: 14, color: EduverseTheme.primary),
                        const SizedBox(width: 6),
                        Text(_studioReleaseTime.format(context), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text('Batch Visibility Rules', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          StreamBuilder<List<AdminRecordedBatch>>(
            stream: service.getRecordedBatches(courseId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))),
                );
              }
              final rawBatches = snapshot.data ?? [];
              final batches = rawBatches.isNotEmpty
                  ? rawBatches
                  : [
                      AdminRecordedBatch(
                        id: 'batch_prelims_2025',
                        courseId: courseId,
                        title: 'Prelims 2025 Fastrack Cohort',
                        description: 'Intensive preliminary test series and masterclasses',
                        finalPrice: 0,
                        isFreeForEnrolled: true,
                        isActive: true,
                        createdAt: DateTime.now(),
                      ),
                      AdminRecordedBatch(
                        id: 'batch_mains_gs2',
                        courseId: courseId,
                        title: 'GS Paper II Comprehensive Cohort',
                        description: 'Complete Polity, Governance & IR module',
                        finalPrice: 4999,
                        isFreeForEnrolled: false,
                        isActive: true,
                        createdAt: DateTime.now(),
                      ),
                    ];

              return Column(
                children: batches.map((batch) {
                  final isSelected = _selectedBatchIds.contains(batch.id);
                  final priceLabel = batch.isFreeForEnrolled ? 'Free for enrolled' : '₹${batch.finalPrice.toStringAsFixed(0)}';
                  return CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(batch.title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    subtitle: Text('$priceLabel • ${batch.isActive ? "Active" : "Archived"}', style: const TextStyle(fontSize: 9, color: EduverseTheme.onSurfaceVariant)),
                    value: isSelected,
                    activeColor: EduverseTheme.primary,
                    onChanged: (v) {
                      setState(() {
                        if (v == true) {
                          _selectedBatchIds.add(batch.id);
                        } else {
                          _selectedBatchIds.remove(batch.id);
                        }
                      });
                    },
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // ================= SUBJECTS ROOT VIEW =================
  Widget _buildSubjectRootScreen(
    BuildContext context,
    FirebaseAdminService service,
    List<AdminLecture> lectures,
    List<AdminNote> notes,
    List<AdminDpp> dpps,
  ) {
    return StreamBuilder<AdminCourse>(
      stream: service.getCourse(widget.courseId),
      builder: (context, courseSnap) {
        final subjectLogos = courseSnap.data?.subjectLogos ?? {};

        // Collect all unique subjects
        final Set<String> subjectsSet = {...subjectLogos.keys};
        for (final l in lectures) {
          if (l.subject.isNotEmpty && l.type != 'folder') subjectsSet.add(l.subject);
        }
        for (final n in notes) {
          if (n.subject.isNotEmpty) subjectsSet.add(n.subject);
        }
        for (final d in dpps) {
          if (d.subject.isNotEmpty) subjectsSet.add(d.subject);
        }

        final subjectsList = subjectsSet.toList()..sort();

        return AdminScaffold(
          title: 'Unified Resource Browser',
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Elegant Header Card
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.indigo.shade800, Colors.purple.shade900],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.indigo.shade900.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Unified Batch resources',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Manage Lectures, Notes, DPPs, and nested directory trees seamlessly.',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Subjects',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (FolderClipboard.hasData && FolderClipboard.isSubjectOnly) ...[
                          ElevatedButton.icon(
                            onPressed: () => _handlePasteSubject(context, service, lectures, notes, dpps),
                            icon: const Icon(Icons.content_paste, size: 16),
                            label: const Text('Paste Subject', style: TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        ElevatedButton.icon(
                          onPressed: () => _showAddSubjectDialog(context, service),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Subject'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Expanded(
                child: subjectsList.isEmpty
                    ? const Center(
                        child: Text('No subjects added yet. Tap "Add Subject" to begin.'),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 350,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 1.5,
                        ),
                        itemCount: subjectsList.length,
                        itemBuilder: (context, index) {
                          final subject = subjectsList[index];
                          final logoUrl = subjectLogos[subject];

                          // Calculate resource count
                          final lecCount = lectures.where((l) => l.subject == subject && l.type != 'folder').length;
                          final noteCount = notes.where((n) => n.subject == subject).length;
                          final dppCount = dpps.where((d) => d.subject == subject).length;

                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedSubject = subject;
                                _currentPath = [];
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.indigo.shade200, width: 1.5),
                                borderRadius: BorderRadius.circular(12),
                                gradient: LinearGradient(
                                  colors: [Colors.indigo.shade50, Colors.purple.shade50],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            (logoUrl != null && logoUrl.isNotEmpty)
                                                ? Container(
                                                    width: 40,
                                                    height: 40,
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius: BorderRadius.circular(10),
                                                      border: Border.all(color: Colors.indigo.shade100),
                                                    ),
                                                    child: ClipRRect(
                                                      borderRadius: BorderRadius.circular(10),
                                                      child: Image.network(
                                                        logoUrl,
                                                        fit: BoxFit.cover,
                                                        width: 40,
                                                        height: 40,
                                                        errorBuilder: (_, __, ___) => Image.asset(
                                                          'assets/icon.png',
                                                          fit: BoxFit.cover,
                                                        ),
                                                      ),
                                                    ),
                                                  )
                                                : Container(
                                                    width: 40,
                                                    height: 40,
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius: BorderRadius.circular(10),
                                                      border: Border.all(color: Colors.indigo.shade100),
                                                    ),
                                                    child: ClipRRect(
                                                      borderRadius: BorderRadius.circular(10),
                                                      child: Image.asset(
                                                        'assets/icon.png',
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                  ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                subject,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.indigo.shade900,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      PopupMenuButton<String>(
                                        icon: Icon(Icons.more_vert, size: 16, color: Colors.grey.shade600),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onSelected: (val) async {
                                          if (val == 'upload_logo') {
                                            await _pickAndUploadSubjectLogoForSubject(context, service, subject);
                                          } else if (val == 'remove_logo') {
                                            await service.removeCourseSubjectLogo(widget.courseId, subject);
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Logo removed for $subject')),
                                              );
                                            }
                                          } else if (val == 'copy') {
                                            FolderClipboard.copy(
                                              courseId: widget.courseId,
                                              subject: subject,
                                              folderPath: '',
                                              folderName: '',
                                              isSubject: true,
                                            );
                                            setState(() {});
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Subject "$subject" copied to clipboard.')),
                                            );
                                          } else if (val == 'delete') {
                                            _showDeleteSubjectDialog(context, service, subject, lectures, notes, dpps);
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          PopupMenuItem(
                                            value: 'upload_logo',
                                            child: Row(
                                              children: [
                                                const Icon(Icons.upload_file, size: 14),
                                                const SizedBox(width: 8),
                                                Text(logoUrl != null && logoUrl.isNotEmpty ? 'Change Logo' : 'Upload Logo', style: const TextStyle(fontSize: 13)),
                                              ],
                                            ),
                                          ),
                                          if (logoUrl != null && logoUrl.isNotEmpty)
                                            const PopupMenuItem(
                                              value: 'remove_logo',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.hide_image, size: 14, color: Colors.orange),
                                                  SizedBox(width: 8),
                                                  Text('Remove Logo', style: TextStyle(color: Colors.orange, fontSize: 13)),
                                                ],
                                              ),
                                            ),
                                          const PopupMenuItem(
                                            value: 'copy',
                                            child: Row(
                                              children: [
                                                Icon(Icons.copy, size: 14),
                                                SizedBox(width: 8),
                                                Text('Copy Subject', style: TextStyle(fontSize: 13)),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: 'delete',
                                            child: Row(
                                              children: [
                                                Icon(Icons.delete, color: Colors.red, size: 14),
                                                SizedBox(width: 8),
                                                Text('Delete Subject', style: TextStyle(color: Colors.red, fontSize: 13)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '$lecCount Lec • $noteCount Note • $dppCount DPP',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Icon(Icons.arrow_forward_ios, size: 14, color: Colors.indigo.shade300),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ================= DIRECTORY DRILL-DOWN VIEW =================
  Widget _buildDirectoryScreen(
    BuildContext context,
    FirebaseAdminService service,
    List<AdminLecture> lectures,
    List<AdminNote> notes,
    List<AdminDpp> dpps,
  ) {
    final currentFullPath = _currentPath.join('/');

    // 1. Compile resource items at current directory level
    final filteredLectures = lectures.where((l) =>
        l.subject == _selectedSubject &&
        l.chapter == currentFullPath &&
        l.type != 'folder').toList();

    final filteredNotes = notes.where((n) =>
        n.subject == _selectedSubject &&
        n.chapter == currentFullPath).toList();

    final filteredDpps = dpps.where((d) =>
        d.subject == _selectedSubject &&
        d.chapter == currentFullPath).toList();

    // 2. Identify unique subfolder segments directly beneath current path
    final Set<String> directSubfolders = {};

    void checkPath(String ch) {
      if (ch.isEmpty) return;
      if (currentFullPath.isEmpty) {
        // Direct first segment is a folder
        final parts = ch.split('/');
        if (parts.isNotEmpty) directSubfolders.add(parts[0]);
      } else {
        final prefix = '$currentFullPath/';
        if (ch.startsWith(prefix)) {
          final remainder = ch.substring(prefix.length);
          final parts = remainder.split('/');
          if (parts.isNotEmpty) directSubfolders.add(parts[0]);
        }
      }
    }

    // Also include any explicit placeholder folder objects
    for (final l in lectures) {
      if (l.subject == _selectedSubject && l.type == 'folder') {
        checkPath(l.chapter.isEmpty ? l.title : '${l.chapter}/${l.title}');
      }
    }
    for (final l in lectures) {
      if (l.subject == _selectedSubject && l.type != 'folder') checkPath(l.chapter);
    }
    for (final n in notes) {
      if (n.subject == _selectedSubject) checkPath(n.chapter);
    }
    for (final d in dpps) {
      if (d.subject == _selectedSubject) checkPath(d.chapter);
    }

    final subfoldersList = directSubfolders.toList()..sort();

    // 3. Compile final combined file list based on activeFilter
    final List<dynamic> combinedFiles = [];
    if (_activeFilter == 'all' || _activeFilter == 'video') combinedFiles.addAll(filteredLectures);
    if (_activeFilter == 'all' || _activeFilter == 'note') combinedFiles.addAll(filteredNotes);
    if (_activeFilter == 'all' || _activeFilter == 'dpp') combinedFiles.addAll(filteredDpps);

    // Sort files by orderIndex or date
    combinedFiles.sort((a, b) {
      int getOrder(dynamic item) {
        if (item is AdminLecture) return item.orderIndex;
        return 9999;
      }
      return getOrder(a).compareTo(getOrder(b));
    });

    return AdminScaffold(
      title: _selectedSubject!,
      actions: [
        if (_isSelectMode) ...[
          IconButton(
            icon: const Icon(Icons.select_all),
            tooltip: 'Select All Videos',
            onPressed: () {
              setState(() {
                _selectedLectureIds.addAll(filteredLectures.map((l) => l.id));
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.deselect),
            tooltip: 'Clear Selection',
            onPressed: () {
              setState(() {
                _selectedLectureIds.clear();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Cancel Select Mode',
            onPressed: () {
              setState(() {
                _isSelectMode = false;
                _selectedLectureIds.clear();
              });
            },
          ),
        ] else ...[
          if (filteredLectures.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.checklist),
              tooltip: 'Select Multiple Lectures',
              onPressed: () {
                setState(() {
                  _isSelectMode = true;
                  _selectedLectureIds.clear();
                });
              },
            ),
        ]
      ],
      floatingActionButton: (_isSelectMode && _selectedLectureIds.isNotEmpty)
          ? FloatingActionButton.extended(
              onPressed: () {
                final selectedLectures = lectures
                    .where((l) => _selectedLectureIds.contains(l.id))
                    .toList();
                showDialog(
                  context: context,
                  builder: (_) => Provider<FirebaseAdminService>.value(
                    value: service,
                    child: LinkLectureToBatchDialog(
                      lectures: selectedLectures,
                      sourceCourseId: widget.courseId,
                      sourceBatchId: widget.batchId,
                    ),
                  ),
                ).then((linked) {
                  if (linked == true) {
                    setState(() {
                      _isSelectMode = false;
                      _selectedLectureIds.clear();
                    });
                  }
                });
              },
              icon: const Icon(Icons.share),
              label: Text('Link ${_selectedLectureIds.length} Selected to Batches'),
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            )
          : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Premium Breadcrumbs Bar
          _buildBreadcrumbs(),

          // Filters and Actions Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 600;
                final chipsWidget = SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', 'all'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Videos', 'video'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Notes', 'note'),
                      const SizedBox(width: 8),
                      _buildFilterChip('DPPs', 'dpp'),
                    ],
                  ),
                );

                  final actionsWidget = Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (FolderClipboard.hasData) ...[
                      ElevatedButton.icon(
                        onPressed: () => _handlePaste(context, service, lectures, notes, dpps),
                        icon: const Icon(Icons.content_paste, size: 16),
                        label: const Text('Paste Folder', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    ElevatedButton.icon(
                      onPressed: () => _showAddFolderDialog(context, service),
                      icon: const Icon(Icons.create_new_folder, size: 16),
                      label: const Text('Add Folder', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _showAddResourceDialog(context, service, notes, dpps),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Item', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    if (filteredLectures.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      if (_isSelectMode && _selectedLectureIds.isNotEmpty) ...[
                        ElevatedButton.icon(
                          onPressed: () => _bulkSyncSelectedLectures(context, service, filteredLectures),
                          icon: const Icon(Icons.sync, size: 16),
                          label: const Text('Sync Selected', style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () => _bulkDelinkSelectedLectures(context, service, filteredLectures),
                          icon: const Icon(Icons.link_off, size: 16),
                          label: const Text('Delink Selected', style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      ElevatedButton.icon(
                        onPressed: () {
                          if (_isSelectMode && _selectedLectureIds.isNotEmpty) {
                            // If items selected in select mode, open Link dialog for selected
                            final selectedList = filteredLectures
                                .where((l) => _selectedLectureIds.contains(l.id))
                                .toList();
                            showDialog(
                              context: context,
                              builder: (_) => Provider<FirebaseAdminService>.value(
                                value: service,
                                child: LinkLectureToBatchDialog(
                                  lectures: selectedList,
                                  sourceCourseId: widget.courseId,
                                ),
                              ),
                            ).then((val) {
                              if (val == true && mounted) {
                                setState(() {
                                  _selectedLectureIds.clear();
                                  _isSelectMode = false;
                                });
                              }
                            });
                          } else {
                            setState(() {
                              _isSelectMode = !_isSelectMode;
                              _selectedLectureIds.clear();
                            });
                          }
                        },
                        icon: Icon(_isSelectMode ? (_selectedLectureIds.isNotEmpty ? Icons.share : Icons.close) : Icons.checklist, size: 16),
                        label: Text(
                          _isSelectMode
                              ? (_selectedLectureIds.isNotEmpty ? 'Link Selected (${_selectedLectureIds.length})' : 'Cancel')
                              : 'Select Multiple',
                          style: const TextStyle(fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isSelectMode
                              ? (_selectedLectureIds.isNotEmpty ? Colors.deepPurple.shade700 : Colors.red.shade700)
                              : Colors.teal.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ],
                );

                if (isMobile) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      chipsWidget,
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [actionsWidget],
                      ),
                    ],
                  );
                } else {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: chipsWidget),
                      actionsWidget,
                    ],
                  );
                }
              },
            ),
          ),

          const Divider(),

          Expanded(
            child: CustomScrollView(
              slivers: [
                // Subfolders Grid/List
                if (subfoldersList.isNotEmpty) ...[
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        'Folders',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 220,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.35,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final folderName = subfoldersList[index];
                          final targetPath = currentFullPath.isEmpty ? folderName : '$currentFullPath/$folderName';
                          
                          // Count contents under targetPath recursively
                          final rLecCount = lectures.where((l) => l.subject == _selectedSubject && l.type != 'folder' && (l.chapter == targetPath || l.chapter.startsWith('$targetPath/'))).length;
                          final rNoteCount = notes.where((n) => n.subject == _selectedSubject && (n.chapter == targetPath || n.chapter.startsWith('$targetPath/'))).length;
                          final rDppCount = dpps.where((d) => d.subject == _selectedSubject && (d.chapter == targetPath || d.chapter.startsWith('$targetPath/'))).length;
                          final totalItems = rLecCount + rNoteCount + rDppCount;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _currentPath.add(folderName);
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.purple.shade100, width: 1.2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.purple.shade900.withValues(alpha: 0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  )
                                ],
                              ),
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.purple.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          Icons.folder,
                                          color: Colors.purple.shade700,
                                          size: 24,
                                        ),
                                      ),
                                      PopupMenuButton<String>(
                                        icon: Icon(Icons.more_vert, size: 16, color: Colors.grey.shade600),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onSelected: (val) {
                                          if (val == 'rename') {
                                            _showRenameFolderDialog(context, service, folderName);
                                          } else if (val == 'delete') {
                                            _showDeleteFolderDialog(
                                              context,
                                              service,
                                              folderName,
                                              lectures: lectures,
                                              notes: notes,
                                              dpps: dpps,
                                            );
                                          } else if (val == 'copy') {
                                            FolderClipboard.copy(
                                              courseId: widget.courseId,
                                              subject: _selectedSubject!,
                                              folderPath: currentFullPath,
                                              folderName: folderName,
                                            );
                                            setState(() {});
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Folder "$folderName" copied to clipboard.')),
                                            );
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          const PopupMenuItem(
                                            value: 'copy',
                                            child: Row(
                                              children: [
                                                Icon(Icons.copy, size: 14),
                                                SizedBox(width: 8),
                                                Text('Copy', style: TextStyle(fontSize: 13)),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: 'rename',
                                            child: Row(
                                              children: [
                                                Icon(Icons.edit, size: 14),
                                                SizedBox(width: 8),
                                                Text('Rename', style: TextStyle(fontSize: 13)),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: 'delete',
                                            child: Row(
                                              children: [
                                                Icon(Icons.delete, color: Colors.red, size: 14),
                                                SizedBox(width: 8),
                                                Text('Delete', style: TextStyle(color: Colors.red, fontSize: 13)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        folderName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: Colors.grey.shade800,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.insert_drive_file_outlined,
                                            size: 10,
                                            color: Colors.grey.shade500,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            totalItems == 0 ? 'Empty' : '$totalItems items',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey.shade600,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        childCount: subfoldersList.length,
                      ),
                    ),
                  ),
                ],

                // Files / Resources Reorderable list
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(left: 16, right: 16, top: 20, bottom: 8),
                    child: Text(
                      'Files & Resources',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                  ),
                ),

                if (combinedFiles.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          'No files at this folder level.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = combinedFiles[index];
                          return _buildFileItemTile(context, service, item, notes, dpps);
                        },
                        childCount: combinedFiles.length,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _activeFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _activeFilter = value;
          });
        }
      },
      selectedColor: Colors.indigo.shade100,
      labelStyle: TextStyle(
        color: isSelected ? Colors.indigo.shade900 : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  // ================= BREADCRUMBS DESIGN =================
  Widget _buildBreadcrumbs() {
    final List<Widget> children = [];

    // Home / Subject Root Button
    children.add(
      IconButton(
        icon: const Icon(Icons.home, size: 20),
        onPressed: () {
          setState(() {
            _selectedSubject = null;
            _currentPath = [];
          });
        },
      ),
    );

    if (_selectedSubject != null) {
      children.add(const Icon(Icons.chevron_right, size: 16, color: Colors.grey));
      children.add(
        TextButton(
          onPressed: () {
            setState(() {
              _currentPath = [];
            });
          },
          child: Text(
            _selectedSubject!,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
      );
    }

    for (int i = 0; i < _currentPath.length; i++) {
      final segment = _currentPath[i];
      children.add(const Icon(Icons.chevron_right, size: 16, color: Colors.grey));
      children.add(
        TextButton(
          onPressed: () {
            setState(() {
              _currentPath = _currentPath.sublist(0, i + 1);
            });
          },
          child: Text(
            segment,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      color: Colors.grey.shade100,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: children,
        ),
      ),
    );
  }

  // ================= INDIVIDUAL FILE ROW TILE =================
  Widget _buildFileItemTile(
    BuildContext context,
    FirebaseAdminService service,
    dynamic item,
    List<AdminNote> allNotes,
    List<AdminDpp> allDpps,
  ) {
    IconData iconData = Icons.insert_drive_file;
    Color iconColor = Colors.grey;
    String typeLabel = '';
    String title = '';
    String subtitle = '';
    String path = '';

    if (item is AdminLecture) {
      iconData = Icons.play_circle_fill;
      iconColor = Colors.red.shade700;
      typeLabel = 'Video';
      title = item.title;
      subtitle = item.lectureNo != null ? 'Lecture #${item.lectureNo}' : 'Lecture Video';
      path = item.storagePath;
    } else if (item is AdminNote) {
      iconData = Icons.picture_as_pdf;
      iconColor = Colors.orange.shade700;
      typeLabel = 'Note';
      title = item.title;
      subtitle = item.subtitle.isNotEmpty ? item.subtitle : 'PDF Document';
      path = item.pdfUrl;
    } else if (item is AdminDpp) {
      iconData = Icons.assignment;
      iconColor = Colors.green.shade700;
      typeLabel = 'DPP';
      title = item.title;
      subtitle = 'Daily Practice Problem';
      path = item.dppPdfUrl;
    }

    final isLec = item is AdminLecture;
    final isSelected = isLec && _selectedLectureIds.contains(item.id);

    return Opacity(
      opacity: (_isSelectMode && !isLec) ? 0.4 : 1.0,
      child: Card(
        elevation: 0.5,
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: Icon(iconData, color: iconColor, size: 28),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      typeLabel,
                      style: TextStyle(color: iconColor, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (isLec && item.linkedCourses.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => _openManageLinkedCoursesDialog(context, service, item),
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.teal.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.teal.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.link, color: Colors.teal, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              '${item.linkedCourses.length} Linked',
                              style: const TextStyle(color: Colors.teal, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                  Text(subtitle, style: const TextStyle(fontSize: 12)),
                ],
              ),
              const SizedBox(height: 4),
              Text(path, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
          trailing: _isSelectMode
              ? (isLec
                  ? Checkbox(
                      value: isSelected,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedLectureIds.add(item.id);
                          } else {
                            _selectedLectureIds.remove(item.id);
                          }
                        });
                      },
                    )
                  : const SizedBox.shrink())
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isLec && item.linkedCourses.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.hub, size: 20, color: Colors.teal),
                        tooltip: 'Manage Linked Courses (Bulk & Single)',
                        onPressed: () => _openManageLinkedCoursesDialog(context, service, item),
                      )
                    else if (isLec)
                      IconButton(
                        icon: const Icon(Icons.share, size: 20, color: Colors.blue),
                        tooltip: 'Link to Batches',
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => Provider<FirebaseAdminService>.value(
                              value: service,
                              child: LinkLectureToBatchDialog(
                                lectures: [item],
                                sourceCourseId: widget.courseId,
                                sourceBatchId: widget.batchId,
                              ),
                            ),
                          );
                        },
                      ),
                    if (isLec && item.linkedCourses.isEmpty && _hasLinkedCopies(item))
                      IconButton(
                        icon: const Icon(Icons.sync, size: 20, color: Colors.teal),
                        tooltip: 'Sync to All Linked Courses',
                        onPressed: () => _confirmAndSyncLecture(context, service, item),
                      ),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () => _showEditResourceDialog(
                        context,
                        service,
                        existingItem: item,
                        allNotes: allNotes,
                        allDpps: allDpps,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                      onPressed: () => _showDeleteResourceConfirmation(context, service, item),
                    ),
                  ],
                ),
          onTap: (_isSelectMode && isLec)
              ? () {
                  setState(() {
                    if (isSelected) {
                      _selectedLectureIds.remove(item.id);
                    } else {
                      _selectedLectureIds.add(item.id);
                    }
                  });
                }
              : null,
        ),
      ),
    );
  }

  // ================= DIALOGS & ACTIONS =================

  Future<void> _pickAndUploadSubjectLogoForSubject(
    BuildContext context,
    FirebaseAdminService service,
    String subjectName,
  ) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not read image file bytes'), backgroundColor: Colors.red),
      );
      return;
    }

    final mimeType = lookupMimeType(file.name) ?? 'image/jpeg';
    try {
      final logoUrl = await service.uploadSubjectLogo(
        widget.courseId,
        subjectName,
        bytes,
        mimeType,
      );
      await service.updateCourseSubjectLogo(widget.courseId, subjectName, logoUrl);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logo updated for $subjectName!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading logo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddSubjectDialog(BuildContext context, FirebaseAdminService service) {
    final controller = TextEditingController();
    Uint8List? selectedLogoBytes;
    String? selectedLogoName;
    String? selectedLogoMime;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Subject'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        labelText: 'Subject Name *',
                        hintText: 'e.g. Physics',
                        border: OutlineInputBorder(),
                      ),
                      autofocus: true,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Subject Logo (Optional)',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (selectedLogoBytes != null)
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.memory(
                              selectedLogoBytes!,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              selectedLogoName ?? 'Selected Image',
                              style: const TextStyle(fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red, size: 20),
                            onPressed: () {
                              setDialogState(() {
                                selectedLogoBytes = null;
                                selectedLogoName = null;
                                selectedLogoMime = null;
                              });
                            },
                          ),
                        ],
                      )
                    else
                      OutlinedButton.icon(
                        onPressed: () async {
                          final result = await FilePicker.platform.pickFiles(
                            type: FileType.image,
                            withData: true,
                          );
                          if (result != null && result.files.isNotEmpty) {
                            final file = result.files.first;
                            if (file.bytes != null) {
                              setDialogState(() {
                                selectedLogoBytes = file.bytes;
                                selectedLogoName = file.name;
                                selectedLogoMime = lookupMimeType(file.name) ?? 'image/jpeg';
                              });
                            }
                          }
                        },
                        icon: const Icon(Icons.add_a_photo, size: 18),
                        label: const Text('Upload Logo'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.indigo,
                          side: BorderSide(color: Colors.indigo.shade200),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final name = controller.text.trim();
                    if (name.isNotEmpty) {
                      Navigator.pop(dialogContext);
                      await service.addSubjectFolderToCourse(widget.courseId, name);
                      if (selectedLogoBytes != null) {
                        try {
                          final logoUrl = await service.uploadSubjectLogo(
                            widget.courseId,
                            name,
                            selectedLogoBytes!,
                            selectedLogoMime ?? 'image/jpeg',
                          );
                          await service.updateCourseSubjectLogo(widget.courseId, name, logoUrl);
                        } catch (e) {
                          debugPrint('Error uploading subject logo: $e');
                        }
                      }
                      setState(() {
                        _selectedSubject = name;
                        _currentPath = [];
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddFolderDialog(BuildContext context, FirebaseAdminService service) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Subfolder'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Folder Name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                // Save explicit folder placeholder
                final placeholder = AdminLecture(
                  id: '',
                  title: name,
                  description: '',
                  orderIndex: 999, // push to bottom
                  type: 'folder',
                  storagePath: '',
                  isLocked: false,
                  subject: _selectedSubject!,
                  chapter: _currentPath.join('/'),
                );
                if (widget.isRecordedBatch) {
                  await service.saveRecordedBatchLecture(widget.courseId, widget.batchId, placeholder, isNew: true);
                } else {
                  await service.saveLecture(widget.courseId, placeholder, isNew: true);
                }
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showRenameFolderDialog(BuildContext context, FirebaseAdminService service, String oldName) {
    final controller = TextEditingController(text: oldName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Folder'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Folder Name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != oldName) {
                final currentFullPath = _currentPath.join('/');
                final oldPath = currentFullPath.isEmpty ? oldName : '$currentFullPath/$oldName';
                final newPath = currentFullPath.isEmpty ? newName : '$currentFullPath/$newName';

                // Call recursive rename in background
                await service.recursivelyRenameFolder(
                  courseId: widget.courseId,
                  subject: _selectedSubject!,
                  oldFolderPath: oldPath,
                  newFolderPath: newPath,
                );
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _showDeleteFolderDialog(
    BuildContext context,
    FirebaseAdminService service,
    String folderName, {
    required List<AdminLecture> lectures,
    required List<AdminNote> notes,
    required List<AdminDpp> dpps,
  }) {
    final currentFullPath = _currentPath.join('/');
    final targetPath = currentFullPath.isEmpty ? folderName : '$currentFullPath/$folderName';

    // Count contents under targetPath recursively
    final rLecCount = lectures.where((l) => l.subject == _selectedSubject && l.type != 'folder' && (l.chapter == targetPath || l.chapter.startsWith('$targetPath/'))).length;
    final rNoteCount = notes.where((n) => n.subject == _selectedSubject && (n.chapter == targetPath || n.chapter.startsWith('$targetPath/'))).length;
    final rDppCount = dpps.where((d) => d.subject == _selectedSubject && (d.chapter == targetPath || d.chapter.startsWith('$targetPath/'))).length;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Folder Recursively?'),
        content: Text(
          'Are you sure you want to delete "$folderName" and ALL its nested contents?\n\n'
          'This includes:\n'
          '• $rLecCount Lecture(s)\n'
          '• $rNoteCount Note(s)\n'
          '• $rDppCount DPP(s)\n\n'
          'This action is permanent and cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await service.recursivelyDeleteFolder(
                courseId: widget.courseId,
                subject: _selectedSubject!,
                folderPath: targetPath,
              );
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Delete All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeleteSubjectDialog(
    BuildContext context,
    FirebaseAdminService service,
    String subject,
    List<AdminLecture> lectures,
    List<AdminNote> notes,
    List<AdminDpp> dpps,
  ) {
    // Count contents under this subject
    final rLecCount = lectures.where((l) => l.subject == subject && l.type != 'folder').length;
    final rNoteCount = notes.where((n) => n.subject == subject).length;
    final rDppCount = dpps.where((d) => d.subject == subject).length;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Subject?'),
        content: Text(
          'Are you sure you want to delete "$subject" and ALL its nested contents?\n\n'
          'This includes:\n'
          '• $rLecCount Lecture(s)\n'
          '• $rNoteCount Note(s)\n'
          '• $rDppCount DPP(s)\n\n'
          'This action is permanent and cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await service.deleteSubjectRecursive(
                courseId: widget.courseId,
                subject: subject,
              );
              // Clean up subject logo from course document
              await service.removeCourseSubjectLogo(widget.courseId, subject);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Delete All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _handlePaste(
    BuildContext context,
    FirebaseAdminService service,
    List<AdminLecture> lectures,
    List<AdminNote> notes,
    List<AdminDpp> dpps,
  ) async {
    if (!FolderClipboard.hasData) return;

    final String sourceCourseId = FolderClipboard.sourceCourseId!;
    final String sourceSubject = FolderClipboard.sourceSubject!;
    final String sourceFolderPath = FolderClipboard.sourceFolderPath!;
    final String sourceFolderName = FolderClipboard.sourceFolderName!;

    final currentFullPath = _currentPath.join('/');

    // Check collision against direct subfolders
    final Set<String> directSubfolders = {};
    void checkPath(String ch) {
      if (ch.isEmpty) return;
      if (currentFullPath.isEmpty) {
        final parts = ch.split('/');
        if (parts.isNotEmpty) directSubfolders.add(parts[0]);
      } else {
        final prefix = '$currentFullPath/';
        if (ch.startsWith(prefix)) {
          final remainder = ch.substring(prefix.length);
          final parts = remainder.split('/');
          if (parts.isNotEmpty) directSubfolders.add(parts[0]);
        }
      }
    }

    for (final l in lectures) {
      if (l.subject == _selectedSubject && l.type == 'folder') {
        checkPath(l.chapter.isEmpty ? l.title : '${l.chapter}/${l.title}');
      }
    }
    for (final l in lectures) {
      if (l.subject == _selectedSubject && l.type != 'folder') checkPath(l.chapter);
    }
    for (final n in notes) {
      if (n.subject == _selectedSubject) checkPath(n.chapter);
    }
    for (final d in dpps) {
      if (d.subject == _selectedSubject) checkPath(d.chapter);
    }

    String targetName = sourceFolderName;
    bool hasCollision = directSubfolders.contains(sourceFolderName);

    if (hasCollision) {
      // Show confirmation/warning dialog
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Folder Conflict'),
          content: Text(
            'A folder named "$sourceFolderName" already exists in this location. '
            'Would you like to paste it and auto-rename it?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Rename & Paste'),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      // Auto rename
      int count = 1;
      targetName = '$sourceFolderName (Copy)';
      while (directSubfolders.contains(targetName)) {
        count++;
        targetName = '$sourceFolderName (Copy) $count';
      }
    }

    // Perform paste
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pasting folder, please wait...')),
    );

    try {
      await service.pasteFolder(
        sourceCourseId: sourceCourseId,
        sourceSubject: sourceSubject,
        sourceFolderPath: sourceFolderPath,
        sourceFolderName: sourceFolderName,
        targetCourseId: widget.courseId,
        targetSubject: _selectedSubject!,
        targetFolderPath: currentFullPath,
        targetFolderName: targetName,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully pasted folder to "$targetName"')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to paste folder: $e')),
        );
      }
    }
  }

  void _handlePasteSubject(
    BuildContext context,
    FirebaseAdminService service,
    List<AdminLecture> lectures,
    List<AdminNote> notes,
    List<AdminDpp> dpps,
  ) async {
    if (!FolderClipboard.hasData || !FolderClipboard.isSubjectOnly) return;

    final String sourceCourseId = FolderClipboard.sourceCourseId!;
    final String sourceSubject = FolderClipboard.sourceSubject!;

    // Prompt for new subject name
    final controller = TextEditingController(text: '$sourceSubject Copy');
    final targetSubjectName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Paste Subject'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter the name for the pasted subject:'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Subject Name',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(context, name);
              }
            },
            child: const Text('Paste'),
          ),
        ],
      ),
    );

    if (targetSubjectName == null || targetSubjectName.isEmpty) return;

    // Check conflict (if a subject with this name already exists in current list)
    final Set<String> currentSubjects = {};
    for (final l in lectures) {
      if (l.subject.isNotEmpty && l.type != 'folder') currentSubjects.add(l.subject);
    }
    for (final n in notes) {
      if (n.subject.isNotEmpty) currentSubjects.add(n.subject);
    }
    for (final d in dpps) {
      if (d.subject.isNotEmpty) currentSubjects.add(d.subject);
    }

    if (currentSubjects.contains(targetSubjectName)) {
      final merge = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Subject Conflict'),
          content: Text(
            'A subject named "$targetSubjectName" already exists. '
            'Pasting will merge the contents into the existing subject. Proceed?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Merge'),
            ),
          ],
        ),
      );
      if (merge != true) return;
    }

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pasting subject, please wait...')),
    );

    try {
      await service.pasteSubject(
        sourceCourseId: sourceCourseId,
        sourceSubject: sourceSubject,
        targetCourseId: widget.courseId,
        targetSubject: targetSubjectName,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully pasted subject to "$targetSubjectName"')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to paste subject: $e')),
        );
      }
    }
  }

  // ================= GENERAL RESOURCE CREATION / EDIT DIALOG =================
  void _showAddResourceDialog(
    BuildContext context,
    FirebaseAdminService service,
    List<AdminNote> allNotes,
    List<AdminDpp> allDpps,
  ) {
    // Show select resource type dialog
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Select Resource Type'),
        children: [
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              _showEditResourceDialog(
                context,
                service,
                newType: 'video',
                allNotes: allNotes,
                allDpps: allDpps,
              );
            },
            child: const Row(
              children: [
                Icon(Icons.play_circle_fill, color: Colors.red),
                SizedBox(width: 12),
                Text('Lecture Video'),
              ],
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              _showEditResourceDialog(
                context,
                service,
                newType: 'note',
                allNotes: allNotes,
                allDpps: allDpps,
              );
            },
            child: Row(
              children: [
                Icon(Icons.picture_as_pdf, color: Colors.orange.shade700),
                SizedBox(width: 12),
                Text('Lecture Note (PDF)'),
              ],
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              _showEditResourceDialog(
                context,
                service,
                newType: 'dpp',
                allNotes: allNotes,
                allDpps: allDpps,
              );
            },
            child: Row(
              children: [
                Icon(Icons.assignment, color: Colors.green.shade700),
                SizedBox(width: 12),
                Text('Daily Practice Problem (DPP)'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _hasLinkedCopies(dynamic item) {
    if (item is AdminLecture) {
      return item.linkedCourses.isNotEmpty || (item.linkedFrom != null && item.linkedFrom!.isNotEmpty);
    }
    return false;
  }

  void _openManageLinkedCoursesDialog(BuildContext context, FirebaseAdminService service, AdminLecture item) {
    showDialog(
      context: context,
      builder: (_) => Provider<FirebaseAdminService>.value(
        value: service,
        child: ManageLinkedCoursesDialog(
          lecture: item,
          sourceCourseId: widget.courseId,
        ),
      ),
    ).then((val) {
      if (val == true && mounted) setState(() {});
    });
  }

  Future<void> _bulkSyncSelectedLectures(
    BuildContext context,
    FirebaseAdminService service,
    List<AdminLecture> allLectures,
  ) async {
    final selectedLectures = allLectures
        .where((lec) => _selectedLectureIds.contains(lec.id))
        .toList();

    if (selectedLectures.isEmpty) return;

    int totalSynced = 0;
    for (final lec in selectedLectures) {
      if (_hasLinkedCopies(lec)) {
        final count = await service.syncLectureToLinkedCourses(
          sourceCourseId: widget.courseId,
          lecture: lec,
        );
        totalSynced += count;
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully synced ${selectedLectures.length} selected lecture(s) across $totalSynced location(s) in one go!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _bulkDelinkSelectedLectures(
    BuildContext context,
    FirebaseAdminService service,
    List<AdminLecture> allLectures,
  ) async {
    final selectedLectures = allLectures
        .where((lec) => _selectedLectureIds.contains(lec.id))
        .toList();

    if (selectedLectures.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delink Selected Lectures in One Go?'),
        content: Text(
          'This will delink all ${selectedLectures.length} selected lectures from their linked courses. They will become independent copies.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delink Selected Now'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    for (final lec in selectedLectures) {
      if (lec.linkedCourses.isNotEmpty) {
        await service.delinkAllLinkedCoursesForLecture(
          sourceCourseId: widget.courseId,
          lectureId: lec.id,
        );
      } else if (lec.linkedFrom != null) {
        await service.delinkLecture(widget.courseId, lec.id);
      }
    }

    if (mounted) {
      setState(() {
        _selectedLectureIds.clear();
        _isSelectMode = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selected lectures delinked in one go!'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  Future<void> _confirmAndSyncLecture(BuildContext context, FirebaseAdminService service, AdminLecture lecture) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sync Lecture to Linked Courses?'),
        content: Text(
          'This will update details for "${lecture.title}" in all other courses where this lecture is shared/linked.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.sync),
            label: const Text('Sync Now'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final updatedCount = await service.syncLectureToLinkedCourses(
        sourceCourseId: widget.courseId,
        lecture: lecture,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(updatedCount > 0
                ? 'Successfully synced lecture across $updatedCount linked course(s).'
                : 'No other linked copies found to sync.'),
            backgroundColor: updatedCount > 0 ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to sync lecture: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showEditResourceDialog(
    BuildContext context,
    FirebaseAdminService service, {
    dynamic existingItem,
    String? newType,
    List<AdminNote> allNotes = const [],
    List<AdminDpp> allDpps = const [],
  }) {
    final type = existingItem != null
        ? (existingItem is AdminLecture
            ? 'video'
            : (existingItem is AdminNote ? 'note' : 'dpp'))
        : newType!;

    final titleController = TextEditingController();
    final val1Controller = TextEditingController(); // videoURL / pdfURL / dppPdfURL
    final val2Controller = TextEditingController(); // lectureNo / subtitle / solutionPdfURL

    if (existingItem != null) {
      if (existingItem is AdminLecture) {
        titleController.text = existingItem.title;
        val1Controller.text = existingItem.storagePath;
        val2Controller.text = existingItem.lectureNo?.toString() ?? '';
      } else if (existingItem is AdminNote) {
        titleController.text = existingItem.title;
        val1Controller.text = existingItem.pdfUrl;
        val2Controller.text = existingItem.subtitle;
      } else if (existingItem is AdminDpp) {
        titleController.text = existingItem.title;
        val1Controller.text = existingItem.dppPdfUrl;
        val2Controller.text = existingItem.solutionPdfUrl;
      }
    }

    final currentFullPath = _currentPath.join('/');
    final localNotes = allNotes
        .where((n) => n.subject == _selectedSubject && n.chapter == currentFullPath)
        .toList();
    final localDpps = allDpps
        .where((d) => d.subject == _selectedSubject && d.chapter == currentFullPath)
        .toList();

    final selectedNoteIds = <String>[];
    final selectedDppIds = <String>[];

    if (existingItem != null && existingItem is AdminLecture) {
      selectedNoteIds.addAll(existingItem.linkedNoteIds);
      for (final note in localNotes) {
        if (note.lectureId == existingItem.id && !selectedNoteIds.contains(note.id)) {
          selectedNoteIds.add(note.id);
        }
      }
      for (final dpp in localDpps) {
        if (dpp.lectureId == existingItem.id) {
          selectedDppIds.add(dpp.id);
        }
      }
    }

    showDialog(
      context: context,
      builder: (context) => Provider<FirebaseAdminService>.value(
        value: service,
        child: StatefulBuilder(
          builder: (context, dialogSetState) {
            return AlertDialog(
              title: Text(existingItem == null ? 'New $type' : 'Edit $type'),
              content: SizedBox(
                width: 450,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: val1Controller,
                        decoration: InputDecoration(
                          labelText: type == 'video'
                              ? 'YouTube Video URL'
                              : (type == 'note' ? 'Note PDF URL' : 'DPP PDF URL'),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      if (type == 'note' || type == 'dpp') ...[
                        const SizedBox(height: 8),
                        MediaUploader(
                          path: 'courses/${widget.courseId}/batches/${widget.batchId}/$type',
                          onUploadComplete: (url) {
                            val1Controller.text = url;
                          },
                        ),
                      ],
                      const SizedBox(height: 12),
                      if (type == 'video') ...[
                        TextField(
                          controller: val2Controller,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Lecture Number (Optional)', border: OutlineInputBorder()),
                        ),
                        const Divider(height: 32),
                        Row(
                          children: [
                            Icon(Icons.description, color: Colors.orange.shade700, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Link Notes in this Folder',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (localNotes.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'No Notes found in this folder. Add Notes first to link them.',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                            ),
                          )
                        else
                          Container(
                            constraints: const BoxConstraints(maxHeight: 180),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: localNotes.length,
                              itemBuilder: (context, idx) {
                                final note = localNotes[idx];
                                final isChecked = selectedNoteIds.contains(note.id);
                                return CheckboxListTile(
                                  value: isChecked,
                                  title: Text(
                                    note.title,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: note.subtitle.isNotEmpty
                                      ? Text(note.subtitle, style: const TextStyle(fontSize: 11))
                                      : null,
                                  dense: true,
                                  activeColor: Colors.indigo,
                                  onChanged: (val) {
                                    dialogSetState(() {
                                      if (val == true) {
                                        selectedNoteIds.add(note.id);
                                      } else {
                                        selectedNoteIds.remove(note.id);
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                        const Divider(height: 32),
                        Row(
                          children: [
                            Icon(Icons.assignment, color: Colors.purple.shade700, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Link DPPs in this Folder',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (localDpps.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'No DPPs found in this folder. Add DPPs first to link them.',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                            ),
                          )
                        else
                          Container(
                            constraints: const BoxConstraints(maxHeight: 180),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: localDpps.length,
                              itemBuilder: (context, idx) {
                                final dpp = localDpps[idx];
                                final isChecked = selectedDppIds.contains(dpp.id);
                                return CheckboxListTile(
                                  value: isChecked,
                                  title: Text(
                                    dpp.title,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  dense: true,
                                  activeColor: Colors.indigo,
                                  onChanged: (val) {
                                    dialogSetState(() {
                                      if (val == true) {
                                        selectedDppIds.add(dpp.id);
                                      } else {
                                        selectedDppIds.remove(dpp.id);
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                      ] else if (type == 'note')
                        TextField(
                          controller: val2Controller,
                          decoration: const InputDecoration(labelText: 'Note Subtitle (Optional)', border: OutlineInputBorder()),
                        )
                      else if (type == 'dpp')
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: val2Controller,
                              decoration: const InputDecoration(labelText: 'Solution PDF URL (Optional)', border: OutlineInputBorder()),
                            ),
                            const SizedBox(height: 8),
                            MediaUploader(
                              path: 'courses/${widget.courseId}/batches/${widget.batchId}/solutions',
                              onUploadComplete: (url) {
                                val2Controller.text = url;
                              },
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                if (existingItem is AdminLecture && _hasLinkedCopies(existingItem))
                  TextButton.icon(
                    icon: const Icon(Icons.sync, size: 16, color: Colors.teal),
                    label: const Text('Sync Linked Courses', style: TextStyle(color: Colors.teal)),
                    onPressed: () async {
                      final title = titleController.text.trim();
                      final val1 = val1Controller.text.trim();
                      final val2 = val2Controller.text.trim();
                      if (title.isEmpty || val1.isEmpty) return;
                      final currentFullPath = _currentPath.join('/');
                      final updatedLecture = AdminLecture(
                        id: existingItem.id,
                        title: title,
                        description: existingItem.description,
                        orderIndex: existingItem.orderIndex,
                        type: 'video',
                        storagePath: val1,
                        isLocked: existingItem.isLocked,
                        subject: _selectedSubject!,
                        chapter: currentFullPath,
                        lectureNo: int.tryParse(val2),
                        linkedNoteIds: selectedNoteIds,
                        linkedCourses: existingItem.linkedCourses,
                        linkedFrom: existingItem.linkedFrom,
                      );
                      await service.saveLecture(widget.courseId, updatedLecture, isNew: false);
                      if (context.mounted) Navigator.pop(context);
                      if (context.mounted) {
                        _confirmAndSyncLecture(context, service, updatedLecture);
                      }
                    },
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final title = titleController.text.trim();
                    final val1 = val1Controller.text.trim();
                    final val2 = val2Controller.text.trim();

                    if (title.isEmpty || val1.isEmpty) return;

                    final currentFullPath = _currentPath.join('/');

                    if (type == 'video') {
                      final lecture = AdminLecture(
                        id: existingItem?.id ?? '',
                        title: title,
                        description: existingItem is AdminLecture ? existingItem.description : '',
                        orderIndex: existingItem?.orderIndex ?? 0,
                        type: 'video',
                        storagePath: val1,
                        isLocked: existingItem?.isLocked ?? false,
                        subject: _selectedSubject!,
                        chapter: currentFullPath,
                        lectureNo: int.tryParse(val2),
                        linkedNoteIds: selectedNoteIds,
                        linkedCourses: existingItem is AdminLecture ? existingItem.linkedCourses : const [],
                        linkedFrom: existingItem is AdminLecture ? existingItem.linkedFrom : null,
                      );
                      final savedId = widget.isRecordedBatch
                          ? await service.saveRecordedBatchLecture(widget.courseId, widget.batchId, lecture, isNew: existingItem == null)
                          : await service.saveLecture(widget.courseId, lecture, isNew: existingItem == null);
 
                      // Update note lectureIds
                      for (final note in localNotes) {
                        final isSelected = selectedNoteIds.contains(note.id);
                        final wasSelected = note.lectureId == savedId;
                        if (isSelected != wasSelected) {
                          final updatedNote = AdminNote(
                            id: note.id,
                            title: note.title,
                            subtitle: note.subtitle,
                            pdfUrl: note.pdfUrl,
                            createdAt: note.createdAt,
                            subject: note.subject,
                            chapter: note.chapter,
                            lectureId: isSelected ? savedId : null,
                          );
                          if (widget.isRecordedBatch) {
                            await service.saveRecordedBatchNote(widget.courseId, widget.batchId, updatedNote, isNew: false);
                          } else {
                            await service.saveCourseNote(widget.courseId, updatedNote, isNew: false);
                          }
                        }
                      }
 
                      // Update dpp lectureIds
                      for (final dpp in localDpps) {
                        final isSelected = selectedDppIds.contains(dpp.id);
                        final wasSelected = dpp.lectureId == savedId;
                        if (isSelected != wasSelected) {
                          final updatedDpp = AdminDpp(
                            id: dpp.id,
                            title: dpp.title,
                            subject: dpp.subject,
                            chapter: dpp.chapter,
                            dppPdfUrl: dpp.dppPdfUrl,
                            solutionPdfUrl: dpp.solutionPdfUrl,
                            lectureId: isSelected ? savedId : null,
                            createdAt: dpp.createdAt,
                          );
                          if (widget.isRecordedBatch) {
                            await service.saveRecordedBatchDpp(widget.courseId, widget.batchId, updatedDpp, isNew: false);
                          } else {
                            await service.saveCourseDpp(widget.courseId, updatedDpp, isNew: false);
                          }
                        }
                      }
                    } else if (type == 'note') {
                      final note = AdminNote(
                        id: existingItem?.id ?? '',
                        title: title,
                        subtitle: val2,
                        pdfUrl: val1,
                        createdAt: existingItem?.createdAt ?? DateTime.now(),
                        subject: _selectedSubject!,
                        chapter: currentFullPath,
                      );
                      if (widget.isRecordedBatch) {
                        await service.saveRecordedBatchNote(widget.courseId, widget.batchId, note, isNew: existingItem == null);
                      } else {
                        await service.saveCourseNote(widget.courseId, note, isNew: existingItem == null);
                      }
                    } else if (type == 'dpp') {
                      final dpp = AdminDpp(
                        id: existingItem?.id ?? '',
                        title: title,
                        subject: _selectedSubject!,
                        chapter: currentFullPath,
                        dppPdfUrl: val1,
                        solutionPdfUrl: val2,
                        createdAt: existingItem?.createdAt ?? DateTime.now(),
                      );
                      if (widget.isRecordedBatch) {
                        await service.saveRecordedBatchDpp(widget.courseId, widget.batchId, dpp, isNew: existingItem == null);
                      } else {
                        await service.saveCourseDpp(widget.courseId, dpp, isNew: existingItem == null);
                      }
                    }

                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showDeleteResourceConfirmation(
    BuildContext context,
    FirebaseAdminService service,
    dynamic item,
  ) {
    String type = '';
    String title = '';

    if (item is AdminLecture) {
      type = 'Lecture Video';
      title = item.title;
    } else if (item is AdminNote) {
      type = 'Note PDF';
      title = item.title;
    } else if (item is AdminDpp) {
      type = 'DPP';
      title = item.title;
    }

    if (item is AdminLecture && _hasLinkedCopies(item)) {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Linked Lecture Options'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '"${item.title}" is linked across courses.',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Choose what you would like to do:',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🔗 Delink', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                    SizedBox(height: 2),
                    Text(
                      'Removes sync connection. The lecture stays in this course as an independent copy.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🗑️ Delete', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                    SizedBox(height: 2),
                    Text(
                      'Warning: Permanently removes the lecture from this course/batch.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.link_off, size: 16),
              label: const Text('Delink'),
              onPressed: () async {
                Navigator.pop(dialogContext);
                try {
                  await service.delinkLecture(widget.courseId, item.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Lecture delinked successfully (now independent)')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error delinking: $e')),
                    );
                  }
                }
              },
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.delete, size: 16),
              label: const Text('Delete'),
              onPressed: () async {
                Navigator.pop(dialogContext);
                try {
                  if (widget.isRecordedBatch) {
                    await service.deleteRecordedBatchLecture(widget.courseId, widget.batchId, item.id);
                  } else {
                    await service.deleteLecture(widget.courseId, item.id);
                  }
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Lecture deleted from this course')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error deleting: $e')),
                    );
                  }
                }
              },
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete $type'),
        content: Text('Are you sure you want to delete "$title"?\n\nThis action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              if (item is AdminLecture) {
                if (widget.isRecordedBatch) {
                  await service.deleteRecordedBatchLecture(widget.courseId, widget.batchId, item.id);
                } else {
                  await service.deleteLecture(widget.courseId, item.id);
                }
              } else if (item is AdminNote) {
                if (widget.isRecordedBatch) {
                  await service.deleteRecordedBatchNote(widget.courseId, widget.batchId, item.id);
                } else {
                  await service.deleteCourseNote(widget.courseId, item.id);
                }
              } else if (item is AdminDpp) {
                if (widget.isRecordedBatch) {
                  await service.deleteRecordedBatchDpp(widget.courseId, widget.batchId, item.id);
                } else {
                  await service.deleteCourseDpp(widget.courseId, item.id);
                }
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
