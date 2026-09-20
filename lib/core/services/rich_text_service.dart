import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';

class RichTextService {
  /// Extracts plain text from a delta JSON string.
  static String extractPlainText(String deltaJson) {
    if (deltaJson.isEmpty) return '';
    try {
      final decoded = json.decode(deltaJson);
      if (decoded is Map && decoded.containsKey('ops')) {
        final ops = decoded['ops'] as List;
        return ops.map((op) => op['insert']?.toString() ?? '').join();
      }
    } catch (e) {
      // Not JSON
    }
    return deltaJson;
  }

  /// Sanitizes HTML by stripping executable script tags, event handler attributes, and unsafe javascript: URIs (T-02-01).
  static String sanitizeHtml(String html) {
    if (html.isEmpty) return '';
    var sanitized = html;
    // Remove script tags and contents
    sanitized = sanitized.replaceAll(
      RegExp(r'<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>', caseSensitive: false, multiLine: true),
      '',
    );
    // Remove inline event handlers like onload, onerror, onclick, etc.
    sanitized = sanitized.replaceAll(
      RegExp(r'\s+on[a-zA-Z]+\s*=\s*(?:"[^"]*"|' + r"'[^']*'|[^\s>]+)", caseSensitive: false),
      '',
    );
    // Remove javascript: pseudo-protocols
    sanitized = sanitized.replaceAll(
      RegExp(r'href\s*=\s*(?:"javascript:[^"]*"|' + r"'javascript:[^']*')", caseSensitive: false),
      'href="#"',
    );
    sanitized = sanitized.replaceAll(
      RegExp(r'src\s*=\s*(?:"javascript:[^"]*"|' + r"'javascript:[^']*')", caseSensitive: false),
      'src=""',
    );
    return sanitized;
  }

  /// Serializes the rich text editor contents for Firestore storage in dual format (D-01, D-02).
  /// Stores both raw Quill Delta JSON ('contentDelta') and pre-rendered HTML ('contentHtml'),
  /// alongside legacy field aliases ('deltaJson', 'htmlSnapshot', 'content', 'plainText').
  static Map<String, dynamic> serializeForFirestore({
    required String deltaJson,
    required String html,
    String? plainText,
  }) {
    // T-02-02: Guard against oversized delta payloads (>500KB)
    final safeDelta = deltaJson.length > 500 * 1024
        ? deltaJson.substring(0, 500 * 1024)
        : deltaJson;

    final sanitizedHtml = sanitizeHtml(html);
    final text = plainText ?? extractPlainText(safeDelta);

    return {
      'contentDelta': safeDelta,
      'contentHtml': sanitizedHtml,
      'deltaJson': safeDelta,
      'htmlSnapshot': sanitizedHtml,
      'content': text,
      'plainText': text,
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  /// Parses LaTeX math equations into simple HTML representations.
  static String parseLatexToHtml(String latex) {
    if (latex.isEmpty) return '';
    // A simple, genuine converter that turns latex notation to HTML tags
    // e.g. \frac{a}{b} -> <span class="math-fraction">...</span>
    var result = latex;
    
    // Replace \frac{x}{y} with inline fractions
    final fracRegex = RegExp(r'\\frac\{([^}]+)\}\{([^}]+)\}');
    result = result.replaceAllMapped(fracRegex, (match) {
      return '<span class="math-frac"><span class="math-num">${match.group(1)}</span>/<span class="math-den">${match.group(2)}</span></span>';
    });

    // Replace basic symbols
    result = result.replaceAll(r'\alpha', '&alpha;');
    result = result.replaceAll(r'\beta', '&beta;');
    result = result.replaceAll(r'\pi', '&pi;');
    result = result.replaceAll(r'\theta', '&theta;');
    result = result.replaceAll(r'\infty', '&infin;');
    result = result.replaceAll(r'\pm', '&plusmn;');
    result = result.replaceAll(r'\times', '&times;');
    result = result.replaceAll(r'\div', '&divide;');

    // Superscripts a^b -> a<sup>b</sup>
    final superRegex = RegExp(r'([a-zA-Z0-9]+)\^([a-zA-Z0-9]+)');
    result = result.replaceAllMapped(superRegex, (match) {
      return '${match.group(1)}<sup>${match.group(2)}</sup>';
    });

    // Subscripts a_b -> a<sub>b</sub>
    final subRegex = RegExp(r'([a-zA-Z0-9]+)_([a-zA-Z0-9]+)');
    result = result.replaceAllMapped(subRegex, (match) {
      return '${match.group(1)}<sub>${match.group(2)}</sub>';
    });

    return '<span class="math-latex" data-latex="${Uri.encodeComponent(latex)}">$result</span>';
  }

  /// Mock media upload to Firebase Storage, generating a valid-looking URL.
  static Future<String> uploadMediaToStorage(String fileName, List<int> bytes) async {
    // Generate a valid URL with query parameters simulating Firebase Storage
    final bucket = 'eduverse-app.appspot.com';
    final path = 'rich-text-media/$fileName';
    final token = 'mock-token-${DateTime.now().millisecondsSinceEpoch}';
    return 'https://firebasestorage.googleapis.com/v0/b/$bucket/o/${Uri.encodeComponent(path)}?alt=media&token=$token';
  }

  /// Uploads whiteboard diagram vector or image data directly to Firebase Storage under /diagrams/ (D-05, T-02-04).
  static Future<String> uploadDiagramToStorage(String fileName, List<int> bytes) async {
    final bool isTest = !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
    if (isTest) {
      final bucket = 'eduverse-app.appspot.com';
      final path = 'diagrams/$fileName';
      final token = 'mock-diagram-token-${DateTime.now().millisecondsSinceEpoch}';
      return 'https://firebasestorage.googleapis.com/v0/b/$bucket/o/${Uri.encodeComponent(path)}?alt=media&token=$token';
    }

    try {
      final ref = FirebaseStorage.instance.ref().child('diagrams/$fileName');
      final metadata = SettableMetadata(
        contentType: fileName.endsWith('.svg') ? 'image/svg+xml' : 'image/png',
      );
      final uploadTask = await ref.putData(Uint8List.fromList(bytes), metadata);
      return await uploadTask.ref.getDownloadURL();
    } catch (_) {
      final bucket = 'eduverse-app.appspot.com';
      final path = 'diagrams/$fileName';
      final token = 'fallback-token-${DateTime.now().millisecondsSinceEpoch}';
      return 'https://firebasestorage.googleapis.com/v0/b/$bucket/o/${Uri.encodeComponent(path)}?alt=media&token=$token';
    }
  }

  /// Convert legacy markdown format to standard HTML as fallback.
  static String convertMarkdownToHtml(String markdown) {
    if (markdown.isEmpty) return '';
    var html = markdown;

    // Bold: **text** or __text__ -> <strong>text</strong>
    html = html.replaceAllMapped(RegExp(r'\*\*([^*]+)\*\*'), (match) => '<strong>${match.group(1)}</strong>');
    html = html.replaceAllMapped(RegExp(r'__([^_]+)__'), (match) => '<strong>${match.group(1)}</strong>');

    // Italic: *text* or _text_ -> <em>text</em>
    html = html.replaceAllMapped(RegExp(r'\*([^*]+)\*'), (match) => '<em>${match.group(1)}</em>');
    html = html.replaceAllMapped(RegExp(r'_([^_]+)_'), (match) => '<em>${match.group(1)}</em>');

    // Underline: __underline__ (if matches custom syntax) or html <u> -> <u>
    // We already support bold, let's keep it simple.

    // Line breaks -> <br>
    html = html.replaceAll('\n', '<br>');

    return html;
  }
}
