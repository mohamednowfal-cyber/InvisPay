import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:invispay/services/auth_service.dart';
import 'package:invispay/services/database_service.dart';
import 'package:invispay/services/lite_service.dart';

class LiteAddMoneyScreen extends ConsumerStatefulWidget {
  const LiteAddMoneyScreen({super.key});

  @override
  ConsumerState<LiteAddMoneyScreen> createState() => _LiteAddMoneyScreenState();
}

class _LiteAddMoneyScreenState extends ConsumerState<LiteAddMoneyScreen> {
  final TextEditingController _amountController = TextEditingController();
  Map<String, dynamic>? _selectedSource;
  bool _isProcessing = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _confirmAddMoney() async {
    final amount = double.tryParse(_amountController.text);

    if (amount == null || amount <= 0) {
      _showErrorDialog('Please enter a valid amount');
      return;
    }

    if (amount < 10) {
      _showErrorDialog('Minimum amount is ₹10');
      return;
    }

    if (amount > 10000) {
      _showErrorDialog('Maximum amount per transaction is ₹10,000');
      return;
    }

    if (_selectedSource == null) {
      _showErrorDialog('Please select a source account');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final auth = AuthService();
      final uid = auth.currentUser?.uid ?? 'demo';

      final success = await LiteService().addMoney(
        uid,
        amount,
        _selectedSource!['id'] ?? 'unknown',
      );

      if (mounted) {
        setState(() => _isProcessing = false);

        if (success) {
          HapticFeedback.heavyImpact();
          _showSuccessDialog(amount);
        } else {
          _showErrorDialog('Transaction failed. Please try again.');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        _showErrorDialog('An error occurred. Please try again.');
      }
    }
  }

  void _showSuccessDialog(double amount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Colors.green,
                size: 64,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Money Added!',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '₹${amount.toStringAsFixed(2)} added to InvisPay Lite',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Error',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        content: Text(
          message,
          style: GoogleFonts.inter(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: GoogleFonts.inter(
                color: const Color(0xFF1976D2),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSourceSelectionSheet() {
    final auth = AuthService();
    final db = DatabaseService();
    final uid = auth.currentUser?.uid ?? 'demo';

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Source',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              StreamBuilder(
                stream: db.getUserStream(uid),
                builder: (context, snapshot) {
                  // Demo accounts
                  final accounts = [
                    {
                      'id': 'acc_1',
                      'type': 'Savings',
                      'bankName': 'HDFC Bank',
                      'number': '****9012',
                    },
                    {
                      'id': 'acc_2',
                      'type': 'Current',
                      'bankName': 'ICICI Bank',
                      'number': '****3456',
                    },
                  ];

                  return Column(
                    children: accounts.map((account) {
                      return _buildSourceOption(
                        context,
                        title: '${account['bankName']}',
                        subtitle: '${account['type']} • ${account['number']}',
                        icon: Icons.account_balance_rounded,
                        onTap: () {
                          setState(() {
                            _selectedSource = account;
                          });
                          Navigator.pop(context);
                        },
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSourceOption(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1976D2).withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFF1976D2), size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          'Add Money to Lite',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        centerTitle: false,
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Amount Input
              _buildAmountInput(),
              const SizedBox(height: 24),

              // Quick Amount Buttons
              _buildQuickAmountButtons(),
              const SizedBox(height: 32),

              // Source Selector
              _buildSourceSelector(),
              const SizedBox(height: 32),

              // Add Money Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _confirmAddMoney,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Add Money to Lite',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmountInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            'AMOUNT TO ADD',
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
          decoration: const BoxDecoration(
            color: Colors.transparent,
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
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: IntrinsicWidth(
                    child: TextField(
                      controller: _amountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      style: GoogleFonts.outfit(
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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

  Widget _buildQuickAmountButtons() {
    final amounts = [100, 500, 1000, 2000];
    return Row(
      children: amounts.map((amount) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: OutlinedButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                _amountController.text = amount.toString();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1976D2),
                side: BorderSide(
                  color: const Color(0xFF1976D2).withValues(alpha: 0.3),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                '₹$amount',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSourceSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            'ADD FROM',
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ),
        GestureDetector(
          onTap: _showSourceSelectionSheet,
          child: Container(
            height: 96, // Increased height for premium touch accessibility
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1976D2).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _selectedSource != null
                        ? Icons.account_balance_rounded
                        : Icons.add_circle_outline_rounded,
                    color: const Color(0xFF1976D2),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _selectedSource != null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedSource!['bankName'] ?? '',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_selectedSource!['type']} • ${_selectedSource!['number']}',
                              style: GoogleFonts.inter(
                                color: Colors.white54,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          'Select source account',
                          style: GoogleFonts.inter(
                            color: Colors.white54,
                            fontSize: 15,
                          ),
                        ),
                ),
                if (_selectedSource != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: const Color(0xFF10B981),
                      size: 20,
                    ),
                  ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
