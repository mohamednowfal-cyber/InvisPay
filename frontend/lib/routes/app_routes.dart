import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:invispay/screens/auth/login_screen.dart';
import 'package:invispay/screens/auth/signup_screen.dart';
import 'package:invispay/screens/auth/splash_screen.dart';
import 'package:invispay/screens/home/home_screen.dart';
import 'package:invispay/screens/kyc/kyc_status_screen.dart';
import 'package:invispay/screens/kyc/kyc_details_screen.dart';
import 'package:invispay/screens/kyc/kyc_document_upload_screen.dart';
import 'package:invispay/screens/transactions/payments_screen.dart';
import 'package:invispay/screens/transactions/transaction_history_screen.dart';
import 'package:invispay/screens/profile/profile_screen.dart';
import 'package:invispay/screens/profile/settings_screen.dart';
import 'package:invispay/screens/profile/language_selector_screen.dart';
import 'package:invispay/screens/profile/onboarding_language_screen.dart';
import 'package:invispay/screens/accounts/accounts_screen.dart';
import 'package:invispay/screens/accounts/account_details_screen.dart';
import 'package:invispay/screens/profile/my_qr_codes_screen.dart';
import 'package:invispay/screens/profile/autopay_screen.dart';
import 'package:invispay/screens/accounts/account_transactions_screen.dart';
import 'package:invispay/widgets/common/scaffold_with_nav_bar.dart';
import 'package:invispay/screens/cards/credit_cards_screen.dart';
import 'package:invispay/screens/cards/add_card_screen.dart';
import 'package:invispay/screens/lite/invispay_lite_screen.dart';
import 'package:invispay/screens/lite/lite_add_money_screen.dart';
import 'package:invispay/screens/profile/profile_details_screen.dart';
import 'package:invispay/screens/lite/lite_withdraw_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>();

class AppRoutes {
  static const String login = '/login';
  static const String signup = '/signup';
  static const String onboardingLanguage = '/onboarding/language';
  static const String home = '/home';
  static const String kyc = '/kyc';
  static const String kycStatus = '/kyc'; // Alias for kyc route
  static const String accounts = '/accounts';
  static const String accountDetails = '/accounts/details'; // New detail route
  static const String history = '/history'; // Replaces transactions as tab
  static const String makeTransaction = '/transactions/new'; // Standalone
  static const String profile = '/profile';
  static const String profileDetails = '/profile/details';
  static const String kycDetails = '/kyc/details';
  static const String kycUpload = '/kyc/upload';
  static const String requestMoney = '/transactions/request';
  static const String language = '/profile/language';
  static const String myQrCodes = '/profile/qr-codes';
  static const String autopay = '/profile/autopay';
  static const String creditCards = '/cards';
  static const String addCard = '/cards/add';
  static const String accountTransactions = '/accounts/transactions/:accountId';
  static const String invispayLite = '/profile/invispay-lite';
  static const String liteAddMoney = '/profile/invispay-lite/add-money';
  static const String liteWithdraw = '/profile/invispay-lite/withdraw';
  // Helper for Bank-Grade Transitions (Slide + Fade)
  static CustomTransitionPage _buildPageWithTransition(
      BuildContext context, GoRouterState state, Widget child) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 200),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var slideTween = Tween(begin: const Offset(0.05, 0), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOut));

        // Fade in
        var fadeTween = Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut));

        return FadeTransition(
          opacity: animation.drive(fadeTween),
          child: SlideTransition(
            position: animation.drive(slideTween),
            child: child,
          ),
        );
      },
    );
  }

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) =>
            _buildPageWithTransition(context, state, const SplashScreen()),
      ),
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) =>
            _buildPageWithTransition(context, state, const SplashScreen()),
      ),
      GoRoute(
        path: login,
        pageBuilder: (context, state) =>
            _buildPageWithTransition(context, state, const LoginScreen()),
      ),
      GoRoute(
        path: signup,
        pageBuilder: (context, state) =>
            _buildPageWithTransition(context, state, const SignupScreen()),
      ),
      GoRoute(
        path: onboardingLanguage,
        pageBuilder: (context, state) => _buildPageWithTransition(
            context, state, const OnboardingLanguageScreen()),
      ),

      // Main App Shell
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return ScaffoldWithNavBar(child: child);
        },
        routes: [
          GoRoute(
            path: home,
            pageBuilder: (context, state) =>
                _buildPageWithTransition(context, state, const HomeScreen()),
          ),
          GoRoute(
            path: accounts,
            pageBuilder: (context, state) => _buildPageWithTransition(
                context, state, const AccountsScreen()),
          ),
          GoRoute(
            path: '$accountDetails/:id',
            parentNavigatorKey: _rootNavigatorKey,
            pageBuilder: (context, state) {
              final id = state.pathParameters['id'] ?? 'unknown';
              return _buildPageWithTransition(
                  context, state, AccountDetailsScreen(accountId: id));
            },
          ),
          GoRoute(
            path: history,
            pageBuilder: (context, state) => _buildPageWithTransition(
                context, state, const TransactionHistoryScreen()),
          ),
          GoRoute(
            path: profile,
            pageBuilder: (context, state) =>
                _buildPageWithTransition(context, state, const ProfileScreen()),
          ),
          GoRoute(
            path: profileDetails,
            parentNavigatorKey: _rootNavigatorKey,
            pageBuilder: (context, state) => _buildPageWithTransition(
                context, state, const ProfileDetailsScreen()),
          ),
        ],
      ),

      // Standalone Routes (Full Screen + Back Button)
      GoRoute(
        path: makeTransaction,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _buildPageWithTransition(
            context, state, const PaymentsScreen(initialTabIndex: 0)),
      ),
      GoRoute(
        path: requestMoney,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _buildPageWithTransition(
            context, state, const PaymentsScreen(initialTabIndex: 1)),
      ),
      GoRoute(
        path: kyc,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) =>
            _buildPageWithTransition(context, state, const KycStatusScreen()),
      ),
      GoRoute(
        path: kycDetails,
        parentNavigatorKey: _rootNavigatorKey,
        name: 'kycDetails',
        pageBuilder: (context, state) =>
            _buildPageWithTransition(context, state, const KycDetailsScreen()),
      ),
      GoRoute(
        path: kycUpload,
        parentNavigatorKey: _rootNavigatorKey,
        name: 'kycUpload',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return _buildPageWithTransition(
            context,
            state,
            KycDocumentUploadScreen(
              fullName: extra['fullName'] ?? '',
              idType: extra['idType'] ?? '',
              idNumber: extra['idNumber'] ?? '',
            ),
          );
        },
      ),
      GoRoute(
        path: '/profile/settings',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) =>
            _buildPageWithTransition(context, state, const SettingsScreen()),
      ),
      GoRoute(
        path: language,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _buildPageWithTransition(
            context, state, const LanguageSelectorScreen()),
      ),
      GoRoute(
        path: autopay,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) =>
            _buildPageWithTransition(context, state, const AutopayScreen()),
      ),
      GoRoute(
        path: myQrCodes,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) =>
            _buildPageWithTransition(context, state, const MyQrCodesScreen()),
      ),
      GoRoute(
        path: accountTransactions,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final accountId = state.pathParameters['accountId']!;
          return _buildPageWithTransition(
            context,
            state,
            AccountTransactionsScreen(accountId: accountId),
          );
        },
      ),
      GoRoute(
        path: creditCards,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) =>
            _buildPageWithTransition(context, state, const CreditCardsScreen()),
      ),
      GoRoute(
        path: addCard,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) =>
            _buildPageWithTransition(context, state, const AddCardScreen()),
      ),
      GoRoute(
        path: invispayLite,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _buildPageWithTransition(
            context, state, const InvispayLiteScreen()),
      ),
      GoRoute(
        path: liteAddMoney,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _buildPageWithTransition(
            context, state, const LiteAddMoneyScreen()),
      ),
      GoRoute(
        path: liteWithdraw,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _buildPageWithTransition(
            context, state, const LiteWithdrawScreen()),
      ),
    ],
  );
}
