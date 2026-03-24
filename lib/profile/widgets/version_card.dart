import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class VersionCard extends StatefulWidget {
  const VersionCard({super.key});

  @override
  State<VersionCard> createState() => _VersionCardState();
}

class _VersionCardState extends State<VersionCard> {
  String _currentVersion = '';
  String _latestVersion = '';
  String _updateUrl = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVersionInfo();
  }

  Future<void> _loadVersionInfo() async {
    try {
      // Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      final current = packageInfo.version;

      // Get latest version from Firestore
      final doc = await FirebaseFirestore.instance
          .collection('app_config')
          .doc('version')
          .get();

      final data = doc.data();
      final latest = data?['latestVersion'] as String? ?? current;
      final url = data?['updateUrl'] as String? ?? '';

      if (mounted) {
        setState(() {
          _currentVersion = current;
          _latestVersion = latest;
          _updateUrl = url;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentVersion = '?.?.?';
          _latestVersion = '?.?.?';
          _isLoading = false;
        });
      }
    }
  }

  bool get _isUpToDate => _compareVersions(_currentVersion, _latestVersion) >= 0;

  /// Compare two semver strings. Returns:
  ///  > 0 if a > b, 0 if equal, < 0 if a < b
  int _compareVersions(String a, String b) {
    final aParts = a.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final bParts = b.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    for (var i = 0; i < 3; i++) {
      final av = i < aParts.length ? aParts[i] : 0;
      final bv = i < bParts.length ? bParts[i] : 0;
      if (av != bv) return av - bv;
    }
    return 0;
  }

  Future<void> _openStore() async {
    if (_updateUrl.isEmpty) return;
    final uri = Uri.parse(_updateUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_isUpToDate) {
      return _buildUpToDateCard();
    } else {
      return _buildUpdateAvailableCard();
    }
  }

  Widget _buildUpToDateCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.green[100], shape: BoxShape.circle),
            child: Icon(Icons.check_circle, color: Colors.green[700], size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "You're on the latest version",
              style: TextStyle(color: Colors.green[900], fontWeight: FontWeight.w500),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(20)),
            child: Text('v$_currentVersion', style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateAvailableCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.orange[100], shape: BoxShape.circle),
                child: Icon(Icons.system_update, color: Colors.orange[700], size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Update Available',
                      style: TextStyle(
                        color: Colors.orange[900],
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'v$_currentVersion → v$_latestVersion',
                      style: TextStyle(color: Colors.orange[700], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_updateUrl.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _openStore,
                icon: const Icon(Icons.download, size: 18),
                label: const Text('Update Now'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.orange[700],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
