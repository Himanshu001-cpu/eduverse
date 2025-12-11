import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:open_filex/open_filex.dart';
import 'package:eduverse/profile/profile_mock_data.dart';
import 'package:eduverse/common/widgets/empty_state.dart';
import 'package:eduverse/common/widgets/cards.dart';

class MyDownloadsPage extends StatefulWidget {
  const MyDownloadsPage({super.key});

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

  // Load downloads from SharedPreferences, filter out fake/missing files
  Future<void> _loadDownloads() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_prefKey);

      if (jsonString != null) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        final allDownloads = jsonList.map((e) => _fromJson(e)).toList();
        
        // Filter out entries without real files
        final validDownloads = <DownloadItem>[];
        for (final item in allDownloads) {
          if (item.filePath != null && await File(item.filePath!).exists()) {
            validDownloads.add(item);
          }
        }
        
        setState(() {
          _downloads = validDownloads;
          _isLoading = false;
        });
        
        // Save filtered list
        if (validDownloads.length != allDownloads.length) {
          _saveDownloads();
        }
      } else {
        // First run: start with empty list (no mock data)
        setState(() {
          _downloads = [];
          _isLoading = false;
        });
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
      'status': item.status.index,
      'filePath': item.filePath,
      'url': item.url,
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
      filePath: json['filePath'] as String?,
      url: json['url'] as String?,
    );
  }

  Future<void> _deleteItem(int index) async {
    final deletedItem = _downloads[index];
    
    // Delete actual file from device
    if (deletedItem.filePath != null) {
      try {
        final file = File(deletedItem.filePath!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint('Error deleting file: $e');
      }
    }
    
    setState(() {
      _downloads.removeAt(index);
    });
    _saveDownloads();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Download deleted permanently')),
    );
  }

  Future<void> _clearAll() async {
    // Delete all actual files from device
    for (final item in _downloads) {
      if (item.filePath != null) {
        try {
          final file = File(item.filePath!);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (e) {
          debugPrint('Error deleting file ${item.filePath}: $e');
        }
      }
    }
    
    setState(() {
      _downloads.clear();
    });
    _saveDownloads();
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All downloads deleted from device')),
    );
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
                    content: const Text('This will permanently delete all downloaded files from your device.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await _clearAll();
                        },
                        child: const Text('Delete All', style: TextStyle(color: Colors.red)),
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

  const _DownloadItemCard({required this.item});

  Future<void> _openFile(BuildContext context) async {
    if (item.filePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File path not available')),
      );
      return;
    }
    
    final file = File(item.filePath!);
    if (!await file.exists()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File not found on device')),
      );
      return;
    }

    try {
      final result = await OpenFilex.open(item.filePath!);
      if (result.type != ResultType.done && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open file: ${result.message}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening file: $e')),
        );
      }
    }
  }

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

    return InkWell(
      onTap: item.status == DownloadStatus.completed ? () => _openFile(context) : null,
      borderRadius: BorderRadius.circular(12),
      child: AppCard(
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
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
              IconButton(
                icon: const Icon(Icons.open_in_new, color: Colors.green),
                onPressed: () => _openFile(context),
                tooltip: 'Open',
              )
            else if (item.status == DownloadStatus.failed)
              const Icon(Icons.refresh, color: Colors.red, size: 20),
          ],
        ),
      ),
    );
  }
}
