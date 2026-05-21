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
  String _searchQuery = '';
  String _statusFilter = 'all'; // all, success, refunded, manual_enrollment, failed
  String _itemTypeFilter = 'all'; // all, courses, test_series

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AdminPurchase> _filterPurchases(List<AdminPurchase> purchases, List<AdminUser> users) {
    return purchases.where((purchase) {
      // 1. Search Query (Matches User Name, Email, or Purchase/Transaction ID)
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final user = _findUser(users, purchase.userId);
        final matchesUser = user != null &&
            (user.name.toLowerCase().contains(query) ||
                user.email.toLowerCase().contains(query));
        final matchesId = purchase.id.toLowerCase().contains(query);
        if (!matchesUser && !matchesId) return false;
      }

      // 2. Status Filter
      if (_statusFilter != 'all') {
        if (_statusFilter == 'success' &&
            purchase.status != 'success' &&
            purchase.status != 'completed') {
          return false;
        } else if (_statusFilter != 'success' && purchase.status != _statusFilter) {
          return false;
        }
      }

      // 3. Item Type Filter
      if (_itemTypeFilter != 'all') {
        final hasCourse = purchase.items.any((item) => item.testSeriesId == null);
        final hasTestSeries = purchase.items.any((item) => item.testSeriesId != null);
        if (_itemTypeFilter == 'courses' && !hasCourse) return false;
        if (_itemTypeFilter == 'test_series' && !hasTestSeries) return false;
      }

      return true;
    }).toList();
  }

  AdminUser? _findUser(List<AdminUser> users, String userId) {
    if (users.isEmpty || userId.isEmpty) return null;
    try {
      return users.firstWhere((u) => u.uid == userId);
    } catch (_) {
      return null;
    }
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

    // Show loading indicator dialog
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
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
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
    final adminService = context.read<FirebaseAdminService>();

    return AdminScaffold(
      title: 'Payments & Purchases',
      actions: [
        IconButton(
          icon: const Icon(Icons.sync_alt),
          tooltip: 'Migrate Legacy Transactions',
          onPressed: () => _runMigration(context),
        ),
      ],
      body: StreamBuilder<List<AdminUser>>(
        stream: adminService.getUsers(),
        builder: (context, usersSnapshot) {
          if (usersSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (usersSnapshot.hasError) {
            return Center(child: Text('Error loading users: ${usersSnapshot.error}'));
          }

          final users = usersSnapshot.data ?? [];

          return StreamBuilder<List<AdminPurchase>>(
            stream: adminService.getAllPurchases(),
            builder: (context, purchasesSnapshot) {
              if (purchasesSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (purchasesSnapshot.hasError) {
                return Center(
                  child: Text('Error loading purchases: ${purchasesSnapshot.error}'),
                );
              }

              final allPurchases = purchasesSnapshot.data ?? [];
              final filteredPurchases = _filterPurchases(allPurchases, users);

              // Aggregate Metrics
              double totalRevenue = 0.0;
              int successCount = 0;
              int refundCount = 0;

              for (final p in allPurchases) {
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
                            totalCount: allPurchases.length,
                          ),
                          const SizedBox(height: 32),

                          // Search and Filters Panel
                          _buildSearchFiltersPanel(context),
                          const SizedBox(height: 24),

                          // Data Table Card
                          _buildTransactionsCard(context, filteredPurchases, users),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
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
            Text(
              'Filters & Search',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
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
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),
                const SizedBox(width: 16),

                // Status Dropdown
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    // ignore: deprecated_member_use
                    value: _statusFilter,
                    decoration: InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All Statuses')),
                      DropdownMenuItem(value: 'success', child: Text('Success')),
                      DropdownMenuItem(value: 'refunded', child: Text('Refunded')),
                      DropdownMenuItem(value: 'manual_enrollment', child: Text('Manual')),
                      DropdownMenuItem(value: 'failed', child: Text('Failed')),
                    ],
                    onChanged: (val) => setState(() => _statusFilter = val!),
                  ),
                ),
                const SizedBox(width: 16),

                // Item Type Dropdown
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    // ignore: deprecated_member_use
                    value: _itemTypeFilter,
                    decoration: InputDecoration(
                      labelText: 'Product Type',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All Products')),
                      DropdownMenuItem(value: 'courses', child: Text('Courses / Batches')),
                      DropdownMenuItem(value: 'test_series', child: Text('Test Series')),
                    ],
                    onChanged: (val) => setState(() => _itemTypeFilter = val!),
                  ),
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
    List<AdminUser> users,
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
                  final user = _findUser(users, purchase.userId);
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
    bool alsoUnenroll = true; // Enabled by default as it is standard admin intent
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

                  // Interactive toggle for auto-unenrollment (as requested by User)
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
                          // ignore: deprecated_member_use
                          activeColor: Colors.orange.shade800,
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
              // Subtle background design
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
