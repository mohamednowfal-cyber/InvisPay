import 'package:flutter/material.dart';
import 'package:invispay/widgets/common/base_screen.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class AccountTransactionsScreen extends StatelessWidget {
  final String accountId;
  const AccountTransactionsScreen({super.key, required this.accountId});

  @override
  Widget build(BuildContext context) {
    final accountIdSuffix = accountId.split('_').last;

    // Dummy Transactions for Demo Passbook
    final List<Map<String, dynamic>> demoTransactions = [
      {
        'amount': 2500.0,
        'type': 'received',
        'note': 'Salary Credit',
        'timestamp': DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      },
      {
        'amount': 450.0,
        'type': 'sent',
        'note': 'Starbucks Coffee',
        'timestamp': DateTime.now().subtract(const Duration(hours: 5)),
      },
      {
        'amount': 1200.0,
        'type': 'sent',
        'note': 'Amazon Shopping',
        'timestamp': DateTime.now().subtract(const Duration(days: 2, hours: 1)),
      },
      {
        'amount': 5000.0,
        'type': 'received',
        'note': 'Refund from Airline',
        'timestamp': DateTime.now().subtract(const Duration(days: 3)),
      },
      {
        'amount': 150.0,
        'type': 'sent',
        'note': 'Uber Ride',
        'timestamp': DateTime.now().subtract(const Duration(days: 4)),
      },
    ]..sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

    return BaseScreen(
      appBar: AppBar(
        title: Column(
          children: [
            const Text('E-Passbook'),
            Text(
              'A/C: ****$accountIdSuffix',
              style: GoogleFonts.inter(
                  fontSize: 11, color: Colors.white38, letterSpacing: 1),
            ),
          ],
        ),
        centerTitle: true,
      ),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        itemCount: demoTransactions.length,
        itemBuilder: (context, index) {
          final data = demoTransactions[index];
          final amount = data['amount'];
          final type = data['type'];
          final note = data['note'];
          final timestamp = data['timestamp'] as DateTime;
          final isCredit = type == 'received';

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (isCredit ? Colors.teal : Colors.redAccent)
                        .withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isCredit ? Icons.add_rounded : Icons.remove_rounded,
                    color: isCredit ? Colors.teal : Colors.redAccent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        note,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        DateFormat('dd MMM yyyy, hh:mm aa').format(timestamp),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.white38,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${isCredit ? "+" : "-"} ₹${NumberFormat('#,##,###.##').format(amount)}',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isCredit ? Colors.teal : Colors.white,
                      ),
                    ),
                    Text(
                      isCredit ? 'CREDIT' : 'DEBIT',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: isCredit
                            ? Colors.teal.withValues(alpha: 0.5)
                            : Colors.redAccent.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
