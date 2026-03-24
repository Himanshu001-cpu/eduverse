/// Utility class for YouTube video detection and handling
class YouTubeUtils {
  /// Extract video ID from YouTube URL, including /live/ URLs
  /// 
  /// This handles URL formats that YoutubePlayer.convertUrlToId() doesn't:
  /// - https://www.youtube.com/live/VIDEO_ID
  /// - https://youtube.com/live/VIDEO_ID?si=...
  /// 
  /// Returns the video ID or null if not a YouTube URL
  static String? extractVideoId(String url) {
    if (url.isEmpty) return null;
    
    // Try the standard converter first
    // Note: This is imported from youtube_player_flutter in calling code
    // We handle the /live/ format here as a fallback
    
    // Handle youtube.com/live/VIDEO_ID format
    final livePattern = RegExp(
      r'(?:youtube\.com|youtu\.be)\/live\/([a-zA-Z0-9_-]{11})',
      caseSensitive: false,
    );
    final liveMatch = livePattern.firstMatch(url);
    if (liveMatch != null && liveMatch.group(1) != null) {
      return liveMatch.group(1);
    }
    
    // Handle standard formats as fallback patterns
    // youtube.com/watch?v=VIDEO_ID
    final watchPattern = RegExp(
      r'(?:youtube\.com\/watch\?v=)([a-zA-Z0-9_-]{11})',
      caseSensitive: false,
    );
    final watchMatch = watchPattern.firstMatch(url);
    if (watchMatch != null && watchMatch.group(1) != null) {
      return watchMatch.group(1);
    }
    
    // youtu.be/VIDEO_ID
    final shortPattern = RegExp(
      r'(?:youtu\.be\/)([a-zA-Z0-9_-]{11})',
      caseSensitive: false,
    );
    final shortMatch = shortPattern.firstMatch(url);
    if (shortMatch != null && shortMatch.group(1) != null) {
      return shortMatch.group(1);
    }
    
    // youtube.com/embed/VIDEO_ID
    final embedPattern = RegExp(
      r'(?:youtube\.com\/embed\/)([a-zA-Z0-9_-]{11})',
      caseSensitive: false,
    );
    final embedMatch = embedPattern.firstMatch(url);
    if (embedMatch != null && embedMatch.group(1) != null) {
      return embedMatch.group(1);
    }
    
    return null;
  }

  /// Check if a live class is currently live based on status and timing
  /// 
  /// Returns true if:
  /// - Status is explicitly 'live'
  /// - Status is 'upcoming' but start time is within the streaming window
  ///   (15 minutes before start to account for early starts)
  /// 
  /// NOTE: Completed videos are treated as recorded videos, not live streams.
  /// URL pattern detection is NOT used because completed live streams would
  /// incorrectly be treated as live.
  static bool isLiveClassByStatus(String status, DateTime startTime, {int? durationMinutes}) {
    // Explicit live status
    if (status.toLowerCase() == 'live') {
      return true;
    }
    
    // Check if we're within the streaming window for upcoming classes
    final now = DateTime.now();
    final streamStartWindow = startTime.subtract(const Duration(minutes: 15));
    final streamEndWindow = durationMinutes != null 
        ? startTime.add(Duration(minutes: durationMinutes + 30)) // Buffer for overtime
        : startTime.add(const Duration(hours: 3)); // Default 3hr window
    
    // If current time is within the streaming window and status is upcoming
    if (status.toLowerCase() == 'upcoming' && 
        now.isAfter(streamStartWindow) && 
        now.isBefore(streamEndWindow)) {
      return true;
    }
    
    return false;
  }

  /// Determines if a video should be treated as live based on status/timing
  /// 
  /// [status] - Status string ('live', 'upcoming', 'completed')
  /// [startTime] - Scheduled start time for live classes
  /// [durationMinutes] - Expected duration
  /// [explicitIsLive] - If set, this takes precedence over auto-detection
  /// 
  /// NOTE: Completed videos always return false (treated as recorded videos)
  static bool shouldTreatAsLive({
    required String url,
    String? status,
    DateTime? startTime,
    int? durationMinutes,
    bool? explicitIsLive,
  }) {
    // Explicit flag takes highest precedence
    if (explicitIsLive != null) {
      return explicitIsLive;
    }
    
    // Completed videos are never treated as live
    if (status?.toLowerCase() == 'completed') {
      return false;
    }
    
    // Check status-based live detection
    if (status != null && startTime != null) {
      return isLiveClassByStatus(status, startTime, durationMinutes: durationMinutes);
    }
    
    // Default to not live (recorded video)
    return false;
  }
}

