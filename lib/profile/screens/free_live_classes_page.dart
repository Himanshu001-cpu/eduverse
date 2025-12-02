import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:eduverse/profile/profile_mock_data.dart';
import 'package:eduverse/common/widgets/empty_state.dart';
import 'package:eduverse/common/widgets/cards.dart';

class FreeLiveClassesPage extends StatefulWidget {
  const FreeLiveClassesPage({Key? key}) : super(key: key);

  @override
  State<FreeLiveClassesPage> createState() => _FreeLiveClassesPageState();
}

class _FreeLiveClassesPageState extends State<FreeLiveClassesPage> {
  String _filter = 'All'; // All, Upcoming, Past
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  List<LiveClass> get _filteredClasses {
    final now = DateTime.now();
    List<LiveClass> list = ProfileMockData.liveClasses;

    // Filter by type
    if (_filter == 'Upcoming') {
      list = list.where((c) => c.dateTime.isAfter(now)).toList();
    } else if (_filter == 'Past') {
      list = list.where((c) => c.dateTime.isBefore(now)).toList();
    }

    // Filter by search
    if (_searchQuery.isNotEmpty) {
      list = list.where((c) {
        final q = _searchQuery.toLowerCase();
        return c.title.toLowerCase().contains(q) ||
            c.instructor.toLowerCase().contains(q);
      }).toList();
    }

    // Sort: Upcoming (nearest first), Past (most recent first)
    list.sort((a, b) {
      if (_filter == 'Past') {
        return b.dateTime.compareTo(a.dateTime);
      }
      return a.dateTime.compareTo(b.dateTime);
    });

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final classes = _filteredClasses;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Free Live Classes'),
      ),
      body: Column(
        children: [
          // Search and Filter
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search by title or instructor',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['All', 'Upcoming', 'Past'].map((filter) {
                      final isSelected = _filter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          label: Text(filter),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _filter = filter;
                              });
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: classes.isEmpty
                ? const EmptyState(
                    title: 'No classes found',
                    icon: Icons.event_busy,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: classes.length,
                    itemBuilder: (context, index) {
                      final item = classes[index];
                      return _LiveClassCard(item: item);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _LiveClassCard extends StatelessWidget {
  final LiveClass item;

  const _LiveClassCard({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isUpcoming = item.dateTime.isAfter(DateTime.now());
    final isLiveSoon = isUpcoming &&
        item.dateTime.difference(DateTime.now()).inMinutes <= 10;

    return AppCard(
      onTap: () {
        showModalBottomSheet(
          context: context,
          builder: (context) => _ClassDetailsSheet(item: item),
        );
      },
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '📺', // Placeholder emoji
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${DateFormat('MMM d, h:mm a').format(item.dateTime)} • ${item.duration.inMinutes} min',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                Text(
                  item.instructor,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          ),
          if (isUpcoming)
            ElevatedButton(
              onPressed: isLiveSoon ? () {} : () {
                // Mock reminder
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reminder set!')),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                backgroundColor: isLiveSoon ? Colors.red : null,
                foregroundColor: isLiveSoon ? Colors.white : null,
              ),
              child: Text(isLiveSoon ? 'Join' : 'Remind'),
            )
          else
             OutlinedButton(
               onPressed: () {
                 // Mock watch
                 Navigator.push(
                   context,
                   MaterialPageRoute(
                     builder: (context) => Scaffold(
                       appBar: AppBar(title: Text(item.title)),
                       body: const Center(child: Text('Video Player Placeholder')),
                     ),
                   ),
                 );
               },
               child: const Text('Watch'),
             ),
        ],
      ),
    );
  }
}

class _ClassDetailsSheet extends StatelessWidget {
  final LiveClass item;

  const _ClassDetailsSheet({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text('Instructor: ${item.instructor}'),
          const SizedBox(height: 16),
          Text(
            'Description goes here. This is a mock description for the live class. Learn about ${item.title} in this interactive session.',
            style: TextStyle(color: Colors.grey[700]),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }
}
