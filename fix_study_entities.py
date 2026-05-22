import re

file_path = "lib/study/domain/models/study_entities.dart"
with open(file_path, "r") as f:
    content = f.read()

# Make required fields optional to fix compilation since this is a pre-existing codebase quirk
lecture_code = """class StudyLecture {
  final String id;
  final String title;
  final String description;
  final String videoUrl;
  final String contentUrl;
  final String subject;
  final String chapter;
  final int orderIndex;
  final int order;
  final bool isLocked;
  final bool isWatched;
  final String type;
  final Duration? duration;
  final int? lectureNo;
  final List<String> linkedNoteIds;

  const StudyLecture({
    required this.id,
    required this.title,
    this.description = '',
    required this.videoUrl,
    this.contentUrl = '',
    this.subject = '', // made optional
    this.chapter = '', // made optional
    this.orderIndex = 0, // made optional
    this.order = 0,
    this.isLocked = false,
    this.isWatched = false,
    this.type = 'video',
    this.duration,
    this.lectureNo,
    this.linkedNoteIds = const [],
  });

  factory StudyLecture.fromMap(Map<String, dynamic> data, String id) {
    return StudyLecture(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      videoUrl: data['videoUrl'] ?? data['storagePath'] ?? '',
      contentUrl: data['contentUrl'] ?? '',
      subject: data['subject'] ?? '',
      chapter: data['chapter'] ?? '',
      orderIndex: data['orderIndex'] ?? 0,
      order: data['order'] ?? 0,
      isLocked: data['isLocked'] ?? false,
      isWatched: data['isWatched'] ?? false,
      type: data['type'] ?? 'video',
      duration: data['durationSeconds'] != null ? Duration(seconds: data['durationSeconds']) : null,
      lectureNo: data['lectureNo'],
      linkedNoteIds: List<String>.from(data['linkedNoteIds'] ?? []),
    );
  }

  StudyLecture copyWith({
    String? id,
    String? title,
    String? description,
    String? videoUrl,
    String? contentUrl,
    String? subject,
    String? chapter,
    int? orderIndex,
    int? order,
    bool? isLocked,
    bool? isWatched,
    String? type,
    Duration? duration,
    int? lectureNo,
    List<String>? linkedNoteIds,
  }) {
    return StudyLecture(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      videoUrl: videoUrl ?? this.videoUrl,
      contentUrl: contentUrl ?? this.contentUrl,
      subject: subject ?? this.subject,
      chapter: chapter ?? this.chapter,
      orderIndex: orderIndex ?? this.orderIndex,
      order: order ?? this.order,
      isLocked: isLocked ?? this.isLocked,
      isWatched: isWatched ?? this.isWatched,
      type: type ?? this.type,
      duration: duration ?? this.duration,
      lectureNo: lectureNo ?? this.lectureNo,
      linkedNoteIds: linkedNoteIds ?? this.linkedNoteIds,
    );
  }
}"""

content = re.sub(r'class StudyLecture \{.*?\n\}', lecture_code, content, flags=re.DOTALL)

with open(file_path, "w") as f:
    f.write(content)
