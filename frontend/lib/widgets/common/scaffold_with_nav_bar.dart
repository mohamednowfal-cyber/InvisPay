import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:invispay/core/i18n/app_localizations.dart';
import 'package:invispay/core/theme/app_theme.dart';
import 'package:invispay/routes/app_routes.dart';

class ScaffoldWithNavBar extends StatelessWidget {
  final Widget child;

  const ScaffoldWithNavBar({required this.child, super.key});

  void _onItemTapped(int index, BuildContext context) {
    HapticFeedback.lightImpact(); // Bank-grade haptic feedback
    switch (index) {
      case 0:
        GoRouter.of(context).go(AppRoutes.home);
        break;
      case 1:
        GoRouter.of(context).go(AppRoutes.accounts);
        break;
      case 2:
        GoRouter.of(context).go(AppRoutes.history);
        break;
      case 3:
        GoRouter.of(context).go(AppRoutes.profile);
        break;
    }
  }

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith(AppRoutes.home)) return 0;
    if (location.startsWith(AppRoutes.accounts)) return 1;
    if (location.startsWith(AppRoutes.history)) return 2;
    if (location.startsWith(AppRoutes.profile)) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    // Custom PopScope implementation for Back -> Home logic
    return PopScope(
      canPop: false, // Handle pop manually
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        final int currentIndex = _calculateSelectedIndex(context);
        if (currentIndex != 0) {
          // If not on Home tab, go to Home
          HapticFeedback.lightImpact();
          GoRouter.of(context).go(AppRoutes.home);
        } else {
          // If on Home tab, exit app
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: child,
        bottomNavigationBar: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.02),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: BottomNavigationBar(
            key: ValueKey(AppLocalizations.of(context).locale.languageCode),
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.home_filled),
                label: AppLocalizations.of(context).home,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.account_balance_wallet_rounded),
                label: AppLocalizations.of(context).accounts,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.history_edu_rounded),
                label: AppLocalizations.of(context).historyLabel,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.person_rounded),
                label: AppLocalizations.of(context).profile,
              ),
            ],
            currentIndex: _calculateSelectedIndex(context),
            onTap: (index) => _onItemTapped(index, context),
            type: BottomNavigationBarType.fixed,
            backgroundColor: AppTheme.surface,
            selectedItemColor: AppTheme.primary,
            unselectedItemColor: Colors.white.withValues(alpha: 0.4),
            showUnselectedLabels: true,
            selectedFontSize: 11,
            unselectedFontSize: 11,
            elevation: 20,
          ),
        ),
      ),
    );
  }
}
