import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsState {
  final bool hideBalance;
  final bool appLock;
  final bool autoLogout;
  final bool profileVisibility;
  final bool qrVisibility;
  final String themeMode; // 'light', 'dark'

  SettingsState({
    this.hideBalance = false,
    this.appLock = false,
    this.autoLogout = false,
    this.profileVisibility = true,
    this.qrVisibility = true,
    this.themeMode = 'dark',
  });

  SettingsState copyWith({
    bool? hideBalance,
    bool? appLock,
    bool? autoLogout,
    bool? profileVisibility,
    bool? qrVisibility,
    String? themeMode,
  }) {
    return SettingsState(
      hideBalance: hideBalance ?? this.hideBalance,
      appLock: appLock ?? this.appLock,
      autoLogout: autoLogout ?? this.autoLogout,
      profileVisibility: profileVisibility ?? this.profileVisibility,
      qrVisibility: qrVisibility ?? this.qrVisibility,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}

class SettingsNotifier extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    _loadSettings();
    return SettingsState();
  }

  static const String _hideBalanceKey = 'settings_hide_balance';
  static const String _appLockKey = 'settings_app_lock';
  static const String _autoLogoutKey = 'settings_auto_logout';
  static const String _profileVisibilityKey = 'settings_profile_visibility';
  static const String _qrVisibilityKey = 'settings_qr_visibility';
  // _themeModeKey removed - theme is now locked to dark mode

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    state = SettingsState(
      hideBalance: prefs.getBool(_hideBalanceKey) ?? false,
      appLock: prefs.getBool(_appLockKey) ?? false,
      autoLogout: prefs.getBool(_autoLogoutKey) ?? false,
      profileVisibility: prefs.getBool(_profileVisibilityKey) ?? true,
      qrVisibility: prefs.getBool(_qrVisibilityKey) ?? true,
      themeMode: 'dark', // Always enforce dark mode, ignore saved preference
    );
  }

  Future<void> toggleHideBalance(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hideBalanceKey, value);
    state = state.copyWith(hideBalance: value);
  }

  Future<void> toggleAppLock(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_appLockKey, value);
    state = state.copyWith(appLock: value);
  }

  Future<void> toggleAutoLogout(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoLogoutKey, value);
    state = state.copyWith(autoLogout: value);
  }

  Future<void> toggleProfileVisibility(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_profileVisibilityKey, value);
    state = state.copyWith(profileVisibility: value);
  }

  Future<void> toggleQrVisibility(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_qrVisibilityKey, value);
    state = state.copyWith(qrVisibility: value);
  }

  // Theme mode is now locked to dark mode only
  // Method removed to prevent theme switching
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(() {
  return SettingsNotifier();
});
