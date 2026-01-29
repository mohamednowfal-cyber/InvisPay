import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:invispay/routes/app_routes.dart';
import 'package:invispay/core/theme/app_theme.dart';
import 'package:invispay/providers/payment_provider.dart';

class InvispayLiteScreen extends ConsumerStatefulWidget {
  const InvispayLiteScreen({super.key});

  @override
  ConsumerState<InvispayLiteScreen> createState() => _InvispayLiteScreenState();
}

class _InvispayLiteScreenState extends ConsumerState<InvispayLiteScreen> {
  // Dummy State
  double _dummyBalance = 12450.00;
  bool _isBalanceVisible = true;

  final List<_DummyTransaction> _dummyTransactions = [
    _DummyTransaction('Added Money', 2500, DateTime.now(), 'credit'),
    _DummyTransaction('Paid to Rahul', 350,
        DateTime.now().subtract(const Duration(days: 1)), 'debit'),
    _DummyTransaction('Starbucks Coffee', 450,
        DateTime.now().subtract(const Duration(days: 3)), 'debit'),
    _DummyTransaction('Refund', 1500,
        DateTime.now().subtract(const Duration(days: 5)), 'credit'),
  ];

  @override
  Widget build(BuildContext context) {
    // No backend calls invoked here

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'InvisPay Lite',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          HapticFeedback.lightImpact();
          // Dummy refresh
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            _buildBalanceCard(),
            const SizedBox(height: 24),
            _buildQuickActions(context),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Transactions',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTransactionList(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionList() {
    if (_dummyTransactions.isEmpty) {
      return _buildEmptyState(context);
    }
    return Column(
      children:
          _dummyTransactions.map((txn) => _buildTransactionItem(txn)).toList(),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, Color(0xFF1E40AF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                'Lite Balance',
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _isBalanceVisible
                    ? '₹${NumberFormat('#,##0.00').format(_dummyBalance)}'
                    : '•••••',
                style: GoogleFonts.outfit(
                  fontSize: 44,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () {
                  setState(() {
                    _isBalanceVisible = !_isBalanceVisible;
                  });
                  HapticFeedback.selectionClick();
                },
                icon: Icon(
                  _isBalanceVisible
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                  color: Colors.white.withValues(alpha: 0.6),
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatusChip('active'),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    // Hardcoded active state for dummy purposes
    Color color = Colors.greenAccent;
    String text = 'Verified & Active';
    IconData icon = Icons.verified_user_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 8),
          Text(
            text.toUpperCase(),
            style: GoogleFonts.inter(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final hasBalance = _dummyBalance > 0;

    return Row(
      children: [
        // Premium Add Money Card
        _buildActionCard(
          context,
          icon: Icons.add_rounded,
          label: 'Add Money',
          subtitle: 'Top up lite wallet',
          color: const Color(0xFF0D9488), // High-end Teal
          onTap: () async {
            HapticFeedback.mediumImpact();
            final newBalance = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    _DummyAddMoneyScreen(currentBalance: _dummyBalance),
              ),
            );
            if (newBalance != null && newBalance is double) {
              setState(() {
                final diff = newBalance - _dummyBalance;
                _dummyBalance = newBalance;
                if (diff > 0) {
                  _dummyTransactions.insert(
                    0,
                    _DummyTransaction(
                      'Added Money',
                      diff,
                      DateTime.now(),
                      'credit',
                    ),
                  );
                }
              });
            }
          },
        ),
        const SizedBox(width: 16),
        // Premium Pay Card
        _buildActionCard(
          context,
          icon: Icons.send_rounded,
          label: 'Pay',
          subtitle: hasBalance ? 'Quick scan & pay' : 'Insufficient funds',
          color: const Color(0xFF3B82F6), // Professional Blue
          isEnabled: hasBalance,
          onTap: () {
            HapticFeedback.mediumImpact();
            ref.read(selectedPaymentAccountProvider.notifier).setAccount({
              'type': 'Lite Wallet',
              'bankName': 'InvisPay Lite',
              'number': 'LITE_WALLET',
              'balance': _dummyBalance,
            });
            context.push(AppRoutes.makeTransaction);
          },
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool isEnabled = true,
  }) {
    return Expanded(
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            color: isEnabled
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.white.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isEnabled
                  ? color.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.05),
              width: 1.5,
            ),
            boxShadow: [
              if (isEnabled)
                BoxShadow(
                  color: color.withValues(alpha: 0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isEnabled ? 0.15 : 0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isEnabled ? color : Colors.white24,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                label,
                style: GoogleFonts.outfit(
                  color: isEnabled ? Colors.white : Colors.white24,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  color: isEnabled ? Colors.white38 : Colors.white12,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionItem(_DummyTransaction txn) {
    final isCredit = txn.type == 'credit';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isCredit ? Colors.greenAccent : Colors.white)
                  .withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCredit ? Icons.add_rounded : Icons.remove_rounded,
              color: isCredit ? Colors.greenAccent : Colors.white70,
              size: 18,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  txn.description,
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14),
                ),
                Text(
                  _formatTimestamp(txn.date),
                  style: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            '${isCredit ? '+' : '-'}₹${NumberFormat('#,##0.00').format(txn.amount)}',
            style: GoogleFonts.outfit(
              color: isCredit ? Colors.greenAccent : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(Icons.bolt_rounded,
                size: 64, color: Colors.white.withValues(alpha: 0.1)),
            const SizedBox(height: 16),
            Text(
              'Pocket Empty',
              style: GoogleFonts.outfit(
                  fontSize: 18,
                  color: Colors.white70,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Top up your lite wallet for instant sub-second payments.',
              style: GoogleFonts.inter(fontSize: 13, color: Colors.white30),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    if (difference.inDays == 0) return DateFormat('hh:mm a').format(timestamp);
    if (difference.inDays == 1) return 'Yesterday';
    return DateFormat('dd MMM').format(timestamp);
  }
}

class _DummyTransaction {
  final String description;
  final double amount;
  final DateTime date;
  final String type; // 'credit' or 'debit'

  _DummyTransaction(this.description, this.amount, this.date, this.type);
}

class _SourceAccount {
  final String name;
  final String type;
  final String maskedNumber;
  final IconData icon;

  _SourceAccount(this.name, this.type, this.maskedNumber, this.icon);
}

class _DummyAddMoneyScreen extends StatefulWidget {
  final double currentBalance;

  const _DummyAddMoneyScreen({required this.currentBalance});

  @override
  State<_DummyAddMoneyScreen> createState() => _DummyAddMoneyScreenState();
}

class _DummyAddMoneyScreenState extends State<_DummyAddMoneyScreen> {
  final TextEditingController _amountController = TextEditingController();

  late final List<_SourceAccount> _sources = [
    _SourceAccount('HDFC Bank', 'Savings Account', '•••• 4022',
        Icons.account_balance_rounded),
    _SourceAccount('SBI Bank', 'Salary Account', '•••• 8890',
        Icons.account_balance_rounded),
    _SourceAccount('InvisPay Card', 'Premium Credit', '•••• 9901',
        Icons.credit_card_rounded),
  ];

  late _SourceAccount _selectedSource = _sources.first;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Add Money',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // 💰 1. Premium Enter Amount Field
            Text(
              'Enter Amount',
              style: GoogleFonts.inter(
                color: Colors.white60,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                children: [
                  Text(
                    '₹',
                    style: GoogleFonts.outfit(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      autofocus: true,
                      cursorColor: AppTheme.primary,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*')),
                      ],
                      style: GoogleFonts.outfit(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -1,
                      ),
                      decoration: InputDecoration(
                        hintText: '0.00',
                        hintStyle: GoogleFonts.outfit(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.white10,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        filled: false,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // 🔽 2. Premium From Account Dropdown Selector
            Text(
              'Select Funding Source',
              style: GoogleFonts.inter(
                color: Colors.white60,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: LayoutBuilder(builder: (context, constraints) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    splashFactory: NoSplash.splashFactory,
                    popupMenuTheme: PopupMenuThemeData(
                      color: const Color(0xFF1E293B), // Slate 800
                      elevation: 16,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24)),
                      textStyle: GoogleFonts.inter(color: Colors.white),
                    ),
                  ),
                  child: PopupMenuButton<_SourceAccount>(
                    clipBehavior: Clip.hardEdge,
                    // Offset adjusted (-10) to center the wider container (+20)
                    offset: const Offset(-10, 70),
                    // Width expanded (+20) to cover parent borders completely
                    constraints: BoxConstraints.tightFor(
                        width: constraints.maxWidth + 20),
                    tooltip: '',
                    itemBuilder: (context) {
                      return _sources.map((source) {
                        return PopupMenuItem<_SourceAccount>(
                          value: source,
                          height: 72, // Increased item height for comfort
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 6), // Better spacing
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color:
                                      AppTheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(source.icon,
                                    color: AppTheme.primary, size: 20),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      source.name,
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(
                                        height: 4), // Added breathing room
                                    Text(
                                      '${source.type} • ${source.maskedNumber}',
                                      style: GoogleFonts.inter(
                                        color: Colors.white38,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_selectedSource == source)
                                const Icon(Icons.check_circle_rounded,
                                    color: AppTheme.primary, size: 18),
                            ],
                          ),
                        );
                      }).toList();
                    },
                    onSelected: (val) => setState(() => _selectedSource = val),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          Icon(Icons.keyboard_arrow_down_rounded,
                              color: Colors.white38),
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(_selectedSource.icon,
                                color: AppTheme.primary, size: 20),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _selectedSource.name,
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${_selectedSource.type} • ${_selectedSource.maskedNumber}',
                                  style: GoogleFonts.inter(
                                    color: Colors.white38,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 80),

            // Confirm Button
            SizedBox(
              width: double.infinity,
              height: 64,
              child: ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () async {
                        final amount = double.tryParse(_amountController.text);
                        if (amount != null && amount > 0) {
                          setState(() => _isLoading = true);
                          HapticFeedback.mediumImpact();
                          await Future.delayed(
                              const Duration(milliseconds: 1500));

                          if (!context.mounted) return;
                          Navigator.pop(
                              context, widget.currentBalance + amount);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      AppTheme.primary.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        'Confirm & Add ₹${_amountController.text.isEmpty ? '0.00' : _amountController.text}',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
