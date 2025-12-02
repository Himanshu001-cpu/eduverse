import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:eduverse/profile/profile_mock_data.dart';
import 'package:eduverse/common/widgets/empty_state.dart';
import 'package:eduverse/common/widgets/cards.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({Key? key}) : super(key: key);

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  String _filter = 'All'; // All, Success, Failed, Pending
  DateTimeRange? _dateRange;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  List<Transaction> get _filteredTransactions {
    List<Transaction> list = ProfileMockData.transactions;

    // Filter by status
    if (_filter != 'All') {
      list = list.where((t) => t.status.name.toLowerCase() == _filter.toLowerCase()).toList();
    }

    // Filter by date range
    if (_dateRange != null) {
      list = list.where((t) {
        return t.date.isAfter(_dateRange!.start.subtract(const Duration(days: 1))) &&
               t.date.isBefore(_dateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    // Filter by search (Order ID)
    if (_searchQuery.isNotEmpty) {
      list = list.where((t) => t.orderId.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    // Sort by date desc
    list.sort((a, b) => b.date.compareTo(a.date));

    return list;
  }

  double get _totalSpent {
    return _filteredTransactions
        .where((t) => t.status == TransactionStatus.success)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );
    if (picked != null) {
      setState(() {
        _dateRange = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactions = _filteredTransactions;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Transactions'),
      ),
      body: Column(
        children: [
          // Summary Card
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: AppCard(
              color: Theme.of(context).primaryColor.withOpacity(0.05),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Spent', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text(
                        '₹${_totalSpent.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Transactions', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text(
                        '${transactions.length}',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Search Order ID',
                          prefixIcon: Icon(Icons.search),
                          contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                        ),
                        onChanged: (val) => setState(() => _searchQuery = val),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.calendar_today, color: _dateRange != null ? Theme.of(context).primaryColor : Colors.grey),
                      onPressed: _pickDateRange,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['All', 'Success', 'Failed', 'Pending'].map((filter) {
                      final isSelected = _filter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(filter),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) setState(() => _filter = filter);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // List
          Expanded(
            child: transactions.isEmpty
                ? const EmptyState(title: 'No transactions found', icon: Icons.receipt_long)
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final item = transactions[index];
                      return _TransactionCard(item: item);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final Transaction item;

  const _TransactionCard({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    IconData statusIcon;

    switch (item.status) {
      case TransactionStatus.success:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case TransactionStatus.failed:
        statusColor = Colors.red;
        statusIcon = Icons.error;
        break;
      case TransactionStatus.pending:
        statusColor = Colors.orange;
        statusIcon = Icons.access_time_filled;
        break;
    }

    return AppCard(
      onTap: () {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Transaction Details'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow('Order ID', item.orderId),
                _detailRow('Date', DateFormat('MMM d, yyyy h:mm a').format(item.date)),
                _detailRow('Amount', '₹${item.amount}'),
                _detailRow('Status', item.status.name.toUpperCase()),
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                Text('Product: ${item.productTitle}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
            ],
          ),
        );
      },
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, color: statusColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productTitle,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                Text(
                  DateFormat('MMM d, yyyy').format(item.date),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${item.amount.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                item.status.name.toUpperCase(),
                style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
