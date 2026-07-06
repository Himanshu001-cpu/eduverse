import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import '../../core/services/rich_text_service.dart';

class RichContentViewer extends StatelessWidget {
  final String? htmlContent;
  final String? legacyMarkdown; // Fallback for backward compatibility

  const RichContentViewer({
    super.key,
    this.htmlContent,
    this.legacyMarkdown,
  });

  @override
  Widget build(BuildContext context) {
    final String contentToRender;

    if (htmlContent != null && htmlContent!.isNotEmpty) {
      contentToRender = htmlContent!;
    } else if (legacyMarkdown != null && legacyMarkdown!.isNotEmpty) {
      // Convert legacy markdown format to standard HTML as fallback
      contentToRender = RichTextService.convertMarkdownToHtml(legacyMarkdown!);
    } else {
      contentToRender = '';
    }

    if (contentToRender.isEmpty) {
      return const SizedBox.shrink();
    }

    return HtmlWidget(
      contentToRender,
      key: const Key('rich_content_html_widget'),
      customWidgetBuilder: (element) {
        // If element is a math latex class, render using flutter_math_fork
        if (element.classes.contains('math-latex')) {
          final rawLatex = element.attributes['data-latex'] ?? '';
          String latex;
          try {
            latex = Uri.decodeComponent(rawLatex);
          } catch (_) {
            latex = rawLatex;
          }
          if (latex.isNotEmpty) {
            return Math.tex(
              latex,
              key: Key('math_latex_render_${latex.hashCode}'),
              textStyle: const TextStyle(fontSize: 16.0),
              onErrorFallback: (err) => Text(
                latex,
                style: const TextStyle(color: Colors.red, fontStyle: FontStyle.italic),
              ),
            );
          }
        }
        
        // Handle math frac and other math spans if they aren't parsed as sub-elements of math-latex
        if (element.classes.contains('math-frac')) {
          // Allow default rendering or custom layout
          return null;
        }

        if (element.classes.contains('rich-diagram')) {
          // Render the SVG or SVG-containing diagram
          return Container(
            key: const Key('rich_diagram_widget'),
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            alignment: Alignment.center,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text(
                element.text,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 10.0),
              ),
            ),
          );
        }

        return null;
      },
    );
  }
}
