import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../widgets/admin_scaffold.dart';
import '../services/firebase_admin_service.dart';
import '../models/admin_models.dart';
import 'user_detail_screen.dart';

class PurchasesScreen extends StatefulWidget {
  const PurchasesScreen({super.key});

  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _searchQuery = '';
  String _statusFilter = 'all'; // all, success, refunded, manual_enrollment, failed
  String _itemTypeFilter = 'all'; // all, courses, test_series
  String _dateFilterPreset = 'All'; // All, Today, Last 7 Days, Last 30 Days, Custom
  DateTime? _startDate;
  DateTime? _endDate;

  List<AdminPurchase> _purchases = [];
  DocumentSnapshot? _lastDocument;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;
  Timer? _debounceTimer;

  final Map<String, AdminUser> _userCache = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialPurchases();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore &&
        !_isLoading) {
      _loadMorePurchases();
    }
  }

  Future<void> _loadInitialPurchases() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _lastDocument = null;
    });

    try {
      final adminService = context.read<FirebaseAdminService>();
      final result = await adminService.getPurchasesPaginated(
        limit: 20,
        statusFilter: _statusFilter,
        startDate: _startDate,
        endDate: _endDate,
      );
      if (!mounted) return;
      setState(() {
        _purchases = result.items;
        _lastDocument = result.lastDocument;
        _hasMore = result.hasMore;
        _isLoading = false;
      });
      _resolveUsersForPurchases(result.items);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMorePurchases() async {
    if (_isLoadingMore || !_hasMore || _isLoading || !mounted) return;
    setState(() {
      _isLoadingMore = true;
    });

    try {
      final adminService = context.read<FirebaseAdminService>();
      final result = await adminService.getPurchasesPaginated(
        limit: 20,
        startAfter: _lastDocument,
        statusFilter: _statusFilter,
        startDate: _startDate,
        endDate: _endDate,
      );
      if (!mounted) return;
      setState(() {
        _purchases.addAll(result.items);
        _lastDocument = result.lastDocument;
        _hasMore = result.hasMore;
        _isLoadingMore = false;
      });
      _resolveUsersForPurchases(result.items);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingMore = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load more transactions: $e')),
      );
    }
  }

  void _resetAndReload() {
    _lastDocument = null;
    _hasMore = true;
    _loadInitialPurchases();
  }

  Future<void> _resolveUsersForPurchases(List<AdminPurchase> purchases) async {
    final adminService = context.read<FirebaseAdminService>();
    final missingUids = purchases
        .map((p) => p.userId)
        .where((uid) => uid.isNotEmpty && !_userCache.containsKey(uid))
        .toSet();

    if (missingUids.isEmpty) return;

    final results = await Future.wait(
      missingUids.map((uid) => adminService.getUserById(uid)),
    );

    for (final user in results) {
      if (user != null) {
        _userCache[user.uid] = user;
      }
    }
    if (mounted) {
      setState(() {});
    }
  }

  void _onSearchChanged(String val) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _searchQuery = val;
      });
    });
  }

  void _setDatePreset(String preset) {
    final now = DateTime.now();
    setState(() {
      _dateFilterPreset = preset;
      switch (preset) {
        case 'Today':
          _startDate = DateTime(now.year, now.month, now.day);
          _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
          break;
        case 'Last 7 Days':
          _startDate = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 7));
          _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
          break;
        case 'Last 30 Days':
          _startDate = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 30));
          _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
          break;
        case 'All':
        default:
          _startDate = null;
          _endDate = null;
          _dateFilterPreset = 'All';
          break;
      }
    });
    _resetAndReload();
  }

  Future<void> _selectCustomDateRange() async {
    final now = DateTime.now();
    final initialRange = DateTimeRange(
      start: _startDate ?? now.subtract(const Duration(days: 7)),
      end: _endDate ?? now,
    );
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 5),
      initialDateRange: initialRange,
    );

    if (picked != null) {
      setState(() {
        _startDate = DateTime(picked.start.year, picked.start.month, picked.start.day);
        _endDate = DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59, 999);
        _dateFilterPreset = 'Custom';
      });
      _resetAndReload();
    }
  }

  List<AdminPurchase> get _filteredPurchases {
    return _purchases.where((purchase) {
      // 1. Search Query (Matches User Name, Email, or Purchase/Transaction ID)
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final user = _findUser(purchase.userId);
        final matchesUser = user != null &&
            (user.name.toLowerCase().contains(query) ||
                user.email.toLowerCase().contains(query));
        final matchesId = purchase.id.toLowerCase().contains(query);
        if (!matchesUser && !matchesId) return false;
      }

      // 2. Item Type Filter
      if (_itemTypeFilter != 'all') {
        final hasCourse = purchase.items.any((item) => item.testSeriesId == null);
        final hasTestSeries = purchase.items.any((item) => item.testSeriesId != null);
        if (_itemTypeFilter == 'courses' && !hasCourse) return false;
        if (_itemTypeFilter == 'test_series' && !hasTestSeries) return false;
      }

      return true;
    }).toList();
  }

  AdminUser? _findUser(String userId) {
    if (userId.isEmpty) return null;
    return _userCache[userId];
  }

  Future<void> _runMigration(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Migrate Legacy Transactions'),
        content: const Text(
          'This tool imports older student purchase records stored under users\' private subcollections into this global list.\n\n'
          'This will allow you to see and process refunds for older purchases directly from this panel.\n\n'
          'This process is safe and will automatically skip any duplicates that have already been migrated.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Start Migration'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 24),
              Expanded(
                child: Text('Migrating legacy transactions...\nPlease wait.'),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final message = await context.read<FirebaseAdminService>().migrateUserTransactionsToPurchases();
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green.shade800,
            duration: const Duration(seconds: 5),
          ),
        );
        _resetAndReload();
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Migration failed: $e'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Payments & Purchases',
      actions: [
        IconButton(
          icon: const Icon(Icons.sync_alt),
          tooltip: 'Migrate Legacy Transactions',
          onPressed: () => _runMigration(context),
        ),
      ],
      body: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_isLoading && _purchases.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _purchases.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text('Error loading purchases: $_errorMessage'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _resetAndReload,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final filteredPurchases = _filteredPurchases;

    // Aggregate Metrics from loaded purchases
    double totalRevenue = 0.0;
    int successCount = 0;
    int refundCount = 0;

    for (final p in _purchases) {
      if (p.status == 'success' || p.status == 'completed') {
        totalRevenue += p.amount;
        successCount++;
      } else if (p.status == 'refunded') {
        refundCount++;
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          controller: _scrollController,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Metrics Row
                _buildMetricsDashboard(
                  constraints,
                  totalRevenue: totalRevenue,
                  successCount: successCount,
                  refundCount: refundCount,
                  totalCount: _purchases.length,
                ),
                const SizedBox(height: 32),

                // Search and Filters Panel
                _buildSearchFiltersPanel(context),
                const SizedBox(height: 24),

                // Data Table Card
                _buildTransactionsCard(context, filteredPurchases),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- Metrics Dashboard Component ---
  Widget _buildMetricsDashboard(
    BoxConstraints constraints, {
    required double totalRevenue,
    required int successCount,
    required int refundCount,
    required int totalCount,
  }) {
    final double cardWidth = constraints.maxWidth > 1200
        ? (constraints.maxWidth - 48 - 72) / 4
        : constraints.maxWidth > 800
            ? (constraints.maxWidth - 24 - 48) / 2
            : constraints.maxWidth - 48;

    final metrics = [
      _MetricData(
        title: 'Total Revenue',
        value: '₹${NumberFormat('#,##,###.##').format(totalRevenue)}',
        icon: Icons.account_balance_wallet,
        colors: [Colors.teal.shade800, Colors.teal.shade400],
      ),
      _MetricData(
        title: 'Successful Payments',
        value: '$successCount',
        icon: Icons.check_circle_outline,
        colors: [Colors.green.shade800, Colors.green.shade400],
      ),
      _MetricData(
        title: 'Refunded Payments',
        value: '$refundCount',
        icon: Icons.replay_outlined,
        colors: [Colors.orange.shade800, Colors.orange.shade400],
      ),
      _MetricData(
        title: 'Total Transactions',
        value: '$totalCount',
        icon: Icons.receipt_long_outlined,
        colors: [Colors.blueGrey.shade800, Colors.blueGrey.shade400],
      ),
    ];

    return Wrap(
      spacing: 24,
      runSpacing: 24,
      children: metrics.map((m) {
        return SizedBox(
          width: cardWidth,
          child: _HoverMetricCard(metric: m),
        );
      }).toList(),
    );
  }

  // --- Search and Filters Panel ---
  Widget _buildSearchFiltersPanel(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filters & Search',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (_startDate != null ||
                    _endDate != null ||
                    _statusFilter != 'all' ||
                    _itemTypeFilter != 'all' ||
                    _searchQuery.isNotEmpty)
                  TextButton.icon(
                    icon: const Icon(Icons.clear_all, size: 18),
                    label: const Text('Reset All'),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                        _statusFilter = 'all';
                        _itemTypeFilter = 'all';
                        _dateFilterPreset = 'All';
                        _startDate = null;
                        _endDate = null;
                      });
                      _resetAndReload();
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                // Search Input
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by User Name, Email, or Transaction ID...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _debounceTimer?.cancel();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    onChanged: _onSearchChanged,
                  ),
                ),
                const SizedBox(width: 16),

                // Status Dropdown
                Expanded(
                  flex: 1,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _statusFilter,
                        isDense: true,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('All Statuses')),
                          DropdownMenuItem(value: 'success', child: Text('Success')),
                          DropdownMenuItem(value: 'refunded', child: Text('Refunded')),
                          DropdownMenuItem(value: 'manual_enrollment', child: Text('Manual')),
                          DropdownMenuItem(value: 'failed', child: Text('Failed')),
                        ],
                        onChanged: (val) {
                          if (val != null && val != _statusFilter) {
                            setState(() => _statusFilter = val);
                            _resetAndReload();
                          }
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Item Type Dropdown
                Expanded(
                  flex: 1,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Product Type',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _itemTypeFilter,
                        isDense: true,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('All Products')),
                          DropdownMenuItem(value: 'courses', child: Text('Courses / Batches')),
                          DropdownMenuItem(value: 'test_series', child: Text('Test Series')),
                        ],
                        onChanged: (val) {
                          if (val != null && val != _itemTypeFilter) {
                            setState(() => _itemTypeFilter = val);
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Date Range Presets Row
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('Date Range:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                ChoiceChip(
                  label: const Text('All Time'),
                  selected: _dateFilterPreset == 'All',
                  onSelected: (selected) {
                    if (selected) _setDatePreset('All');
                  },
                ),
                ChoiceChip(
                  label: const Text('Today'),
                  selected: _dateFilterPreset == 'Today',
                  onSelected: (selected) {
                    if (selected) _setDatePreset('Today');
                  },
                ),
                ChoiceChip(
                  label: const Text('Last 7 Days'),
                  selected: _dateFilterPreset == 'Last 7 Days',
                  onSelected: (selected) {
                    if (selected) _setDatePreset('Last 7 Days');
                  },
                ),
                ChoiceChip(
                  label: const Text('Last 30 Days'),
                  selected: _dateFilterPreset == 'Last 30 Days',
                  onSelected: (selected) {
                    if (selected) _setDatePreset('Last 30 Days');
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.date_range, size: 16),
                  label: Text(
                    _dateFilterPreset == 'Custom' && _startDate != null && _endDate != null
                        ? '${DateFormat('d MMM').format(_startDate!)} - ${DateFormat('d MMM yyyy').format(_endDate!)}'
                        : 'Custom Range',
                  ),
                  onPressed: _selectCustomDateRange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- Transactions DataTable Component ---
  Widget _buildTransactionsCard(
    BuildContext context,
    List<AdminPurchase> purchases,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Transaction History',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  'Showing ${purchases.length} transactions',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),
              ],
            ),
          ),
          if (purchases.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 64.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.payment_outlined, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      'No matching transactions found.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                showCheckboxColumn: false,
                headingRowColor: WidgetStateProperty.all(
                  Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.05),
                ),
                horizontalMargin: 24,
                columnSpacing: 32,
                columns: const [
                  DataColumn(
                    label: Text(
                      'Customer',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Date & Time',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Amount',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Product(s)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Payment Method',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Status',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Actions',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
                rows: purchases.map((purchase) {
                  final user = _findUser(purchase.userId);
                  final userDisplayName = user?.name ?? 'Unknown Customer';
                  final userEmail = user?.email ?? purchase.userId;

                  return DataRow(
                    onSelectChanged: (_) => _showPurchaseDetails(context, purchase, user),
                    cells: [
                      // Customer Cell
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.teal.shade100,
                              child: Text(
                                userDisplayName.isNotEmpty
                                    ? userDisplayName[0].toUpperCase()
                                    : 'U',
                                style: TextStyle(
                                  color: Colors.teal.shade800,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  userDisplayName,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  userEmail,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Date Cell
                      DataCell(
                        Text(
                          DateFormat('dd MMM yyyy, hh:mm a').format(purchase.createdAt),
                        ),
                      ),
                      // Amount Cell
                      DataCell(
                        Text(
                          '₹${purchase.amount.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      // Products Cell
                      DataCell(
                        SizedBox(
                          width: 220,
                          child: Text(
                            purchase.items.map((i) => i.title).join(', '),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                      // Method Cell
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Text(
                            purchase.paymentMethod.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                      ),
                      // Status Cell
                      DataCell(_buildStatusChip(purchase.status)),
                      // Actions Cell
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.receipt_long, size: 20),
                              tooltip: 'Receipt Details',
                              onPressed: () => _showPurchaseDetails(context, purchase, user),
                            ),
                            if (purchase.status == 'success' ||
                                purchase.status == 'completed' ||
                                purchase.status == 'manual_enrollment')
                              IconButton(
                                icon: const Icon(Icons.replay_circle_filled,
                                    size: 20, color: Colors.orange),
                                tooltip: 'Refund Payment',
                                onPressed: () => _confirmRefundDialog(context, purchase),
                              ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          if (_isLoadingMore)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_hasMore)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.arrow_downward),
                  label: const Text('Load More Transactions'),
                  onPressed: _loadMorePurchases,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- Status Chip Generator ---
  Widget _buildStatusChip(String status) {
    Color baseColor;
    String displayStatus = status.toUpperCase();

    switch (status) {
      case 'success':
      case 'completed':
        baseColor = Colors.green;
        displayStatus = 'SUCCESS';
        break;
      case 'refunded':
        baseColor = Colors.orange;
        displayStatus = 'REFUNDED';
        break;
      case 'manual_enrollment':
        baseColor = Colors.blue;
        displayStatus = 'MANUAL';
        break;
      case 'failed':
        baseColor = Colors.red;
        displayStatus = 'FAILED';
        break;
      default:
        baseColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: baseColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: baseColor.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: baseColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            displayStatus,
            style: TextStyle(
              color: baseColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // --- High Fidelity Details Popup Sheet ---
  void _showPurchaseDetails(
    BuildContext context,
    AdminPurchase purchase,
    AdminUser? user,
  ) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: EdgeInsets.zero,
          content: Container(
            width: 600,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Invoice Header Banner
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade900,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.receipt_long, color: Colors.white, size: 48),
                        const SizedBox(height: 12),
                        const Text(
                          'Transaction Details',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ID: ${purchase.id}',
                          style: TextStyle(
                            color: Colors.teal.shade200,
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section: Customer Profile
                        const Text(
                          'CUSTOMER INFORMATION',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: Colors.teal.shade50,
                            child: const Icon(Icons.person, color: Colors.teal),
                          ),
                          title: Text(
                            user?.name ?? 'Unknown Customer',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(user?.email ?? purchase.userId),
                          trailing: user != null
                              ? IconButton(
                                  icon: const Icon(Icons.open_in_new, size: 20),
                                  tooltip: 'Open User Profile',
                                  onPressed: () {
                                    Navigator.pop(dialogCtx);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => UserDetailScreen(userId: user.uid),
                                      ),
                                    );
                                  },
                                )
                              : null,
                        ),
                        const Divider(height: 32),

                        // Section: Transaction Details
                        const Text(
                          'PAYMENT METRICS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow('Date & Time',
                            DateFormat('dd MMM yyyy, hh:mm a').format(purchase.createdAt)),
                        _buildDetailRow('Payment Gateway', purchase.paymentMethod.toUpperCase()),
                        _buildDetailRow('Transaction ID', purchase.id),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Payment Status', style: TextStyle(color: Colors.grey)),
                            _buildStatusChip(purchase.status),
                          ],
                        ),
                        const Divider(height: 32),

                        // Section: Itemized Breakdowns
                        const Text(
                          'PURCHASED ITEMS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            children: purchase.items.map((item) {
                              return ListTile(
                                dense: true,
                                title: Text(
                                  item.title,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  item.testSeriesId != null
                                  ? 'Test Series ID: ${item.testSeriesId}'
                                  : 'Course ID: ${item.courseId}',
                                  style: const TextStyle(fontSize: 11),
                                ),
                                trailing: Text(
                                  '₹${item.price.toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Total Breakdown
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'TOTAL PAID',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              '₹${purchase.amount.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: Colors.teal.shade900,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Actions Footer Buttons
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    color: Colors.grey.shade50,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogCtx),
                          child: const Text('Close'),
                        ),
                        if (purchase.status == 'success' ||
                            purchase.status == 'completed' ||
                            purchase.status == 'manual_enrollment') ...[
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(dialogCtx);
                              _confirmRefundDialog(context, purchase);
                            },
                            icon: const Icon(Icons.replay),
                            label: const Text('Process Refund'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade800,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // --- Interactive Process Refund Confirmation Dialog ---
  void _confirmRefundDialog(BuildContext context, AdminPurchase purchase) {
    bool alsoUnenroll = true;
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (statefulCtx, setStateDialog) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                  SizedBox(width: 12),
                  Text('Confirm Process Refund'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Are you sure you want to refund this payment of ₹${purchase.amount.toStringAsFixed(2)}?',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'This action is irreversible. The payment status will be marked as REFUNDED in history, and audits will be logged.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person_remove_outlined, color: Colors.orange),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Auto-Unenroll Student',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                'Remove student from course batches or test series associated with this receipt.',
                                style: TextStyle(fontSize: 11, color: Colors.orange.shade900),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: alsoUnenroll,
                          activeThumbColor: Colors.orange.shade800,
                          onChanged: (val) {
                            setStateDialog(() => alsoUnenroll = val);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          setStateDialog(() => isSubmitting = true);
                          try {
                            final adminService = context.read<FirebaseAdminService>();
                            await adminService.triggerRefund(
                              purchase.id,
                              unenrollUser: alsoUnenroll,
                            );

                            if (context.mounted) {
                              Navigator.pop(dialogCtx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Refund processed successfully.${alsoUnenroll ? " Student has been unenrolled." : ""}',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              _resetAndReload();
                            }
                          } catch (e) {
                            setStateDialog(() => isSubmitting = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error processing refund: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade800,
                    foregroundColor: Colors.white,
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Confirm Refund'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// --- Supporting Metric Classes ---
class _MetricData {
  final String title;
  final String value;
  final IconData icon;
  final List<Color> colors;

  _MetricData({
    required this.title,
    required this.value,
    required this.icon,
    required this.colors,
  });
}

// --- Hover Lift Animation Card ---
class _HoverMetricCard extends StatefulWidget {
  final _MetricData metric;

  const _HoverMetricCard({required this.metric});

  @override
  State<_HoverMetricCard> createState() => _HoverMetricCardState();
}

class _HoverMetricCardState extends State<_HoverMetricCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: _isHovered
            ? Matrix4.translationValues(0.0, -6.0, 0.0)
            : Matrix4.identity(),
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.metric.colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: widget.metric.colors.first.withValues(alpha: _isHovered ? 0.4 : 0.2),
                blurRadius: _isHovered ? 16 : 8,
                offset: Offset(0, _isHovered ? 8 : 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                bottom: -20,
                child: Icon(
                  widget.metric.icon,
                  size: 100,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.metric.title,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            widget.metric.value,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            widget.metric.icon,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
