import 'dart:async';
import 'package:flutter/material.dart';

/// A complete custom video controls overlay.
///
/// Features:
/// - Double-tap left/right halves to rewind/skip 10 seconds
/// - Tap to show/hide controls (auto-hide after 3 seconds)
/// - Play / Pause button (center)
/// - Rewind 10s / Forward 10s buttons
/// - Progress bar (draggable)
/// - Current time / Total time labels
/// - Fullscreen button
/// - Quality settings button
class VideoSkipOverlay extends StatefulWidget {
  final Widget child;

  /// Called to seek the player to the given [Duration].
  final void Function(Duration position) onSeek;

  /// Returns the current playback position.
  final Duration Function() getCurrentPosition;

  /// Returns the total duration of the video.
  final Duration Function() getTotalDuration;

  /// Returns whether the video is currently playing.
  final bool Function() getIsPlaying;

  /// Called to play the video.
  final VoidCallback onPlay;

  /// Called to pause the video.
  final VoidCallback onPause;

  /// Called to toggle fullscreen mode.
  final VoidCallback? onToggleFullScreen;

  /// Called to show quality settings sheet.
  final VoidCallback? onShowQuality;

  /// A [Listenable] (e.g. the player controller) that signals value changes
  /// so the overlay can rebuild with updated position/state.
  final Listenable? controllerListenable;

  const VideoSkipOverlay({
    super.key,
    required this.child,
    required this.onSeek,
    required this.getCurrentPosition,
    required this.getTotalDuration,
    required this.getIsPlaying,
    required this.onPlay,
    required this.onPause,
    this.onToggleFullScreen,
    this.onShowQuality,
    this.controllerListenable,
  });

  @override
  State<VideoSkipOverlay> createState() => _VideoSkipOverlayState();
}

class _VideoSkipOverlayState extends State<VideoSkipOverlay> {
  bool _showControls = false;
  Timer? _hideTimer;

  // Double-tap feedback
  bool _showRewindIcon = false;
  bool _showForwardIcon = false;
  Timer? _rewindIconTimer;
  Timer? _forwardIconTimer;

  // Drag state
  bool _isDragging = false;
  double _dragValue = 0;

  static const _controlsTimeout = Duration(seconds: 3);
  static const _feedbackDuration = Duration(milliseconds: 700);

  @override
  void initState() {
    super.initState();
    widget.controllerListenable?.addListener(_onControllerUpdate);
  }

  @override
  void didUpdateWidget(covariant VideoSkipOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controllerListenable != widget.controllerListenable) {
      oldWidget.controllerListenable?.removeListener(_onControllerUpdate);
      widget.controllerListenable?.addListener(_onControllerUpdate);
    }
  }

  void _onControllerUpdate() {
    if (mounted && _showControls && !_isDragging) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    widget.controllerListenable?.removeListener(_onControllerUpdate);
    _hideTimer?.cancel();
    _rewindIconTimer?.cancel();
    _forwardIconTimer?.cancel();
    super.dispose();
  }

  // ── Seeking ──────────────────────────────────────────────────────────

  void _seek(int deltaSeconds) {
    final current = widget.getCurrentPosition();
    final total = widget.getTotalDuration();
    var target = current + Duration(seconds: deltaSeconds);
    if (target.isNegative) target = Duration.zero;
    if (total > Duration.zero && target > total) target = total;
    widget.onSeek(target);
  }

  void _onDoubleTapLeft() {
    _seek(-10);
    setState(() => _showRewindIcon = true);
    _rewindIconTimer?.cancel();
    _rewindIconTimer = Timer(_feedbackDuration, () {
      if (mounted) setState(() => _showRewindIcon = false);
    });
  }

  void _onDoubleTapRight() {
    _seek(10);
    setState(() => _showForwardIcon = true);
    _forwardIconTimer?.cancel();
    _forwardIconTimer = Timer(_feedbackDuration, () {
      if (mounted) setState(() => _showForwardIcon = false);
    });
  }

  // ── Controls visibility ──────────────────────────────────────────────

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    _resetHideTimer();
  }

  void _resetHideTimer() {
    _hideTimer?.cancel();
    if (_showControls) {
      _hideTimer = Timer(_controlsTimeout, () {
        if (mounted) setState(() => _showControls = false);
      });
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  // ── Build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final position = widget.getCurrentPosition();
    final duration = widget.getTotalDuration();
    final isPlaying = widget.getIsPlaying();

    final totalMs = duration.inMilliseconds.toDouble();
    final currentMs = _isDragging
        ? _dragValue
        : position.inMilliseconds.toDouble().clamp(0, totalMs > 0 ? totalMs : 1);

    return Stack(
      children: [
        // The actual player
        widget.child,

        // ── Double-tap zones ─────────────────────────────────────────
        Positioned.fill(
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onDoubleTap: _onDoubleTapLeft,
                  onTap: _toggleControls,
                  child: const SizedBox.expand(),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onDoubleTap: _onDoubleTapRight,
                  onTap: _toggleControls,
                  child: const SizedBox.expand(),
                ),
              ),
            ],
          ),
        ),

        // ── Rewind feedback ──────────────────────────────────────────
        if (_showRewindIcon)
          Positioned(
            left: 40,
            top: 0,
            bottom: 0,
            child: Center(
              child: _FeedbackBubble(icon: Icons.fast_rewind, label: '10s'),
            ),
          ),

        // ── Forward feedback ─────────────────────────────────────────
        if (_showForwardIcon)
          Positioned(
            right: 40,
            top: 0,
            bottom: 0,
            child: Center(
              child: _FeedbackBubble(icon: Icons.fast_forward, label: '10s'),
            ),
          ),

        if (_showControls)
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggleControls,
              child: Container(
                color: Colors.black45,
                child: Stack(
                  children: [
                    // ── Top-right: quality button ───────────────────
                    if (widget.onShowQuality != null)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: IconButton(
                          icon: const Icon(
                            Icons.settings,
                            color: Colors.white,
                            size: 26,
                          ),
                          onPressed: () {
                            widget.onShowQuality!();
                            _resetHideTimer();
                          },
                        ),
                      ),

                    // ── Center: play/pause + skip buttons ────────────
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ControlButton(
                            icon: Icons.replay_10,
                            onTap: () {
                              _seek(-10);
                              _resetHideTimer();
                            },
                          ),
                          const SizedBox(width: 32),
                          _ControlButton(
                            icon: isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            size: 40,
                            onTap: () {
                              if (isPlaying) {
                                widget.onPause();
                              } else {
                                widget.onPlay();
                              }
                              _resetHideTimer();
                              setState(() {});
                            },
                          ),
                          const SizedBox(width: 32),
                          _ControlButton(
                            icon: Icons.forward_10,
                            onTap: () {
                              _seek(10);
                              _resetHideTimer();
                            },
                          ),
                        ],
                      ),
                    ),

                    // ── Bottom bar: timeline + fullscreen ─────────────
                    Positioned(
                      left: 12,
                      right: 8,
                      bottom: 8,
                      child: Row(
                        children: [
                          // Current time
                          Text(
                            _formatDuration(
                              _isDragging
                                  ? Duration(
                                      milliseconds: _dragValue.round(),
                                    )
                                  : position,
                            ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Progress bar
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 3,
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 6,
                                ),
                                overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 12,
                                ),
                                activeTrackColor: Colors.red,
                                inactiveTrackColor: Colors.white38,
                                thumbColor: Colors.red,
                              ),
                              child: Slider(
                                value: currentMs.clamp(
                                  0.0,
                                  totalMs > 0 ? totalMs : 1.0,
                                ).toDouble(),
                                min: 0,
                                max: totalMs > 0 ? totalMs : 1,
                                onChangeStart: (v) {
                                  _isDragging = true;
                                  _hideTimer?.cancel();
                                },
                                onChanged: (v) {
                                  setState(() => _dragValue = v);
                                },
                                onChangeEnd: (v) {
                                  _isDragging = false;
                                  widget.onSeek(
                                    Duration(milliseconds: v.round()),
                                  );
                                  _resetHideTimer();
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Total time
                          Text(
                            _formatDuration(duration),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                          // Fullscreen
                          if (widget.onToggleFullScreen != null)
                            IconButton(
                              icon: const Icon(
                                Icons.fullscreen,
                                color: Colors.white,
                                size: 26,
                              ),
                              padding: const EdgeInsets.only(left: 4),
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                widget.onToggleFullScreen!();
                                _resetHideTimer();
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Circular control button.
class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;

  const _ControlButton({
    required this.icon,
    required this.onTap,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(40),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withValues(alpha: 0.5),
          ),
          child: Icon(icon, color: Colors.white, size: size),
        ),
      ),
    );
  }
}

/// Feedback bubble shown on double-tap.
class _FeedbackBubble extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeedbackBubble({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
