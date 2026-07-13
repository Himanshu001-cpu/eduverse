class Poster {
  final String id;
  final String title;
  final String subtitle;
  final String thumbnailUrl;
  final String aspectRatio; // '16:9', '4:3', '1:1', '9:16'
  final String? externalUrl;
  final String? inAppRoute;
  final String? inAppTargetId;
  final String? inAppTargetType;
  final List<PosterButton> buttons;
  final bool sendNotification;
  final bool isActive;
  final int order;
  final DateTime createdAt;
  final DateTime updatedAt;

  Poster({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.thumbnailUrl,
    required this.aspectRatio,
    this.externalUrl,
    this.inAppRoute,
    this.inAppTargetId,
    this.inAppTargetType,
    required this.buttons,
    this.sendNotification = false,
    this.isActive = true,
    this.order = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Poster.fromMap(Map<String, dynamic> data, String id) {
    return Poster(
      id: id,
      title: data['title'] ?? '',
      subtitle: data['subtitle'] ?? '',
      thumbnailUrl: data['thumbnailUrl'] ?? '',
      aspectRatio: data['aspectRatio'] ?? '16:9',
      externalUrl: data['externalUrl'],
      inAppRoute: data['inAppRoute'],
      inAppTargetId: data['inAppTargetId'],
      inAppTargetType: data['inAppTargetType'],
      buttons: (data['buttons'] as List<dynamic>?)
              ?.map((b) => PosterButton.fromMap(b as Map<String, dynamic>))
              .toList() ??
          [],
      sendNotification: data['sendNotification'] ?? false,
      isActive: data['isActive'] ?? true,
      order: data['order'] ?? 0,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as dynamic).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as dynamic).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subtitle': subtitle,
      'thumbnailUrl': thumbnailUrl,
      'aspectRatio': aspectRatio,
      'externalUrl': externalUrl,
      'inAppRoute': inAppRoute,
      'inAppTargetId': inAppTargetId,
      'inAppTargetType': inAppTargetType,
      'buttons': buttons.map((b) => b.toMap()).toList(),
      'sendNotification': sendNotification,
      'isActive': isActive,
      'order': order,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  double get aspectRatioValue {
    switch (aspectRatio) {
      case '4:3':
        return 4.0 / 3.0;
      case '1:1':
        return 1.0;
      case '9:16':
        return 9.0 / 16.0;
      case '16:9':
      default:
        return 16.0 / 9.0;
    }
  }
}

class PosterButton {
  final String label;
  final String? externalUrl;
  final String? inAppRoute;
  final String? inAppTargetId;
  final String? inAppTargetType;

  PosterButton({
    required this.label,
    this.externalUrl,
    this.inAppRoute,
    this.inAppTargetId,
    this.inAppTargetType,
  });

  factory PosterButton.fromMap(Map<String, dynamic> data) {
    return PosterButton(
      label: data['label'] ?? '',
      externalUrl: data['externalUrl'],
      inAppRoute: data['inAppRoute'],
      inAppTargetId: data['inAppTargetId'],
      inAppTargetType: data['inAppTargetType'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'externalUrl': externalUrl,
      'inAppRoute': inAppRoute,
      'inAppTargetId': inAppTargetId,
      'inAppTargetType': inAppTargetType,
    };
  }
}
