import 'package:flutter/material.dart';
import 'package:eduverse/study/study_data.dart';

class MapWorkPage extends StatelessWidget {
  const MapWorkPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Topic Map'),
        actions: [
          IconButton(icon: const Icon(Icons.filter_list), onPressed: () {}),
        ],
      ),
      body: SafeArea(
        child: InteractiveViewer(
          boundaryMargin: const EdgeInsets.all(double.infinity),
          minScale: 0.5,
          maxScale: 2.0,
          child: Container(
            width: 1000,
            height: 1000,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              // Removed NetworkImage to prevent potential crashes if offline or invalid URL
              // Using a simple gradient or solid color instead for stability
              gradient: LinearGradient(
                colors: [Colors.grey[50]!, Colors.grey[100]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                // Draw connecting lines (simplified)
                CustomPaint(
                  size: const Size(1000, 1000),
                  painter: _ConnectionPainter(),
                ),
                // Place Topic Nodes
                _buildNode(context, StudyData.mapTopics[0], 400, 100),
                _buildNode(context, StudyData.mapTopics[1], 200, 300),
                _buildNode(context, StudyData.mapTopics[2], 600, 300),
                _buildNode(context, StudyData.mapTopics[3], 400, 500),
                _buildNode(context, StudyData.mapTopics[4], 200, 700),
                _buildNode(context, StudyData.mapTopics[5], 600, 700),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNode(BuildContext context, TopicNodeModel topic, double left, double top) {
    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onTap: () {
          showModalBottomSheet(
            context: context,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
            builder: (_) => Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(topic.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(topic.description, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Explore Topic'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: topic.color, width: 3),
            boxShadow: [
              BoxShadow(color: topic.color.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6)),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.layers, color: topic.color, size: 32),
              const SizedBox(height: 4),
              Text(
                topic.title,
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, color: topic.color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConnectionPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Simple hierarchy lines
    canvas.drawLine(const Offset(460, 160), const Offset(260, 360), paint);
    canvas.drawLine(const Offset(460, 160), const Offset(660, 360), paint);
    canvas.drawLine(const Offset(260, 360), const Offset(460, 560), paint);
    canvas.drawLine(const Offset(660, 360), const Offset(460, 560), paint);
    canvas.drawLine(const Offset(460, 560), const Offset(260, 760), paint);
    canvas.drawLine(const Offset(460, 560), const Offset(660, 760), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
