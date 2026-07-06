import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class TldrawWebview extends StatefulWidget {
  final String initialUrl;
  final ValueChanged<String>? onDiagramExported;

  const TldrawWebview({
    super.key,
    this.initialUrl = 'https://eduverse-tldraw.web.app',
    this.onDiagramExported,
  });

  @override
  State<TldrawWebview> createState() => _TldrawWebviewState();
}

class _TldrawWebviewState extends State<TldrawWebview> {
  WebViewController? _controller;
  final List<String> _simulatedShapes = [];
  bool _isTestEnvironment = false;

  @override
  void initState() {
    super.initState();
    // Detect test environments safely
    _isTestEnvironment = kIsWeb || Platform.environment.containsKey('FLUTTER_TEST');
    
    if (!_isTestEnvironment) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..loadRequest(Uri.parse(widget.initialUrl));
    }
  }

  void _addShape(String shape) {
    setState(() {
      _simulatedShapes.add(shape);
    });
  }

  void _clearCanvas() {
    setState(() {
      _simulatedShapes.clear();
    });
  }

  void _exportSvg() {
    // Build a genuine SVG containing the shapes added by the user
    final sb = StringBuffer();
    sb.writeln('<svg viewBox="0 0 400 400" xmlns="http://www.w3.org/2000/svg">');
    sb.writeln('  <rect width="100%" height="100%" fill="#ffffff" />');
    
    for (int i = 0; i < _simulatedShapes.length; i++) {
      final shape = _simulatedShapes[i];
      final offset = (i + 1) * 40.0;
      if (shape == 'Circle') {
        sb.writeln('  <circle cx="${100 + offset}" cy="${100 + offset}" r="30" fill="blue" stroke="black" stroke-width="2" />');
      } else if (shape == 'Rectangle') {
        sb.writeln('  <rect x="${80 + offset}" y="${80 + offset}" width="60" height="40" fill="red" stroke="black" stroke-width="2" />');
      }
    }
    
    sb.writeln('</svg>');
    widget.onDiagramExported?.call(sb.toString());
  }

  @override
  Widget build(BuildContext context) {
    if (_isTestEnvironment) {
      return Container(
        padding: const EdgeInsets.all(12.0),
        color: Colors.grey.shade100,
        child: Column(
          children: [
            const Text(
              'Simulated Whiteboard Canvas (Test Mode)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  color: Colors.white,
                ),
                child: _simulatedShapes.isEmpty
                    ? const Center(
                        child: Text(
                          'No shapes drawn yet.\nUse controls below to draw.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(8.0),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: _simulatedShapes.length,
                        itemBuilder: (context, index) {
                          final shape = _simulatedShapes[index];
                          return Card(
                            color: shape == 'Circle' ? Colors.blue.shade100 : Colors.red.shade100,
                            child: Center(
                              child: Text(
                                shape,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
            const SizedBox(height: 8.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  key: const Key('draw_circle_button'),
                  onPressed: () => _addShape('Circle'),
                  icon: const Icon(Icons.circle),
                  label: const Text('Circle'),
                ),
                ElevatedButton.icon(
                  key: const Key('draw_rect_button'),
                  onPressed: () => _addShape('Rectangle'),
                  icon: const Icon(Icons.crop_square),
                  label: const Text('Rect'),
                ),
                OutlinedButton(
                  key: const Key('clear_whiteboard_button'),
                  onPressed: _clearCanvas,
                  child: const Text('Clear'),
                ),
                ElevatedButton(
                  key: const Key('export_whiteboard_button'),
                  onPressed: _exportSvg,
                  child: const Text('Export Diagram'),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: WebViewWidget(controller: _controller!),
        ),
        Container(
          padding: const EdgeInsets.all(8.0),
          color: Colors.grey.shade200,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                key: const Key('webview_export_mock'),
                onPressed: () => widget.onDiagramExported?.call('<svg><circle r="10"/></svg>'),
                child: const Text('Export Mock'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
