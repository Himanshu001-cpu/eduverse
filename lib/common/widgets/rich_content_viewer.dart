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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mathColor = Theme.of(context).textTheme.bodyMedium?.color ??
        (isDark ? Colors.white : Colors.black87);

    return HtmlWidget(
      contentToRender,
      key: const Key('rich_content_html_widget'),
      customWidgetBuilder: (element) {
        // If element is a math latex class or has data-latex attribute, render using flutter_math_fork
        final isMathElement = element.classes.contains('math-latex') ||
            element.classes.contains('math-block') ||
            element.classes.contains('math-inline') ||
            element.attributes.containsKey('data-latex');

        if (isMathElement) {
          final rawLatex = element.attributes['data-latex'];
          if (rawLatex == null || rawLatex.trim().isEmpty) {
            return null;
          }

          String latex;
          try {
            latex = Uri.decodeComponent(rawLatex);
          } catch (_) {
            latex = rawLatex;
          }

          if (latex.isNotEmpty) {
            final isBlock = element.classes.contains('math-block') ||
                element.localName == 'div';

            final mathWidget = Math.tex(
              latex,
              key: Key('math_latex_render_${latex.hashCode}'),
              mathStyle: isBlock ? MathStyle.display : MathStyle.text,
              textStyle: TextStyle(
                fontSize: isBlock ? 18.0 : 16.0,
                color: mathColor,
              ),
              onErrorFallback: (err) => Text(
                latex,
                key: const Key('math_latex_error_fallback'),
                style: const TextStyle(
                  color: Colors.red,
                  fontStyle: FontStyle.italic,
                ),
              ),
            );

            if (isBlock) {
              return Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: mathWidget,
                ),
              );
            }

            return mathWidget;
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
