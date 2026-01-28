import 'package:flutter/material.dart';

enum CardType { visa, mastercard, rupay, amex, other }

class CreditCard {
  final String id;
  final String cardNumber; // stored masked or encrypted in real app
  final String holderName;
  final String expiryDate;
  final CardType type;
  final Color color;
  final bool isDefault;

  CreditCard({
    required this.id,
    required this.cardNumber,
    required this.holderName,
    required this.expiryDate,
    required this.type,
    required this.color,
    this.isDefault = false,
  });

  String get maskedNumber {
    if (cardNumber.length < 4) return cardNumber;
    return '**** ${cardNumber.substring(cardNumber.length - 4)}';
  }

  CreditCard copyWith({
    String? id,
    String? cardNumber,
    String? holderName,
    String? expiryDate,
    CardType? type,
    Color? color,
    bool? isDefault,
  }) {
    return CreditCard(
      id: id ?? this.id,
      cardNumber: cardNumber ?? this.cardNumber,
      holderName: holderName ?? this.holderName,
      expiryDate: expiryDate ?? this.expiryDate,
      type: type ?? this.type,
      color: color ?? this.color,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
