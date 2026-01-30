import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:invispay/core/theme/app_theme.dart';
import 'package:invispay/routes/app_routes.dart';
import 'package:invispay/services/auth_service.dart';
import 'package:invispay/services/database_service.dart';
import 'package:invispay/services/kyc_service.dart';
import 'package:invispay/widgets/common/base_screen.dart';
import 'package:invispay/widgets/common/animated_localize.dart';
import 'package:invispay/providers/qr_provider.dart';
import 'package:invispay/providers/lite_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final auth = AuthService();
    final db = DatabaseService();
    final user = auth.currentUser;
    final l10n = AppLocalizations.of(context);
    final isDemo = user == null || !db.isConfigured;
    final uid = user?.uid ?? 'demo';

    return BaseScreen(
      appBar: AppBar(
        title: AnimatedLocalize(
          text: (loc) => loc.profile,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      child: StreamBuilder<DocumentSnapshot>(
        stream: db.getUserStream(uid),
        builder: (context, snapshot) {
          // Default / Demo Data
          String name = isDemo ? l10n.translate('demo_user') : 'InvisPay User';
          String mobile = '7904459738';
          String email = 'demo@invispay.com';
          String kycStatus = 'not_started';

          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            name = data['displayName'] ?? name;
            mobile = data['mobile'] ?? mobile;
            email = data['email'] ?? email;
            kycStatus = data['kycStatus'] ?? kycStatus;
          }

          final invispayId =
              '${name.toLowerCase().replaceAll(' ', '')}@invispay';

          return StreamBuilder<Map<String, dynamic>?>(
            stream: KycService().kycStatusStream,
            builder: (context, kycSnapshot) {
              final kycData = kycSnapshot.data;
              final currentKycStatus = kycData?['kycStatus'] ?? kycStatus;
              final isVerified = currentKycStatus.toLowerCase() == 'verified';

              // Get latest photoURL from main snapshot
              final photoURL = snapshot.hasData && snapshot.data!.exists
                  ? (snapshot.data!.data() as Map<String, dynamic>)['photoURL']
                      as String?
                  : null;

              return ListView(
                padding: const EdgeInsets.all(0),
                children: [
                  // 1. Profile Header Card
                  _buildProfileHeader(context, name, invispayId, mobile,
                      isVerified, photoURL, uid, isDemo),

                  // 2. Payment Methods Section
                  _buildPaymentMethodsSection(context, ref),

                  const SizedBox(height: 8),

                  // 3. Menu List
                  _buildMenuItem(
                    context: context,
                    icon: Icons.shield_outlined,
                    title: (loc) => loc.kycVerification,
                    subtitle: _getKycStatusSubtitle(currentKycStatus),
                    onTap: () => context
                        .push(AppRoutes.kyc, extra: {'fromProfile': true}),
                  ),

                  _buildMenuItem(
                    context: context,
                    icon: Icons.autorenew_rounded,
                    title: (loc) => loc.translate('autopay'),
                    subtitle: (loc) => loc.translate('no_pending'),
                    onTap: () => context.push(AppRoutes.autopay),
                  ),

                  _buildMenuItem(
                    context: context,
                    icon: Icons.language_rounded,
                    title: (loc) => loc.language,
                    subtitle: (loc) => loc.languageSub,
                    onTap: () => context.push(AppRoutes.language),
                  ),

                  _buildMenuItem(
                    context: context,
                    icon: Icons.settings_outlined,
                    title: (loc) => loc.settings,
                    onTap: () => context.push('/profile/settings'),
                  ),

                  _buildMenuItem(
                    context: context,
                    icon: Icons.help_outline_rounded,
                    title: (loc) => loc.translate('get_help'),
                    onTap: () {},
                  ),

                  const SizedBox(height: 32),

                  // 4. Logout Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _PremiumLogoutButton(
                      onTap: () =>
                          _showLogoutConfirmation(context, auth, isDemo),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              );
            },
          );
        },
      ),
    );
  }

  String Function(AppLocalizations) _getKycStatusSubtitle(String status) {
    switch (status.toLowerCase()) {
      case 'verified':
        return (loc) => loc.kycStatusVerified;
      case 'pending':
        return (loc) => loc.kycStatusPending;
      case 'failed':
        return (loc) => loc.kycStatusFailed;
      case 'not_started':
      default:
        return (loc) => loc.kycVerification;
    }
  }

  Widget _buildProfileHeader(
      BuildContext context,
      String name,
      String invispayId,
      String mobile,
      bool isVerified,
      String? photoURL,
      String uid,
      bool isDemo) {
    // Removed unused l10n
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0D9488), // Premium Solid Teal 600
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          // Subtle inner surface depth
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
            spreadRadius: -5,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A), // Slate 900 (High Contrast)
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'InvisPay ID: $invispayId',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF334155), // Slate 700 (Readable)
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      mobile,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A), // Slate 900
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (isVerified) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB), // Blue 600
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle,
                                color: Colors.white, size: 12),
                            const SizedBox(width: 4),
                            AnimatedLocalize(
                              text: (loc) => loc.translate('verified'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              GestureDetector(
                onTap: () => _showProfilePhotoOptions(context, photoURL, name),
                child: Hero(
                  tag: 'profile_photo',
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 32,
                      backgroundColor:
                          const Color(0xFF0F766E), // Dark Teal bg for avatar
                      backgroundImage:
                          photoURL != null ? NetworkImage(photoURL) : null,
                      child: photoURL == null
                          ? Text(
                              name.isNotEmpty ? name[0].toUpperCase() : 'U',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Consumer(builder: (context, ref, _) {
                final selectedAccount = ref.watch(qrSelectionProvider);
                final hasAccount = selectedAccount != null;

                return GestureDetector(
                  onTap: () => context.push(AppRoutes.myQrCodes),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ]),
                    child: Icon(
                        hasAccount && selectedAccount.type == 'Wallet'
                            ? Icons.wallet_rounded
                            : hasAccount && selectedAccount.type == 'Card'
                                ? Icons.credit_card_rounded
                                : Icons.qr_code_2_rounded,
                        color: const Color(0xFF0F172A),
                        size: 32),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodsSection(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 0),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPaymentMethodIcon(
                icon: Icons.account_balance_rounded,
                label: (loc) => loc.translate('bank_account'),
                subtitle: (loc) => '3 accounts', // Or localize if needed
                color: const Color(0xFF1976D2),
                onTap: () =>
                    context.go(AppRoutes.accounts), // Navigate to Accounts
              ),
              _buildPaymentMethodIcon(
                icon: Icons.credit_card_rounded,
                label: (loc) => loc.translate('invispay_credit'),
                subtitle: (loc) => loc.translate('pay_with_invispay'),
                color: const Color(0xFF1976D2),
                showAdd: true,
                onTap: () => context.push(AppRoutes.creditCards),
              ),
              Consumer(builder: (context, ref, _) {
                final auth = AuthService();
                final uid = auth.currentUser?.uid ?? 'demo';
                final liteBalance = ref.watch(liteBalanceProvider(uid));

                return _buildPaymentMethodIcon(
                  icon: Icons.bolt_rounded,
                  label: (loc) => loc.translate('invispay_lite'),
                  subtitle: (loc) => liteBalance.when(
                    data: (balance) =>
                        'Balance: ₹${balance.toStringAsFixed(0)}',
                    loading: () => 'Balance: ...',
                    error: (_, __) => 'Lite Wallet',
                  ),
                  color: const Color(0xFF1976D2),
                  subtitleColor: const Color(0xFFFF6B6B),
                  onTap: () => context.push(AppRoutes.invispayLite),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  } // Fixed closing brace

  Widget _buildPaymentMethodIcon({
    required IconData icon,
    required String Function(AppLocalizations) label,
    required String Function(AppLocalizations) subtitle,
    required Color color,
    Color? subtitleColor,
    bool showAdd = false,
    required VoidCallback onTap,
  }) {
    return Consumer(builder: (context, ref, child) {
      return GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: showAdd
                        ? Border.all(
                            color: color.withValues(alpha: 0.3),
                            width: 2,
                            strokeAlign: BorderSide.strokeAlignOutside)
                        : null,
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                if (showAdd)
                  Positioned(
                    bottom: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFF1976D2),
                        shape: BoxShape.circle,
                      ),
                      child:
                          const Icon(Icons.add, color: Colors.white, size: 16),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            AnimatedLocalize(
              text: label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedLocalize(
              text: subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: subtitleColor ??
                    Colors.white
                        .withValues(alpha: 0.95), // Increased contrast/opacity
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String Function(AppLocalizations) title,
    String Function(AppLocalizations)? subtitle,
    String Function(AppLocalizations)? trailing,
    String? badge,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF1976D2), size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AnimatedLocalize(
                          text: title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1976D2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              badge,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      AnimatedLocalize(
                        text: subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null)
                AnimatedLocalize(
                  text: trailing,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1976D2),
                  ),
                )
              else
                Icon(Icons.chevron_right,
                    color: Colors.white.withValues(alpha: 0.3)),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirmation(
      BuildContext context, AuthService auth, bool isDemo) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B), // Slate 800
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          l10n.logout,
          style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold, color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to log out of InvisPay?',
          style: GoogleFonts.inter(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              if (!isDemo) {
                await auth.signOut();
              }
              if (context.mounted) context.go(AppRoutes.login);
            },
            child: Text(
              l10n.logout,
              style: GoogleFonts.inter(
                color: const Color(0xFFEF4444),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Profile Photo Interactions ---

  void _showProfilePhotoOptions(
      BuildContext context, String? photoURL, String name) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0A0F1E),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: Colors.white.withAlpha(25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(25),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            _buildOptionTile(
              icon: Icons.visibility_rounded,
              label: 'View Profile Photo',
              onTap: () {
                Navigator.pop(context);
                _viewProfilePhoto(context, photoURL, name);
              },
            ),
            _buildOptionTile(
              icon: Icons.edit_rounded,
              label: 'Edit Profile Photo',
              onTap: () {
                Navigator.pop(context);
                _showEditOptions(context);
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _viewProfilePhoto(BuildContext context, String? photoURL, String name) {
    showDialog(
      context: context,
      useSafeArea: false,
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(color: Colors.black.withAlpha(200)),
            ),
          ),
          Center(
            child: Hero(
              tag: 'profile_photo',
              child: photoURL != null
                  ? Image.network(
                      photoURL,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.primary,
                          ),
                        );
                      },
                    )
                  : Container(
                      width: 240,
                      height: 240,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0D9488),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'U',
                          style: const TextStyle(
                            fontSize: 100,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
          Positioned(
            top: 60,
            right: 24,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.black26,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0A0F1E),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: Colors.white.withAlpha(25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(25),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            _buildOptionTile(
              icon: Icons.photo_library_rounded,
              label: 'Choose from Gallery',
              onTap: () {
                Navigator.pop(context);
                _pickAndCropImage(context, ImageSource.gallery);
              },
            ),
            _buildOptionTile(
              icon: Icons.camera_alt_rounded,
              label: 'Take Photo',
              onTap: () {
                Navigator.pop(context);
                _pickAndCropImage(context, ImageSource.camera);
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndCropImage(
      BuildContext context, ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 1000,
      maxHeight: 1000,
      imageQuality: 85,
    );

    if (pickedFile == null) return;

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: pickedFile.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Photo',
          toolbarColor: const Color(0xFF0A0F1E),
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
          backgroundColor: const Color(0xFF0A0F1E),
          activeControlsWidgetColor: AppTheme.primary,
          showCropGrid: false,
        ),
        IOSUiSettings(
          title: 'Crop Photo',
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
        ),
      ],
    );

    if (croppedFile != null) {
      if (context.mounted) {
        _previewAndSavePhoto(context, File(croppedFile.path));
      }
    }
  }

  void _previewAndSavePhoto(BuildContext context, File image) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF0A0F1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Preview Photo',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: FileImage(image),
                    fit: BoxFit.cover,
                  ),
                  border: Border.all(color: AppTheme.primary, width: 3),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(color: Colors.white70),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _uploadPhoto(image);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Save',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _uploadPhoto(File image) async {
    final auth = AuthService();
    final db = DatabaseService();
    final user = auth.currentUser;

    if (user != null) {
      final url = await db.uploadProfilePhoto(user.uid, image);
      if (url != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile photo updated successfully'),
              backgroundColor: AppTheme.primary,
            ),
          );
        }
      }
    }
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF3B82F6), size: 24),
      title: Text(
        label,
        style: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }
}

class _PremiumLogoutButton extends StatefulWidget {
  final VoidCallback onTap;
  const _PremiumLogoutButton({required this.onTap});

  @override
  State<_PremiumLogoutButton> createState() => _PremiumLogoutButtonState();
}

class _PremiumLogoutButtonState extends State<_PremiumLogoutButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        HapticFeedback.mediumImpact();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFFEF4444), // Red 500
                Color(0xFFF43F5E), // Rose 500 (Deep Coral)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.logout_rounded, color: Colors.white, size: 22),
              const SizedBox(width: 12),
              AnimatedLocalize(
                text: (loc) => loc.logout,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
