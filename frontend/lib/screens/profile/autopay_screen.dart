import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:invispay/core/theme/app_theme.dart';
import 'package:invispay/widgets/common/base_screen.dart';

class AutopayScreen extends StatefulWidget {
  const AutopayScreen({super.key});

  @override
  State<AutopayScreen> createState() => _AutopayScreenState();
}

class _AutopayScreenState extends State<AutopayScreen> {
  String _activeFilter = 'All';

  final List<Map<String, dynamic>> _mockAutopays = [
    {
      'payee': 'Reliance Jio Info',
      'amount': '₹499.00',
      'frequency': 'Monthly',
      'nextDebit': '12 Feb 2026',
      'status': 'Pending',
    },
    {
      'payee': 'Tata Power-DDL',
      'amount': '₹2,450.00',
      'frequency': 'Monthly',
      'nextDebit': '05 Feb 2026',
      'status': 'Pending',
    },
    {
      'payee': 'Netflix Entertainment',
      'amount': '₹649.00',
      'frequency': 'Monthly',
      'nextDebit': '28 Jan 2026',
      'status': 'Completed',
    },
    {
      'payee': 'LIC of India',
      'amount': '₹12,400.00',
      'frequency': 'Yearly',
      'nextDebit': '--',
      'status': 'Cancelled',
    },
  ];

  List<Map<String, dynamic>> get _filteredAutopays {
    if (_activeFilter == 'All') return _mockAutopays;
    if (_activeFilter == 'Active / Pending') {
      return _mockAutopays
          .where((a) => a['status'] == 'Pending' || a['status'] == 'Completed')
          .toList();
    }
    return _mockAutopays.where((a) => a['status'] == 'Cancelled').toList();
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      appBar: AppBar(
        title: Text(
          'Autopay Mandates',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: false,
      ),
      child: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip('All'),
                const SizedBox(width: 8),
                _buildFilterChip('Active / Pending'),
                const SizedBox(width: 8),
                _buildFilterChip('Cancelled'),
              ],
            ),
          ),

          Expanded(
            child: _filteredAutopays.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _filteredAutopays.length,
                    itemBuilder: (context, index) {
                      final item = _filteredAutopays[index];
                      return _buildAutopayCard(item);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isActive = _activeFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.primary
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isActive
                ? AppTheme.primary
                : AppTheme.authBorder.withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            color: isActive ? Colors.white : Colors.white70,
          ),
        ),
      ),
    );
  }

  Widget _buildAutopayCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.authBorder.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item['payee'],
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              _buildStatusBadge(item['status']),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoItem('Amount', item['amount']),
              _buildInfoItem('Frequency', item['frequency']),
              _buildInfoItem('Next Debit', item['nextDebit']),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'Pending':
        color = const Color(0xFFF59E0B); // Amber
        break;
      case 'Completed':
        color = const Color(0xFF10B981); // Emerald
        break;
      case 'Cancelled':
        color = const Color(0xFFEF4444); // Red
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        status,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: Colors.white38,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.autorenew_outlined,
            size: 64,
            color: Colors.white.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 16),
          Text(
            'No Autopay Mandates Found',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white38,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Keep track of your recurring payments here.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white24,
            ),
          ),
        ],
      ),
    );
  }
}
