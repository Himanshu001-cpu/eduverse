import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eduverse/profile/profile_mock_data.dart';
import 'package:eduverse/common/widgets/empty_state.dart';
import 'package:eduverse/common/widgets/cards.dart';

class MyDownloadsPage extends StatefulWidget {
  const MyDownloadsPage({Key? key}) : super(key: key);

  @override
  State<MyDownloadsPage> createState() => _MyDownloadsPageState();
}

class _MyDownloadsPageState extends State<MyDownloadsPage> {
  List<DownloadItem> _downloads = [];
  bool _isLoading = true;
  final String _prefKey = 'my_downloads_list';

  @override
  void initState() {
    super.initState();
    _loadDownloads();
  }

  // Load downloads from SharedPreferences or use mock data if empty/first run
  Future<void> _loadDownloads() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_prefKey);

      if (jsonString != null) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        setState(() {
          _downloads = jsonList.map((e) => _fromJson(e)).toList();
          _isLoading = false;
        });
      } else {
        // First run: use mock data
        setState(() {
          _downloads = List.from(ProfileMockData.downloads);
          _isLoading = false;
        });
        _saveDownloads(); // Save mock data for persistence
      }
    } catch (e) {
      debugPrint('Error loading downloads: $e');
      setState(() {
        _downloads = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _saveDownloads() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String jsonString = jsonEncode(_downloads.map((e) => _toJson(e)).toList());
      await prefs.setString(_prefKey, jsonString);
    } catch (e) {
      debugPrint('Error saving downloads: $e');
    }
  }

  // Simple JSON serialization for local persistence
  Map<String, dynamic> _toJson(DownloadItem item) {
    return {
      'id': item.id,
      'title': item.title,
      'type': item.type,
      'size': item.size,
      'progress': item.progress,
      'status': item.status.index, // Store enum index
    };
  }

  DownloadItem _fromJson(Map<String, dynamic> json) {
    return DownloadItem(
      id: json['id'],
      title: json['title'],
      type: json['type'],
      size: json['size'],
      progress: (json['progress'] as num).toDouble(),
      status: DownloadStatus.values[json['status'] as int],
    );
  }

  void _deleteItem(int index) {
    final deletedItem = _downloads[index];
    setState(() {
      _downloads.removeAt(index);
    });
    _saveDownloads();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Download removed'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              _downloads.insert(index, deletedItem);
            });
            _saveDownloads();
          },
        ),
      ),
    );
  }

  void _clearAll() {
    setState(() {
      _downloads.clear();
    });
    _saveDownloads();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Downloads'),
        actions: [
          if (_downloads.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Clear All?'),
                    content: const Text('This will remove all downloaded items.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          _clearAll();
                          Navigator.pop(ctx);
                        },
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _downloads.isEmpty
              ? const EmptyState(
                  title: 'No downloads yet',
                  icon: Icons.download_done,
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _downloads.length,
                  itemBuilder: (context, index) {
                    final item = _downloads[index];
                    return Dismissible(
                      key: Key(item.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: Colors.red,
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) => _deleteItem(index),
                      child: _DownloadItemCard(item: item),
                    );
                  },
                ),
    );
  }
}

class _DownloadItemCard extends StatelessWidget {
  final DownloadItem item;

  const _DownloadItemCard({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    switch (item.type) {
      case 'video':
        icon = Icons.play_circle_fill;
        color = Colors.redAccent;
        break;
      case 'pdf':
        icon = Icons.picture_as_pdf;
        color = Colors.orangeAccent;
        break;
      case 'article':
        icon = Icons.article;
        color = Colors.blueAccent;
        break;
      default:
        icon = Icons.insert_drive_file;
        color = Colors.grey;
    }

    return AppCard(
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                const SizedBox(height: 4),
                if (item.status == DownloadStatus.downloading)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LinearProgressIndicator(value: item.progress, minHeight: 4),
                      const SizedBox(height: 4),
                      Text(
                        'Downloading... ${(item.progress * 100).toInt()}%',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  )
                else if (item.status == DownloadStatus.failed)
                  Text(
                    'Failed • Tap to retry',
                    style: TextStyle(fontSize: 12, color: Colors.red[400]),
                  )
                else
                  Text(
                    '${item.size} • ${item.type.toUpperCase()}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
              ],
            ),
          ),
          if (item.status == DownloadStatus.completed)
            const Icon(Icons.check_circle, color: Colors.green, size: 20)
          else if (item.status == DownloadStatus.failed)
            const Icon(Icons.refresh, color: Colors.red, size: 20),
        ],
      ),
    );
  }
}
