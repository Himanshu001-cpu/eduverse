import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:eduverse/common/widgets/empty_state.dart';
import 'package:eduverse/common/widgets/cards.dart';
import 'package:eduverse/study/data/repositories/study_repository_impl.dart';
import 'package:eduverse/study/domain/models/study_entities.dart';
import 'package:eduverse/study/presentation/screens/lecture_player_screen.dart';

class FreeLiveClassesPage extends StatefulWidget {
  const FreeLiveClassesPage({super.key});

  @override
  State<FreeLiveClassesPage> createState() => _FreeLiveClassesPageState();
}

class _FreeLiveClassesPageState extends State<FreeLiveClassesPage> {
  String _filter = 'All'; // All, Upcoming, Past
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  
  // Future to fetch data
  late Future<List<StudyLiveClass>> _classesFuture;

  @override
  void initState() {
    super.initState();
    _classesFuture = StudyRepositoryImpl().getFreeLiveClasses();
  }

  // Helper to filter and sort
  List<StudyLiveClass> _filterClasses(List<StudyLiveClass> all) {
    var list = List<StudyLiveClass>.from(all);
    final now = DateTime.now();

    // Filter by type
    if (_filter == 'Upcoming') {
      list = list.where((c) => c.startTime.isAfter(now)).toList();
    } else if (_filter == 'Past') {
      list = list.where((c) => c.startTime.isBefore(now)).toList();
    }

    // Filter by search
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((c) {
        return c.title.toLowerCase().contains(q);
        // Instructor is not in StudyLiveClass yet, can add later if needed.
        // || c.instructor.toLowerCase().contains(q);
      }).toList();
    }

    // Sort: Upcoming (nearest first), Past (most recent first)
    list.sort((a, b) {
      if (_filter == 'Past') {
        return b.startTime.compareTo(a.startTime);
      }
      return a.startTime.compareTo(b.startTime);
    });

    return list;
  }

  @override
  Widget build(BuildContext context) {
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
                    hintText: 'Search by title',
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
            child: FutureBuilder<List<StudyLiveClass>>(
              future: _classesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  debugPrint('Snapshot error: ${snapshot.error}');
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  debugPrint('Snapshot has no data or empty');
                  return const EmptyState(
                      title: 'No classes found', icon: Icons.event_busy);
                }

                debugPrint('Received ${snapshot.data!.length} classes from repo');
                final filtered = _filterClasses(snapshot.data!);
                debugPrint('After filtering: ${filtered.length} classes');

                if (filtered.isEmpty) {
                   return const EmptyState(
                      title: 'No matching classes', icon: Icons.search_off);
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {
                      _classesFuture = StudyRepositoryImpl().getFreeLiveClasses();
                    });
                    await _classesFuture;
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return _LiveClassCard(item: item);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveClassCard extends StatelessWidget {
  final StudyLiveClass item;

  const _LiveClassCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final isUpcoming = item.startTime.isAfter(DateTime.now());
    final isLiveSoon = isUpcoming &&
        item.startTime.difference(DateTime.now()).inMinutes <= 10;
        
    // Placeholder logic for duration since it's an int in minutes
    final durationText = '${item.durationMinutes} min';

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
              color: Colors.blueAccent.withOpacity(0.2), // Default color
              borderRadius: BorderRadius.circular(12),
            ),
             child: item.thumbnailUrl.isNotEmpty
                ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(item.thumbnailUrl, fit: BoxFit.cover),
                )
                : const Center(
                  child: Text(
                    '📺',
                    style: TextStyle(fontSize: 24),
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${DateFormat('MMM d, h:mm a').format(item.startTime)} • $durationText',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          ),
          if (isUpcoming)
            ElevatedButton(
              onPressed: isLiveSoon ? () {
                _joinClass(context);
              } : () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Class hasn\'t started yet!')),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                backgroundColor: isLiveSoon ? Colors.red : null,
                foregroundColor: isLiveSoon ? Colors.white : null,
              ),
              child: Text(isLiveSoon ? 'Join' : 'Soon'),
            )
          else
             OutlinedButton(
               onPressed: () {
                 _joinClass(context);
               },
               child: const Text('Watch'),
             ),
        ],
      ),
    );
  }

  void _joinClass(BuildContext context) {
    // Map StudyLiveClass to StudyLecture for the player
    final lecture = StudyLecture(
      id: item.id,
      title: item.title,
      videoUrl: item.youtubeUrl ?? '', // Ensure fallback if needed, or handle empty URL upstream
      description: item.description,
      order: 0,
      duration: Duration(minutes: item.durationMinutes),
    );

    if (lecture.videoUrl.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No video URL available for this class.')),
        );
        return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LecturePlayerScreen(
          lecture: lecture,
          isFreeClass: true,
          // courseId and batchId are null for free classes
        ),
      ),
    );
  }
}

class _ClassDetailsSheet extends StatelessWidget {
  final StudyLiveClass item;

  const _ClassDetailsSheet({required this.item});

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
          const SizedBox(height: 16),
          Text(
            item.description.isNotEmpty ? item.description : 'No description available.',
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
