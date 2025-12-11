import 'package:flutter/material.dart';
import 'package:eduverse/profile/profile_storage.dart';

class EditProfilePage extends StatefulWidget {
  final ProfileModel? initialData;

  const EditProfilePage({super.key, this.initialData});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _headlineController;
  late TextEditingController _bioController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  
  String _medium = 'Hinglish';
  String _avatarType = 'emoji';
  String _avatarValue = '👤';
  int _avatarColor = 0xFFD1C4E9;
  
  bool _isSaving = false;

  final List<String> _emojis = [
    '👤', '👨‍🎓', '👩‍🎓', '👨‍🏫', '👩‍🏫', '🚀', '⭐', '📚', 
    '💡', '🧠', '🎓', '📝', '💻', '🌍', '🎨', '⚽',
    '🎵', '🎮', '🍕', '🐱', '🐶', '🦁', '🐼', '🦊'
  ];

  final List<Color> _bgColors = [
    Colors.deepPurple[100]!,
    Colors.blue[100]!,
    Colors.green[100]!,
    Colors.orange[100]!,
    Colors.red[100]!,
    Colors.teal[100]!,
    Colors.pink[100]!,
    Colors.amber[100]!,
  ];

  @override
  void initState() {
    super.initState();
    final data = widget.initialData ?? ProfileModel.defaultProfile;
    _nameController = TextEditingController(text: data.fullName);
    _headlineController = TextEditingController(text: data.headline);
    _bioController = TextEditingController(text: data.bio);
    _emailController = TextEditingController(text: data.email ?? '');
    _phoneController = TextEditingController(text: data.phone ?? '');
    _medium = data.medium;
    _avatarType = data.avatarType;
    _avatarValue = data.avatarValue;
    _avatarColor = data.avatarColor;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _headlineController.dispose();
    _bioController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    final newProfile = ProfileModel(
      fullName: _nameController.text.trim(),
      headline: _headlineController.text.trim(),
      bio: _bioController.text.trim(),
      medium: _medium,
      avatarType: _avatarType,
      avatarValue: _avatarValue,
      avatarColor: _avatarColor,
      email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
      phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
    );

    try {
      await ProfileStorage.saveProfile(newProfile);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
      Navigator.pop(context, true); // Return true to indicate update
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save profile')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _reset() async {
    setState(() => _isSaving = true);
    await ProfileStorage.clearProfile();
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _reset,
            child: const Text('Reset', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar Section
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Color(_avatarColor),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey.shade300, width: 2),
                            ),
                            child: Center(
                              child: Text(
                                _avatarValue,
                                style: const TextStyle(fontSize: 48),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text('Choose Avatar', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 50,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _emojis.length,
                              itemBuilder: (context, index) {
                                final emoji = _emojis[index];
                                return GestureDetector(
                                  onTap: () => setState(() => _avatarValue = emoji),
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: _avatarValue == emoji ? Colors.grey[200] : null,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(emoji, style: const TextStyle(fontSize: 24)),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 40,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _bgColors.length,
                              itemBuilder: (context, index) {
                                final color = _bgColors[index];
                                return GestureDetector(
                                  onTap: () => setState(() => _avatarColor = color.value),
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                      border: _avatarColor == color.value
                                          ? Border.all(color: Colors.black, width: 2)
                                          : null,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Form Fields
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Full Name'),
                      validator: (val) => val == null || val.isEmpty ? 'Name is required' : null,
                      maxLength: 40,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _headlineController,
                      decoration: const InputDecoration(labelText: 'Headline (Optional)'),
                      maxLength: 60,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _bioController,
                      decoration: const InputDecoration(labelText: 'Bio', alignLabelWithHint: true),
                      maxLines: 3,
                      maxLength: 250,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 24),

                    // Medium Selection
                    const Text('Preferred Medium', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'Hinglish', label: Text('Hinglish')),
                        ButtonSegment(value: 'Hindi', label: Text('Hindi')),
                        ButtonSegment(value: 'English', label: Text('English')),
                      ],
                      selected: {_medium},
                      onSelectionChanged: (Set<String> newSelection) {
                        setState(() {
                          _medium = newSelection.first;
                        });
                      },
                    ),
                    const SizedBox(height: 32),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Save Changes'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
