import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invispay/core/theme/app_theme.dart';
import 'package:invispay/routes/app_routes.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:invispay/core/i18n/app_localizations.dart';
import 'package:invispay/providers/locale_provider.dart';

class InvisPayApp extends ConsumerWidget {
  const InvisPayApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);

    // Dark Mode is now the only theme - hardcoded for consistency
    return MaterialApp.router(
      title: 'InvisPay',
      theme: AppTheme.darkTheme, // Use dark theme as default
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark, // Always enforce dark mode
      debugShowCheckedModeBanner: false,
      routerConfig: AppRoutes.router,
      locale: locale,
      builder: (context, child) {
        return Directionality(
          textDirection: (locale.languageCode == 'ur')
              ? TextDirection.rtl
              : TextDirection.ltr,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            child: KeyedSubtree(
              key: ValueKey(locale.languageCode),
              child: child!,
            ),
          ),
        );
      },
      supportedLocales:
          supportedLanguages.map((lang) => Locale(lang.code)).toList(),
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
