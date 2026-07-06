import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eduverse/study/presentation/providers/study_controller.dart';

class StickyTabPillHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  StickyTabPillHeaderDelegate({required this.child});

  @override
  double get minExtent => 60.0;

  @override
  double get maxExtent => 60.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      height: 60.0,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: overlapsContent
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ]
            : null,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant StickyTabPillHeaderDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}

class StickyTabPillsWidget extends StatelessWidget {
  const StickyTabPillsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<StudyController>(context);
    final tabs = ['Courses', 'Test Series', 'E-books'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: tabs.map((tab) {
          final isSelected = controller.currentTab == tab;
          
          Key getTabKey() {
            switch (tab) {
              case 'Courses':
                return const Key('tab_courses');
              case 'Test Series':
                return const Key('tab_test_series');
              case 'E-books':
                return const Key('tab_ebooks');
              default:
                return Key('tab_$tab');
            }
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: ChoiceChip(
              key: getTabKey(),
              label: Text(
                tab,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 14,
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                ),
              ),
              selected: isSelected,
              selectedColor: Colors.blue.shade700,
              backgroundColor: Colors.grey.shade100,
              showCheckmark: false,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? Colors.blue.shade700 : Colors.transparent,
                ),
              ),
              onSelected: (selected) {
                if (selected) {
                  controller.setTab(tab);
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}
