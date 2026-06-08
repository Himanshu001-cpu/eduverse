import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/admin_models.dart';
import '../services/firebase_admin_service.dart';

/// Dialog that shows all existing live classes from every course,
/// allowing the admin to pick ONE OR MORE to link into the current course.
class LinkLiveClassDialog extends StatefulWidget {
  /// The courseId of the *target* course we want to link into.
  final String targetCourseId;

  const LinkLiveClassDialog({
    super.key,
    required this.targetCourseId,
    // Keep targetBatchId parameter for compatibility but mark it optional/unused
    String? targetBatchId,
  });

  @override
  State<LinkLiveClassDialog> createState() => _LinkLiveClassDialogState();
}

class _LinkLiveClassDialogState extends State<LinkLiveClassDialog> {
  List<Map<String, dynamic>> _allClasses = [];
  List<Map<String, dynamic>> _filteredClasses = [];
  bool _isLoading = true;
  bool _isLinking = false;
  String _searchQuery = '';
  final _searchController = TextEditingController();
  String? _error;

  /// Keys: '${courseId}___${classId}' for uniqueness
  final Set<String> _selectedKeys = {};
  /// Track classes linked during this dialog session (to grey them out on retry)
  final Set<String> _newlyLinkedKeys = {};

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

  /// Unique key for a class entry
  String _entryKey(Map<String, dynamic> entry) {
    final liveClass = entry['class'] as AdminLiveClass;
    final courseId = entry['courseId'] as String;
    return '${courseId}___${liveClass.id}';
  }

  bool _isAlreadyLinked(Map<String, dynamic> entry) {
    final key = _entryKey(entry);
    return _newlyLinkedKeys.contains(key);
  }

  Future<void> _loadClasses() async {
    try {
      final service = context.read<FirebaseAdminService>();
      final classes = await service.getAllLiveClassesForLinking();

      // Filter out classes that are already in the target course
      final filtered = classes.where((entry) {
        return !(entry['courseId'] == widget.targetCourseId);
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
              (entry['courseName'] as String).toLowerCase().contains(lowerQuery);
        }).toList();
      }
    });
  }

  Future<void> _linkSelected() async {
    if (_selectedKeys.isEmpty || _isLinking) return;

    final targetsSnapshot = Set<String>.from(_selectedKeys);
    setState(() => _isLinking = true);

    // Build a lookup map: key -> entry
    final entryByKey = <String, Map<String, dynamic>>{
      for (final e in _allClasses) _entryKey(e): e,
    };

    final List<String> succeeded = [];
    final List<Map<String, String>> failed = [];

    try {
      final service = context.read<FirebaseAdminService>();

      for (final key in targetsSnapshot) {
        final entry = entryByKey[key];
        if (entry == null) continue;

        final liveClass = entry['class'] as AdminLiveClass;
        final sourceCourseId = entry['courseId'] as String;

        try {
          if (sourceCourseId.isEmpty) {
            // Linking from free live classes
            await service.linkFreeLiveClassToCourse(
              sourceClass: liveClass,
              targetCourseId: widget.targetCourseId,
            );
          } else {
            // Linking from another course
            await service.linkLiveClassToCourse(
              sourceClass: liveClass,
              sourceCourseId: sourceCourseId,
              targetCourseId: widget.targetCourseId,
            );
          }
          succeeded.add(key);
        } catch (e) {
          failed.add({'key': key, 'title': liveClass.title, 'error': e.toString()});
        }
      }

      if (!mounted) return;

      setState(() {
        for (final key in succeeded) {
          _selectedKeys.remove(key);
          _newlyLinkedKeys.add(key);
        }
      });

      if (failed.isEmpty) {
        // All succeeded — close dialog and show snackbar
        final messenger = ScaffoldMessenger.of(context);
        Navigator.pop(context, true);
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Linked ${succeeded.length} class${succeeded.length > 1 ? 'es' : ''} successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Partial failure — keep dialog open, show details
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Partial Link Failure'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '✅ Linked ${succeeded.length} class${succeeded.length > 1 ? 'es' : ''}.\n'
                  '❌ Failed to link ${failed.length}:',
                ),
                const SizedBox(height: 8),
                ...failed.map((f) => Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '• ${f['title']}: ${f['error']}',
                        style: const TextStyle(fontSize: 12, color: Colors.red),
                      ),
                    )),
                const SizedBox(height: 8),
                const Text(
                  'Failed items remain selected — you can retry.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unexpected error: $e'), backgroundColor: Colors.red),
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
          maxHeight: MediaQuery.of(context).size.height * 0.80,
          maxWidth: 620,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
              child: Row(
                children: [
                  const Icon(Icons.add_link, color: Colors.blue),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Link Live Classes',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
            Expanded(child: _buildBody()),

            // Footer with Link button
            if (!_isLoading && _error == null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  children: [
                    Text(
                      '${_selectedKeys.length} selected',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: _selectedKeys.isEmpty || _isLinking ? null : _linkSelected,
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
                      label: Text(_isLinking ? 'Linking...' : 'Link'),
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
              Icon(Icons.video_camera_front_outlined, size: 48, color: Colors.grey),
              SizedBox(height: 12),
              Text(
                'No live classes found in other courses',
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
        final key = _entryKey(entry);
        final isLinked = _isAlreadyLinked(entry);
        final isSelected = _selectedKeys.contains(key);

        final isLive = liveClass.status == 'live';
        final statusColor = isLive
            ? Colors.red
            : liveClass.status == 'completed'
                ? Colors.grey
                : Colors.blue;

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: isLinked ? Colors.grey : null,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.folder_outlined, size: 13, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      courseName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
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
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
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
                  if (isLinked) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.check_circle, color: Colors.green, size: 14),
                    const SizedBox(width: 2),
                    const Text(
                      'Linked',
                      style: TextStyle(color: Colors.green, fontSize: 11),
                    ),
                  ],
                ],
              ),
            ],
          ),
          trailing: isLinked
              ? const Icon(Icons.link, color: Colors.green, size: 22)
              : Checkbox(
                  value: isSelected,
                  onChanged: _isLinking
                      ? null
                      : (val) {
                          setState(() {
                            if (val == true) {
                              _selectedKeys.add(key);
                            } else {
                              _selectedKeys.remove(key);
                            }
                          });
                        },
                ),
          onTap: (isLinked || _isLinking)
              ? null
              : () {
                  setState(() {
                    if (_selectedKeys.contains(key)) {
                      _selectedKeys.remove(key);
                    } else {
                      _selectedKeys.add(key);
                    }
                  });
                },
        );
      },
    );
  }
}
