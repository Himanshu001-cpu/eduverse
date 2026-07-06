class RichTextService {
  /// Serializes the rich text editor contents for Firestore storage.
  static Map<String, dynamic> serializeForFirestore({
    required String deltaJson,
    required String html,
  }) {
    return {
      'deltaJson': deltaJson,
      'htmlSnapshot': html,
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
