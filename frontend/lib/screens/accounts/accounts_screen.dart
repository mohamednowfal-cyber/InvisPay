import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:invispay/core/i18n/app_localizations.dart';
import 'package:invispay/routes/app_routes.dart';
import 'package:invispay/widgets/common/base_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // Strict Demo Data (as per Task Objective)
    final List<Map<String, dynamic>> displayDocs = [
      {
        'type': 'Savings Account',
        'bankName': 'State Bank of India',
        'number': 'DEMO_SBI_9012',
        'isActive': true,
      },
      {
        'type': 'Digital Wallet',
        'bankName': 'InvisPay',
        'number': 'DEMO_INVIS_1098',
        'isActive': true,
      },
      {
        'type': 'Savings Account',
        'bankName': 'HDFC Bank',
        'number': 'DEMO_HDFC_2345',
        'isActive': true,
      },
    ];

    return BaseScreen(
      appBar: AppBar(
        title: Text(
          l10n.accounts,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false,
      ),
      // Removed local gradient override to match app-wide background
      gradient: null,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        physics: const BouncingScrollPhysics(),
        itemCount: displayDocs.length,
        itemBuilder: (context, index) {
          final data = displayDocs[index];
          String type = data['type'] ?? 'Account';

          if (type.contains('Savings')) {
            type = l10n.savingsAccount;
          } else if (data['type'] == 'Digital Wallet') {
            type = 'Digital Wallet';
          }

          final id = data['number'] ?? 'Unknown';
          final bankName = data['bankName'] ?? 'InvisPay Bank';

          // Define Card Gradient and Shadow based on Bank Name
          LinearGradient gradient = const LinearGradient(
            colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          );
          Color shadowColor = Colors.black.withValues(alpha: 0.4);

          if (bankName.contains('State Bank')) {
            gradient = const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1E3A8A), // Deep Blue
                Color(0xFF1D4ED8), // Royal Blue
              ],
            );
            shadowColor = const Color(0xFF1E3A8A).withValues(alpha: 0.15);
          } else if (bankName.contains('InvisPay')) {
            gradient = const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0F766E), // Dark Teal
                Color(0xFF0D9488), // Primary Teal
              ],
            );
            shadowColor = const Color(0xFF0D9488).withValues(alpha: 0.12);
          } else if (bankName.contains('HDFC')) {
            gradient = const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1E293B), // Slate Slate
                Color(0xFF334155), // Graphite Slate
              ],
            );
            shadowColor = Colors.black.withValues(alpha: 0.2);
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: _buildAccountCard(
              context,
              type,
              id,
              bankName,
              gradient: gradient,
              shadowColor: shadowColor,
              onTap: () => context.push('${AppRoutes.accountDetails}/$id'),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAccountCard(
    BuildContext context,
    String type,
    String id,
    String bankName, {
    required LinearGradient gradient,
    required Color shadowColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent, // Using Container decoration for gradient
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        splashColor: Colors.white.withValues(alpha: 0.1),
        highlightColor: Colors.white.withValues(alpha: 0.05),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
              // Premium Top Highlight (Inner Glow)
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.12),
                blurRadius: 20,
                spreadRadius: -8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    type.contains('Wallet')
                        ? Icons.account_balance_wallet_rounded
                        : Icons.account_balance_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type.toUpperCase(),
                      style: GoogleFonts.outfit(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      bankName,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '**** ${id.split('_').last}',
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.5),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
