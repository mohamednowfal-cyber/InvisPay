import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:invispay/core/theme/app_theme.dart';
import 'package:invispay/routes/app_routes.dart';
import 'package:invispay/services/auth_service.dart';
import 'package:invispay/services/database_service.dart';
import 'package:invispay/widgets/common/base_screen.dart';
import 'package:invispay/widgets/common/animated_localize.dart';
import 'package:invispay/widgets/payments/premium_amount_input.dart';
import 'package:invispay/widgets/payments/recipient_selector.dart';
import 'package:invispay/widgets/payments/account_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invispay/providers/cards_provider.dart';
import 'package:invispay/providers/lite_provider.dart';
import 'package:invispay/services/lite_service.dart';
import 'package:invispay/models/card_model.dart';
import 'package:invispay/providers/payment_provider.dart';

class PaymentsScreen extends ConsumerStatefulWidget {
  final int initialTabIndex;
  const PaymentsScreen({super.key, this.initialTabIndex = 0});

  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen> {
  // Send Money tab state
  late final TextEditingController _sendAmountController;
  late final TextEditingController _sendNoteController;
  String _sendSelectedRecipient = '';
  double _sendAmount = 0.0;

  // Request Money tab state
  late final TextEditingController _requestAmountController;
  late final TextEditingController _requestNoteController;
  String _requestSelectedRecipient = '';
  double _requestAmount = 0.0;

  final AuthService _auth = AuthService();
  final DatabaseService _db = DatabaseService();
  String _kycStatus = 'pending';

  // New: From Account State managed by selectedPaymentAccountProvider

  @override
  void initState() {
    super.initState();
    // Send tab controllers
    _sendAmountController = TextEditingController();
    _sendNoteController = TextEditingController();
    _sendAmountController.addListener(_updateSendAmount);

    // Request tab controllers
    _requestAmountController = TextEditingController();
    _requestNoteController = TextEditingController();
    _requestAmountController.addListener(_updateRequestAmount);

    _fetchKycStatus();
  }

  void _updateSendAmount() {
    setState(() {
      _sendAmount = double.tryParse(_sendAmountController.text) ?? 0.0;
    });
  }

  void _updateRequestAmount() {
    setState(() {
      _requestAmount = double.tryParse(_requestAmountController.text) ?? 0.0;
    });
  }

  Future<void> _fetchKycStatus() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await _db.getUserData(user.uid);
      if (mounted && doc != null) {
        setState(() {
          _kycStatus =
              (doc.data() as Map<String, dynamic>?)?['kycStatus'] ?? 'pending';
        });
      }
    }
  }

  @override
  void dispose() {
    _sendAmountController.dispose();
    _sendNoteController.dispose();
    _requestAmountController.dispose();
    _requestNoteController.dispose();
    super.dispose();
  }

  void _onConfirmSend() async {
    if (_kycStatus != 'verified') {
      _showKycRequiredDialog();
      return;
    }
    final l10n = AppLocalizations.of(context);

    final selectedAccount = ref.read(selectedPaymentAccountProvider);

    // Check if paying with InvisPay Lite
    if (selectedAccount['type'] == 'Lite Wallet') {
      final balance = selectedAccount['balance'] as double? ?? 0.0;
      if (_sendAmount > balance) {
        _showLiteBalanceError();
        return;
      }

      _showProcessingDialog(l10n.processingSend);

      final auth = AuthService();
      final uid = auth.currentUser?.uid ?? 'demo';
      final note = _sendNoteController.text.trim();

      await LiteService().payWithLite(
        uid,
        _sendAmount,
        note.isNotEmpty ? note : 'Paid via InvisPay Lite',
      );
      return;
    }

    // Check if paying with card
    if (selectedAccount['isCard'] == true) {
      _showCvvPrompt(l10n);
      return;
    }
    // Show premium processing UI
    _showProcessingDialog(l10n.processingSend);
  }

  void _showLiteBalanceError() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Insufficient Lite Balance',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        content: Text(
          'You don\'t have enough balance in your InvisPay Lite wallet. Please add money or use another account.',
          style: GoogleFonts.inter(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.push(AppRoutes.liteAddMoney);
            },
            child: Text(
              'Add Money',
              style: GoogleFonts.inter(
                color: const Color(0xFF10B981),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCvvPrompt(AppLocalizations l10n) {
    final cvvController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Security Check',
          style: GoogleFonts.outfit(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter CVV to confirm payment',
              style: GoogleFonts.inter(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: cvvController,
              keyboardType: TextInputType.number,
              maxLength: 3,
              obscureText: true,
              style: GoogleFonts.outfit(
                  color: Colors.white, fontSize: 18, letterSpacing: 4),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.black26,
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                hintText: '•••',
                hintStyle: const TextStyle(color: Colors.white24),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                Text('Cancel', style: GoogleFonts.inter(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (cvvController.text.length == 3) {
                _showProcessingDialog(l10n.processingSend);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _onConfirmRequest() async {
    if (_kycStatus != 'verified') {
      _showKycRequiredDialog();
      return;
    }
    final l10n = AppLocalizations.of(context);
    _showProcessingDialog(l10n.processingRequest);
  }

  void _showKycRequiredDialog() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        title: Text(l10n.verificationRequired,
            style: GoogleFonts.outfit(
                color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          l10n.kycRequiredMsg,
          style: GoogleFonts.inter(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.maybeLater,
                style: const TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.push(AppRoutes.kyc);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: Text(l10n.completeKyc),
          ),
        ],
      ),
    );
  }

  void _showProcessingDialog(String message) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppTheme.primary),
              const SizedBox(height: 24),
              Text(
                message,
                style: GoogleFonts.inter(
                    color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pop(context);
        context.go(AppRoutes.home);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.actionSuccessful),
            backgroundColor: AppTheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: widget.initialTabIndex,
      child: BaseScreen(
        appBar: AppBar(
          title: AnimatedLocalize(
            text: (loc) => loc.transferMoney,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              letterSpacing: -0.5,
            ),
          ),
          centerTitle: false,
          elevation: 0,
          backgroundColor: Colors.transparent,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.light
                    ? const Color(0xFFF1F5F9)
                    : Colors.white.withValues(alpha: 0.05),
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
                unselectedLabelColor:
                    Theme.of(context).brightness == Brightness.light
                        ? const Color(0xFF64748B)
                        : Colors.white30,
                labelStyle: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 0.8,
                ),
                unselectedLabelStyle: GoogleFonts.outfit(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(
                    child: AnimatedLocalize(
                      text: (loc) => loc.send.toUpperCase(),
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  Tab(
                    child: AnimatedLocalize(
                      text: (loc) => loc.request.toUpperCase(),
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        child: TabBarView(
          children: [
            _buildSendTab(),
            _buildRequestTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildSendTab() {
    final selectedAccount = ref.watch(selectedPaymentAccountProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          RecipientSelector(
            onRecipientSelected: (val) =>
                setState(() => _sendSelectedRecipient = val),
            selectedRecipient: _sendSelectedRecipient,
          ),
          const SizedBox(height: 40),
          PremiumAmountInput(
            controller: _sendAmountController,
            label: (loc) => loc.amountToSend,
          ),
          const SizedBox(height: 40),
          AccountSelector(
            label: (loc) => loc.fromAccount,
            accountType: (loc) {
              if (selectedAccount['isCard'] == true) {
                return '${selectedAccount['bankName']} Card';
              }
              if (selectedAccount['type'] == 'Lite Wallet') {
                return 'InvisPay Lite';
              }
              return selectedAccount['type'] == 'Digital Wallet'
                  ? 'Digital Wallet'
                  : loc.savingsAccount;
            },
            accountNumber: selectedAccount['isCard'] == true
                ? '**** ${(selectedAccount['number'] as String).substring((selectedAccount['number'] as String).length - 4)}'
                : selectedAccount['type'] == 'Lite Wallet'
                    ? 'UPI Lite Wallet'
                    : '**** ${(selectedAccount['number'] as String).split('_').last}',
            icon: selectedAccount['type'] == 'Lite Wallet'
                ? Icons.bolt_rounded
                : null,
            onTap: _showAccountSelectionSheet,
          ),
          const SizedBox(height: 40),
          _buildNoteField(_sendNoteController),
          const SizedBox(height: 56),
          _buildPrimaryButton(
            label: (loc) => loc.sendMoneyBtn,
            onPressed: (_sendSelectedRecipient.isNotEmpty && _sendAmount > 0)
                ? _onConfirmSend
                : null,
            color: const Color(0xFF2563EB), // Solid Premium Blue
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildRequestTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          RecipientSelector(
            onRecipientSelected: (val) =>
                setState(() => _requestSelectedRecipient = val),
            selectedRecipient: _requestSelectedRecipient,
          ),
          const SizedBox(height: 40),
          PremiumAmountInput(
            controller: _requestAmountController,
            label: (loc) => loc.amountToRequest,
          ),
          const SizedBox(height: 40),
          _buildNoteField(_requestNoteController),
          const SizedBox(height: 56),
          _buildPrimaryButton(
            label: (loc) => loc.requestMoneyBtn,
            onPressed:
                (_requestSelectedRecipient.isNotEmpty && _requestAmount > 0)
                    ? _onConfirmRequest
                    : null,
            color: const Color(0xFF2563EB).withValues(alpha: 0.8),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildNoteField(TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 4, bottom: 12),
          child: AnimatedLocalize(
            text: (loc) => loc.notesOptional.toUpperCase(),
            style: GoogleFonts.inter(
              color: Theme.of(context).brightness == Brightness.light
                  ? const Color(0xFF64748B)
                  : Colors.white.withValues(alpha: 0.4),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ),
        TextField(
          controller: controller,
          textAlignVertical: TextAlignVertical.center,
          cursorColor: AppTheme.primary,
          cursorWidth: 1.5,
          style: GoogleFonts.inter(
            color: Theme.of(context).brightness == Brightness.light
                ? const Color(0xFF0F172A)
                : Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context).notesHint,
            hintStyle: GoogleFonts.inter(
              color: Theme.of(context).brightness == Brightness.light
                  ? const Color(0xFF94A3B8)
                  : Colors.white.withValues(alpha: 0.4),
              fontSize: 15,
            ),
            filled: true,
            fillColor: Theme.of(context).brightness == Brightness.light
                ? const Color(0xFFF1F5F9)
                : Colors.white.withValues(alpha: 0.05),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 22,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide(
                color: Theme.of(context).brightness == Brightness.light
                    ? const Color(0xFFE2E8F0)
                    : Colors.white.withValues(alpha: 0.1),
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide(
                color: Theme.of(context).brightness == Brightness.light
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
      ],
    );
  }

  Widget _buildPrimaryButton({
    required String Function(AppLocalizations) label,
    required VoidCallback? onPressed,
    Color? color,
    Gradient? gradient,
  }) {
    final bool isEnabled = onPressed != null;

    return AnimatedScale(
      scale: isEnabled ? 1.0 : 0.98,
      duration: const Duration(milliseconds: 200),
      child: Container(
        width: double.infinity,
        height: 64,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: isEnabled ? gradient : null,
          color: isEnabled
              ? (gradient == null ? color : null)
              : Colors.white.withValues(alpha: 0.05),
          boxShadow: [
            if (isEnabled)
              BoxShadow(
                color: (gradient?.colors.first ?? color ?? AppTheme.primary)
                    .withValues(alpha: 0.2),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
          ],
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            disabledForegroundColor: Colors.white24,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          ),
          child: AnimatedLocalize(
            text: label,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: isEnabled ? Colors.white : Colors.white24,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  void _showAccountSelectionSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final cards = ref.watch(cardsProvider);
        final accounts = [
          {
            'type': 'Savings Account',
            'bankName': 'State Bank of India',
            'number': 'DEMO_SBI_9012',
          },
          {
            'type': 'Digital Wallet',
            'bankName': 'InvisPay',
            'number': 'DEMO_INVIS_1098',
          },
          {
            'type': 'Savings Account',
            'bankName': 'HDFC Bank',
            'number': 'DEMO_HDFC_2345',
          },
        ];

        return Container(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).fromAccount,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                // InvisPay Lite Wallet
                Consumer(builder: (context, ref, _) {
                  final auth = AuthService();
                  final uid = auth.currentUser?.uid ?? 'demo';
                  final liteBalanceAsync = ref.watch(liteBalanceProvider(uid));

                  return liteBalanceAsync.when(
                    data: (liteBalance) {
                      final liteAccount = {
                        'type': 'Lite Wallet',
                        'bankName': 'InvisPay Lite',
                        'number': 'LITE_WALLET',
                        'balance': liteBalance,
                      };
                      final selectedAccount =
                          ref.watch(selectedPaymentAccountProvider);
                      final isSelected =
                          selectedAccount['number'] == liteAccount['number'];
                      return _buildAccountOption(
                        context,
                        title: 'InvisPay Lite',
                        subtitle: '₹ ${liteBalance.toStringAsFixed(2)}',
                        icon: Icons.bolt_rounded,
                        isSelected: isSelected,
                        onTap: () {
                          ref
                              .read(selectedPaymentAccountProvider.notifier)
                              .setAccount(liteAccount);
                          Navigator.pop(context);
                        },
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  );
                }),
                const SizedBox(height: 16),
                Text(
                  'BANK ACCOUNTS',
                  style: GoogleFonts.inter(
                    color: Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                // Bank Accounts
                ...accounts.map((account) {
                  final selectedAccount =
                      ref.watch(selectedPaymentAccountProvider);
                  final isSelected =
                      selectedAccount['number'] == account['number'];
                  return _buildAccountOption(
                    context,
                    title: account['bankName'] as String,
                    subtitle:
                        '**** ${(account['number'] as String).split('_').last}',
                    icon: account['type'] == 'Digital Wallet'
                        ? Icons.account_balance_wallet_rounded
                        : Icons.account_balance_rounded,
                    isSelected: isSelected,
                    onTap: () {
                      ref
                          .read(selectedPaymentAccountProvider.notifier)
                          .setAccount(account);
                      Navigator.pop(context);
                    },
                  );
                }),
                // Credit Cards
                if (cards.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'CREDIT & DEBIT CARDS',
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...cards.map((card) {
                    final selectedAccount =
                        ref.watch(selectedPaymentAccountProvider);
                    final isSelected =
                        selectedAccount['number'] == card.cardNumber;
                    return _buildAccountOption(
                      context,
                      title: card.type == CardType.visa
                          ? 'Visa • ${card.expiryDate}'
                          : 'Mastercard • ${card.expiryDate}',
                      subtitle: card.maskedNumber,
                      icon: Icons.credit_card_rounded,
                      isSelected: isSelected,
                      onTap: () {
                        ref
                            .read(selectedPaymentAccountProvider.notifier)
                            .setAccount({
                          'type': 'Card', // Marker
                          'bankName': card.type == CardType.visa
                              ? 'Visa'
                              : 'Mastercard',
                          'number': card
                              .cardNumber, // Store raw for ID match, mask in UI
                          'isCard': true,
                          'cardId': card.id,
                        });
                        Navigator.pop(context);
                      },
                    );
                  }),
                ],
                const SizedBox(height: 12),
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    context.push(AppRoutes.addCard);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: Colors.white24, style: BorderStyle.solid),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_rounded, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          'Add New Card',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAccountOption(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppTheme.primary
                : Colors.white.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primary : Colors.white70,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: AppTheme.primary),
          ],
        ),
      ),
    );
  }
}
