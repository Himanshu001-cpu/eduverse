import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firebase_admin_service.dart';
import 'package:eduverse/store/models/store_models.dart';
import '../widgets/admin_scaffold.dart';

class EbooksScreen extends StatefulWidget {
  const EbooksScreen({super.key});

  @override
  State<EbooksScreen> createState() => _EbooksScreenState();
}

class _EbooksScreenState extends State<EbooksScreen> {
  @override
  Widget build(BuildContext context) {
    final adminService = context.read<FirebaseAdminService>();

    return AdminScaffold(
      title: 'E-books Manager',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEditEbookDialog(context, adminService, null),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add E-book', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.indigo,
      ),
      body: StreamBuilder<List<Ebook>>(
        stream: adminService.getAdminEbooks(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error fetching E-books: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final ebooks = snapshot.data!;

          if (ebooks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.book_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No E-books yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('Tap "Add E-book" to publish your first electronic book!'),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 400,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.15,
            ),
            itemCount: ebooks.length,
            itemBuilder: (context, index) {
              final ebook = ebooks[index];
              return _buildEbookCard(context, adminService, ebook);
            },
          );
        },
      ),
    );
  }

  Widget _buildEbookCard(BuildContext context, FirebaseAdminService service, Ebook ebook) {
    final discountPercent = ebook.realPrice > 0
        ? (((ebook.realPrice - ebook.finalPrice) / ebook.realPrice) * 100).round()
        : 0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail / Status Header
          Stack(
            children: [
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.indigo.shade700, Colors.teal.shade700],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  image: ebook.thumbnailUrl.isNotEmpty
                      ? DecorationImage(image: NetworkImage(ebook.thumbnailUrl), fit: BoxFit.cover)
                      : null,
                ),
                child: ebook.thumbnailUrl.isEmpty
                    ? const Center(child: Icon(Icons.book, size: 48, color: Colors.white70))
                    : null,
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: ebook.isActive ? Colors.green.shade800 : Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    ebook.isActive ? 'ACTIVE' : 'INACTIVE',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              if (discountPercent > 0)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade800,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$discountPercent% OFF',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
          // Info Details
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ebook.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (ebook.subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          ebook.subtitle,
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 12, fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        ebook.description,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '₹${ebook.finalPrice.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                          const SizedBox(width: 6),
                          if (ebook.realPrice > ebook.finalPrice)
                            Text(
                              '₹${ebook.realPrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.indigo, size: 20),
                            onPressed: () => _showEditEbookDialog(context, service, ebook),
                            tooltip: 'Edit E-book',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                            onPressed: () => _showDeleteConfirmation(context, service, ebook),
                            tooltip: 'Delete E-book',
                          ),
                        ],
                      )
                    ],
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, FirebaseAdminService service, Ebook ebook) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete E-book?'),
        content: Text('Are you sure you want to delete "${ebook.title}"?\n\nThis will remove this E-book listing from the store. Existing student purchases will NOT be affected.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await service.deleteEbook(ebook.id);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditEbookDialog(BuildContext context, FirebaseAdminService service, Ebook? existing) {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final subtitleController = TextEditingController(text: existing?.subtitle ?? '');
    final descController = TextEditingController(text: existing?.description ?? '');
    final thumbController = TextEditingController(text: existing?.thumbnailUrl ?? '');
    final pdfUrlController = TextEditingController(text: existing?.pdfUrl ?? '');
    final realPriceController = TextEditingController(text: existing?.realPrice.toString() ?? '0.00');
    final finalPriceController = TextEditingController(text: existing?.finalPrice.toString() ?? '0.00');
    bool isActive = existing?.isActive ?? true;

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text(existing == null ? 'Add E-book' : 'Edit E-book'),
          content: SizedBox(
            width: 500,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'E-book Title *', border: OutlineInputBorder()),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Title is required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: subtitleController,
                      decoration: const InputDecoration(labelText: 'Subtitle', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: descController,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: thumbController,
                      decoration: const InputDecoration(labelText: 'Thumbnail Image URL', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: pdfUrlController,
                      decoration: const InputDecoration(labelText: 'PDF URL *', border: OutlineInputBorder()),
                      validator: (value) => value == null || value.trim().isEmpty ? 'PDF URL is required' : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: realPriceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Real Price (₹) *', border: OutlineInputBorder()),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) return 'Required';
                              if (double.tryParse(value) == null) return 'Must be a number';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: finalPriceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Sale Price (₹) *', border: OutlineInputBorder()),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) return 'Required';
                              if (double.tryParse(value) == null) return 'Must be a number';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Is Active in Store?'),
                      value: isActive,
                      onChanged: (val) => setStateDialog(() => isActive = val),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  final ebook = Ebook(
                    id: existing?.id ?? '',
                    title: titleController.text.trim(),
                    subtitle: subtitleController.text.trim(),
                    description: descController.text.trim(),
                    thumbnailUrl: thumbController.text.trim(),
                    pdfUrl: pdfUrlController.text.trim(),
                    realPrice: double.parse(realPriceController.text.trim()),
                    finalPrice: double.parse(finalPriceController.text.trim()),
                    isActive: isActive,
                  );

                  await service.saveEbook(ebook, isNew: existing == null);
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: Text(existing == null ? 'Add' : 'Save', style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
