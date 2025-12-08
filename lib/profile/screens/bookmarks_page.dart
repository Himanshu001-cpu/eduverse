import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:eduverse/common/widgets/empty_state.dart';
import 'package:eduverse/common/widgets/cards.dart';
import 'package:eduverse/core/firebase/bookmark_service.dart';
import 'package:eduverse/profile/models/bookmark_model.dart';
import 'package:eduverse/feed/repository/feed_repository.dart';
import 'package:eduverse/study/study_repository.dart';
import 'package:eduverse/feed/screens/article_detail_page.dart';
import 'package:eduverse/study/presentation/screens/batch_detail_screen.dart';
import 'package:eduverse/feed/models.dart';
import 'package:eduverse/study/domain/models/study_entities.dart' show StudyBatch;

class BookmarksPage extends StatefulWidget {
  const BookmarksPage({Key? key}) : super(key: key);

  @override
  State<BookmarksPage> createState() => _BookmarksPageState();
}

class _BookmarksPageState extends State<BookmarksPage> {
  final BookmarkService _bookmarkService = BookmarkService();
  final FeedRepository _feedRepository = FeedRepository();
  final StudyRepository _studyRepository = StudyRepository();
  
  bool _isSelectionMode = false;
  bool _isNavigating = false;
  final Set<String> _selectedIds = {};
  String _sort = 'Newest'; // Newest, Oldest, Type

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _deleteSelected() async {
    final idsToDelete = List<String>.from(_selectedIds);
    setState(() {
      _selectedIds.clear();
      _isSelectionMode = false;
    });

    try {
      for (final id in idsToDelete) {
        await _bookmarkService.removeBookmark(id);
      }
      if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Selected bookmarks deleted')),
          );
      }
    } catch (e) {
      if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting bookmarks: $e'), backgroundColor: Colors.red),
          );
      }
    }
  }

  void _exportSelected(List<BookmarkItem> allBookmarks) {
    final selectedItems = allBookmarks.where((item) => _selectedIds.contains(item.id)).toList();
    final jsonStr = jsonEncode(selectedItems.map((e) => e.toMap()).toList()); // Use toMap from model
    Clipboard.setData(ClipboardData(text: jsonStr));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exported to clipboard')),
    );
    setState(() {
      _selectedIds.clear();
      _isSelectionMode = false;
    });
  }
  
  List<BookmarkItem> _getSortedBookmarks(List<BookmarkItem> bookmarks) {
    List<BookmarkItem> list = List.from(bookmarks);
    switch (_sort) {
      case 'Newest':
        list.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
        break;
      case 'Oldest':
        list.sort((a, b) => a.dateAdded.compareTo(b.dateAdded));
        break;
      case 'Type':
        list.sort((a, b) => a.type.name.compareTo(b.type.name));
        break;
    }
    return list;
  }

  Future<void> _handleNavigation(BookmarkItem item) async {
    if (_isNavigating) return;
    setState(() => _isNavigating = true);

    try {
      debugPrint('Navigating for item: ${item.id}, Type: ${item.type}, Metadata: ${item.metadata}');
      if (item.type == BookmarkType.article || item.type == BookmarkType.video) {
        final feedItem = await _feedRepository.getFeedItem(item.id);
        debugPrint('Feed item fetch result: ${feedItem != null}');
        if (feedItem != null && mounted) {
           Navigator.push(
             context,
             MaterialPageRoute(builder: (_) => ArticleDetailPage(item: feedItem)),
           );
        } else if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Content not found')));
        }
      } else if (item.type == BookmarkType.batch) {
        final courseId = item.metadata?['courseId'];
        debugPrint('Batch navigation - CourseId: $courseId');
        if (courseId != null) {
           final batchModel = await _studyRepository.getBatch(item.id, courseId: courseId);
           debugPrint('Batch fetch result: ${batchModel != null}');
           if (batchModel != null && mounted) {
             // Map Model to Entity
             final batch = StudyBatch(
                id: batchModel.id,
                courseId: batchModel.courseId,
                name: batchModel.name,
                courseName: batchModel.courseName,
                emoji: batchModel.emoji,
                gradientColors: batchModel.gradientColors,
                thumbnailUrl: item.metadata?['thumbnailUrl'] ?? '', 
                startDate: batchModel.startDate,
                totalLectures: batchModel.lessonCount,
                completedLectures: (batchModel.progress * batchModel.lessonCount).round(),
                progress: batchModel.progress,
             );

             Navigator.push(
               context,
               MaterialPageRoute(builder: (_) => BatchDetailScreen(batch: batch)),
             );
           } else if (mounted) {
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Batch not found')));
           }
        } else if (mounted) {
             // Fallback or error for legacy bookmarks
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to open batch (Missing course info)')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isNavigating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
      appBar: AppBar(
        title: Text(_isSelectionMode ? '${_selectedIds.length} Selected' : 'Bookmarks'),
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() {
                  _isSelectionMode = false;
                  _selectedIds.clear();
                }),
              )
            : null,
        actions: [
          StreamBuilder<List<BookmarkItem>>(
             stream: _bookmarkService.getBookmarksStream(),
             builder: (context, snapshot) {
                 final bookmarks = snapshot.data ?? [];
                 if (_isSelectionMode) {
                   return Row(
                     mainAxisSize: MainAxisSize.min,
                     children: [
                       IconButton(icon: const Icon(Icons.copy), onPressed: () => _exportSelected(bookmarks)),
                       IconButton(icon: const Icon(Icons.delete), onPressed: _deleteSelected),
                     ],
                   );
                 } else {
                   return PopupMenuButton<String>(
                     onSelected: (val) => setState(() => _sort = val),
                     itemBuilder: (context) => ['Newest', 'Oldest', 'Type']
                         .map((s) => PopupMenuItem(value: s, child: Text(s)))
                         .toList(),
                     icon: const Icon(Icons.sort),
                   );
                 }
             },
          ),
        ],
      ),
      body: StreamBuilder<List<BookmarkItem>>(
        stream: _bookmarkService.getBookmarksStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
             return Center(child: Text('Error: ${snapshot.error}'));
          }

          final rawBookmarks = snapshot.data ?? [];
          final list = _getSortedBookmarks(rawBookmarks);

          if (list.isEmpty) {
            return const EmptyState(title: 'No bookmarks yet', icon: Icons.bookmark_border);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final item = list[index];
              final isSelected = _selectedIds.contains(item.id);

              return AppCard(
                color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
                child: ListTile(
                  onTap: _isSelectionMode
                      ? () => _toggleSelection(item.id)
                      : () => _handleNavigation(item),
                  contentPadding: EdgeInsets.zero,
                  leading: _isSelectionMode
                      ? Checkbox(
                          value: isSelected,
                          onChanged: (_) => _toggleSelection(item.id),
                        )
                      : Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getIconForType(item.type),
                            color: Colors.indigo,
                          ),
                        ),
                  title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    '${item.type.name.toUpperCase()} • ${DateFormat('MMM d').format(item.dateAdded)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  onLongPress: () {
                    setState(() {
                      _isSelectionMode = true;
                      _toggleSelection(item.id);
                    });
                  },
                ),
              );
            },
          );
        },
      ),
      ),
      if (_isNavigating)
          Container(
            color: Colors.black26,
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  IconData _getIconForType(BookmarkType type) {
      switch (type) {
        case BookmarkType.video: return Icons.play_circle;
        case BookmarkType.article: return Icons.article;
        default: return Icons.bookmark;
      }
  }
}
