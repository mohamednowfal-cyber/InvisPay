import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:invispay/core/i18n/app_localizations.dart';
import 'package:invispay/core/theme/app_theme.dart';
import 'package:invispay/routes/app_routes.dart';
import 'package:invispay/widgets/common/base_screen.dart';
import 'package:invispay/providers/settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final String _version = '1.0.0 (1)'; // Hardcoded for demo stability

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return BaseScreen(
      appBar: AppBar(
        title: Text(
          l10n.settings,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildSectionHeader(l10n.language),
          _buildListTile(
            icon: Icons.language_rounded,
            title: l10n.language,
            subtitle: l10n.currentLanguageName,
            onTap: () => context.push(AppRoutes.language),
            trailing: const Icon(Icons.arrow_forward_ios_rounded,
                size: 16, color: Colors.white54),
          ),
          const SizedBox(height: 32),

          _buildSectionHeader('SECURITY'),
          _buildSwitchTile(
            title: 'App Lock',
            subtitle: 'Secure with biometric or PIN',
            value: settings.appLock,
            onChanged: (v) => notifier.toggleAppLock(v),
            icon: Icons.fingerprint_rounded,
          ),
          _buildSwitchTile(
            title: 'Auto Logout',
            subtitle: 'Logout after 5 mins of inactivity',
            value: settings.autoLogout,
            onChanged: (v) => notifier.toggleAutoLogout(v),
            icon: Icons.timer_off_outlined,
          ),
          const SizedBox(height: 32),

          _buildSectionHeader('NOTIFICATIONS'), // Dummy logic as requested
          _buildSwitchTile(
            title: 'Push Notifications',
            value: true,
            onChanged: (v) {},
            icon: Icons.notifications_none_rounded,
          ),
          _buildSwitchTile(
            title: 'Transaction Alerts',
            value: true,
            onChanged: (v) {},
            icon: Icons.attach_money_rounded,
          ),
          const SizedBox(height: 32),

          _buildSectionHeader(l10n.privacy),
          _buildSwitchTile(
            title: 'Profile Visibility',
            subtitle: 'Show profile to others',
            value: settings.profileVisibility,
            onChanged: (v) => notifier.toggleProfileVisibility(v),
            icon: Icons.visibility_outlined,
          ),
          const SizedBox(height: 32),

          _buildSectionHeader('GENERAL'),
          _buildListTile(
            icon: Icons.info_outline_rounded,
            title: 'App Version',
            trailing: Text(
              _version,
              style: GoogleFonts.inter(
                color: Colors.white54,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 4),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          color: AppTheme.primary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    String? subtitle,
    required bool value,
    required Function(bool) onChanged,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        activeTrackColor: AppTheme.primary.withValues(alpha: 0.5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        secondary: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppTheme.primary, size: 20),
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: Colors.white,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.white54,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppTheme.primary, size: 20),
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: Colors.white,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.white54,
                ),
              )
            : null,
        trailing: trailing,
      ),
    );
  }
}
