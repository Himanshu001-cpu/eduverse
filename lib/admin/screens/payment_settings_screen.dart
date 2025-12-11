import 'package:flutter/material.dart';
import '../widgets/admin_scaffold.dart';
import 'package:eduverse/core/firebase/razorpay_service.dart';

class PaymentSettingsScreen extends StatefulWidget {
  const PaymentSettingsScreen({super.key});

  @override
  State<PaymentSettingsScreen> createState() => _PaymentSettingsScreenState();
}

class _PaymentSettingsScreenState extends State<PaymentSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _keyIdController = TextEditingController();
  final _keySecretController = TextEditingController();
  final _companyNameController = TextEditingController();
  bool _isTestMode = true;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _obscureSecret = true;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _keyIdController.dispose();
    _keySecretController.dispose();
    _companyNameController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    final service = RazorpayService();
    await service.initialize();
    final config = service.config;
    
    if (config != null) {
      _keyIdController.text = config.keyId;
      _keySecretController.text = config.keySecret;
      _companyNameController.text = config.companyName;
      _isTestMode = config.isTestMode;
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final newConfig = RazorpayConfig(
        keyId: _keyIdController.text.trim(),
        keySecret: _keySecretController.text.trim(),
        isTestMode: _isTestMode,
        companyName: _companyNameController.text.trim(),
        currency: 'INR',
      );

      await RazorpayService().saveConfig(newConfig);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment settings saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Payment Settings',
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Image.network(
                              'https://razorpay.com/favicon.png',
                              width: 40,
                              height: 40,
                              errorBuilder: (_, __, ___) => const Icon(Icons.payment, size: 40),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Razorpay Configuration',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  _isTestMode ? 'Test Mode' : 'Live Mode',
                                  style: TextStyle(
                                    color: _isTestMode ? Colors.orange : Colors.green,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Mode Toggle
                    Card(
                      child: SwitchListTile(
                        title: const Text('Test Mode'),
                        subtitle: Text(
                          _isTestMode
                              ? 'Using test credentials (no real charges)'
                              : 'Using live credentials (real charges)',
                        ),
                        value: _isTestMode,
                        onChanged: (value) => setState(() => _isTestMode = value),
                        activeThumbColor: Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // API Keys
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'API Credentials',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _keyIdController,
                              decoration: const InputDecoration(
                                labelText: 'Key ID',
                                hintText: 'rzp_test_...',
                                prefixIcon: Icon(Icons.key),
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) => v?.isEmpty == true ? 'Required' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _keySecretController,
                              obscureText: _obscureSecret,
                              decoration: InputDecoration(
                                labelText: 'Key Secret',
                                prefixIcon: const Icon(Icons.lock),
                                border: const OutlineInputBorder(),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscureSecret ? Icons.visibility : Icons.visibility_off),
                                  onPressed: () => setState(() => _obscureSecret = !_obscureSecret),
                                ),
                              ),
                              validator: (v) => v?.isEmpty == true ? 'Required' : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Company Info
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Display Settings',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _companyNameController,
                              decoration: const InputDecoration(
                                labelText: 'Company Name',
                                hintText: 'Shown on payment page',
                                prefixIcon: Icon(Icons.business),
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) => v?.isEmpty == true ? 'Required' : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveConfig,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save),
                        label: Text(_isSaving ? 'Saving...' : 'Save Settings'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
