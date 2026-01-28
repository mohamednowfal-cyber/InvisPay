import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:invispay/core/theme/app_theme.dart';
import 'package:invispay/widgets/common/animated_localize.dart';

class AccountSelector extends StatelessWidget {
  final String Function(AppLocalizations)? label;
  final String Function(AppLocalizations) accountType;
  final String accountNumber;
  final IconData? icon;
  final VoidCallback onTap;

  const AccountSelector({
    super.key,
    this.label,
    required this.accountType,
    required this.accountNumber,
    this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 4, bottom: 16),
            child: AnimatedLocalize(
              text: (loc) => label!(loc).toUpperCase(),
              style: GoogleFonts.inter(
                color: Theme.of(context).brightness == Brightness.light
                    ? const Color(0xFF94A3B8)
                    : Colors.white.withValues(alpha: 0.3),
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.08),
                  Colors.white.withValues(alpha: 0.03),
                ],
                begin: AlignmentDirectional.topStart,
                end: AlignmentDirectional.bottomEnd,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon ?? Icons.account_balance_rounded,
                      color: AppTheme.primary, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedLocalize(
                        text: accountType,
                        style: GoogleFonts.inter(
                          color:
                              Theme.of(context).brightness == Brightness.light
                                  ? const Color(0xFF0F172A)
                                  : Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        accountNumber,
                        style: GoogleFonts.inter(
                          color:
                              Theme.of(context).brightness == Brightness.light
                                  ? const Color(0xFF94A3B8)
                                  : Colors.white.withValues(alpha: 0.3),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.keyboard_arrow_down_rounded,
                    color: Theme.of(context).brightness == Brightness.light
                        ? const Color(0xFF94A3B8)
                        : Colors.white.withValues(alpha: 0.2)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
