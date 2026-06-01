import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/admin_models.dart';
import '../services/firebase_admin_service.dart';

/// Dialog that allows an admin to link an existing lecture to additional
/// batches. Shows a tree of Course → Batch and lets the admin select targets.
class LinkLectureToBatchDialog extends StatefulWidget {
  final AdminLecture lecture;

  /// The course/batch where this lecture currently lives.
  final String sourceCourseId;
  final String sourceBatchId;

  const LinkLectureToBatchDialog({
    super.key,
    required this.lecture,
    required this.sourceCourseId,
    required this.sourceBatchId,
  });

  @override
  State<LinkLectureToBatchDialog> createState() => _LinkLectureToBatchDialogState();
}

class _LinkLectureToBatchDialogState extends State<LinkLectureToBatchDialog> {
  List<Map<String, dynamic>> _coursesWithBatches = [];
  bool _isLoading = true;
  String? _error;

  /// Set of selected target "courseId_batchId" keys
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

  bool _isCurrentBatch(String courseId, String batchId) {
    return courseId == widget.sourceCourseId &&
        batchId == widget.sourceBatchId;
  }

  bool _isAlreadyLinked(String courseId, String batchId) {
    final key = '${courseId}___$batchId';
    if (_newlyLinkedKeys.contains(key)) return true;
    return widget.lecture.linkedBatches.any(
      (lb) => lb['courseId'] == courseId && lb['batchId'] == batchId,
    );
  }

  Future<void> _linkSelected() async {
    if (_selectedTargets.isEmpty || _isLinking) return;
    final targetsSnapshot = Set<String>.from(_selectedTargets);
    setState(() => _isLinking = true);

    try {
      final service = context.read<FirebaseAdminService>();
      final List<String> succeeded = [];
      final List<Map<String, String>> failed = [];

      for (final key in targetsSnapshot) {
        final index = key.indexOf('___');
        if (index == -1) continue;
        final targetCourseId = key.substring(0, index);
        final targetBatchId = key.substring(index + 3);

        try {
          await service.linkLectureToBatch(
            sourceLecture: widget.lecture,
            sourceCourseId: widget.sourceCourseId,
            sourceBatchId: widget.sourceBatchId,
            targetCourseId: targetCourseId,
            targetBatchId: targetBatchId,
          );
          succeeded.add(key);
        } catch (e) {
          failed.add({
            'key': key,
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
                'Linked to ${succeeded.length} batch${succeeded.length > 1 ? 'es' : ''}',
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
                'Successfully linked to ${succeeded.length} batches, but failed to link to ${failed.length} batches.\n\n'
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
                          'Link Lecture to Batches',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.lecture.title,
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
            if (widget.lecture.linkedBatches.isNotEmpty)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.blue[300]),
                    const SizedBox(width: 6),
                    Text(
                      'Already linked to ${widget.lecture.linkedBatches.length} batch${widget.lecture.linkedBatches.length > 1 ? 'es' : ''}',
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
                  mainAxisAlignment: MainAxisAlignment.end,
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
          child: Text('No courses or batches found'),
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
        final batches =
            course['batches'] as List<Map<String, dynamic>>;

        return ExpansionTile(
          initiallyExpanded: true,
          leading: const Icon(Icons.school, color: Colors.deepPurple),
          title: Text(
            courseName,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            '${batches.length} batch${batches.length != 1 ? 'es' : ''}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          children: batches.map((batch) {
            final batchId = batch['id'] as String;
            final batchName = batch['name'] as String;
            final key = '${courseId}___$batchId';
            final isCurrent = _isCurrentBatch(courseId, batchId);
            final isLinked = _isAlreadyLinked(courseId, batchId);
            final isSelected = _selectedTargets.contains(key);

            return ListTile(
              contentPadding: const EdgeInsets.only(left: 48, right: 16),
              leading: Icon(
                isCurrent
                    ? Icons.home
                    : isLinked
                        ? Icons.link
                        : Icons.group_outlined,
                color: isCurrent
                    ? Colors.green
                    : isLinked
                        ? Colors.blue
                        : null,
                size: 20,
              ),
              title: Text(
                batchName,
                style: TextStyle(
                  fontSize: 14,
                  color: (isCurrent || isLinked)
                      ? Colors.grey
                      : null,
                ),
              ),
              subtitle: isCurrent
                  ? const Text(
                      'Current batch',
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
                                  _selectedTargets.add(key);
                                } else {
                                  _selectedTargets.remove(key);
                                }
                              });
                            },
                    ),
              onTap: (isCurrent || isLinked || _isLinking)
                  ? null
                  : () {
                      setState(() {
                        if (_selectedTargets.contains(key)) {
                          _selectedTargets.remove(key);
                        } else {
                          _selectedTargets.add(key);
                        }
                      });
                    },
            );
          }).toList(),
        );
      },
    );
  }
}
