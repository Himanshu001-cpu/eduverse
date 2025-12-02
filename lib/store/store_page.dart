import 'package:flutter/material.dart';
import 'store_widgets.dart';
import 'store_data.dart';

class StorePage extends StatefulWidget {
  const StorePage({Key? key}) : super(key: key);

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Image.asset('assets/icon.png', height: 30),
        actions: [
          IconButton(icon: const Icon(Icons.shopping_cart_outlined), onPressed: () {}),
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const BannerSlider(),

            const SizedBox(height: 24),

            CourseSection(
              title: 'UPSC IAS Prelims to Interview (P2I) Hinglish Batches',
              icon: Icons.star,
              courses: StoreData.hinglishBatches,
            ),

            const SizedBox(height: 20),

            CourseSection(
              title: 'UPSC Target Year 2027',
              icon: Icons.calendar_today,
              courses: StoreData.target2027,
            ),

            const SizedBox(height: 20),

            CourseSection(
              title: 'UPSC IAS (Mains) Optional Batches',
              icon: Icons.book,
              courses: StoreData.optionalBatches,
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
