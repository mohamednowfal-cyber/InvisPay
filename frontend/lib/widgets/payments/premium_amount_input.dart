import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:invispay/widgets/common/animated_localize.dart';

class PremiumAmountInput extends StatelessWidget {
  final TextEditingController controller;
  final String Function(AppLocalizations) label;

  const PremiumAmountInput({
    super.key,
    required this.controller,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: AnimatedLocalize(
            text: (loc) => label(loc).toUpperCase(),
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 52, horizontal: 28),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.light
                ? Colors.white
                : const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.light
                  ? const Color(0xFFE2E8F0)
                  : Colors.white.withValues(alpha: 0.08),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '₹',
                  style: GoogleFonts.outfit(
                    fontSize: 32,
                    fontWeight: FontWeight.w400,
                    color: Theme.of(context).brightness == Brightness.light
                        ? const Color(0xFF64748B)
                        : Colors.white.withValues(alpha: 0.4),
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: IntrinsicWidth(
                    child: TextField(
                      controller: controller,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      style: GoogleFonts.outfit(
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.light
                            ? const Color(0xFF0F172A)
                            : Colors.white,
                        letterSpacing: -2,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: '0',
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                        isCollapsed: true,
                        filled: false,
                        fillColor: Colors.transparent,
                      ),
                      textAlign: TextAlign.center,
                      cursorColor: Colors.white,
                      cursorWidth: 2,
                      autofocus: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
