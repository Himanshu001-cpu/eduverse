import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import '../widgets/admin_scaffold.dart';
import '../services/firebase_admin_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = 'Loading...';
  String _buildNumber = '';

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
  }

  Future<void> _loadAppInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      setState(() {
        _version = info.version;
        _buildNumber = info.buildNumber;
      });
    } catch (e) {
      setState(() => _version = 'Unknown');
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminService = context.watch<FirebaseAdminService>();

    return AdminScaffold(
      title: 'Settings',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // General Settings Card
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('General Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  const Divider(height: 1),
                  
                  // Maintenance Mode Toggle
                  StreamBuilder<Map<String, dynamic>>(
                    stream: adminService.getGeneralConfig(),
                    builder: (context, snapshot) {
                      final config = snapshot.data ?? {'maintenanceMode': false};
                      final isMaintenance = config['maintenanceMode'] == true;

                      return SwitchListTile(
                        title: const Text('Maintenance Mode'),
                        subtitle: Text(
                          isMaintenance 
                              ? 'App is currently in maintenance mode (users cannot access)'
                              : 'App is live and accessible to users'
                        ),
                        secondary: Icon(
                          isMaintenance ? Icons.construction : Icons.check_circle,
                          color: isMaintenance ? Colors.orange : Colors.green,
                        ),
                        value: isMaintenance,
                        onChanged: (val) async {
                          try {
                            await adminService.updateMaintenanceMode(val);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Maintenance mode ${val ? 'enabled' : 'disabled'}'),
                                  backgroundColor: val ? Colors.orange : Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                              );
                            }
                          }
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Integrations Card
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Integrations & Keys', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.payment, color: Colors.blue),
                    title: const Text('Payment Configuration'),
                    subtitle: const Text('Razorpay keys and settings'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.pushNamed(context, '/payment_settings'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // App Info Card
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('App Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Version'),
                    trailing: Text('$_version ($_buildNumber)'),
                  ),
                  const ListTile(
                    title: Text('Platform'),
                    trailing: Text('Admin Panel (Flutter)'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
