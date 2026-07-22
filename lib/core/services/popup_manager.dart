import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eduverse/store/models/poster_model.dart';
import 'package:eduverse/core/services/new_batch_promotion_service.dart';
import 'package:url_launcher/url_launcher.dart';

/// Centralized manager for App Open popups.
/// Handles lifecycle resume events, frequency tracking, and priority sequencing.
class PopupManager with WidgetsBindingObserver {
  static final PopupManager instance = PopupManager._internal();
  PopupManager._internal();

  bool _initialized = false;
  bool _hasCheckedAppOpen = false;
  DateTime? _lastBackgroundTime;
  static const Duration _backgroundThreshold = Duration(minutes: 30);

  final NewBatchPromotionService _batchPromotionService = NewBatchPromotionService();

  /// Initialize lifecycle listener
  void initialize() {
    if (_initialized) return;
    _initialized = true;
    WidgetsBinding.instance.addObserver(this);
  }

  /// Clean up observer
  void dispose() {
    if (_initialized) {
      WidgetsBinding.instance.removeObserver(this);
      _initialized = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _lastBackgroundTime = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      if (_lastBackgroundTime != null) {
        final elapsed = DateTime.now().difference(_lastBackgroundTime!);
        if (elapsed >= _backgroundThreshold) {
          // Reset flag so next home screen frame can present an app open popup
          _hasCheckedAppOpen = false;
        }
      }
      _lastBackgroundTime = null;
    }
  }

  /// Main entry point called once when user reaches the home screen navigation page
  Future<void> triggerAppOpenPopups(BuildContext context) async {
    if (_hasCheckedAppOpen) return;
    _hasCheckedAppOpen = true;

    try {
      // 1. Check for Active Admin Poster Popups
      final shownPoster = await _checkAndShowPosterPopup(context);
      if (shownPoster) return; // Shown a poster popup, stop sequence for this launch

      // 2. Fallback: Check for New Batch Promotion Popup
      final promoResult = await _batchPromotionService.getEligiblePromotion();
      if (promoResult != null && context.mounted) {
        await _batchPromotionService.showPromoDialog(context, promoResult);
      }
    } catch (e) {
      debugPrint('PopupManager error during triggerAppOpenPopups: $e');
    }
  }

  /// Queries active poster popups and displays the first eligible one based on frequency rules.
  Future<bool> _checkAndShowPosterPopup(BuildContext context) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('posters')
          .where('isActive', isEqualTo: true)
          .where('showAsPopup', isEqualTo: true)
          .orderBy('order')
          .get();

      if (snap.docs.isEmpty) return false;

      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final todayStr = '${now.year}-${now.month}-${now.day}';

      for (final doc in snap.docs) {
        final poster = Poster.fromMap(doc.data(), doc.id);
        final freq = poster.popupFrequency;

        // Check frequency rules
        if (freq == 'once') {
          final shown = prefs.getBool('poster_popup_shown_${poster.id}') ?? false;
          if (shown) continue;
        } else if (freq == 'daily') {
          final lastDate = prefs.getString('poster_popup_last_date_${poster.id}');
          if (lastDate == todayStr) continue;
        }

        // Eligible poster found! Display popup dialog
        if (context.mounted) {
          await _showPosterDialog(context, poster, prefs, todayStr);
          return true;
        }
      }
    } catch (e) {
      debugPrint('Error fetching poster popups: $e');
    }
    return false;
  }

  Future<void> _showPosterDialog(
    BuildContext context,
    Poster poster,
    SharedPreferences prefs,
    String todayStr,
  ) async {
    // Record frequency presentation
    await prefs.setBool('poster_popup_shown_${poster.id}', true);
    await prefs.setString('poster_popup_last_date_${poster.id}', todayStr);

    if (!context.mounted) return;

    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: poster.title.isNotEmpty ? poster.title : 'Announcement',
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (dialogContext, anim1, anim2, child) {
        final curveValue = Curves.easeInOutBack.transform(anim1.value);
        return Transform.scale(
          scale: curveValue,
          child: Opacity(
            opacity: anim1.value,
            child: AlertDialog(
              contentPadding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              content: _PosterPopupContent(poster: poster),
            ),
          ),
        );
      },
    );
  }
}

class _PosterPopupContent extends StatelessWidget {
  final Poster poster;

  const _PosterPopupContent({required this.poster});

  void _handleButtonAction(BuildContext context, PosterButton btn) async {
    Navigator.of(context).maybePop();

    if (btn.externalUrl != null && btn.externalUrl!.isNotEmpty) {
      final uri = Uri.parse(btn.externalUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } else if (btn.inAppRoute != null && btn.inAppRoute!.isNotEmpty) {
      Navigator.of(context).pushNamed(btn.inAppRoute!, arguments: btn.inAppTargetId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Image Header or Fallback Banner
        Stack(
          children: [
            if (poster.thumbnailUrl.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: AspectRatio(
                  aspectRatio: poster.aspectRatioValue,
                  child: Image.network(
                    poster.thumbnailUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildFallbackBanner(theme),
                  ),
                ),
              )
            else
              _buildFallbackBanner(theme),

            // Close button overlay
            Positioned(
              top: 8,
              right: 8,
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.black.withValues(alpha: 0.5),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.close, color: Colors.white, size: 18),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
            ),
          ],
        ),

        // Text & Content Body
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (poster.title.isNotEmpty)
                Text(
                  poster.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              if (poster.subtitle.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  poster.subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade700,
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Interactive Action Buttons
              if (poster.buttons.isNotEmpty)
                Column(
                  children: poster.buttons.map((btn) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton(
                          onPressed: () => _handleButtonAction(context, btn),
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            btn.label,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                )
              else
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Dismiss'),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackBanner(ThemeData theme) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.primaryColor, theme.primaryColor.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: const Center(
        child: Icon(Icons.campaign_outlined, size: 64, color: Colors.white70),
      ),
    );
  }
}
