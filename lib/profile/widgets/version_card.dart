import 'package:flutter/material.dart';

class VersionCard extends StatelessWidget {
  const VersionCard({super.key});

  @override
  Widget build(BuildContext context) {
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
              "You're already on latest version",
              style: TextStyle(color: Colors.green[900], fontWeight: FontWeight.w500),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(20)),
            child: Text('v2.7.0', style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
