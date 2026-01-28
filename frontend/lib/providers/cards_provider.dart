import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invispay/models/card_model.dart';

class CardsNotifier extends Notifier<List<CreditCard>> {
  @override
  List<CreditCard> build() {
    _loadInitialData();
    return state;
  }

  void _loadInitialData() {
    state = [
      CreditCard(
        id: 'demo_card_1',
        cardNumber: '4532123456788812',
        holderName: 'InvisPay User',
        expiryDate: '12/28',
        type: CardType.visa,
        color: const Color(0xFF1E293B), // Premium Slate
        isDefault: true,
      ),
    ];
  }

  void addCard(CreditCard card) {
    if (card.isDefault) {
      state = [
        for (final c in state) c.copyWith(isDefault: false),
        card,
      ];
    } else {
      state = [...state, card];
    }
  }

  void removeCard(String id) {
    state = state.where((c) => c.id != id).toList();
  }

  void setDefault(String id) {
    state = [
      for (final c in state)
        if (c.id == id)
          c.copyWith(isDefault: true)
        else
          c.copyWith(isDefault: false)
    ];
  }
}

final cardsProvider = NotifierProvider<CardsNotifier, List<CreditCard>>(() {
  return CardsNotifier();
});
