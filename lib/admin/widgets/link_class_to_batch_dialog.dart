import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/admin_models.dart';
import '../services/firebase_admin_service.dart';

/// Dialog that allows an admin to link an existing live class to additional
/// courses. Shows a list of courses and lets the admin select targets.
class LinkClassToBatchDialog extends StatefulWidget {
  final AdminLiveClass liveClass;

  /// The course where this class currently lives.
  final String? sourceCourseId;

  const LinkClassToBatchDialog({
    super.key,
    required this.liveClass,
    this.sourceCourseId,
    // Keep sourceBatchId parameter for compatibility, but mark it optional/unused
    String? sourceBatchId,
  });

  @override
  State<LinkClassToBatchDialog> createState() => _LinkClassToBatchDialogState();
}

class _LinkClassToBatchDialogState extends State<LinkClassToBatchDialog> {
  List<Map<String, dynamic>> _coursesWithBatches = [];
  bool _isLoading = true;
  String? _error;

  /// Set of selected target course IDs
  final Set<String> _selectedTargets = {};
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
    return widget.liveClass.linkedCourses.contains(courseId);
  }

  Future<void> _linkSelected() async {
    if (_selectedTargets.isEmpty) return;
    setState(() => _isLinking = true);

    try {
      final service = context.read<FirebaseAdminService>();
      final isFreeClass = widget.sourceCourseId == null || widget.sourceCourseId!.isEmpty;

      for (final targetCourseId in _selectedTargets) {
        if (isFreeClass) {
          await service.linkFreeLiveClassToCourse(
            sourceClass: widget.liveClass,
            targetCourseId: targetCourseId,
          );
        } else {
          await service.linkLiveClassToCourse(
            sourceClass: widget.liveClass,
            sourceCourseId: widget.sourceCourseId!,
            targetCourseId: targetCourseId,
          );
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Linked to ${_selectedTargets.length} course${_selectedTargets.length > 1 ? 's' : ''}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLinking = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                        const Text(
                          'Link to Courses',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.liveClass.title,
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

            // Existing links info
            if (widget.liveClass.linkedCourses.isNotEmpty)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.blue[300]),
                    const SizedBox(width: 6),
                    Text(
                      'Already linked to ${widget.liveClass.linkedCourses.length} course${widget.liveClass.linkedCourses.length > 1 ? 's' : ''}',
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
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        _selectedTargets.add(courseId);
                      } else {
                        _selectedTargets.remove(courseId);
                      }
                    });
                  },
                ),
          onTap: (isCurrent || isLinked)
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
