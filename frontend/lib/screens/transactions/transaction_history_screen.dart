import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:invispay/core/theme/app_theme.dart';
import 'package:invispay/services/auth_service.dart';
import 'package:invispay/services/database_service.dart';
import 'package:invispay/widgets/common/base_screen.dart';
import 'package:invispay/widgets/common/animated_localize.dart';
import 'package:intl/intl.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final AuthService _auth = AuthService();
  final DatabaseService _db = DatabaseService();
  String _filter = 'All'; // All, Sent, Received

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final isDemo = user == null || !_db.isConfigured;
    final l10n = AppLocalizations.of(context);

    return BaseScreen(
      appBar: AppBar(
        title: Text(l10n.history),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      child: Column(
        children: [
          // Custom Tab/Filter Bar
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Row(
              children: [
                _buildTab((loc) => loc.all, 'All'),
                _buildTab((loc) => loc.sent, 'Sent'),
                _buildTab((loc) => loc.received, 'Received'),
              ],
            ),
          ),

          Expanded(
            child: isDemo
                ? _buildList(_getMockData())
                : StreamBuilder<QuerySnapshot>(
                    stream: _db.getTransactionsStream(user.uid),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return _buildEmptyState();
                      }

                      // Convert docs to maps
                      final allData = snapshot.data!.docs
                          .map((d) => d.data() as Map<String, dynamic>)
                          .toList();

                      return _buildList(allData);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(
      String Function(AppLocalizations) labelBuilder, String value) {
    final isSelected = _filter == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _filter = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: AnimatedLocalize(
            text: labelBuilder,
            useFittedBox: true,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getMockData() {
    return [
      {
        'toContact': 'Starbucks (Demo)',
        'amount': -5.50,
        'status': 'completed',
        'timestamp': Timestamp.now(),
      },
      {
        'toContact': 'Transfer from Savings',
        'amount': 500.00,
        'status': 'completed',
        'timestamp': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 1))),
      },
      {
        'toContact': 'Netflix Subscription',
        'amount': -15.99,
        'status': 'completed',
        'timestamp': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 2))),
      },
      {
        'toContact': 'Alice Smith',
        'amount': 25.00,
        'status': 'received', // explicitly marked
        'timestamp': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 3))),
      },
    ];
  }

  Widget _buildList(List<Map<String, dynamic>> rawList) {
    // Client-side filtering
    final filteredList = rawList.where((data) {
      final amount = (data['amount'] ?? 0.0) as double;
      // Note: Data might have explicit 'type' = sent/received but amount check is safer fallback
      // Actually earlier code used amount > 0 for credit.

      final type = data['type'] as String?;
      bool isReceived = (amount > 0) || (type == 'received');
      // If amount is negative, it is sent.
      if (amount < 0) isReceived = false;

      if (_filter == 'Sent') return !isReceived;
      if (_filter == 'Received') return isReceived;
      return true; // All
    }).toList();

    if (filteredList.isEmpty) return _buildEmptyState();

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredList.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _buildTransactionCard(filteredList[index]);
      },
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> data) {
    final amount = (data['amount'] ?? 0.0) as double;
    final isCredit = amount > 0;
    final status = data['status'] ?? 'completed';
    final date = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
    final title = data['toContact'] ?? 'Unknown';

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isCredit
                ? const Color(0xFF10B981).withValues(alpha: 0.1)
                : const Color(0xFFEF4444).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isCredit
                ? Icons.arrow_downward_rounded
                : Icons.arrow_upward_rounded,
            color: isCredit ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            DateFormat('MMM d, h:mm a').format(date),
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isCredit ? '+' : ''}₹${amount.abs().toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isCredit ? const Color(0xFF10B981) : Colors.white,
              ),
            ),
            if (status != 'completed') ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded,
              size: 64, color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          AnimatedLocalize(
            text: (loc) => loc.noTransactions,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
          ),
        ],
      ),
    );
  }
}
