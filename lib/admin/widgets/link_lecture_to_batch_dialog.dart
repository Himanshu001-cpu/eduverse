import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/admin_models.dart';
import '../services/firebase_admin_service.dart';

/// Dialog that allows an admin to link existing lecture(s) to additional
/// courses. Shows a list of courses and lets the admin select targets.
class LinkLectureToBatchDialog extends StatefulWidget {
  final List<AdminLecture> lectures;

  /// The course where this lecture currently lives.
  final String sourceCourseId;

  const LinkLectureToBatchDialog({
    super.key,
    required this.lectures,
    required this.sourceCourseId,
    // Keep sourceBatchId parameter for compatibility, but mark it optional/unused
    String? sourceBatchId,
  });

  @override
  State<LinkLectureToBatchDialog> createState() => _LinkLectureToBatchDialogState();
}

class _LinkLectureToBatchDialogState extends State<LinkLectureToBatchDialog> {
  List<Map<String, dynamic>> _coursesWithBatches = [];
  bool _isLoading = true;
  String? _error;

  /// Set of selected target course IDs
  final Set<String> _selectedTargets = {};
  final Set<String> _newlyLinkedKeys = {};
  bool _isLinking = false;

  @override
  void initState() {
    super.initState();
    _loadCoursesAndBatches();
  }

  Future<void> _loadCoursesAndBatches() async {
    try {
      final service = context.read<FirebaseAdminService>();
      final data = await service.getCoursesWithBatches();
      if (mounted) {
        setState(() {
          _coursesWithBatches = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  bool _isCurrentCourse(String courseId) {
    return courseId == widget.sourceCourseId;
  }

  bool _isAlreadyLinked(String courseId) {
    if (_newlyLinkedKeys.contains(courseId)) return true;
    
    // Consider it already linked if ALL selected lectures are already linked
    return widget.lectures.every(
      (lec) => lec.linkedCourses.contains(courseId),
    );
  }

  Future<void> _linkSelected() async {
    if (_selectedTargets.isEmpty || _isLinking || widget.lectures.isEmpty) return;
    final targetsSnapshot = Set<String>.from(_selectedTargets);
    setState(() => _isLinking = true);

    try {
      final service = context.read<FirebaseAdminService>();
      final List<String> succeeded = [];
      final List<Map<String, String>> failed = [];

      for (final targetCourseId in targetsSnapshot) {
        try {
          // Link all selected lectures to this target course
          for (final lecture in widget.lectures) {
            await service.linkLectureToCourse(
              sourceLecture: lecture,
              sourceCourseId: widget.sourceCourseId,
              targetCourseId: targetCourseId,
            );
          }
          succeeded.add(targetCourseId);
        } catch (e) {
          failed.add({
            'key': targetCourseId,
            'error': e.toString(),
          });
        }
      }

      if (mounted) {
        setState(() {
          for (final key in succeeded) {
            _selectedTargets.remove(key);
            _newlyLinkedKeys.add(key);
          }
        });

        if (failed.isEmpty) {
          final messenger = ScaffoldMessenger.of(context);
          Navigator.pop(context, true);
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                widget.lectures.length == 1
                    ? 'Linked to ${succeeded.length} course${succeeded.length > 1 ? 's' : ''}'
                    : 'Successfully linked ${widget.lectures.length} lectures to ${succeeded.length} course${succeeded.length > 1 ? 's' : ''}',
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Partial Link Failure'),
              content: Text(
                'Successfully linked to ${succeeded.length} courses, but failed to link to ${failed.length} courses.\n\n'
                'The failed ones remain selected. You can retry linking them.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLinking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lectureTitleText = widget.lectures.length == 1
        ? widget.lectures.first.title
        : '${widget.lectures.length} lectures selected for sharing';

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
          maxWidth: 500,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
              child: Row(
                children: [
                  const Icon(Icons.share, color: Colors.deepPurple),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.lectures.length == 1
                              ? 'Link Lecture to Courses'
                              : 'Link Lectures to Courses',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          lectureTitleText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(),

            // Existing links info (only relevant for single-lecture link info)
            if (widget.lectures.length == 1 && widget.lectures.first.linkedCourses.isNotEmpty)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.blue[300]),
                    const SizedBox(width: 6),
                    Text(
                      'Already linked to ${widget.lectures.first.linkedCourses.length} course${widget.lectures.first.linkedCourses.length > 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[400],
                      ),
                    ),
                  ],
                ),
              ),

            // Body
            Expanded(child: _buildBody()),

            // Footer with Link button
            if (!_isLoading && _error == null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      '${_selectedTargets.length} selected',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: _selectedTargets.isEmpty || _isLinking
                          ? null
                          : _linkSelected,
                      icon: _isLinking
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.link, size: 18),
                      label: Text(
                        _isLinking ? 'Linking...' : 'Link',
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Error: $_error',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }
    if (_coursesWithBatches.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('No courses found'),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: _coursesWithBatches.length,
      itemBuilder: (context, index) {
        final course = _coursesWithBatches[index];
        final courseId = course['courseId'] as String;
        final courseName = course['courseName'] as String;
        final isCurrent = _isCurrentCourse(courseId);
        final isLinked = _isAlreadyLinked(courseId);
        final isSelected = _selectedTargets.contains(courseId);

        return ListTile(
          leading: Icon(
            isCurrent
                ? Icons.home
                : isLinked
                    ? Icons.link
                    : Icons.school,
            color: isCurrent
                ? Colors.green
                : isLinked
                    ? Colors.blue
                    : Colors.deepPurple,
            size: 20,
          ),
          title: Text(
            courseName,
            style: TextStyle(
              fontSize: 14,
              color: (isCurrent || isLinked) ? Colors.grey : null,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: isCurrent
              ? const Text(
                  'Current course',
                  style: TextStyle(fontSize: 11, color: Colors.green),
                )
              : isLinked
                  ? const Text(
                      'Already linked',
                      style: TextStyle(fontSize: 11, color: Colors.blue),
                    )
                  : null,
          trailing: (isCurrent || isLinked)
              ? Icon(
                  isCurrent ? Icons.check_circle : Icons.link,
                  color: isCurrent ? Colors.green : Colors.blue,
                  size: 20,
                )
              : Checkbox(
                  value: isSelected,
                  onChanged: _isLinking
                      ? null
                      : (val) {
                          setState(() {
                            if (val == true) {
                              _selectedTargets.add(courseId);
                            } else {
                              _selectedTargets.remove(courseId);
                            }
                          });
                        },
                ),
          onTap: (isCurrent || isLinked || _isLinking)
              ? null
              : () {
                  setState(() {
                    if (_selectedTargets.contains(courseId)) {
                      _selectedTargets.remove(courseId);
                    } else {
                      _selectedTargets.add(courseId);
                    }
                  });
                },
        );
      },
    );
  }
}
