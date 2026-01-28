import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:invispay/core/theme/app_theme.dart';
import 'package:invispay/routes/app_routes.dart';
import 'package:invispay/widgets/common/base_screen.dart';

class AccountDetailsScreen extends StatefulWidget {
  final String accountId;

  const AccountDetailsScreen({super.key, required this.accountId});

  @override
  State<AccountDetailsScreen> createState() => _AccountDetailsScreenState();
}

class _AccountDetailsScreenState extends State<AccountDetailsScreen> {
  bool _isBalanceVisible = false;
  bool _isLoadingBalance = false;

  void _checkBalance() async {
    setState(() {
      _isLoadingBalance = true;
    });

    // Simulate network delay for checking balance securely
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() {
        _isLoadingBalance = false;
        _isBalanceVisible = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Fallback demo data logic
    Map<String, dynamic> accountData;
    if (widget.accountId.contains('SBI')) {
      accountData = {
        'type': 'Savings Account',
        'bankName': 'State Bank of India',
        'number': 'DEMO_SBI_9012',
        'balance': 12450.75,
        'branch': 'Connaught Place, New Delhi',
        'ifsc': 'SBIN0001234',
        'holder': 'InvisPay User',
        'mobile': '+91 79044 59738',
        'email': 'demo@invispay.com',
      };
    } else if (widget.accountId.contains('INVIS')) {
      accountData = {
        'type': 'Digital Wallet',
        'bankName': 'InvisPay Wallet',
        'number': 'DEMO_INVIS_1098',
        'balance': 850.25,
        'branch': 'Digital Branch',
        'ifsc': 'INVS0000001',
        'holder': 'InvisPay User',
        'mobile': '+91 79044 59738',
        'email': 'demo@invispay.com',
      };
    } else {
      accountData = {
        'type': 'Savings Account',
        'bankName': 'HDFC Bank',
        'number': 'DEMO_HDFC_2345',
        'balance': 50000.00,
        'branch': 'Indiranagar, Bangalore',
        'ifsc': 'HDFC0004567',
        'holder': 'InvisPay User',
        'mobile': '+91 79044 59738',
        'email': 'demo@invispay.com',
      };
    }

    final bankName = accountData['bankName'];
    final type = accountData['type'];
    final number = accountData['number'];
    final balance = accountData['balance'];
    final branch = accountData['branch'];
    final ifsc = accountData['ifsc'];
    final holder = accountData['holder'];
    final mobile = accountData['mobile'];
    final email = accountData['email'];

    return BaseScreen(
      appBar: AppBar(
        title: Text('$type - $bankName',
            style:
                GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account Info Card
            _buildInfoCard(
                holder, number, bankName, branch, ifsc, mobile, email),

            const SizedBox(height: 32),

            // Features Grid/List
            _buildSectionHeader('ACCOUNT FEATURES'),
            const SizedBox(height: 16),
            _buildFeatureTile(
              icon: Icons.refresh_rounded,
              title: 'Check Bank Balance',
              subtitle: _isBalanceVisible
                  ? '₹ ${NumberFormat('#,##,###.##').format(balance)}'
                  : 'Tap to refresh balance',
              onTap: _isLoadingBalance ? null : _checkBalance,
              trailing: _isLoadingBalance
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : null,
            ),
            _buildFeatureTile(
              icon: Icons.receipt_long_rounded,
              title: 'View E-Passbook',
              subtitle: 'Digital transaction record',
              onTap: () => context.push(AppRoutes.accountTransactions
                  .replaceAll(':accountId', widget.accountId)),
            ),
            _buildFeatureTile(
              icon: Icons.history_rounded,
              title: 'Transaction History',
              subtitle: 'Recent payments for this account',
              onTap: () => context.push(AppRoutes.accountTransactions
                  .replaceAll(':accountId', widget.accountId)),
            ),
            _buildFeatureTile(
              icon: Icons.file_download_outlined,
              title: 'Download Statement',
              subtitle: 'Get account statement in PDF',
              onTap: () {},
            ),
            _buildFeatureTile(
              icon: Icons.support_agent_rounded,
              title: 'Account Support',
              subtitle: 'Bank-related help & queries',
              onTap: () {},
            ),

            const SizedBox(height: 40),
            Center(
              child: Text(
                'Secured by InvisPay Encryption',
                style: GoogleFonts.inter(
                  color: Colors.white24,
                  fontSize: 10,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String holder, String number, String bank,
      String branch, String ifsc, String mobile, String email) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          _buildDetailRow('Account Holder', holder),
          _buildDetailRow(
              'Account Number', '**** **** **** ${number.split('_').last}'),
          _buildDetailRow('Bank Name', bank),
          _buildDetailRow('Branch Name', branch),
          _buildDetailRow('IFSC Code', ifsc),
          _buildDetailRow('Mobile Number', mobile),
          _buildDetailRow('Email ID', email),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.inter(color: Colors.white38, fontSize: 13)),
          Text(value,
              style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        color: AppTheme.primary,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildFeatureTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: AppTheme.primary, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600)),
                      Text(subtitle,
                          style: GoogleFonts.inter(
                              color: Colors.white38, fontSize: 12)),
                    ],
                  ),
                ),
                trailing ??
                    const Icon(Icons.chevron_right_rounded,
                        color: Colors.white24, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
