import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:invispay/widgets/common/animated_localize.dart';
import 'package:invispay/core/theme/app_theme.dart';
import 'package:invispay/models/card_model.dart';
import 'package:invispay/providers/cards_provider.dart';
import 'package:invispay/providers/payment_provider.dart';
import 'package:invispay/routes/app_routes.dart';
import 'package:invispay/widgets/common/base_screen.dart';

import 'package:uuid/uuid.dart';

class AddCardScreen extends ConsumerStatefulWidget {
  const AddCardScreen({super.key});

  @override
  ConsumerState<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends ConsumerState<AddCardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _holderNameController = TextEditingController();
  bool _isDefault = false;
  bool _isValid = false;
  bool _isCreditCard = true; // Internal state for card type

  @override
  void initState() {
    super.initState();
    _cardNumberController.addListener(_validateForm);
    _expiryController.addListener(_handleExpiryInput);
    _cvvController.addListener(_validateForm);
    _holderNameController.addListener(_validateForm);
  }

  void _validateForm() {
    final cardValid = _cardNumberController.text.length == 16;
    final expiryValid = _isExpiryValid(_expiryController.text);
    final cvvValid = _cvvController.text.length == 3;
    final nameValid = _holderNameController.text.trim().isNotEmpty &&
        !RegExp(r'[0-9!@#\$%^&*(),.?":{}|<>]')
            .hasMatch(_holderNameController.text);

    setState(() {
      _isValid = cardValid && expiryValid && cvvValid && nameValid;
    });
  }

  bool _isExpiryValid(String value) {
    if (value.length != 5) return false;
    final parts = value.split('/');
    if (parts.length != 2) return false;

    final month = int.tryParse(parts[0]);
    final year = int.tryParse(parts[1]);

    if (month == null || year == null) return false;
    if (month < 1 || month > 12) return false;

    final now = DateTime.now();
    final currentYearShort = now.year % 100;
    final currentMonth = now.month;

    if (year < currentYearShort) return false;
    if (year == currentYearShort && month < currentMonth) return false;

    return true;
  }

  void _handleExpiryInput() {
    String text = _expiryController.text;
    if (text.length == 2 && !_expiryController.text.contains('/')) {
      _expiryController.text = '$text/';
      _expiryController.selection = TextSelection.fromPosition(
          TextPosition(offset: _expiryController.text.length));
    }
    _validateForm();
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _holderNameController.dispose();
    super.dispose();
  }

  void _onSave() {
    if (_isValid) {
      final newCard = CreditCard(
        id: const Uuid().v4(),
        cardNumber: _cardNumberController.text.replaceAll(' ', ''),
        holderName: _holderNameController.text,
        expiryDate: _expiryController.text,
        type: _determineCardType(_cardNumberController.text),
        color: _determineCardColor(_cardNumberController.text),
        isDefault: _isDefault,
      );

      ref.read(cardsProvider.notifier).addCard(newCard);

      // Pre-select this new card for payment
      ref.read(selectedPaymentAccountProvider.notifier).setAccount({
        'type': 'Card',
        'bankName': newCard.type == CardType.visa ? 'Visa' : 'Mastercard',
        'number': newCard.cardNumber,
        'isCard': true,
        'cardId': newCard.id,
        'isCredit': _isCreditCard,
      });

      // Show success and move to payment flow
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(AppLocalizations.of(context).translate('action_successful')),
          backgroundColor: AppTheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Navigate to payment screen directly
      context.pushReplacement(AppRoutes.makeTransaction);
    }
  }

  CardType _determineCardType(String number) {
    if (number.startsWith('4')) return CardType.visa;
    if (number.startsWith('5')) return CardType.mastercard;
    return CardType.other;
  }

  Color _determineCardColor(String number) {
    if (number.startsWith('4')) return const Color(0xFF1A1F71); // Visa Blue
    if (number.startsWith('5')) return const Color(0xFFEB001B); // Master Red
    return const Color(0xFF1E293B); // Default Slate
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: BaseScreen(
        appBar: AppBar(
          title: AnimatedLocalize(
            text: (loc) => loc.translate('add_new_card'),
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          centerTitle: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(64),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: TabBar(
                indicator: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF0D9488), // Teal 600
                      Color(0xFF059669), // Green 600
                    ],
                    begin: AlignmentDirectional.topStart,
                    end: AlignmentDirectional.bottomEnd,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0D9488).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white30,
                labelStyle: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
                unselectedLabelStyle: GoogleFonts.outfit(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'CREDIT CARD'),
                  Tab(text: 'DEBIT CARD'),
                ],
                onTap: (index) {
                  setState(() {
                    _isCreditCard = index == 0;
                  });
                  HapticFeedback.selectionClick();
                },
              ),
            ),
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel('CARD NUMBER'),
                _buildTextField(
                  controller: _cardNumberController,
                  hint: '0000 0000 0000 0000',
                  keyboardType: TextInputType.number,
                  maxLength: 16,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) => (v?.length ?? 0) != 16
                      ? 'Card number must be exactly 16 digits'
                      : null,
                ),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('EXPIRY DATE'),
                          _buildTextField(
                            controller: _expiryController,
                            hint: 'MM/YY',
                            keyboardType: TextInputType.number,
                            maxLength: 5,
                            validator: (v) => !_isExpiryValid(v ?? '')
                                ? 'Enter a valid expiry date (MM/YY)'
                                : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('CVV'),
                          _buildTextField(
                            controller: _cvvController,
                            hint: '123',
                            obscureText: true,
                            keyboardType: TextInputType.number,
                            maxLength: 3,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            validator: (v) => (v?.length ?? 0) != 3
                                ? 'Exactly 3 digits'
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildLabel('CARD HOLDER NAME'),
                _buildTextField(
                  controller: _holderNameController,
                  hint: 'JONATHAN DOE',
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                  ],
                  validator: (v) => (v?.trim().isEmpty ?? true)
                      ? 'Enter card holder name'
                      : null,
                ),
                const SizedBox(height: 32),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Set as Default Card',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  value: _isDefault,
                  onChanged: (v) => setState(() => _isDefault = v),
                  activeThumbColor: AppTheme.primary,
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: _isValid ? 1.0 : 0.5,
                    child: ElevatedButton(
                      onPressed: _isValid ? _onSave : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            AppTheme.primary.withValues(alpha: 0.5),
                        disabledForegroundColor:
                            Colors.white.withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: _isValid ? 4 : 0,
                      ),
                      child: Text(
                        'Save Card',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: Colors.white54,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    bool obscureText = false,
    int? maxLength,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Container(
      height: 64, // Consistent premium height for world-class touch targets
      decoration: BoxDecoration(
        color: Colors.transparent, // Clean, single-layer surface
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: Alignment.center,
      child: TextFormField(
        controller: controller,
        textAlignVertical: TextAlignVertical.center,
        style: GoogleFonts.outfit(
            color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
        keyboardType: keyboardType,
        obscureText: obscureText,
        maxLength: maxLength,
        textCapitalization: textCapitalization,
        validator: validator,
        inputFormatters: inputFormatters,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: GoogleFonts.outfit(color: Colors.white24, fontSize: 15),
          counterText: '',
          isDense: true,
          contentPadding: EdgeInsets.zero,
          errorStyle: const TextStyle(height: 0.8, fontSize: 10),
          filled: false,
          fillColor: Colors.transparent,
        ),
      ),
    );
  }
}
