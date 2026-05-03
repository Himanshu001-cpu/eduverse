import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/admin_models.dart';
import '../services/firebase_admin_service.dart';

/// Dialog that shows all existing live classes from every course/batch,
/// allowing the admin to pick one to link into the current batch.
class LinkLiveClassDialog extends StatefulWidget {
  /// The courseId + batchId of the *target* batch we want to link into.
  final String targetCourseId;
  final String targetBatchId;

  const LinkLiveClassDialog({
    super.key,
    required this.targetCourseId,
    required this.targetBatchId,
  });

  @override
  State<LinkLiveClassDialog> createState() => _LinkLiveClassDialogState();
}

class _LinkLiveClassDialogState extends State<LinkLiveClassDialog> {
  List<Map<String, dynamic>> _allClasses = [];
  List<Map<String, dynamic>> _filteredClasses = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final _searchController = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadClasses() async {
    try {
      final service = context.read<FirebaseAdminService>();
      final classes = await service.getAllLiveClassesForLinking();
      
      // Filter out classes that are already in the target batch
      final filtered = classes.where((entry) {
        return !(entry['courseId'] == widget.targetCourseId &&
            entry['batchId'] == widget.targetBatchId);
      }).toList();

      if (mounted) {
        setState(() {
          _allClasses = filtered;
          _filteredClasses = filtered;
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

  void _filterClasses(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredClasses = _allClasses;
      } else {
        final lowerQuery = query.toLowerCase();
        _filteredClasses = _allClasses.where((entry) {
          final liveClass = entry['class'] as AdminLiveClass;
          return liveClass.title.toLowerCase().contains(lowerQuery) ||
              liveClass.subject.toLowerCase().contains(lowerQuery) ||
              liveClass.instructorName.toLowerCase().contains(lowerQuery) ||
              (entry['courseName'] as String)
                  .toLowerCase()
                  .contains(lowerQuery) ||
              (entry['batchName'] as String)
                  .toLowerCase()
                  .contains(lowerQuery);
        }).toList();
      }
    });
  }

  Future<void> _linkClass(Map<String, dynamic> entry) async {
    final liveClass = entry['class'] as AdminLiveClass;
    final sourceCourseId = entry['courseId'] as String;
    final sourceBatchId = entry['batchId'] as String;

    // Show confirmation
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Link Class?'),
        content: Text(
          'Link "${liveClass.title}" from '
          '${entry['courseName']} / ${entry['batchName']} '
          'to this batch?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Link'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      final service = context.read<FirebaseAdminService>();

      if (sourceCourseId.isEmpty && sourceBatchId.isEmpty) {
        // Linking from free live classes
        await service.linkFreeLiveClassToBatch(
          sourceClass: liveClass,
          targetCourseId: widget.targetCourseId,
          targetBatchId: widget.targetBatchId,
        );
      } else {
        // Linking from another batch
        await service.linkLiveClassToBatch(
          sourceClass: liveClass,
          sourceCourseId: sourceCourseId,
          sourceBatchId: sourceBatchId,
          targetCourseId: widget.targetCourseId,
          targetBatchId: widget.targetBatchId,
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${liveClass.title}" linked successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
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
          maxWidth: 600,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
              child: Row(
                children: [
                  const Icon(Icons.link, color: Colors.blue),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Link Existing Class',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by title, subject, instructor, course...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _filterClasses('');
                          },
                        )
                      : null,
                ),
                onChanged: _filterClasses,
              ),
            ),

            // Body
            Expanded(
              child: _buildBody(),
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
            'Error loading classes:\n$_error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    if (_allClasses.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.video_camera_front_outlined,
                  size: 48, color: Colors.grey),
              SizedBox(height: 12),
              Text(
                'No live classes found in other batches',
                style: TextStyle(color: Colors.grey, fontSize: 15),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredClasses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'No classes matching "$_searchQuery"',
            style: const TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      itemCount: _filteredClasses.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final entry = _filteredClasses[index];
        final liveClass = entry['class'] as AdminLiveClass;
        final courseName = entry['courseName'] as String;
        final batchName = entry['batchName'] as String;

        final isLive = liveClass.status == 'live';
        final statusColor = isLive
            ? Colors.red
            : liveClass.status == 'completed'
                ? Colors.grey
                : Colors.blue;

        return ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          leading: CircleAvatar(
            radius: 22,
            backgroundImage: liveClass.thumbnailUrl.isNotEmpty
                ? NetworkImage(liveClass.thumbnailUrl)
                : null,
            child: liveClass.thumbnailUrl.isEmpty
                ? const Icon(Icons.video_camera_front, size: 20)
                : null,
          ),
          title: Text(
            liveClass.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.folder_outlined,
                      size: 13, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '$courseName › $batchName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.access_time, size: 13, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM dd, HH:mm').format(liveClass.startTime),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      liveClass.status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.add_link, color: Colors.blue),
            tooltip: 'Link this class',
            onPressed: () => _linkClass(entry),
          ),
          onTap: () => _linkClass(entry),
        );
      },
    );
  }
}
