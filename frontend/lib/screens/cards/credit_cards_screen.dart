import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:invispay/widgets/common/animated_localize.dart';
import 'package:invispay/core/theme/app_theme.dart';
import 'package:invispay/models/card_model.dart';
import 'package:invispay/providers/cards_provider.dart';
import 'package:invispay/routes/app_routes.dart';
import 'package:invispay/widgets/common/base_screen.dart';
import 'package:invispay/providers/payment_provider.dart';

class CreditCardsScreen extends ConsumerWidget {
  const CreditCardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cards = ref.watch(cardsProvider);

    return BaseScreen(
      appBar: AppBar(
        title: AnimatedLocalize(
          text: (loc) => loc.translate('pay_cards'),
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.addCard),
            icon: const Icon(Icons.add_card_rounded, color: AppTheme.primary),
          ),
        ],
      ),
      child: cards.isEmpty
          ? _buildEmptyState(context, l10n)
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: cards.length,
              itemBuilder: (context, index) {
                final card = cards[index];
                return _buildCardItem(context, ref, card);
              },
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.credit_card_off_rounded,
              size: 64, color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text(
            l10n.translate('no_cards_added'),
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => context.push(AppRoutes.addCard),
            child: Text(
              l10n.translate('add_new_card'),
              style: GoogleFonts.inter(
                  color: AppTheme.primary, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardItem(BuildContext context, WidgetRef ref, CreditCard card) {
    return Dismissible(
      key: Key(card.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        ref.read(cardsProvider.notifier).removeCard(card.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(AppLocalizations.of(context).translate('card_removed'))),
        );
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(24),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_outline_rounded,
            color: Colors.redAccent, size: 28),
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          // Pre-select this card for payment
          ref.read(selectedPaymentAccountProvider.notifier).setAccount({
            'type': 'Card',
            'bankName': card.type == CardType.visa ? 'Visa' : 'Mastercard',
            'number': card.cardNumber,
            'isCard': true,
            'cardId': card.id,
          });
          // Navigate to Payment Screen (Send Money Tab)
          context.push(AppRoutes.makeTransaction);
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                card.color,
                Color.lerp(card.color, Colors.black, 0.2)!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: card.color.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildCardIcon(card.type),
                  if (card.isDefault)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'DEFAULT',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                card.maskedNumber,
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CARD HOLDER',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: Colors.white54,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        card.holderName.toUpperCase(),
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'EXPIRES',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: Colors.white54,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        card.expiryDate,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardIcon(CardType type) {
    IconData icon;
    switch (type) {
      case CardType.visa:
        icon = Icons.credit_card; // Replace with actual asset in real app
        break;
      case CardType.mastercard:
        icon = Icons.credit_card; // Replace with asset
        break;
      default:
        icon = Icons.credit_card;
    }
    return Icon(icon, color: Colors.white, size: 32);
  }
}
