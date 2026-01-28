import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:invispay/core/theme/app_theme.dart';
import 'package:invispay/widgets/common/animated_localize.dart';

class RecipientSelector extends StatelessWidget {
  final Function(String) onRecipientSelected;
  final String selectedRecipient;

  const RecipientSelector({
    super.key,
    required this.onRecipientSelected,
    this.selectedRecipient = '',
  });

  @override
  Widget build(BuildContext context) {
    final bool isLight = Theme.of(context).brightness == Brightness.light;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Premium Rebuilt Search Bar (Single Layer)
        TextField(
          onChanged: onRecipientSelected,
          textAlignVertical: TextAlignVertical.center,
          cursorColor: AppTheme.primary,
          cursorWidth: 1.5,
          style: GoogleFonts.inter(
            color: isLight ? const Color(0xFF0F172A) : Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context).recipientSearch,
            hintStyle: GoogleFonts.inter(
              color: isLight
                  ? const Color(0xFF94A3B8)
                  : Colors.white.withValues(alpha: 0.4),
              fontSize: 15,
            ),
            prefixIcon: const Padding(
              padding: EdgeInsetsDirectional.only(start: 22, end: 14),
              child: Icon(
                Icons.search_rounded,
                color: Color(0xFF94A3B8),
                size: 22,
              ),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 40),
            filled: true,
            fillColor: isLight
                ? const Color(0xFFF1F5F9)
                : Colors.white.withValues(alpha: 0.05),
            contentPadding: const EdgeInsets.symmetric(vertical: 22),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide(
                color: isLight
                    ? const Color(0xFFE2E8F0)
                    : Colors.white.withValues(alpha: 0.1),
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide(
                color: isLight
                    ? const Color(0xFFE2E8F0)
                    : Colors.white.withValues(alpha: 0.1),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: const BorderSide(
                color: AppTheme.primary,
                width: 1.5,
              ),
            ),
          ),
        ),

        const SizedBox(height: 32),

        // Recent Contacts (Clean Chips)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AnimatedLocalize(
              text: (loc) => loc.recentlyPaid.toUpperCase(),
              style: GoogleFonts.inter(
                color: isLight
                    ? const Color(0xFF94A3B8)
                    : Colors.white.withValues(alpha: 0.3),
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            Icon(Icons.more_horiz,
                color: isLight
                    ? const Color(0xFFCBD5E1)
                    : Colors.white.withValues(alpha: 0.2)),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            children: [
              _buildRecentChip('Rahul', Icons.person, const Color(0xFF6366F1)),
              _buildRecentChip(
                  'Anjali', Icons.person_3, const Color(0xFFEC4899)),
              _buildRecentChip(
                  'Vikram', Icons.person_2, const Color(0xFF10B981)),
              _buildRecentChip(
                  'Sneha', Icons.person_4, const Color(0xFFF59E0B)),
              _buildRecentChip('Karan', Icons.person, const Color(0xFF8B5CF6)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentChip(String name, IconData icon, Color accentColor) {
    final isSelected = selectedRecipient == name;

    return GestureDetector(
      onTap: () => onRecipientSelected(name),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsetsDirectional.only(end: 20),
        width: 72,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppTheme.primary : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                    width: 1,
                  ),
                ),
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: accentColor.withValues(alpha: 0.1),
                  child: Icon(icon, color: accentColor, size: 24),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
