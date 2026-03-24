import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../widgets/admin_scaffold.dart';
import 'package:eduverse/core/firebase/promo_code_service.dart';

class PromoCodesScreen extends StatefulWidget {
  const PromoCodesScreen({super.key});

  @override
  State<PromoCodesScreen> createState() => _PromoCodesScreenState();
}

class _PromoCodesScreenState extends State<PromoCodesScreen> {
  final PromoCodeService _promoService = PromoCodeService();

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Promo Codes',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPromoCodeDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Create Code'),
      ),
      body: StreamBuilder<List<PromoCode>>(
        stream: _promoService.getAllPromoCodes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final codes = snapshot.data ?? [];

          if (codes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.local_offer_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No promo codes yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the + button to create one',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: codes.length,
            itemBuilder: (context, index) {
              final code = codes[index];
              return _PromoCodeCard(
                promoCode: code,
                onEdit: () => _showPromoCodeDialog(existing: code),
                onDelete: () => _confirmDelete(code),
                onToggle: () => _toggleActive(code),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showPromoCodeDialog({PromoCode? existing}) async {
    final result = await showDialog<PromoCode>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _PromoCodeEditorDialog(existing: existing),
    );

    if (result != null) {
      try {
        if (existing != null) {
          await _promoService.updatePromoCode(result);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Promo code "${result.code}" updated')),
            );
          }
        } else {
          await _promoService.createPromoCode(result);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Promo code "${result.code}" created')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _confirmDelete(PromoCode code) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Promo Code'),
        content: Text(
          'Are you sure you want to delete "${code.code}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _promoService.deletePromoCode(code.code);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Promo code "${code.code}" deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _toggleActive(PromoCode code) async {
    try {
      final updated = PromoCode(
        code: code.code,
        type: code.type,
        value: code.value,
        minOrderAmount: code.minOrderAmount,
        maxDiscount: code.maxDiscount,
        expiresAt: code.expiresAt,
        isActive: !code.isActive,
        usageLimit: code.usageLimit,
        usedCount: code.usedCount,
        applicableCourseIds: code.applicableCourseIds,
        applicableBatchIds: code.applicableBatchIds,
      );
      await _promoService.updatePromoCode(updated);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

// ─── Promo Code Card ──────────────────────────────────────────────
class _PromoCodeCard extends StatelessWidget {
  final PromoCode promoCode;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggle;

  const _PromoCodeCard({
    required this.promoCode,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isExpired =
        promoCode.expiresAt != null &&
        DateTime.now().isAfter(promoCode.expiresAt!);
    final isUsedUp =
        promoCode.usageLimit != null &&
        promoCode.usedCount >= promoCode.usageLimit!;

    Color statusColor;
    String statusText;
    if (!promoCode.isActive) {
      statusColor = Colors.grey;
      statusText = 'Inactive';
    } else if (isExpired) {
      statusColor = Colors.red;
      statusText = 'Expired';
    } else if (isUsedUp) {
      statusColor = Colors.orange;
      statusText = 'Limit Reached';
    } else {
      statusColor = Colors.green;
      statusText = 'Active';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.teal.shade200),
                    ),
                    child: Text(
                      promoCode.code,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.teal.shade800,
                        letterSpacing: 1.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                Switch(
                  value: promoCode.isActive,
                  onChanged: (_) => onToggle(),
                  activeTrackColor: Colors.teal,
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Discount info
            Row(
              children: [
                Icon(Icons.discount, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    promoCode.type == 'percentage'
                        ? '${promoCode.value.toStringAsFixed(0)}% off'
                        : '₹${promoCode.value.toStringAsFixed(0)} off',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (promoCode.maxDiscount != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    '(max ₹${promoCode.maxDiscount!.toStringAsFixed(0)})',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            // Usage info
            Row(
              children: [
                Icon(
                  Icons.people_outline,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 6),
                Text(
                  promoCode.usageLimit != null
                      ? 'Used ${promoCode.usedCount} / ${promoCode.usageLimit}'
                      : 'Used ${promoCode.usedCount} times (unlimited)',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
            ),
            if (promoCode.minOrderAmount != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Min order: ₹${promoCode.minOrderAmount!.toStringAsFixed(0)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ],
            if (promoCode.expiresAt != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Text(
                    'Expires: ${DateFormat('dd MMM yyyy, hh:mm a').format(promoCode.expiresAt!)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ],
            // Applicable courses/batches
            if (promoCode.applicableCourseIds != null &&
                promoCode.applicableCourseIds!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.school_outlined,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Courses: ${promoCode.applicableCourseIds!.length} selected',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (promoCode.applicableBatchIds != null &&
                promoCode.applicableBatchIds!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.group_outlined,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Batches: ${promoCode.applicableBatchIds!.length} selected',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                  label: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Promo Code Editor Dialog ─────────────────────────────────────
class _PromoCodeEditorDialog extends StatefulWidget {
  final PromoCode? existing;
  const _PromoCodeEditorDialog({this.existing});

  @override
  State<_PromoCodeEditorDialog> createState() => _PromoCodeEditorDialogState();
}

class _PromoCodeEditorDialogState extends State<_PromoCodeEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _codeController;
  late TextEditingController _valueController;
  late TextEditingController _minOrderController;
  late TextEditingController _maxDiscountController;
  late TextEditingController _usageLimitController;

  String _type = 'percentage';
  bool _isActive = true;
  DateTime? _expiresAt;
  bool _hasExpiry = false;

  // Course / batch selection
  List<_CourseOption> _availableCourses = [];
  Set<String> _selectedCourseIds = {};
  Map<String, List<_BatchOption>> _courseBatches = {};
  Set<String> _selectedBatchIds = {};
  bool _loadingCourses = true;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _codeController = TextEditingController(text: e?.code ?? '');
    _valueController = TextEditingController(
      text: e?.value.toStringAsFixed(0) ?? '',
    );
    _minOrderController = TextEditingController(
      text: e?.minOrderAmount?.toStringAsFixed(0) ?? '',
    );
    _maxDiscountController = TextEditingController(
      text: e?.maxDiscount?.toStringAsFixed(0) ?? '',
    );
    _usageLimitController = TextEditingController(
      text: e?.usageLimit?.toString() ?? '',
    );
    _type = e?.type ?? 'percentage';
    _isActive = e?.isActive ?? true;
    _expiresAt = e?.expiresAt;
    _hasExpiry = e?.expiresAt != null;
    _selectedCourseIds = (e?.applicableCourseIds ?? []).toSet();
    _selectedBatchIds = (e?.applicableBatchIds ?? []).toSet();

    _loadCourses();
  }

  Future<void> _loadCourses() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('courses')
          .get();
      final courses = <_CourseOption>[];
      final batches = <String, List<_BatchOption>>{};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        courses.add(
          _CourseOption(id: doc.id, title: data['title'] as String? ?? doc.id),
        );

        // Load batches for this course
        final batchSnapshot = await FirebaseFirestore.instance
            .collection('courses')
            .doc(doc.id)
            .collection('batches')
            .get();
        batches[doc.id] = batchSnapshot.docs.map((bDoc) {
          final bData = bDoc.data();
          return _BatchOption(
            id: bDoc.id,
            name: bData['name'] as String? ?? bDoc.id,
            courseId: doc.id,
          );
        }).toList();
      }

      if (mounted) {
        setState(() {
          _availableCourses = courses;
          _courseBatches = batches;
          _loadingCourses = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading courses: $e');
      if (mounted) {
        setState(() => _loadingCourses = false);
      }
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _valueController.dispose();
    _minOrderController.dispose();
    _maxDiscountController.dispose();
    _usageLimitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title bar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.teal,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_offer, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      _isEditing ? 'Edit Promo Code' : 'Create Promo Code',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Form body
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Code
                      TextFormField(
                        controller: _codeController,
                        enabled: !_isEditing,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'Promo Code *',
                          hintText: 'e.g. SAVE20',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.tag),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      // Type toggle
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text(
                            'Discount Type:',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          ChoiceChip(
                            label: const Text('Percentage'),
                            selected: _type == 'percentage',
                            onSelected: (_) =>
                                setState(() => _type = 'percentage'),
                          ),
                          ChoiceChip(
                            label: const Text('Fixed Amount'),
                            selected: _type == 'fixed',
                            onSelected: (_) => setState(() => _type = 'fixed'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Value
                      TextFormField(
                        controller: _valueController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: _type == 'percentage'
                              ? 'Discount Percentage *'
                              : 'Discount Amount (₹) *',
                          hintText: _type == 'percentage'
                              ? 'e.g. 20'
                              : 'e.g. 500',
                          border: const OutlineInputBorder(),
                          prefixIcon: Icon(
                            _type == 'percentage'
                                ? Icons.percent
                                : Icons.currency_rupee,
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          final val = double.tryParse(v);
                          if (val == null || val <= 0) {
                            return 'Enter a valid number';
                          }
                          if (_type == 'percentage' && val > 100) {
                            return 'Max 100%';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Min order & max discount
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _minOrderController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Min Order (₹)',
                                hintText: 'Optional',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (_type == 'percentage')
                            Expanded(
                              child: TextFormField(
                                controller: _maxDiscountController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Max Discount (₹)',
                                  hintText: 'Optional',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Usage limit
                      TextFormField(
                        controller: _usageLimitController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Usage Limit',
                          hintText: 'Leave empty for unlimited',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.people),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Expiry
                      SwitchListTile(
                        title: const Text('Set Expiry Date'),
                        value: _hasExpiry,
                        onChanged: (v) => setState(() {
                          _hasExpiry = v;
                          if (!v) _expiresAt = null;
                        }),
                        contentPadding: EdgeInsets.zero,
                      ),
                      if (_hasExpiry) ...[
                        InkWell(
                          onTap: _pickExpiryDate,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Expires At',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.calendar_today),
                            ),
                            child: Text(
                              _expiresAt != null
                                  ? DateFormat(
                                      'dd MMM yyyy, hh:mm a',
                                    ).format(_expiresAt!)
                                  : 'Tap to select',
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      // Active toggle
                      SwitchListTile(
                        title: const Text('Active'),
                        subtitle: const Text('Inactive codes cannot be used'),
                        value: _isActive,
                        onChanged: (v) => setState(() => _isActive = v),
                        contentPadding: EdgeInsets.zero,
                      ),
                      const Divider(),
                      const SizedBox(height: 8),
                      // Course / batch targeting
                      Text(
                        'Applicable To',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Leave empty to apply to all courses & batches',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_loadingCourses)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else
                        _buildCourseSelection(),
                    ],
                  ),
                ),
              ),
              // Actions
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: _submit,
                      child: Text(_isEditing ? 'Update' : 'Create'),
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

  Widget _buildCourseSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final course in _availableCourses) ...[
          CheckboxListTile(
            title: Text(
              course.title,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            value: _selectedCourseIds.contains(course.id),
            onChanged: (v) {
              setState(() {
                if (v == true) {
                  _selectedCourseIds.add(course.id);
                } else {
                  _selectedCourseIds.remove(course.id);
                  // Also deselect its batches
                  final batches = _courseBatches[course.id] ?? [];
                  for (final b in batches) {
                    _selectedBatchIds.remove(b.id);
                  }
                }
              });
            },
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
          // Show batches if course is selected
          if (_selectedCourseIds.contains(course.id) &&
              (_courseBatches[course.id]?.isNotEmpty ?? false))
            Padding(
              padding: const EdgeInsets.only(left: 32),
              child: Column(
                children: [
                  for (final batch in _courseBatches[course.id]!)
                    CheckboxListTile(
                      title: Text(
                        batch.name,
                        style: const TextStyle(fontSize: 13),
                      ),
                      value: _selectedBatchIds.contains(batch.id),
                      onChanged: (v) {
                        setState(() {
                          if (v == true) {
                            _selectedBatchIds.add(batch.id);
                          } else {
                            _selectedBatchIds.remove(batch.id);
                          }
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                ],
              ),
            ),
        ],
      ],
    );
  }

  Future<void> _pickExpiryDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _expiresAt ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_expiresAt ?? DateTime.now()),
    );
    if (!mounted) return;

    setState(() {
      _expiresAt = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? 23,
        time?.minute ?? 59,
      );
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final code = _codeController.text.trim().toUpperCase();
    final value = double.parse(_valueController.text.trim());
    final minOrder = _minOrderController.text.trim().isNotEmpty
        ? double.parse(_minOrderController.text.trim())
        : null;
    final maxDiscount = _maxDiscountController.text.trim().isNotEmpty
        ? double.parse(_maxDiscountController.text.trim())
        : null;
    final usageLimit = _usageLimitController.text.trim().isNotEmpty
        ? int.parse(_usageLimitController.text.trim())
        : null;

    final promoCode = PromoCode(
      code: code,
      type: _type,
      value: value,
      minOrderAmount: minOrder,
      maxDiscount: maxDiscount,
      expiresAt: _hasExpiry ? _expiresAt : null,
      isActive: _isActive,
      usageLimit: usageLimit,
      usedCount: widget.existing?.usedCount ?? 0,
      applicableCourseIds: _selectedCourseIds.isNotEmpty
          ? _selectedCourseIds.toList()
          : null,
      applicableBatchIds: _selectedBatchIds.isNotEmpty
          ? _selectedBatchIds.toList()
          : null,
    );

    Navigator.pop(context, promoCode);
  }
}

// ─── Helper models ────────────────────────────────────────────────
class _CourseOption {
  final String id;
  final String title;
  const _CourseOption({required this.id, required this.title});
}

class _BatchOption {
  final String id;
  final String name;
  final String courseId;
  const _BatchOption({
    required this.id,
    required this.name,
    required this.courseId,
  });
}
