import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:eduverse/profile/profile_mock_data.dart';
import 'package:eduverse/common/widgets/empty_state.dart';
import 'package:eduverse/common/widgets/cards.dart';

class BookmarksPage extends StatefulWidget {
  const BookmarksPage({Key? key}) : super(key: key);

  @override
  State<BookmarksPage> createState() => _BookmarksPageState();
}

class _BookmarksPageState extends State<BookmarksPage> {
  List<BookmarkItem> _bookmarks = [];
  bool _isLoading = true;
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};
  String _sort = 'Newest'; // Newest, Oldest, Type

  final String _prefKey = 'my_bookmarks_list';

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_prefKey);

      if (jsonString != null) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        setState(() {
          _bookmarks = jsonList.map((e) => _fromJson(e)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _bookmarks = List.from(ProfileMockData.bookmarks);
          _isLoading = false;
        });
        _saveBookmarks();
      }
    } catch (e) {
      debugPrint('Error loading bookmarks: $e');
      setState(() {
        _bookmarks = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _saveBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonString = jsonEncode(_bookmarks.map((e) => _toJson(e)).toList());
    await prefs.setString(_prefKey, jsonString);
  }

  // Simplified serialization - skipping complex Course object for now or simplifying it
  Map<String, dynamic> _toJson(BookmarkItem item) {
    return {
      'id': item.id,
      'title': item.title,
      'type': item.type.index,
      'dateAdded': item.dateAdded.toIso8601String(),
      // 'courseData': ... (omitted for simplicity in this mock persistence)
    };
  }

  BookmarkItem _fromJson(Map<String, dynamic> json) {
    return BookmarkItem(
      id: json['id'],
      title: json['title'],
      type: BookmarkType.values[json['type']],
      dateAdded: DateTime.parse(json['dateAdded']),
    );
  }

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

  void _deleteSelected() {
    setState(() {
      _bookmarks.removeWhere((item) => _selectedIds.contains(item.id));
      _selectedIds.clear();
      _isSelectionMode = false;
    });
    _saveBookmarks();
  }

  void _exportSelected() {
    final selectedItems = _bookmarks.where((item) => _selectedIds.contains(item.id)).toList();
    final jsonStr = jsonEncode(selectedItems.map((e) => _toJson(e)).toList());
    Clipboard.setData(ClipboardData(text: jsonStr));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exported to clipboard')),
    );
    setState(() {
      _selectedIds.clear();
      _isSelectionMode = false;
    });
  }

  List<BookmarkItem> get _sortedBookmarks {
    List<BookmarkItem> list = List.from(_bookmarks);
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

  @override
  Widget build(BuildContext context) {
    final list = _sortedBookmarks;

    return Scaffold(
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
          if (_isSelectionMode) ...[
            IconButton(icon: const Icon(Icons.copy), onPressed: _exportSelected),
            IconButton(icon: const Icon(Icons.delete), onPressed: _deleteSelected),
          ] else ...[
             PopupMenuButton<String>(
               onSelected: (val) => setState(() => _sort = val),
               itemBuilder: (context) => ['Newest', 'Oldest', 'Type']
                   .map((s) => PopupMenuItem(value: s, child: Text(s)))
                   .toList(),
               icon: const Icon(Icons.sort),
             ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : list.isEmpty
              ? const EmptyState(title: 'No bookmarks yet', icon: Icons.bookmark_border)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final item = list[index];
                    final isSelected = _selectedIds.contains(item.id);

                    return AppCard(
                      color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
                      onTap: _isSelectionMode
                          ? () => _toggleSelection(item.id)
                          : () {
                              // Navigate to details
                            },
                      child: ListTile(
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
                                  item.type == BookmarkType.course
                                      ? Icons.school
                                      : item.type == BookmarkType.video
                                          ? Icons.play_circle
                                          : Icons.article,
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
                ),
    );
  }
}
