import 'package:flutter/material.dart';

class FindReplacePanel extends StatefulWidget {
  final TextEditingController textController;
  final VoidCallback? onMatchesChanged;

  const FindReplacePanel({
    super.key,
    required this.textController,
    this.onMatchesChanged,
  });

  @override
  State<FindReplacePanel> createState() => _FindReplacePanelState();
}

class _FindReplacePanelState extends State<FindReplacePanel> {
  final TextEditingController _findController = TextEditingController();
  final TextEditingController _replaceController = TextEditingController();

  bool _caseSensitive = false;
  bool _useRegex = false;
  
  List<RegExpMatch> _matches = [];
  int _currentIndex = -1;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    widget.textController.addListener(_onTextChanged);
    _findController.addListener(_performSearch);
  }

  @override
  void dispose() {
    widget.textController.removeListener(_onTextChanged);
    _findController.dispose();
    _replaceController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    _performSearch();
  }

  void _performSearch() {
    final query = _findController.text;
    final text = widget.textController.text;

    setState(() {
      _errorMessage = null;
      _matches.clear();
      _currentIndex = -1;
    });

    if (query.isEmpty) {
      widget.onMatchesChanged?.call();
      return;
    }

    try {
      RegExp regExp;
      if (_useRegex) {
        regExp = RegExp(query, caseSensitive: _caseSensitive);
      } else {
        regExp = RegExp(RegExp.escape(query), caseSensitive: _caseSensitive);
      }

      final allMatches = regExp.allMatches(text).toList();
      setState(() {
        _matches = allMatches;
        if (_matches.isNotEmpty) {
          _currentIndex = 0;
        }
      });
    } on FormatException catch (e) {
      setState(() {
        _errorMessage = 'Invalid regex: ${e.message}';
      });
    }

    widget.onMatchesChanged?.call();
  }

  void _nextMatch() {
    if (_matches.isEmpty) return;
    setState(() {
      _currentIndex = (_currentIndex + 1) % _matches.length;
    });
  }

  void _replace() {
    if (_matches.isEmpty || _currentIndex < 0 || _currentIndex >= _matches.length) return;
    
    final match = _matches[_currentIndex];
    final text = widget.textController.text;
    final replacement = _replaceController.text;

    final newText = text.substring(0, match.start) + replacement + text.substring(match.end);
    
    widget.textController.text = newText;
    // Selection will trigger _onTextChanged and re-run search, updating matches list automatically.
  }

  void _replaceAll() {
    final query = _findController.text;
    if (query.isEmpty) return;

    final text = widget.textController.text;
    final replacement = _replaceController.text;

    try {
      RegExp regExp;
      if (_useRegex) {
        regExp = RegExp(query, caseSensitive: _caseSensitive);
      } else {
        regExp = RegExp(RegExp.escape(query), caseSensitive: _caseSensitive);
      }

      final newText = text.replaceAll(regExp, replacement);
      widget.textController.text = newText;
    } on FormatException catch (e) {
      setState(() {
        _errorMessage = 'Invalid regex: ${e.message}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4.0,
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Find & Replace',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8.0),
            TextField(
              controller: _findController,
              key: const Key('find_input'),
              decoration: InputDecoration(
                labelText: 'Find',
                errorText: _errorMessage,
                suffixText: _matches.isNotEmpty
                    ? '${_currentIndex + 1}/${_matches.length}'
                    : null,
              ),
            ),
            const SizedBox(height: 8.0),
            TextField(
              controller: _replaceController,
              key: const Key('replace_input'),
              decoration: const InputDecoration(
                labelText: 'Replace with',
              ),
            ),
            const SizedBox(height: 8.0),
            Row(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      key: const Key('case_sensitive_checkbox'),
                      value: _caseSensitive,
                      onChanged: (val) {
                        setState(() {
                          _caseSensitive = val ?? false;
                          _performSearch();
                        });
                      },
                    ),
                    const Text('Aa (Match Case)'),
                  ],
                ),
                const SizedBox(width: 16.0),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      key: const Key('regex_checkbox'),
                      value: _useRegex,
                      onChanged: (val) {
                        setState(() {
                          _useRegex = val ?? false;
                          _performSearch();
                        });
                      },
                    ),
                    const Text('.* (Regex)'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  key: const Key('find_next_button'),
                  onPressed: _matches.isEmpty ? null : _nextMatch,
                  child: const Text('Find Next'),
                ),
                TextButton(
                  key: const Key('replace_button'),
                  onPressed: _matches.isEmpty ? null : _replace,
                  child: const Text('Replace'),
                ),
                ElevatedButton(
                  key: const Key('replace_all_button'),
                  onPressed: _findController.text.isEmpty ? null : _replaceAll,
                  child: const Text('Replace All'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
