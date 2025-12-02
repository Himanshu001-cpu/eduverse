import 'package:flutter/material.dart';

class StatsSection extends StatelessWidget {
  const StatsSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            const Text('Stats', style: TextStyle(fontSize:20, fontWeight: FontWeight.bold)),
            const SizedBox(width:8),
            Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle), child: const Icon(Icons.question_mark, color: Colors.white, size: 12)),
          ]),
          Container(padding: const EdgeInsets.symmetric(horizontal:12, vertical:6), decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(20)), child: const Text('Last 30 days', style: TextStyle(fontSize:13, fontWeight: FontWeight.w500)))
        ]),
        const SizedBox(height:20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0,2))]),
          child: Column(children: [
            Row(children: [
              Expanded(child: StatCard(title: 'TOTAL WATCH MINS', value: '0', icon: Icons.access_time, iconColor: Colors.deepPurple[300]!, iconBackground: Colors.deepPurple[50]!)),
              const SizedBox(width:16),
              Expanded(child: StatCard(title: 'QUESTIONS\nATTEMPTED', value: '0', icon: Icons.help_outline, iconColor: Colors.teal[400]!, iconBackground: Colors.teal[50]!)),
            ]),
            const SizedBox(height:20),
            Row(children: [
              Expanded(child: StatCard(title: 'QUIZZES ATTEMPTED', value: '0', icon: Icons.assignment, iconColor: Colors.red[400]!, iconBackground: Colors.red[50]!)),
              const SizedBox(width:16),
              Expanded(child: StatCard(title: 'QUIZZES COMPLETED', value: '0', icon: Icons.check_circle, iconColor: Colors.amber[700]!, iconBackground: Colors.amber[50]!)),
            ]),
          ]),
        ),
      ]),
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;

  const StatCard({Key? key, required this.title, required this.value, required this.icon, required this.iconColor, required this.iconBackground}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(fontSize:11, fontWeight: FontWeight.w600, color: Colors.grey[600], letterSpacing:0.5)),
      const SizedBox(height:12),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(value, style: const TextStyle(fontSize:32, fontWeight: FontWeight.bold, color: Colors.black87)),
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: iconBackground, shape: BoxShape.circle), child: Icon(icon, color: iconColor, size: 28)),
      ]),
    ]);
  }
}
