import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firebase_admin_service.dart';
import '../services/csv_importer.dart';
import '../models/admin_models.dart';
import '../widgets/admin_scaffold.dart';

class BatchEditorScreen extends StatelessWidget {
  final String courseId;
  const BatchEditorScreen({Key? key, required this.courseId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final service = context.read<FirebaseAdminService>();
    return AdminScaffold(
      title: 'Manage Batches',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.upload_file),
              label: const Text('Import CSV'),
              onPressed: () async {
                final batches = await CsvImporter().pickAndParseBatches(courseId);
                for (var b in batches) {
                  await service.saveBatch(courseId, b, isNew: true);
                }
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<List<AdminBatch>>(
              stream: service.getBatches(courseId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final batch = snapshot.data![index];
                    return ListTile(
                      title: Text(batch.name),
                      subtitle: Text('Seats: ${batch.seatsLeft}/${batch.seatsTotal}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          // Open edit dialog or screen
                        },
                      ),
                      onTap: () => Navigator.pushNamed(context, '/lecture_editor', arguments: {'courseId': courseId, 'batchId': batch.id}),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
