import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/admin_models.dart';
import '../services/firebase_admin_service.dart';
import 'link_lecture_to_batch_dialog.dart';
import 'link_class_to_batch_dialog.dart';

/// Modal dialog that gives complete, centralized control over all courses linked
/// to a Main Lecture or Main Live Class. Allows bulk actions (Sync All, Delink All,
/// Delete All Copies) as well as per-course control.
class ManageLinkedCoursesDialog extends StatefulWidget {
  final AdminLecture? lecture;
  final AdminLiveClass? liveClass;
  final String sourceCourseId;

  const ManageLinkedCoursesDialog({
    super.key,
    this.lecture,
    this.liveClass,
    required this.sourceCourseId,
  }) : assert(lecture != null || liveClass != null, 'Must provide either lecture or liveClass');

  @override
  State<ManageLinkedCoursesDialog> createState() => _ManageLinkedCoursesDialogState();
}

class _ManageLinkedCoursesDialogState extends State<ManageLinkedCoursesDialog> {
  bool _isLoading = true;
  bool _isProcessing = false;
  Map<String, String> _courseNames = {}; // courseId -> courseName
  List<String> _linkedCourses = [];

  @override
  void initState() {
    super.initState();
    _linkedCourses = List<String>.from(
      widget.lecture?.linkedCourses ?? widget.liveClass?.linkedCourses ?? [],
    );
    _loadCourseNames();
  }

  Future<void> _loadCourseNames() async {
    try {
      final service = context.read<FirebaseAdminService>();
      final coursesData = await service.getCoursesWithBatches();
      final Map<String, String> names = {};
      for (final item in coursesData) {
        final cid = item['courseId'] as String;
        final cname = item['courseName'] as String;
        names[cid] = cname;
      }
      if (mounted) {
        setState(() {
          _courseNames = names;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getCourseName(String cid) {
    return _courseNames[cid] ?? 'Course (ID: ${cid.length > 8 ? cid.substring(0, 8) : cid})';
  }

  bool get _isLecture => widget.lecture != null;
  String get _itemTitle => widget.lecture?.title ?? widget.liveClass?.title ?? '';

  Future<void> _syncAll() async {
    setState(() => _isProcessing = true);
    try {
      final service = context.read<FirebaseAdminService>();
      int count = 0;
      if (_isLecture) {
        count = await service.syncLectureToLinkedCourses(
          sourceCourseId: widget.sourceCourseId,
          lecture: widget.lecture!,
        );
      } else {
        count = await service.syncLiveClassToLinkedCourses(
          sourceCourseId: widget.sourceCourseId,
          liveClass: widget.liveClass!,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully synced to $count location(s) in one go!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to sync: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _delinkAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delink All Courses in One Go?'),
        content: Text(
          'This will convert linked copies in ALL ${_linkedCourses.length} courses into independent, unlinked content. Future updates to "$_itemTitle" will no longer sync to those courses.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.link_off),
            label: const Text('Delink All Now'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    if (!mounted) return;

    setState(() => _isProcessing = true);
    try {
      final service = context.read<FirebaseAdminService>();
      if (_isLecture) {
        await service.delinkAllLinkedCoursesForLecture(
          sourceCourseId: widget.sourceCourseId,
          lectureId: widget.lecture!.id,
        );
      } else {
        await service.delinkAllLinkedCoursesForLiveClass(
          sourceCourseId: widget.sourceCourseId,
          classId: widget.liveClass!.id,
        );
      }
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All courses delinked in one go! Content is now independent.'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delink: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _deleteAllCopies() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete All Linked Copies?'),
        content: Text(
          'Warning: This will permanently remove "$_itemTitle" from ALL ${_linkedCourses.length} linked target courses.\n\n(The main copy in this course will be kept).',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.delete_forever),
            label: const Text('Delete All Copies'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    if (!mounted) return;

    setState(() => _isProcessing = true);
    try {
      final service = context.read<FirebaseAdminService>();
      if (_isLecture) {
        await service.deleteAllLinkedCopiesForLecture(
          sourceCourseId: widget.sourceCourseId,
          lectureId: widget.lecture!.id,
        );
      } else {
        await service.deleteAllLinkedCopiesForLiveClass(
          sourceCourseId: widget.sourceCourseId,
          classId: widget.liveClass!.id,
        );
      }
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All linked copies removed successfully!'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete copies: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _delinkSingle(String targetCourseId) async {
    setState(() => _isProcessing = true);
    try {
      final service = context.read<FirebaseAdminService>();
      if (_isLecture) {
        await service.delinkSingleCourseFromMainLecture(
          sourceCourseId: widget.sourceCourseId,
          lectureId: widget.lecture!.id,
          targetCourseId: targetCourseId,
        );
      } else {
        await service.delinkSingleCourseFromMainLiveClass(
          sourceCourseId: widget.sourceCourseId,
          classId: widget.liveClass!.id,
          targetCourseId: targetCourseId,
        );
      }
      if (mounted) {
        setState(() {
          _linkedCourses.remove(targetCourseId);
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delinked ${_getCourseName(targetCourseId)}')),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _deleteSingle(String targetCourseId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove from this course?'),
        content: Text('Remove "$_itemTitle" from ${_getCourseName(targetCourseId)}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    if (!mounted) return;

    setState(() => _isProcessing = true);
    try {
      final service = context.read<FirebaseAdminService>();
      if (_isLecture) {
        await service.deleteSingleCourseLinkedCopy(
          sourceCourseId: widget.sourceCourseId,
          lectureId: widget.lecture!.id,
          targetCourseId: targetCourseId,
        );
      } else {
        await service.deleteSingleCourseLinkedLiveClassCopy(
          sourceCourseId: widget.sourceCourseId,
          classId: widget.liveClass!.id,
          targetCourseId: targetCourseId,
        );
      }
      if (mounted) {
        setState(() {
          _linkedCourses.remove(targetCourseId);
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Removed from ${_getCourseName(targetCourseId)}')),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _openLinkToMoreDialog() {
    final service = context.read<FirebaseAdminService>();
    if (_isLecture) {
      showDialog(
        context: context,
        builder: (_) => Provider<FirebaseAdminService>.value(
          value: service,
          child: LinkLectureToBatchDialog(
            lectures: [widget.lecture!],
            sourceCourseId: widget.sourceCourseId,
          ),
        ),
      ).then((val) {
        if (val == true && mounted) Navigator.pop(context, true);
      });
    } else {
      showDialog(
        context: context,
        builder: (_) => Provider<FirebaseAdminService>.value(
          value: service,
          child: LinkClassToBatchDialog(
            liveClass: widget.liveClass!,
            sourceCourseId: widget.sourceCourseId,
          ),
        ),
      ).then((val) {
        if (val == true && mounted) Navigator.pop(context, true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: 550,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 12),
              decoration: BoxDecoration(
                color: Colors.teal.withValues(alpha: 0.06),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Colors.teal,
                    radius: 18,
                    child: Icon(Icons.link, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Manage Linked Courses',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _itemTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13, color: Colors.grey[700]),
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
            const Divider(height: 1),

            if (_isProcessing) const LinearProgressIndicator(),

            // Main Body
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // In One Go Summary Card
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.hub, color: Colors.teal, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Linked to ${_linkedCourses.length} target course${_linkedCourses.length == 1 ? '' : 's'}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Manage all linked copies in one go:',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    FilledButton.icon(
                                      style: FilledButton.styleFrom(backgroundColor: Colors.teal),
                                      onPressed: _linkedCourses.isEmpty || _isProcessing ? null : _syncAll,
                                      icon: const Icon(Icons.sync, size: 16),
                                      label: Text('Sync All (${_linkedCourses.length})'),
                                    ),
                                    OutlinedButton.icon(
                                      onPressed: _linkedCourses.isEmpty || _isProcessing ? null : _delinkAll,
                                      icon: const Icon(Icons.link_off, size: 16),
                                      label: const Text('Delink All'),
                                    ),
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                                      onPressed: _linkedCourses.isEmpty || _isProcessing ? null : _deleteAllCopies,
                                      icon: const Icon(Icons.delete_sweep, size: 16),
                                      label: const Text('Delete All Copies'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          const Text(
                            'Linked Target Courses:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 8),

                          if (_linkedCourses.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(20),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'No target courses currently linked',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _linkedCourses.length,
                              separatorBuilder: (_, _) => const Divider(height: 1),
                              itemBuilder: (context, idx) {
                                final cid = _linkedCourses[idx];
                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  leading: const CircleAvatar(
                                    backgroundColor: Colors.deepPurple,
                                    radius: 14,
                                    child: Icon(Icons.school, size: 14, color: Colors.white),
                                  ),
                                  title: Text(
                                    _getCourseName(cid),
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                  ),
                                  subtitle: Text('Course ID: $cid', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.link_off, size: 18, color: Colors.blue),
                                        tooltip: 'Delink this course',
                                        onPressed: _isProcessing ? null : () => _delinkSingle(cid),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                        tooltip: 'Remove from this course',
                                        onPressed: _isProcessing ? null : () => _deleteSingle(cid),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _isProcessing ? null : _openLinkToMoreDialog,
                    icon: const Icon(Icons.add_link, size: 18),
                    label: const Text('+ Link to More Courses'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
