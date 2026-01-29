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
import 'package:invispay/widgets/common/base_screen.dart';

import 'package:uuid/uuid.dart';

class AddCardScreen extends ConsumerStatefulWidget {
  const AddCardScreen({super.key});

  @override
  ConsumerState<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends ConsumerState<AddCardScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;

  // Credit Card Controllers & FocusNodes
  final _creditNumber = TextEditingController();
  final _creditExpiry = TextEditingController();
  final _creditCvv = TextEditingController();
  final _creditName = TextEditingController();

  final _fCreditNumber = FocusNode();
  final _fCreditExpiry = FocusNode();
  final _fCreditCvv = FocusNode();
  final _fCreditName = FocusNode();

  // Debit Card Controllers & FocusNodes
  final _debitNumber = TextEditingController();
  final _debitExpiry = TextEditingController();
  final _debitCvv = TextEditingController();
  final _debitName = TextEditingController();

  final _fDebitNumber = FocusNode();
  final _fDebitExpiry = FocusNode();
  final _fDebitCvv = FocusNode();
  final _fDebitName = FocusNode();

  bool _isDefault = false;
  bool _isValid = false;
  bool _isCreditCard = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabSelection);

    // Listeners for Credit
    _creditNumber.addListener(_validateForm);
    _creditExpiry.addListener(() => _handleExpiryInput(_creditExpiry));
    _creditCvv.addListener(_validateForm);
    _creditName.addListener(_validateForm);

    _fCreditNumber.addListener(() => setState(() {}));
    _fCreditExpiry.addListener(() => setState(() {}));
    _fCreditCvv.addListener(() => setState(() {}));
    _fCreditName.addListener(() => setState(() {}));

    // Listeners for Debit
    _debitNumber.addListener(_validateForm);
    _debitExpiry.addListener(() => _handleExpiryInput(_debitExpiry));
    _debitCvv.addListener(_validateForm);
    _debitName.addListener(_validateForm);

    _fDebitNumber.addListener(() => setState(() {}));
    _fDebitExpiry.addListener(() => setState(() {}));
    _fDebitCvv.addListener(() => setState(() {}));
    _fDebitName.addListener(() => setState(() {}));
  }

  void _handleTabSelection() {
    final isCredit = _tabController.index == 0;

    // Check if the actual index has changed vs our local state
    // We remove the indexIsChanging check to trigger resets INSTANTLY on tap
    if (_isCreditCard != isCredit) {
      // Always reset form states on tab switch for strict isolation
      _resetForm();

      setState(() {
        _isCreditCard = isCredit;
      });
    }
  }

  void _validateForm() {
    final cardController = _isCreditCard ? _creditNumber : _debitNumber;
    final expiryController = _isCreditCard ? _creditExpiry : _debitExpiry;
    final cvvController = _isCreditCard ? _creditCvv : _debitCvv;
    final nameController = _isCreditCard ? _creditName : _debitName;

    final cardValid = cardController.text.length == 16;
    final expiryValid = _isExpiryValid(expiryController.text);
    final cvvValid = cvvController.text.length == 3;
    final nameValid = nameController.text.trim().isNotEmpty &&
        !RegExp(r'[0-9!@#\$%^&*(),.?":{}|<>]').hasMatch(nameController.text);

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

  void _handleExpiryInput(TextEditingController controller) {
    String text = controller.text;
    if (text.length == 2 && !text.contains('/')) {
      controller.text = '$text/';
      controller.selection = TextSelection.fromPosition(
          TextPosition(offset: controller.text.length));
    }
    _validateForm();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _creditNumber.dispose();
    _creditExpiry.dispose();
    _creditCvv.dispose();
    _creditName.dispose();
    _fCreditNumber.dispose();
    _fCreditExpiry.dispose();
    _fCreditCvv.dispose();
    _fCreditName.dispose();

    _debitNumber.dispose();
    _debitExpiry.dispose();
    _debitCvv.dispose();
    _debitName.dispose();
    _fDebitNumber.dispose();
    _fDebitExpiry.dispose();
    _fDebitCvv.dispose();
    _fDebitName.dispose();
    super.dispose();
  }

  void _resetForm() {
    // Clear ALL controllers to ensure strict isolation
    _creditNumber.clear();
    _creditExpiry.clear();
    _creditCvv.clear();
    _creditName.clear();

    _debitNumber.clear();
    _debitExpiry.clear();
    _debitCvv.clear();
    _debitName.clear();

    // Unfocus all fields
    FocusManager.instance.primaryFocus?.unfocus();

    _isDefault = false;
    setState(() {
      _isValid = false;
    });
    // Ensure validation errors are cleared visually
    _formKey.currentState?.reset();
  }

  void _onSave() {
    if (_isValid) {
      final cardController = _isCreditCard ? _creditNumber : _debitNumber;
      final expiryController = _isCreditCard ? _creditExpiry : _debitExpiry;
      final nameController = _isCreditCard ? _creditName : _debitName;

      final newCard = CreditCard(
        id: const Uuid().v4(),
        cardNumber: cardController.text.replaceAll(' ', ''),
        holderName: nameController.text,
        expiryDate: expiryController.text,
        type: _determineCardType(cardController.text),
        color: _determineCardColor(cardController.text),
        isDefault: _isDefault,
      );

      ref.read(cardsProvider.notifier).addCard(newCard);

      ref.read(selectedPaymentAccountProvider.notifier).setAccount({
        'type': 'Card',
        'bankName': newCard.type == CardType.visa ? 'Visa' : 'Mastercard',
        'number': newCard.cardNumber,
        'isCard': true,
        'cardId': newCard.id,
        'isCredit': _isCreditCard,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(AppLocalizations.of(context).translate('action_successful')),
          backgroundColor: AppTheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );

      context.pop();
    }
  }

  CardType _determineCardType(String number) {
    if (number.startsWith('4')) return CardType.visa;
    if (number.startsWith('5')) return CardType.mastercard;
    return CardType.other;
  }

  Color _determineCardColor(String number) {
    if (number.startsWith('4')) return const Color(0xFF1A1F71);
    if (number.startsWith('5')) return const Color(0xFFEB001B);
    return const Color(0xFF1E293B);
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
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
              controller: _tabController,
              indicator: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF0D9488),
                    Color(0xFF059669),
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
              onTap: (index) {
                HapticFeedback.selectionClick();
              },
              tabs: const [
                Tab(text: 'CREDIT CARD'),
                Tab(text: 'DEBIT CARD'),
              ],
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
              _buildStaticTextField(
                controller: _isCreditCard ? _creditNumber : _debitNumber,
                focusNode: _isCreditCard ? _fCreditNumber : _fDebitNumber,
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
                        _buildStaticTextField(
                          controller:
                              _isCreditCard ? _creditExpiry : _debitExpiry,
                          focusNode:
                              _isCreditCard ? _fCreditExpiry : _fDebitExpiry,
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
                        _buildStaticTextField(
                          controller: _isCreditCard ? _creditCvv : _debitCvv,
                          focusNode: _isCreditCard ? _fCreditCvv : _fDebitCvv,
                          hint: '123',
                          obscureText: true,
                          keyboardType: TextInputType.number,
                          maxLength: 3,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          validator: (v) =>
                              (v?.length ?? 0) != 3 ? 'Exactly 3 digits' : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildLabel('CARD HOLDER NAME'),
              _buildStaticTextField(
                controller: _isCreditCard ? _creditName : _debitName,
                focusNode: _isCreditCard ? _fCreditName : _fDebitName,
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

  Widget _buildStaticTextField({
    required TextEditingController controller,
    required String hint,
    FocusNode? focusNode,
    TextInputType? keyboardType,
    bool obscureText = false,
    int? maxLength,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
  }) {
    final isFocused = focusNode?.hasFocus ?? false;

    return Container(
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: !isFocused
            ? Border.all(
                color: Colors.white.withValues(alpha: 0.12), width: 1.5)
            : null,
        gradient: isFocused
            ? const LinearGradient(
                colors: [
                  Color(0xFF0D9488),
                  Color(0xFF059669),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
      ),
      padding: const EdgeInsets.all(1.5), // The Border Width
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A), // Matches background depth
          borderRadius: BorderRadius.circular(14.5), // Inner radius
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.center,
        child: TextFormField(
          controller: controller,
          focusNode: focusNode,
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
      ),
    );
  }
}
