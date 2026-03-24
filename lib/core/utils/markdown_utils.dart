// file: lib/core/utils/markdown_utils.dart

class MarkdownUtils {
  /// Normalizes markdown so that bold (**) and italic (*) markers render
  /// correctly regardless of how the admin entered the content.
  ///
  /// Problems fixed:
  ///   1. Spaces inside markers: `** bold **` → `**bold**`
  ///   2. Space only on one side: `** bold**` or `**bold **` → `**bold**`
  ///   3. Soft single-newlines inside a paragraph break the inline parser —
  ///      they are collapsed into spaces while double-newlines (paragraph
  ///      breaks) are preserved.
  static String normalizeMarkdown(String text) {
    if (text.isEmpty) return text;

    // Step 1 — collapse soft line-breaks (single \n) into spaces so the
    // inline parser sees the whole paragraph as one line.
    // Double (or more) newlines that separate paragraphs are preserved.
    String normalized = text.replaceAllMapped(
      RegExp(r'(?<!\n)\n(?!\n)'),
      (_) => ' ',
    );

    // Step 2 — fix bold markers with optional leading/trailing whitespace:
    //   `** bold **` / `** bold**` / `**bold **` → `**bold**`
    // Using dotAll:true so content containing its own newlines is matched
    // (shouldn't happen after step 1, but acts as a safety net).
    normalized = normalized.replaceAllMapped(
      RegExp(r'\*\*\s*(.*?)\s*\*\*', dotAll: true),
      (m) {
        final inner = m.group(1)!.trim();
        if (inner.isEmpty) return m.group(0)!; // not a valid marker, leave it
        return '**$inner**';
      },
    );

    // Step 3 — fix italic markers (single *), skipping `**` sequences.
    // Matches `* text *` / `* text*` / `*text *` but NOT `** ... **`.
    normalized = normalized.replaceAllMapped(
      RegExp(r'(?<!\*)\*\s*((?:[^*]|\*(?!\*))+?)\s*\*(?!\*)'),
      (m) {
        final inner = m.group(1)!.trim();
        if (inner.isEmpty) return m.group(0)!;
        return '*$inner*';
      },
    );

    return normalized;
  }

  /// Strips basic markdown formatting from a string.
  /// Useful for displaying preview text in cards where rich formatting
  /// might break the layout.
  static String stripMarkdown(String text) {
    if (text.isEmpty) return text;

    // Normalize first to handle spaces inside markers
    String stripped = normalizeMarkdown(text);

    // Remove bold and italic (**, *, __, _)
    stripped = stripped.replaceAll(RegExp(r'(\*\*|\*|__|_)(.*?)\1'), r'$2');

    // Remove headers (# Header text)
    stripped = stripped.replaceAll(
      RegExp(r'^#+\s+(.*?)$', multiLine: true),
      r'$1',
    );

    // Remove inline links [text](url) -> text
    stripped = stripped.replaceAll(RegExp(r'\[([^\]]+)\]\([^\)]+\)'), r'$1');

    // Remove inline code (`code`)
    stripped = stripped.replaceAll(RegExp(r'`([^`]+)`'), r'$1');

    // Remove blockquotes (> quote)
    stripped = stripped.replaceAll(
      RegExp(r'^>\s+(.*?)$', multiLine: true),
      r'$1',
    );

    // Remove list markers (- item, * item, 1. item)
    stripped = stripped.replaceAll(
      RegExp(r'^(\s*[-*]|\s*\d+\.)\s+(.*?)$', multiLine: true),
      r'$2',
    );

    return stripped;
  }
}
