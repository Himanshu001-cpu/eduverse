// file: lib/feed/screens/job_detail_page.dart
import 'package:flutter/material.dart';
import 'package:eduverse/feed/models.dart';
import 'package:eduverse/feed/widgets/rich_text_block.dart';

/// Detail page for Job/Vacancy content type.
/// Shows full job details, eligibility, dates, and apply action.
class JobDetailPage extends StatefulWidget {
  final FeedItem item;

  const JobDetailPage({super.key, required this.item});

  @override
  State<JobDetailPage> createState() => _JobDetailPageState();
}

class _JobDetailPageState extends State<JobDetailPage> {
  bool _isSaved = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final item = widget.item;
    final content = item.jobContent;

    return Scaffold(
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          slivers: [
            // Header
            SliverAppBar(
              expandedHeight: 160,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        item.color,
                        item.color.withValues(alpha: 0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        Text(
                          item.emoji,
                          style: const TextStyle(fontSize: 48),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text(
                            'JOB ALERT',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    _isSaved ? Icons.bookmark : Icons.bookmark_outline,
                    color: Colors.white,
                  ),
                  onPressed: _toggleSave,
                ),
                IconButton(
                  icon: const Icon(Icons.share, color: Colors.white),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Share feature coming soon!')),
                    );
                  },
                ),
              ],
            ),
            // Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title & Organization
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.business, size: 18, color: colorScheme.primary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            content?.organization ?? 'Government of India',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: colorScheme.primary,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Quick info chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (content?.location != null)
                          InfoChip(
                            icon: Icons.location_on,
                            label: content!.location,
                          ),
                        if (content?.vacancies != null)
                          InfoChip(
                            icon: Icons.people,
                            label: '${content!.vacancies} Vacancies',
                            color: Colors.green,
                          ),
                        if (content?.salaryRange != null)
                          InfoChip(
                            icon: Icons.currency_rupee,
                            label: content!.salaryRange!,
                            color: Colors.amber.shade700,
                          ),
                        if (content?.jobType != null)
                          InfoChip(
                            icon: Icons.work,
                            label: content!.jobType!,
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Divider(color: colorScheme.outlineVariant),
                    const SizedBox(height: 16),
                    // Important Dates Card
                    Card(
                      elevation: 0,
                      color: Colors.orange.withValues(alpha: 0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.orange.withValues(alpha: 0.3)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, color: Colors.orange),
                                const SizedBox(width: 8),
                                Text(
                                  'Important Dates',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange.shade800,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildDateRow(
                              'Application Start',
                              _formatDate(content?.applicationStart ?? DateTime.now()),
                              Icons.play_arrow,
                              Colors.green,
                            ),
                            const SizedBox(height: 8),
                            _buildDateRow(
                              'Application End',
                              _formatDate(content?.applicationEnd ?? DateTime.now().add(const Duration(days: 30))),
                              Icons.stop,
                              Colors.red,
                            ),
                            const SizedBox(height: 8),
                            _buildDateRow(
                              'Exam Date',
                              'To be announced',
                              Icons.event,
                              Colors.blue,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Job Details
                    RichTextBlock(
                      title: 'Job Details',
                      body: content?.detailsText ?? item.description,
                      icon: Icons.description,
                    ),
                    // Eligibility
                    RichTextBlock(
                      title: 'Eligibility Criteria',
                      body: content?.eligibility ?? _defaultEligibility,
                      icon: Icons.checklist,
                      iconColor: Colors.green,
                    ),
                    // Selection Process
                    RichTextBulletList(
                      title: 'Selection Process',
                      items: const [
                        'Preliminary Examination',
                        'Main Examination',
                        'Interview/Personality Test',
                        'Document Verification',
                        'Final Selection',
                      ],
                      icon: Icons.format_list_numbered,
                      iconColor: Colors.indigo,
                      showDivider: false,
                    ),
                    const SizedBox(height: 20),
                    // How to Apply Card
                    Card(
                      elevation: 0,
                      color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.how_to_reg, color: colorScheme.primary),
                                const SizedBox(width: 8),
                                Text(
                                  'How to Apply',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '1. Visit the official website\n'
                              '2. Register with valid email and phone\n'
                              '3. Fill the application form carefully\n'
                              '4. Upload required documents\n'
                              '5. Pay the application fee\n'
                              '6. Submit and download acknowledgment',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    height: 1.6,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Disclaimer
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 20,
                            color: colorScheme.error,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Please verify all details from the official notification before applying.',
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // Bottom action bar
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _toggleSave,
                  icon: Icon(_isSaved ? Icons.bookmark : Icons.bookmark_add_outlined),
                  label: Text(_isSaved ? 'Saved' : 'Save Job'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: _applyNow,
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Apply Now'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  void _toggleSave() {
    setState(() {
      _isSaved = !_isSaved;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isSaved ? 'Job saved' : 'Job removed from saved'),
        duration: const Duration(seconds: 1),
      ),
    );
    // TODO: Persist saved state to backend/local storage
  }

  void _applyNow() {
    final url = widget.item.jobContent?.applyUrl ?? 'https://upsc.gov.in';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening job application: $url'),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
        ),
      ),
    );
    // TODO: Integrate with url_launcher to open the actual URL
    // await launchUrl(Uri.parse(url));
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  static const String _defaultEligibility = '''
Age Limit: 21-32 years (relaxation as per rules)
Educational Qualification: Graduate from recognized university
Nationality: Indian Citizen
Physical Standards: As per post requirements
Medical Standards: Must be physically and mentally fit''';
}
