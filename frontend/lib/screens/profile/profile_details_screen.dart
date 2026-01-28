import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:invispay/core/theme/app_theme.dart';
import 'package:invispay/services/auth_service.dart';
import 'package:invispay/services/database_service.dart';
import 'package:invispay/widgets/common/base_screen.dart';
import 'package:invispay/widgets/common/primary_button.dart';

class ProfileDetailsScreen extends ConsumerStatefulWidget {
  const ProfileDetailsScreen({super.key});

  @override
  ConsumerState<ProfileDetailsScreen> createState() =>
      _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends ConsumerState<ProfileDetailsScreen> {
  final AuthService _auth = AuthService();
  final DatabaseService _db = DatabaseService();

  bool _isEditMode = false;
  bool _isLoading = false;

  final _nameController = TextEditingController();
  File? _selectedImage;
  String? _currentPhotoUrl;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickAndCropImage(ImageSource source) async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Profile Photo',
            toolbarColor: AppTheme.primary,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Crop Profile Photo',
            aspectRatioLockEnabled: true,
          ),
        ],
      );

      if (croppedFile == null) return;

      setState(() {
        _selectedImage = File(croppedFile.path);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error picking image')),
        );
      }
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            const Text(
              'Change Profile Photo',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: Colors.white70),
              title:
                  const Text('Gallery', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickAndCropImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.camera_alt_outlined, color: Colors.white70),
              title:
                  const Text('Camera', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickAndCropImage(ImageSource.camera);
              },
            ),
            if (_selectedImage != null || _currentPhotoUrl != null)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded,
                    color: Colors.redAccent),
                title: const Text('Remove Photo',
                    style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedImage = null;
                    _currentPhotoUrl = null;
                  });
                },
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      String? photoUrl = _currentPhotoUrl;

      // Upload new image if selected
      if (_selectedImage != null) {
        photoUrl = await _db.uploadProfilePhoto(user.uid, _selectedImage!);
      } else if (_currentPhotoUrl == null) {
        // Photo was removed
        await _db.removeProfilePhoto(user.uid);
        photoUrl = null;
      }

      // Update name
      await _db.updateUserProfile(user.uid, {
        'displayName': _nameController.text.trim(),
        if (photoUrl != null ||
            _selectedImage != null ||
            _currentPhotoUrl == null)
          'photoURL': photoUrl,
      });

      if (mounted) {
        setState(() {
          _isEditMode = false;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error updating profile')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: _db.getUserStream(user.uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final String name = data['displayName'] ?? 'InvisPay User';
        final String email = data['email'] ?? '';
        final String mobile = data['mobile'] ?? '';
        final String kycStatus = data['kycStatus'] ?? 'Not Started';
        final String? photoUrlFromDb = data['photoURL'];

        if (!_isEditMode) {
          _nameController.text = name;
          _currentPhotoUrl = photoUrlFromDb;
        }

        return BaseScreen(
          appBar: AppBar(
            title: Text(
              _isEditMode ? 'Edit Profile' : 'Profile Details',
              style:
                  GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => context.pop(),
            ),
            actions: [
              if (!_isEditMode)
                TextButton(
                  onPressed: () => setState(() => _isEditMode = true),
                  child: const Text('Edit',
                      style: TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold)),
                ),
            ],
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Profile Photo
                GestureDetector(
                  onTap: _isEditMode ? _showPhotoOptions : null,
                  child: Stack(
                    children: [
                      Hero(
                        tag: 'profile_photo',
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: AppTheme.primary.withValues(alpha: 0.5),
                                width: 4),
                          ),
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: AppTheme.surface,
                            backgroundImage: _selectedImage != null
                                ? FileImage(_selectedImage!)
                                : (_currentPhotoUrl != null
                                    ? NetworkImage(_currentPhotoUrl!)
                                    : null) as ImageProvider?,
                            child: (_selectedImage == null &&
                                    _currentPhotoUrl == null)
                                ? Text(
                                    name.isNotEmpty
                                        ? name[0].toUpperCase()
                                        : 'U',
                                    style: const TextStyle(
                                        fontSize: 48,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  )
                                : null,
                          ),
                        ),
                      ),
                      if (_isEditMode)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                                color: AppTheme.primary,
                                shape: BoxShape.circle),
                            child: const Icon(Icons.camera_alt_rounded,
                                size: 20, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Fields
                _buildInfoField(
                  label: 'Full Name',
                  controller: _nameController,
                  isEditable: _isEditMode,
                  icon: Icons.person_outline_rounded,
                ),

                const SizedBox(height: 20),

                _buildInfoField(
                  label: 'Email Address',
                  value: email,
                  isEditable: false,
                  icon: Icons.email_outlined,
                ),

                const SizedBox(height: 20),

                _buildInfoField(
                  label: 'Mobile Number',
                  value: mobile,
                  isEditable: false,
                  icon: Icons.phone_android_rounded,
                ),

                const SizedBox(height: 20),

                _buildInfoField(
                  label: 'KYC Status',
                  value: kycStatus.toUpperCase(),
                  isEditable: false,
                  icon: Icons.verified_user_outlined,
                  trailing: _buildKycBadge(kycStatus),
                ),

                const SizedBox(height: 48),

                if (_isEditMode) ...[
                  PrimaryButton(
                    text: 'Save Changes',
                    isLoading: _isLoading,
                    onPressed: _handleSave,
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isEditMode = false;
                        _selectedImage = null;
                      });
                    },
                    child: const Text('Cancel',
                        style: TextStyle(color: Colors.white60)),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoField({
    required String label,
    String? value,
    TextEditingController? controller,
    required bool isEditable,
    required IconData icon,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.white38),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                    color: Colors.white38,
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: isEditable
                    ? TextField(
                        controller: controller,
                        style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      )
                    : Text(
                        value ?? '',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKycBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'verified':
        color = const Color(0xFF10B981);
        break;
      case 'pending':
        color = const Color(0xFFF59E0B);
        break;
      case 'failed':
        color = const Color(0xFFEF4444);
        break;
      default:
        color = Colors.white24;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.inter(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5),
      ),
    );
  }
}
