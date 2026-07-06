import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eduverse/profile/services/performance_dashboard_service.dart'; // For Period enum
import '../services/student_performance_service.dart';
import '../models/test_series_models.dart';

class StudentPerformanceTab extends StatefulWidget {
  final String userId;
  final List<String> purchasedTestSeriesIds;
  final List<AdminTestSeries> allTestSeries;

  const StudentPerformanceTab({
    super.key,
    required this.userId,
    required this.purchasedTestSeriesIds,
    required this.allTestSeries,
  });

  @override
  State<StudentPerformanceTab> createState() => _StudentPerformanceTabState();
}

class _StudentPerformanceTabState extends State<StudentPerformanceTab> {
  final StudentPerformanceService _performanceService = StudentPerformanceService();

  Period _activePeriod = Period.thisWeek;
  DateTimeRange? _customDateRange;
  String _selectedSubject = 'All Subjects';

  bool _isLoading = true;
  String? _errorMessage;
  StudentDashboardStats? _stats;
  List<String> _subjects = [];
  List<Map<String, dynamic>> _testAttempts = [];

  // Table pagination and sorting
  int _quizPage = 0;
  int _watchPage = 0;
  int _testPage = 0;
  final int _pageSize = 5;

  bool _sortQuizAscending = false;
  int _sortQuizColumnIndex = 3; // default date sorting

  bool _sortWatchAscending = false;
  int _sortWatchColumnIndex = 3; // default date sorting

  bool _sortTestAscending = false;
  int _sortTestColumnIndex = 4; // default date sorting
  Map<String, String> _testTitles = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      DateTime? start;
      DateTime? end;
      if (_activePeriod == Period.thisWeek && _customDateRange != null) {
        // Custom period mode
        start = _customDateRange!.start;
        end = _customDateRange!.end;
      }

      final stats = await _performanceService.getAggregatedStats(
        widget.userId,
        _activePeriod,
        customStart: start,
        customEnd: end,
      );

      final subjects = await _performanceService.getDistinctCategories(widget.userId);
      final testAttempts = await _performanceService.getTestAttempts(widget.userId);

      final Map<String, String> fetchedTitles = {};
      final List<Future<void>> fetchFutures = [];
      final Set<String> processedIds = {};

      for (final attempt in testAttempts) {
        final attemptId = attempt['id'] as String? ?? '';
        if (attemptId.isEmpty || processedIds.contains(attemptId)) continue;
        processedIds.add(attemptId);

        final parts = attemptId.split('_');
        if (parts.length >= 2) {
          final testSeriesId = parts[0];
          final testId = parts.sublist(1).join('_');

          fetchFutures.add(
            FirebaseFirestore.instance
                .collection('test_series')
                .doc(testSeriesId)
                .collection('tests')
                .doc(testId)
                .get()
                .then((doc) {
              if (doc.exists) {
                final data = doc.data();
                if (data != null && data['title'] != null) {
                  final title = data['title'] as String;
                  if (title.isNotEmpty) {
                    fetchedTitles[attemptId] = title;
                  }
                }
              }
            }).catchError((e) {
              debugPrint('Error fetching test title for $attemptId: $e');
            }),
          );
        }
      }

      await Future.wait(fetchFutures);

      if (mounted) {
        setState(() {
          _stats = stats;
          _subjects = subjects;
          _testAttempts = testAttempts;
          _testTitles = fetchedTitles;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load performance metrics: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _onPeriodChanged(Period period) {
    setState(() {
      _activePeriod = period;
      _customDateRange = null;
      _quizPage = 0;
      _watchPage = 0;
      _testPage = 0;
    });
    _loadData();
  }

  Future<void> _selectCustomDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: _customDateRange ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 7)),
            end: DateTime.now(),
          ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _activePeriod = Period.thisWeek; // reuse thisWeek as custom trigger when customDateRange is non-null
        _customDateRange = picked;
        _quizPage = 0;
        _watchPage = 0;
      });
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return _buildDashboardContent();
  }

  Widget _buildDashboardContent() {
    final stats = _stats!;

    // Filter quiz attempts and watch sessions by subject
    final filteredAttempts = stats.rawQuizAttempts.where((attempt) {
      if (_selectedSubject == 'All Subjects') return true;
      return attempt['categoryLabel'] == _selectedSubject;
    }).toList();

    final filteredSessions = stats.rawWatchSessions.where((session) {
      if (_selectedSubject == 'All Subjects') return true;
      return session['subjectName'] == _selectedSubject;
    }).toList();

    // Line Chart Spots
    // Sort chronologically first
    final sortedAttemptsForChart = [...filteredAttempts]..sort((a, b) {
        final ta = a['timestamp'] as Timestamp?;
        final tb = b['timestamp'] as Timestamp?;
        if (ta == null || tb == null) return 0;
        return ta.compareTo(tb);
      });

    final sortedSessionsForChart = [...filteredSessions]..sort((a, b) {
        final ta = a['timestamp'] as Timestamp?;
        final tb = b['timestamp'] as Timestamp?;
        if (ta == null || tb == null) return 0;
        return ta.compareTo(tb);
      });

    final List<FlSpot> scoreSpots = [];
    for (int i = 0; i < sortedAttemptsForChart.length; i++) {
      final pct = sortedAttemptsForChart[i]['percentage'] ?? 0.0;
      scoreSpots.add(FlSpot(i.toDouble(), (pct as num).toDouble()));
    }

    final List<FlSpot> studySpots = [];
    for (int i = 0; i < sortedSessionsForChart.length; i++) {
      final mins = sortedSessionsForChart[i]['watchedMinutes'] ?? 0.0;
      studySpots.add(FlSpot(i.toDouble(), (mins as num).toDouble()));
    }

    final hasChartData = scoreSpots.isNotEmpty || studySpots.isNotEmpty;

    // Test Series progress computation
    int totalTestSeriesTests = 0;
    for (final tsId in widget.purchasedTestSeriesIds) {
      final ts = widget.allTestSeries.cast<AdminTestSeries?>().firstWhere(
            (t) => t!.id == tsId,
            orElse: () => null,
          );
      if (ts != null) {
        totalTestSeriesTests += ts.totalTests;
      }
    }

    int completedTestSeriesTests = 0;
    for (final attempt in _testAttempts) {
      final attemptId = attempt['id'] as String;
      // check if this attempt matches any purchased test series ID
      final belongsToEnrolled = widget.purchasedTestSeriesIds.any((tsId) => attemptId.startsWith(tsId));
      if (belongsToEnrolled) {
        completedTestSeriesTests++;
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Filters Section
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 16,
                    runSpacing: 12,
                    children: [
                      // Time Chips
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ChoiceChip(
                            label: const Text('Week'),
                            selected: _activePeriod == Period.thisWeek && _customDateRange == null,
                            onSelected: (_) => _onPeriodChanged(Period.thisWeek),
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('Month'),
                            selected: _activePeriod == Period.thisMonth,
                            onSelected: (_) => _onPeriodChanged(Period.thisMonth),
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('Year'),
                            selected: _activePeriod == Period.thisYear,
                            onSelected: (_) => _onPeriodChanged(Period.thisYear),
                          ),
                          const SizedBox(width: 8),
                          ActionChip(
                            avatar: const Icon(Icons.date_range, size: 16),
                            label: Text(_customDateRange != null
                                ? '${DateFormat('MM/dd').format(_customDateRange!.start)} - ${DateFormat('MM/dd').format(_customDateRange!.end)}'
                                : 'Custom'),
                            backgroundColor: _customDateRange != null ? Colors.blue.shade50 : null,
                            side: _customDateRange != null ? BorderSide(color: Colors.blue.shade300) : null,
                            onPressed: _selectCustomDateRange,
                          ),
                        ],
                      ),
                      // Category Filter
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.filter_list, size: 18, color: Colors.grey),
                          const SizedBox(width: 8),
                          const Text('Subject: ', style: TextStyle(fontWeight: FontWeight.w500)),
                          const SizedBox(width: 8),
                          DropdownButton<String>(
                            value: _selectedSubject,
                            underline: const SizedBox(),
                            items: [
                              const DropdownMenuItem(value: 'All Subjects', child: Text('All Subjects')),
                              ..._subjects.toSet().map((sub) => DropdownMenuItem(value: sub, child: Text(sub))),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedSubject = val;
                                  _quizPage = 0;
                                  _watchPage = 0;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Stat Cards
              isWide
                  ? Row(
                      children: [
                        Expanded(child: _buildStatCard('Overall Score', '${stats.overallScore.toStringAsFixed(1)}%', stats.scoreImprovementFormatted, stats.scoreImprovementPercentage >= 0, Colors.blue)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildStatCard('Quizzes Taken', '${stats.quizzesTaken}', stats.quizzesImprovementFormatted, stats.quizzesImprovementCount >= 0, Colors.purple)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildStatCard('Watch Duration', stats.formattedStudyTime, 'Video Sessions', true, Colors.green)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildStatCard('Test Series Progress', '$completedTestSeriesTests / $totalTestSeriesTests', 'Tests Completed', true, Colors.teal)),
                      ],
                    )
                  : Column(
                      children: [
                        _buildStatCard('Overall Score', '${stats.overallScore.toStringAsFixed(1)}%', stats.scoreImprovementFormatted, stats.scoreImprovementPercentage >= 0, Colors.blue),
                        const SizedBox(height: 8),
                        _buildStatCard('Quizzes Taken', '${stats.quizzesTaken}', stats.quizzesImprovementFormatted, stats.quizzesImprovementCount >= 0, Colors.purple),
                        const SizedBox(height: 8),
                        _buildStatCard('Watch Duration', stats.formattedStudyTime, 'Video Sessions', true, Colors.green),
                        const SizedBox(height: 8),
                        _buildStatCard('Test Series Progress', '$completedTestSeriesTests / $totalTestSeriesTests', 'Tests Completed', true, Colors.teal),
                      ],
                    ),
              const SizedBox(height: 20),

              // Visual Charts
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _buildTrendChartCard(scoreSpots, studySpots, hasChartData)),
                    const SizedBox(width: 16),
                    Expanded(flex: 2, child: _buildPieChartCard(stats.accuracyData)),
                  ],
                )
              else ...[
                _buildTrendChartCard(scoreSpots, studySpots, hasChartData),
                const SizedBox(height: 16),
                _buildPieChartCard(stats.accuracyData),
              ],
              const SizedBox(height: 20),

              // Subject-wise performance table
              _buildSubjectBreakdownCard(filteredAttempts),
              const SizedBox(height: 20),

              // Detailed tables
              _buildQuizAttemptsTable(filteredAttempts),
              const SizedBox(height: 20),

              _buildWatchSessionsTable(filteredSessions),
              const SizedBox(height: 20),

              _buildTestAttemptsTable(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, String subtext, bool isPositive, Color accentColor) {
    final theme = Theme.of(context);
    IconData trendIcon = isPositive ? Icons.trending_up : Icons.trending_down;
    Color trendColor = isPositive ? Colors.green.shade600 : Colors.red.shade600;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: accentColor.withValues(alpha: 0.1), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
            const SizedBox(height: 6),
            Row(
              children: [
                if (subtext != 'N/A' && subtext != 'Video Sessions' && subtext != 'Tests Completed') ...[
                  Icon(trendIcon, size: 16, color: trendColor),
                  const SizedBox(width: 4),
                ],
                Text(
                  subtext,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: (subtext == 'Video Sessions' || subtext == 'Tests Completed' || subtext == 'N/A')
                        ? Colors.grey.shade500
                        : trendColor,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTrendChartCard(List<FlSpot> scoreSpots, List<FlSpot> studySpots, bool hasData) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Activity & Performance Trends', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    _buildIndicatorLegend('Quiz score %', Colors.blue),
                    const SizedBox(width: 12),
                    _buildIndicatorLegend('Study min', Colors.green),
                  ],
                )
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 220,
              child: hasData
                  ? LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: true, drawVerticalLine: false),
                        titlesData: const FlTitlesData(
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 32,
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 22,
                            ),
                          ),
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border(
                            bottom: BorderSide(color: Colors.grey.shade300, width: 1.5),
                            left: BorderSide(color: Colors.grey.shade300, width: 1.5),
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: scoreSpots.isNotEmpty ? scoreSpots : [const FlSpot(0, 0)],
                            isCurved: true,
                            color: Colors.blue,
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: true),
                          ),
                          LineChartBarData(
                            spots: studySpots.isNotEmpty ? studySpots : [const FlSpot(0, 0)],
                            isCurved: true,
                            color: Colors.green,
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: true),
                          ),
                        ],
                      ),
                    )
                  : const Center(
                      child: Text(
                        'No trend data available for this range',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChartCard(StudentAccuracyData accuracy) {
    final total = accuracy.total;
    final hasData = total > 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Quiz Accuracy Distribution', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            SizedBox(
              height: 160,
              child: hasData
                  ? PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: [
                          PieChartSectionData(
                            value: accuracy.correct.toDouble(),
                            title: 'Correct\n${accuracy.correct}',
                            color: Colors.green.shade500,
                            radius: 50,
                            titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          PieChartSectionData(
                            value: accuracy.wrong.toDouble(),
                            title: 'Wrong\n${accuracy.wrong}',
                            color: Colors.red.shade500,
                            radius: 50,
                            titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          PieChartSectionData(
                            value: accuracy.unattempted.toDouble(),
                            title: 'Skipped\n${accuracy.unattempted}',
                            color: Colors.orange.shade500,
                            radius: 50,
                            titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                    )
                  : const Center(
                      child: Text('No question-level stats', style: TextStyle(color: Colors.grey)),
                    ),
            ),
            const SizedBox(height: 12),
            if (hasData)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildPieLegend('Correct', Colors.green),
                  _buildPieLegend('Wrong', Colors.red),
                  _buildPieLegend('Skipped', Colors.orange),
                ],
              )
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectBreakdownCard(List<Map<String, dynamic>> quizAttempts) {
    // Group quiz results by subject (categoryLabel)
    final Map<String, List<double>> subjectScores = {};
    for (final attempt in quizAttempts) {
      final subject = attempt['categoryLabel'] as String? ?? 'General';
      final pct = (attempt['percentage'] ?? 0.0) as num;
      subjectScores.putIfAbsent(subject, () => []).add(pct.toDouble());
    }

    final List<MapEntry<String, double>> subjectAverages = subjectScores.entries.map((entry) {
      final average = entry.value.reduce((a, b) => a + b) / entry.value.length;
      return MapEntry(entry.key, average);
    }).toList();

    // Sort by average descending
    subjectAverages.sort((a, b) => b.value.compareTo(a.value));

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Subject-wise Performance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (subjectAverages.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24.0),
                child: Center(child: Text('No subject-wise records available', style: TextStyle(color: Colors.grey))),
              )
            else
              Table(
                columnWidths: const {
                  0: FlexColumnWidth(3),
                  1: FlexColumnWidth(4),
                  2: FlexColumnWidth(2),
                },
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: [
                  TableRow(
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1.5)),
                    ),
                    children: const [
                      Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Subject/Topic', style: TextStyle(fontWeight: FontWeight.bold))),
                      Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Performance Score', style: TextStyle(fontWeight: FontWeight.bold))),
                      Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Average %', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                    ],
                  ),
                  ...subjectAverages.map((entry) {
                    final progressVal = entry.value / 100.0;
                    Color barColor = Colors.red;
                    if (entry.value >= 75) {
                      barColor = Colors.green;
                    } else if (entry.value >= 50) {
                      barColor = Colors.orange;
                    }

                    return TableRow(
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                      ),
                      children: [
                        Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w500))),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: progressVal,
                              backgroundColor: Colors.grey.shade100,
                              color: barColor,
                              minHeight: 8,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            '${entry.value.toStringAsFixed(1)}%',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizAttemptsTable(List<Map<String, dynamic>> quizAttempts) {
    // Sort attempts based on state
    final sortedAttempts = [...quizAttempts];
    sortedAttempts.sort((a, b) {
      int compareResult = 0;
      switch (_sortQuizColumnIndex) {
        case 0:
          final titleA = a['quizTitle'] as String? ?? '';
          final titleB = b['quizTitle'] as String? ?? '';
          compareResult = titleA.compareTo(titleB);
          break;
        case 1:
          final subjectA = a['categoryLabel'] as String? ?? '';
          final subjectB = b['categoryLabel'] as String? ?? '';
          compareResult = subjectA.compareTo(subjectB);
          break;
        case 2:
          final pctA = (a['percentage'] ?? 0.0) as num;
          final pctB = (b['percentage'] ?? 0.0) as num;
          compareResult = pctA.compareTo(pctB);
          break;
        case 3:
        default:
          final tA = a['timestamp'] as Timestamp?;
          final tB = b['timestamp'] as Timestamp?;
          if (tA == null && tB == null) compareResult = 0;
          else if (tA == null) compareResult = -1;
          else if (tB == null) compareResult = 1;
          else compareResult = tA.compareTo(tB);
          break;
      }
      return _sortQuizAscending ? compareResult : -compareResult;
    });

    final totalPages = (sortedAttempts.length / _pageSize).ceil();
    final startIndex = _quizPage * _pageSize;
    final endIndex = (startIndex + _pageSize).clamp(0, sortedAttempts.length);
    final pageAttempts = sortedAttempts.isEmpty ? <Map<String, dynamic>>[] : sortedAttempts.sublist(startIndex, endIndex);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Detailed Quiz Attempts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Chip(label: Text('${sortedAttempts.length} attempts'), backgroundColor: Colors.blue.shade50),
              ],
            ),
            const SizedBox(height: 12),
            if (sortedAttempts.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Center(child: Text('No quiz records for this range', style: TextStyle(color: Colors.grey))),
              )
            else ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  sortColumnIndex: _sortQuizColumnIndex,
                  sortAscending: _sortQuizAscending,
                  columns: [
                    DataColumn(
                      label: const Text('Quiz Name'),
                      onSort: (index, ascending) {
                        setState(() {
                          _sortQuizColumnIndex = index;
                          _sortQuizAscending = ascending;
                        });
                      },
                    ),
                    DataColumn(
                      label: const Text('Subject'),
                      onSort: (index, ascending) {
                        setState(() {
                          _sortQuizColumnIndex = index;
                          _sortQuizAscending = ascending;
                        });
                      },
                    ),
                    DataColumn(
                      label: const Text('Score'),
                      onSort: (index, ascending) {
                        setState(() {
                          _sortQuizColumnIndex = index;
                          _sortQuizAscending = ascending;
                        });
                      },
                    ),
                    DataColumn(
                      label: const Text('Date'),
                      onSort: (index, ascending) {
                        setState(() {
                          _sortQuizColumnIndex = index;
                          _sortQuizAscending = ascending;
                        });
                      },
                    ),
                  ],
                  rows: pageAttempts.map((attempt) {
                    final title = attempt['quizTitle'] ?? 'Quiz';
                    final subject = attempt['categoryLabel'] ?? 'General';
                    final pct = (attempt['percentage'] ?? 0.0) as num;
                    final correct = attempt['correctAnswers'] ?? 0;
                    final total = attempt['questionsAttempted'] ?? 0;
                    final t = attempt['timestamp'] as Timestamp?;
                    final dateStr = t != null ? DateFormat('MMM dd, yyyy').format(t.toDate()) : 'N/A';

                    return DataRow(
                      cells: [
                        DataCell(Text(title, style: const TextStyle(fontWeight: FontWeight.w500))),
                        DataCell(Text(subject)),
                        DataCell(
                          Row(
                            children: [
                              Text('${pct.toStringAsFixed(0)}%'),
                              const SizedBox(width: 8),
                              Text('($correct/$total)', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                            ],
                          ),
                        ),
                        DataCell(Text(dateStr)),
                      ],
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
              _buildPaginationControls(_quizPage, totalPages, (page) {
                setState(() => _quizPage = page);
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWatchSessionsTable(List<Map<String, dynamic>> watchSessions) {
    final sortedSessions = [...watchSessions];
    sortedSessions.sort((a, b) {
      int compareResult = 0;
      switch (_sortWatchColumnIndex) {
        case 0:
          final titleA = a['lectureTitle'] as String? ?? '';
          final titleB = b['lectureTitle'] as String? ?? '';
          compareResult = titleA.compareTo(titleB);
          break;
        case 1:
          final subA = a['subjectName'] as String? ?? '';
          final subB = b['subjectName'] as String? ?? '';
          compareResult = subA.compareTo(subB);
          break;
        case 2:
          final durA = (a['watchedMinutes'] ?? 0.0) as num;
          final durB = (b['watchedMinutes'] ?? 0.0) as num;
          compareResult = durA.compareTo(durB);
          break;
        case 3:
        default:
          final tA = a['timestamp'] as Timestamp?;
          final tB = b['timestamp'] as Timestamp?;
          if (tA == null && tB == null) compareResult = 0;
          else if (tA == null) compareResult = -1;
          else if (tB == null) compareResult = 1;
          else compareResult = tA.compareTo(tB);
          break;
      }
      return _sortWatchAscending ? compareResult : -compareResult;
    });

    final totalPages = (sortedSessions.length / _pageSize).ceil();
    final startIndex = _watchPage * _pageSize;
    final endIndex = (startIndex + _pageSize).clamp(0, sortedSessions.length);
    final pageSessions = sortedSessions.isEmpty ? <Map<String, dynamic>>[] : sortedSessions.sublist(startIndex, endIndex);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Detailed Watch Sessions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Chip(label: Text('${sortedSessions.length} sessions'), backgroundColor: Colors.green.shade50),
              ],
            ),
            const SizedBox(height: 12),
            if (sortedSessions.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Center(child: Text('No watch sessions for this range', style: TextStyle(color: Colors.grey))),
              )
            else ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  sortColumnIndex: _sortWatchColumnIndex,
                  sortAscending: _sortWatchAscending,
                  columns: [
                    DataColumn(
                      label: const Text('Lecture Title'),
                      onSort: (index, ascending) {
                        setState(() {
                          _sortWatchColumnIndex = index;
                          _sortWatchAscending = ascending;
                        });
                      },
                    ),
                    DataColumn(
                      label: const Text('Subject'),
                      onSort: (index, ascending) {
                        setState(() {
                          _sortWatchColumnIndex = index;
                          _sortWatchAscending = ascending;
                        });
                      },
                    ),
                    DataColumn(
                      label: const Text('Duration'),
                      onSort: (index, ascending) {
                        setState(() {
                          _sortWatchColumnIndex = index;
                          _sortWatchAscending = ascending;
                        });
                      },
                    ),
                    DataColumn(
                      label: const Text('Date'),
                      onSort: (index, ascending) {
                        setState(() {
                          _sortWatchColumnIndex = index;
                          _sortWatchAscending = ascending;
                        });
                      },
                    ),
                  ],
                  rows: pageSessions.map((session) {
                    final title = session['lectureTitle'] ?? 'Lecture';
                    final subject = session['subjectName'] ?? 'General';
                    final mins = (session['watchedMinutes'] ?? 0.0) as num;
                    final t = session['timestamp'] as Timestamp?;
                    final dateStr = t != null ? DateFormat('MMM dd, yyyy').format(t.toDate()) : 'N/A';

                    return DataRow(
                      cells: [
                        DataCell(Text(title, style: const TextStyle(fontWeight: FontWeight.w500))),
                        DataCell(Text(subject)),
                        DataCell(Text('${mins.toStringAsFixed(1)} min')),
                        DataCell(Text(dateStr)),
                      ],
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
              _buildPaginationControls(_watchPage, totalPages, (page) {
                setState(() => _watchPage = page);
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTestAttemptsTable() {
    // Filter attempts to enrolled test series only
    final filteredTestAttempts = _testAttempts.where((attempt) {
      final attemptId = attempt['id'] as String;
      return widget.purchasedTestSeriesIds.any((tsId) => attemptId.startsWith(tsId));
    }).toList();

    final sortedTests = [...filteredTestAttempts];
    sortedTests.sort((a, b) {
      int compareResult = 0;
      switch (_sortTestColumnIndex) {
        case 0:
          final idA = a['id'] as String? ?? '';
          final idB = b['id'] as String? ?? '';
          final titleA = _testTitles[idA] ?? idA;
          final titleB = _testTitles[idB] ?? idB;
          compareResult = titleA.compareTo(titleB);
          break;
        case 1:
          final scoreA = (a['score'] ?? 0.0) as num;
          final scoreB = (b['score'] ?? 0.0) as num;
          compareResult = scoreA.compareTo(scoreB);
          break;
        case 2:
          final maxA = (a['totalMarks'] ?? 0.0) as num;
          final maxB = (b['totalMarks'] ?? 0.0) as num;
          compareResult = maxA.compareTo(maxB);
          break;
        case 3:
          final pctA = (a['percentage'] ?? 0.0) as num;
          final pctB = (b['percentage'] ?? 0.0) as num;
          compareResult = pctA.compareTo(pctB);
          break;
        case 4:
        default:
          final tA = a['completedAt'] as Timestamp?;
          final tB = b['completedAt'] as Timestamp?;
          if (tA == null && tB == null) compareResult = 0;
          else if (tA == null) compareResult = -1;
          else if (tB == null) compareResult = 1;
          else compareResult = tA.compareTo(tB);
          break;
      }
      return _sortTestAscending ? compareResult : -compareResult;
    });

    final totalPages = (sortedTests.length / _pageSize).ceil();
    final startIndex = _testPage * _pageSize;
    final endIndex = (startIndex + _pageSize).clamp(0, sortedTests.length);
    final pageTests = sortedTests.isEmpty ? <Map<String, dynamic>>[] : sortedTests.sublist(startIndex, endIndex);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Test Series Results', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Chip(label: Text('${sortedTests.length} tests taken'), backgroundColor: Colors.teal.shade50),
              ],
            ),
            const SizedBox(height: 12),
            if (sortedTests.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Center(child: Text('No test series attempts yet', style: TextStyle(color: Colors.grey))),
              )
            else ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  sortColumnIndex: _sortTestColumnIndex,
                  sortAscending: _sortTestAscending,
                  columns: [
                    DataColumn(
                      label: const Text('Test ID / Title'),
                      onSort: (index, ascending) {
                        setState(() {
                          _sortTestColumnIndex = index;
                          _sortTestAscending = ascending;
                        });
                      },
                    ),
                    DataColumn(
                      label: const Text('Obtained'),
                      onSort: (index, ascending) {
                        setState(() {
                          _sortTestColumnIndex = index;
                          _sortTestAscending = ascending;
                        });
                      },
                    ),
                    DataColumn(
                      label: const Text('Max Marks'),
                      onSort: (index, ascending) {
                        setState(() {
                          _sortTestColumnIndex = index;
                          _sortTestAscending = ascending;
                        });
                      },
                    ),
                    DataColumn(
                      label: const Text('Percentage'),
                      onSort: (index, ascending) {
                        setState(() {
                          _sortTestColumnIndex = index;
                          _sortTestAscending = ascending;
                        });
                      },
                    ),
                    DataColumn(
                      label: const Text('Completed At'),
                      onSort: (index, ascending) {
                        setState(() {
                          _sortTestColumnIndex = index;
                          _sortTestAscending = ascending;
                        });
                      },
                    ),
                  ],
                  rows: pageTests.map((test) {
                    final attemptId = test['id'] as String;
                    final displayTitle = _testTitles[attemptId] ?? attemptId;
                    final score = (test['score'] ?? 0.0) as num;
                    final total = (test['totalMarks'] ?? 0.0) as num;
                    final pct = (test['percentage'] ?? 0.0) as num;
                    final t = test['completedAt'] as Timestamp?;
                    final dateStr = t != null ? DateFormat('MMM dd, yyyy hh:mm a').format(t.toDate()) : 'N/A';

                    return DataRow(
                      cells: [
                        DataCell(Text(displayTitle, style: const TextStyle(fontWeight: FontWeight.w500))),
                        DataCell(Text(score.toStringAsFixed(1))),
                        DataCell(Text(total.toStringAsFixed(1))),
                        DataCell(Text('${pct.toStringAsFixed(1)}%')),
                        DataCell(Text(dateStr)),
                      ],
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
              _buildPaginationControls(_testPage, totalPages, (page) {
                setState(() => _testPage = page);
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaginationControls(int currentPage, int totalPages, Function(int) onPageChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: currentPage > 0 ? () => onPageChanged(currentPage - 1) : null,
        ),
        Text('Page ${currentPage + 1} of ${totalPages == 0 ? 1 : totalPages}'),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: currentPage < totalPages - 1 ? () => onPageChanged(currentPage + 1) : null,
        ),
      ],
    );
  }

  Widget _buildIndicatorLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildPieLegend(String label, Color color) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
