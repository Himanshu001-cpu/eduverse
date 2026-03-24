// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:js_interop';
import 'package:web/web.dart' as web;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

/// A widget that displays a network image using an HTML <img> element
/// with crossOrigin set to 'anonymous'. This is required for Flutter web's
/// CanvasKit renderer to properly render cross-origin images (e.g. Firebase Storage).
class WebImage extends StatefulWidget {
  final String url;
  final BoxFit fit;
  final Widget Function()? fallbackBuilder;

  const WebImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.fallbackBuilder,
  });

  @override
  State<WebImage> createState() => _WebImageState();
}

class _WebImageState extends State<WebImage> {
  late final String _viewType;
  bool _registered = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _viewType = 'web-img-${widget.url.hashCode}-${identityHashCode(this)}';
    _registerView();
  }

  void _registerView() {
    if (_registered) return;
    _registered = true;

    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final img = web.HTMLImageElement()
        ..src = widget.url
        ..crossOrigin = 'anonymous'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.display = 'block';

      switch (widget.fit) {
        case BoxFit.cover:
          img.style.objectFit = 'cover';
          break;
        case BoxFit.contain:
          img.style.objectFit = 'contain';
          break;
        case BoxFit.fill:
          img.style.objectFit = 'fill';
          break;
        default:
          img.style.objectFit = 'cover';
      }

      img.addEventListener(
        'error',
        ((web.Event _) {
          if (mounted) {
            setState(() => _hasError = true);
          }
        }).toJS,
      );

      return img;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError && widget.fallbackBuilder != null) {
      return widget.fallbackBuilder!();
    }
    return HtmlElementView(viewType: _viewType);
  }
}
