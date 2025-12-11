// file: lib/study/widgets/batch_lesson_tile.dart
import 'package:flutter/material.dart';

class BatchLessonTile extends StatelessWidget {
  final int index;
  final String title;
  final String duration;
  final String type; // 'video', 'article', 'quiz'
  final bool isLocked;
  final double progress; // 0.0 to 1.0
  final bool hasNote;
  final VoidCallback onTap;
  final Function(String) onAction; // 'complete', 'download', 'note', 'report'

  const BatchLessonTile({
    super.key,
    required this.index,
    required this.title,
    required this.duration,
    required this.type,
    this.isLocked = false,
    this.progress = 0.0,
    this.hasNote = false,
    required this.onTap,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final IconData typeIcon = _getTypeIcon(type);
    final Color typeColor = _getTypeColor(type);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: isLocked ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Leading Icon / Index
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isLocked ? Colors.grey.shade100 : typeColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: isLocked
                      ? const Icon(Icons.lock, size: 20, color: Colors.grey)
                      : Text(
                          '$index',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: typeColor,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (hasNote)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Icon(Icons.note, size: 14, color: Colors.amber),
                          ),
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: isLocked ? Colors.grey : Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(typeIcon, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          type.toUpperCase(),
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.access_time, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          duration,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    if (progress > 0 && !isLocked) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.grey.shade100,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            progress == 1.0 ? Colors.green : typeColor,
                          ),
                          minHeight: 4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Trailing Action
              if (isLocked)
                Tooltip(
                  message: 'Complete previous lessons to unlock',
                  triggerMode: TooltipTriggerMode.tap,
                  child: IconButton(
                    icon: const Icon(Icons.info_outline, color: Colors.grey),
                    onPressed: () {
                      // Tooltip handles tap
                    },
                  ),
                )
              else
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: onAction,
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'complete',
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline, size: 20),
                          SizedBox(width: 8),
                          Text('Mark Complete'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'download',
                      child: Row(
                        children: [
                          Icon(Icons.download_outlined, size: 20),
                          SizedBox(width: 8),
                          Text('Download'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'note',
                      child: Row(
                        children: [
                          Icon(Icons.note_add_outlined, size: 20),
                          SizedBox(width: 8),
                          Text('Add Note'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'report',
                      child: Row(
                        children: [
                          Icon(Icons.flag_outlined, size: 20),
                          SizedBox(width: 8),
                          Text('Report Issue'),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'video':
        return Icons.play_circle_outline;
      case 'article':
        return Icons.article_outlined;
      case 'quiz':
        return Icons.quiz_outlined;
      default:
        return Icons.class_outlined;
    }
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'video':
        return Colors.blue;
      case 'article':
        return Colors.orange;
      case 'quiz':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
