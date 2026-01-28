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
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF0F172A), // Deep Navy Slate
          Color(0xFF0F172A), // Mid Transition (Smoother)
          Color(0xFF020617), // Near Black Navy
        ],
        stops: [0.0, 0.4, 1.0],
      ),
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

          // Define Card Gradient based on Bank Name
          LinearGradient gradient = const LinearGradient(
            colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          );

          if (bankName.contains('State Bank')) {
            gradient = const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF2563EB), // Brighter Royal Blue
                Color(0xFF1E40AF), // Rich Blue Depth
                Color(0xFF172554), // Deep Navy Finish
              ],
              stops: [0.0, 0.6, 1.0],
            );
          } else if (bankName.contains('InvisPay')) {
            gradient = const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF14B8A6), // Vibrant Teal
                Color(0xFF0F766E), // Deep Teal
                Color(0xFF064E3B), // Dark Emerald
              ],
              stops: [0.0, 0.5, 1.0],
            );
          } else if (bankName.contains('HDFC')) {
            gradient = const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF334155), // Sophisticated Slate
                Color(0xFF1E293B), // Darker Slate
                Color(0xFF0F172A), // Deep Blue undertone
              ],
              stops: [0.0, 0.5, 1.0],
            );
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: _buildAccountCard(
              context,
              type,
              id,
              bankName,
              gradient: gradient,
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
              color: Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
              // Premium Top Highlight (Inner Glow)
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.08),
                blurRadius: 12,
                spreadRadius: -6,
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
                        color: Colors.white.withValues(alpha: 0.5),
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
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.3),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
