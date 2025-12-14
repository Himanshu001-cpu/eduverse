import 'package:flutter/material.dart';
import 'package:eduverse/profile/edit_profile_page.dart';
import 'package:eduverse/profile/profile_storage.dart';

class ProfileHeader extends StatefulWidget {
  const ProfileHeader({super.key});

  @override
  State<ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<ProfileHeader> {
  ProfileModel? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await ProfileStorage.loadProfile();
    if (mounted) {
      setState(() {
        _profile = profile;
      });
    }
  }

  Future<void> _openEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfilePage(initialData: _profile),
      ),
    );

    if (result == true) {
      _loadProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    
    
    final displayProfile = _profile ?? ProfileModel.defaultProfile;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue, Colors.indigo],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0,4))],
            ),
            child: Column(
              children: [
                // avatar
                GestureDetector(
                  onTap: _openEditProfile,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.deepPurple[300]!, width: 3),
                      color: Color(displayProfile.avatarColor),
                    ),
                    child: Center(
                      child: Text(
                        displayProfile.avatarValue,
                        style: const TextStyle(fontSize: 60),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  displayProfile.fullName,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  displayProfile.headline,
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _openEditProfile,
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8)),
                  child: const Text('Edit Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
