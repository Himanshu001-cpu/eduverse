import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/admin_models.dart';
import '../services/firebase_admin_service.dart';

/// Dialog that allows an admin to link an existing live class to additional
/// batches. Shows a tree of Course → Batch and lets the admin select targets.
class LinkClassToBatchDialog extends StatefulWidget {
  final AdminLiveClass liveClass;

  /// The course/batch where this class currently lives.
  final String? sourceCourseId;
  final String? sourceBatchId;

  const LinkClassToBatchDialog({
    super.key,
    required this.liveClass,
    this.sourceCourseId,
    this.sourceBatchId,
  });

  @override
  State<LinkClassToBatchDialog> createState() => _LinkClassToBatchDialogState();
}

class _LinkClassToBatchDialogState extends State<LinkClassToBatchDialog> {
  List<Map<String, dynamic>> _coursesWithBatches = [];
  bool _isLoading = true;
  String? _error;

  /// Set of selected target "courseId_batchId" keys
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

  bool _isCurrentBatch(String courseId, String batchId) {
    return courseId == widget.sourceCourseId &&
        batchId == widget.sourceBatchId;
  }

  bool _isAlreadyLinked(String courseId, String batchId) {
    return widget.liveClass.linkedBatches.any(
      (lb) => lb['courseId'] == courseId && lb['batchId'] == batchId,
    );
  }

  Future<void> _linkSelected() async {
    if (_selectedTargets.isEmpty) return;
    setState(() => _isLinking = true);

    try {
      final service = context.read<FirebaseAdminService>();
      final isFreeClass =
          (widget.sourceCourseId == null || widget.sourceCourseId!.isEmpty) &&
          (widget.sourceBatchId == null || widget.sourceBatchId!.isEmpty);

      for (final key in _selectedTargets) {
        final parts = key.split('___');
        final targetCourseId = parts[0];
        final targetBatchId = parts[1];

        if (isFreeClass) {
          await service.linkFreeLiveClassToBatch(
            sourceClass: widget.liveClass,
            targetCourseId: targetCourseId,
            targetBatchId: targetBatchId,
          );
        } else {
          await service.linkLiveClassToBatch(
            sourceClass: widget.liveClass,
            sourceCourseId: widget.sourceCourseId!,
            sourceBatchId: widget.sourceBatchId!,
            targetCourseId: targetCourseId,
            targetBatchId: targetBatchId,
          );
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Linked to ${_selectedTargets.length} batch${_selectedTargets.length > 1 ? 'es' : ''}',
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
                          'Link to Batches',
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
            if (widget.liveClass.linkedBatches.isNotEmpty)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.blue[300]),
                    const SizedBox(width: 6),
                    Text(
                      'Already linked to ${widget.liveClass.linkedBatches.length} batch${widget.liveClass.linkedBatches.length > 1 ? 'es' : ''}',
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
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedTargets.add(key);
                          } else {
                            _selectedTargets.remove(key);
                          }
                        });
                      },
                    ),
              onTap: (isCurrent || isLinked)
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
