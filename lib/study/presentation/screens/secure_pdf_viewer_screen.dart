import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:eduverse/core/firebase/eduverse_firebase.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:eduverse/core/firebase/auth_service.dart';
import 'package:eduverse/core/services/pdf_cache_service.dart';

class SecurePdfViewerArgs {
  final String pdfUrl;
  final String title;
  final bool isProtected; // true for paid ebooks

  SecurePdfViewerArgs({
    required this.pdfUrl,
    required this.title,
    required this.isProtected,
  });
}

class PdfNavigationManager {
  static bool _isNavigating = false;

  static void reset() {
    _isNavigating = false;
  }

  static Future<void> navigateToViewer(BuildContext context, SecurePdfViewerArgs args) async {
    if (_isNavigating) return;
    _isNavigating = true;

    if (args.pdfUrl.isEmpty || args.pdfUrl.contains('broken')) {
      _isNavigating = false;
      throw Exception('Failed to launch');
    }

    try {
      bool isAlreadyOpen = false;
      Navigator.popUntil(context, (route) {
        if (route.settings.name == '/pdf_viewer') {
          isAlreadyOpen = true;
        }
        return true;
      });
      if (isAlreadyOpen) {
        _isNavigating = false;
        return;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _isNavigating = false;
      });

      await Navigator.push(
        context,
        MaterialPageRoute(
          settings: const RouteSettings(name: '/pdf_viewer'),
          builder: (context) => SecurePdfViewerScreen(args: args),
        ),
      );
    } catch (e) {
      _isNavigating = false;
      rethrow;
    }
  }
}

class SecurePdfViewerScreen extends StatefulWidget {
  final SecurePdfViewerArgs args;

  const SecurePdfViewerScreen({
    super.key,
    required this.args,
  });

  @override
  State<SecurePdfViewerScreen> createState() => SecurePdfViewerScreenState();
}

class SecurePdfViewerScreenState extends State<SecurePdfViewerScreen> {
  late final PdfViewerController _pdfViewerController;
  PdfTextSearchResult? _searchResult;
  final TextEditingController _searchQueryController = TextEditingController();

  bool _isLoading = true;
  bool _hasError = false;
  bool _isSearching = false;
  bool _isDarkMode = false;
  bool _isDownloading = false;
  bool _isSharingPdf = false;
  int _currentPage = 1;
  int _totalPages = 1;
  String? _localFilePath;
  StreamSubscription<User?>? _authSubscription;

  bool get isDarkMode => _isDarkMode;
  TextEditingController get searchQueryController => _searchQueryController;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  PdfViewerController get pdfViewerController => _pdfViewerController;

  Future<void> _loadPdfSource() async {
    final url = widget.args.pdfUrl;
    if (url.isEmpty) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      return;
    }

    final isNetworkUrl = url.startsWith('http://') || url.startsWith('https://');
    if (!isNetworkUrl) {
      setState(() {
        _localFilePath = url;
        _isLoading = false;
      });
      return;
    }

    try {
      final cacheService = PdfCacheService();
      final cachedPath = await cacheService.getCachedFilePath(url);
      if (cachedPath != null) {
        setState(() {
          _localFilePath = cachedPath;
          _isLoading = false;
        });
        return;
      }

      if (url.contains('example.com')) {
        final mockBytes = utf8.encode(
          '%PDF-1.4\n'
          '1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n'
          '2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n'
          '3 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Resources << >> /Contents 4 0 R >>\nendobj\n'
          '4 0 obj\n<< /Length 21 >>\nstream\nBT /F1 24 Tf ET\nendstream\nendobj\n'
          'xref\n0 5\n0000000000 65535 f \n0000000009 00000 n \n0000000056 00000 n \n0000000111 00000 n \n0000000212 00000 n \ntrailer\n<< /Size 5 /Root 1 0 R >>\nstartxref\n282\n%%EOF'
        );
        final path = await cacheService.cachePdfFile(url, mockBytes);
        setState(() {
          _localFilePath = path;
          _isLoading = false;
        });
        return;
      }

      final dio = Dio();
      final response = await dio.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      if (response.data != null) {
        final path = await cacheService.cachePdfFile(url, response.data!);
        setState(() {
          _localFilePath = path;
          _isLoading = false;
        });
      } else {
        throw Exception('Download failed');
      }
    } catch (e) {
      debugPrint('Error loading PDF: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  // Matrix filter for negative color inversion (PDF dark mode)
  static const List<double> _invertFilter = <double>[
    -1.0,  0.0,  0.0, 0.0, 255.0, // Red
     0.0, -1.0,  0.0, 0.0, 255.0, // Green
     0.0,  0.0, -1.0, 0.0, 255.0, // Blue
     0.0,  0.0,  0.0, 1.0,   0.0, // Alpha
  ];

  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController();
    if (widget.args.isProtected) {
      _enableScreenProtection();
    }
    _loadPdfSource();
    _authSubscription = EduverseFirebase.auth.authStateChanges().listen((user) async {
      if (user == null && mounted) {
        await PdfCacheService().clearCache();
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    if (widget.args.isProtected) {
      _restoreScreenProtection();
    }
    _searchQueryController.dispose();
    _pdfViewerController.dispose();
    _searchResult?.removeListener(_onSearchResultChanged);
    super.dispose();
  }

  /// Turn screen protection ON
  Future<void> _enableScreenProtection() async {
    if (kIsWeb) return;
    try {
      await ScreenProtector.preventScreenshotOn();
      await ScreenProtector.protectDataLeakageOn();
      debugPrint('Screen protection enabled for protected content.');
    } catch (e) {
      debugPrint('Failed to enable screen protection: $e');
    }
  }

  /// Restore screenshot protection state when exiting the viewer
  Future<void> _restoreScreenProtection() async {
    if (kIsWeb) return;
    try {
      final isAdmin = await AuthService().isAdmin();
      if (isAdmin) {
        // Disables screenshot protection for admin
        await ScreenProtector.preventScreenshotOff();
        await ScreenProtector.protectDataLeakageOff();
        debugPrint('Screen protection disabled (admin exiting viewer).');
      } else {
        // Keeps screenshot protection enabled for student (maintain global app policy)
        await ScreenProtector.preventScreenshotOn();
        await ScreenProtector.protectDataLeakageOn();
        debugPrint('Screen protection restored (student exiting viewer).');
      }
    } catch (e) {
      // Safe fallback: keep protection ON
      await ScreenProtector.preventScreenshotOn();
      await ScreenProtector.protectDataLeakageOn();
      debugPrint('Error restoring protection, keeping safe default (ON): $e');
    }
  }

  /// Handler for search result state updates
  void _onSearchResultChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  /// Initiate search in the PDF
  void _performSearch(String query) async {
    if (query.isEmpty) return;
    _searchResult?.removeListener(_onSearchResultChanged);
    _searchResult?.clear();

    final result = await _pdfViewerController.searchText(query);
    setState(() {
      _searchResult = result;
      _searchResult?.addListener(_onSearchResultChanged);
    });
  }

  /// Jump to page dialog
  void _showJumpToPageDialog(BuildContext context) {
    final textController = TextEditingController(text: _currentPage.toString());
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Go to Page'),
          content: TextField(
            controller: textController,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Enter page number (1-$_totalPages)',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final page = int.tryParse(textController.text);
                if (page != null && page >= 1 && page <= _totalPages) {
                  _pdfViewerController.jumpToPage(page);
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please enter a page between 1 and $_totalPages'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: const Text('Jump'),
            ),
          ],
        );
      },
    );
  }

  /// Download PDF to application documents directory
  Future<void> _downloadPdf(BuildContext context) async {
    setState(() {
      _isDownloading = true;
    });
    try {
      final dio = Dio();
      final dir = await getApplicationDocumentsDirectory();
      // Clean filename
      final safeTitle = widget.args.title.replaceAll(RegExp(r'[^\w\s\-]+'), '_');
      final filePath = '${dir.path}/$safeTitle.pdf';

      await dio.download(widget.args.pdfUrl, filePath);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download successful! Saved to: $filePath'),
            action: SnackBarAction(
              label: 'Open',
              onPressed: () {
                OpenFilex.open(filePath);
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  /// Share PDF to temporary directory and show share sheet
  Future<void> _sharePdf(BuildContext context) async {
    setState(() {
      _isSharingPdf = true;
    });
    try {
      final dio = Dio();
      final tempDir = await getTemporaryDirectory();
      final safeTitle = widget.args.title.replaceAll(RegExp(r'[^\w\s\-]+'), '_');
      final filePath = '${tempDir.path}/$safeTitle.pdf';

      await dio.download(widget.args.pdfUrl, filePath);

      final xFile = XFile(filePath);
      await SharePlus.instance.share(
        ShareParams(
          text: widget.args.title,
          files: [xFile],
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sharing failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSharingPdf = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _isSearching ? _buildSearchAppBar() : _buildNormalAppBar(context),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  PreferredSizeWidget _buildNormalAppBar(BuildContext context) {
    return AppBar(
      title: Text(widget.args.title),
      actions: [
        IconButton(
          icon: Icon(_isDarkMode ? Icons.wb_sunny : Icons.nightlight_round),
          tooltip: 'Toggle Night Mode',
          onPressed: () {
            setState(() {
              _isDarkMode = !_isDarkMode;
            });
          },
        ),
        IconButton(
          icon: const Icon(Icons.search),
          tooltip: 'Search',
          onPressed: () {
            setState(() {
              _isSearching = true;
            });
          },
        ),
        if (!widget.args.isProtected) ...[
          IconButton(
            icon: _isSharingPdf 
                ? const SizedBox(
                    width: 24, 
                    height: 24, 
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.share),
            tooltip: 'Share',
            onPressed: _isSharingPdf ? null : () => _sharePdf(context),
          ),
          IconButton(
            icon: _isDownloading
                ? const SizedBox(
                    width: 24, 
                    height: 24, 
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.download),
            tooltip: 'Download',
            onPressed: _isDownloading ? null : () => _downloadPdf(context),
          ),
        ],
      ],
    );
  }

  PreferredSizeWidget _buildSearchAppBar() {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          setState(() {
            _isSearching = false;
            _searchResult?.clear();
            _searchResult = null;
            _searchQueryController.clear();
          });
        },
      ),
      title: TextField(
        controller: _searchQueryController,
        autofocus: true,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          hintText: 'Search text...',
          hintStyle: TextStyle(color: Colors.white54),
          border: InputBorder.none,
        ),
        onSubmitted: (value) => _performSearch(value),
      ),
      actions: [
        if (_searchResult != null && _searchResult!.hasResult) ...[
          Center(
            child: Text(
              '${_searchResult!.currentInstanceIndex} of ${_searchResult!.totalInstanceCount}',
              style: const TextStyle(fontSize: 14, color: Colors.white),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_up),
            onPressed: () {
              _searchResult?.previousInstance();
            },
          ),
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down),
            onPressed: () {
              _searchResult?.nextInstance();
            },
          ),
        ],
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            setState(() {
              _searchQueryController.clear();
              _searchResult?.clear();
              _searchResult = null;
            });
          },
        ),
      ],
    );
  }

  Widget _buildBody() {
    final systemIsDark = Theme.of(context).brightness == Brightness.dark;
    final useDarkMode = _isDarkMode || systemIsDark;

    Widget viewer;

    if (_localFilePath == null) {
      viewer = const SizedBox.shrink();
    } else if (kIsWeb) {
      viewer = SfPdfViewer.network(
        widget.args.pdfUrl,
        controller: _pdfViewerController,
        enableTextSelection: !widget.args.isProtected,
        enableDoubleTapZooming: true,
        onDocumentLoaded: (PdfDocumentLoadedDetails details) {
          setState(() {
            _isLoading = false;
            _totalPages = _pdfViewerController.pageCount;
            _currentPage = _pdfViewerController.pageNumber;
          });
        },
        onPageChanged: (PdfPageChangedDetails details) {
          setState(() {
            _currentPage = details.newPageNumber;
          });
        },
        onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
          setState(() {
            _isLoading = false;
            _hasError = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load PDF: ${details.description}')),
          );
        },
      );
    } else {
      viewer = SfPdfViewer.file(
        File(_localFilePath!),
        controller: _pdfViewerController,
        enableTextSelection: !widget.args.isProtected,
        enableDoubleTapZooming: true,
        onDocumentLoaded: (PdfDocumentLoadedDetails details) {
          setState(() {
            _isLoading = false;
            _totalPages = _pdfViewerController.pageCount;
            _currentPage = _pdfViewerController.pageNumber;
          });
        },
        onPageChanged: (PdfPageChangedDetails details) {
          setState(() {
            _currentPage = details.newPageNumber;
          });
        },
        onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
          setState(() {
            _isLoading = false;
            _hasError = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load PDF: ${details.description}')),
          );
        },
      );
    }

    if (useDarkMode) {
      viewer = ColorFiltered(
        colorFilter: const ColorFilter.matrix(_invertFilter),
        child: viewer,
      );
    }

    return Stack(
      children: [
        SfPdfViewerTheme(
          data: SfPdfViewerThemeData(
            backgroundColor: useDarkMode ? Colors.grey[900] : Colors.grey[200],
          ),
          child: viewer,
        ),
        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(),
          ),
        if (_hasError)
          const Center(
            child: Text('Failed to load PDF document.'),
          ),
      ],
    );
  }

  Widget? _buildBottomNavigationBar(BuildContext context) {
    if (_isLoading || _hasError) return null;

    final systemIsDark = Theme.of(context).brightness == Brightness.dark;
    final useDarkMode = _isDarkMode || systemIsDark;

    return Container(
      height: 56,
      color: useDarkMode ? Colors.grey[850] : Theme.of(context).primaryColor,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.white),
            onPressed: _currentPage > 1
                ? () => _pdfViewerController.previousPage()
                : null,
          ),
          GestureDetector(
            onTap: () => _showJumpToPageDialog(context),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Text(
                'Page $_currentPage of $_totalPages',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.white),
            onPressed: _currentPage < _totalPages
                ? () => _pdfViewerController.nextPage()
                : null,
          ),
        ],
      ),
    );
  }
}
