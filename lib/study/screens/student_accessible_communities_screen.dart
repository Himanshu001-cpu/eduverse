import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/repositories/community_repository.dart';
import '../models/community_models.dart';
import '../presentation/providers/study_controller.dart';
import 'student_community_screen.dart';

class StudentAccessibleCommunitiesScreen extends StatefulWidget {
  const StudentAccessibleCommunitiesScreen({super.key});

  @override
  State<StudentAccessibleCommunitiesScreen> createState() =>
      _StudentAccessibleCommunitiesScreenState();
}

class _StudentAccessibleCommunitiesScreenState
    extends State<StudentAccessibleCommunitiesScreen> {
  final CommunityRepository _repository = CommunityRepository();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'My Communities',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: Consumer<StudyController>(
        builder: (context, controller, child) {
          // Extract set of accessible course IDs from student's enrolled batches
          final enrolledCourseIds = <String>{};
          for (final batch in controller.enrolledBatches) {
            if (batch.isCombo && batch.courseIds != null) {
              enrolledCourseIds.addAll(batch.courseIds!);
            } else {
              enrolledCourseIds.add(batch.courseId);
            }
          }

          return Column(
            children: [
              // Search Header
              Container(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.04),
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.trim().toLowerCase();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search communities by subject or teacher...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Theme.of(context).primaryColor),
                    ),
                  ),
                ),
              ),

              // Communities Stream
              Expanded(
                child: StreamBuilder<List<StudentCommunity>>(
                  stream: _repository.getCommunitiesForStudent(enrolledCourseIds),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, size: 48, color: Colors.red),
                              const SizedBox(height: 12),
                              Text(
                                'Error loading communities:\n${snapshot.error}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    var communities = snapshot.data ?? [];

                    // Apply client-side search filtering
                    if (_searchQuery.isNotEmpty) {
                      communities = communities.where((c) {
                        final subject = c.subjectName.toLowerCase();
                        final teacher = c.teacherName.toLowerCase();
                        final desc = c.description.toLowerCase();
                        return subject.contains(_searchQuery) ||
                            teacher.contains(_searchQuery) ||
                            desc.contains(_searchQuery);
                      }).toList();
                    }

                    if (communities.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.teal.shade50,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.groups_outlined,
                                  size: 56,
                                  color: Colors.teal.shade400,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                enrolledCourseIds.isEmpty
                                    ? 'No Enrolled Courses'
                                    : (_searchQuery.isNotEmpty
                                        ? 'No Communities Match Your Search'
                                        : 'No Accessible Communities Found'),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                enrolledCourseIds.isEmpty
                                    ? 'Enroll in batches or courses to access subject discussion communities.'
                                    : (_searchQuery.isNotEmpty
                                        ? 'Try searching with a different term.'
                                        : 'Communities linked to your enrolled courses will appear here.'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: communities.length,
                      itemBuilder: (context, index) {
                        final community = communities[index];
                        return _buildCommunityCard(context, community, index);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCommunityCard(
      BuildContext context, StudentCommunity community, int index) {
    const cardGradients = [
      [Color(0xFF009688), Color(0xFF00796B)],
      [Color(0xFF3F51B5), Color(0xFF303F9F)],
      [Color(0xFF673AB7), Color(0xFF512DA8)],
      [Color(0xFF00838F), Color(0xFF006064)],
      [Color(0xFFE91E63), Color(0xFFC2185B)],
    ];

    final gradient = cardGradients[index % cardGradients.length];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StudentCommunityScreen(community: community),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon Avatar
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: gradient[0].withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.forum_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),

              // Content Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      community.subjectName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (community.teacherName.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Teacher: ${community.teacherName}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    if (community.description.isNotEmpty)
                      Text(
                        community.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Post count badge & arrow
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.teal.shade100),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 12,
                          color: Colors.teal.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${community.postCount}',
                          style: TextStyle(
                            color: Colors.teal.shade800,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
