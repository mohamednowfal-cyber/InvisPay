import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:invispay/core/theme/app_theme.dart';
import 'package:invispay/routes/app_routes.dart';
import 'package:invispay/services/auth_service.dart';
import 'package:invispay/services/kyc_service.dart';
import 'package:invispay/widgets/common/base_screen.dart';
import 'package:invispay/widgets/common/primary_button.dart';
import 'package:intl/intl.dart';

class KycStatusScreen extends StatefulWidget {
  const KycStatusScreen({super.key});

  @override
  State<KycStatusScreen> createState() => _KycStatusScreenState();
}

class _KycStatusScreenState extends State<KycStatusScreen> {
  final KycService _kycService = KycService();
  final AuthService _auth = AuthService();

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return StreamBuilder<DocumentSnapshot?>(
      stream: _kycService.kycStatusStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final status = data?['kycStatus'] ?? 'not_started';

        // Extract details for display
        final submittedAt = data?['submittedAt'] as Timestamp?;
        final idType = data?['idType'] ?? 'ID Card';
        final idNumber = data?['idNumber'] ?? '****';
        final maskedId = _maskIdNumber(idNumber);

        return BaseScreen(
          appBar: AppBar(
            title: Text(
              'KYC Status',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => context.go(AppRoutes.home),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),

                // 1. Status Card (Hero Section)
                _buildStatusCard(status),

                const SizedBox(height: 32),

                // 2. Submission Details (Only if submitted/verified/failed)
                if (status != 'not_started') ...[
                  Text(
                    'Submission Details',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Detail Container
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.grey.shade200,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow(
                          icon: Icons.calendar_today_rounded,
                          label: 'Submitted on',
                          value: _formatTimestamp(submittedAt),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(height: 1, thickness: 0.5),
                        ),
                        _buildDetailRow(
                          icon: Icons.badge_outlined,
                          label: 'ID Type',
                          value: idType.toString().toUpperCase(),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(height: 1, thickness: 0.5),
                        ),
                        _buildDetailRow(
                          icon: Icons.numbers_rounded,
                          label: 'ID Number',
                          value: maskedId,
                          isMono: true,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 3. Documents List
                  Text(
                    'Documents Uploaded',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDocumentItem(idType),
                ],

                // 4. Action Buttons (Retry / Start)
                if (status == 'not_started' || status == 'failed') ...[
                  const SizedBox(height: 40),
                  PrimaryButton(
                    text: status == 'failed'
                        ? 'Retry Verification'
                        : 'Start Verification',
                    onPressed: () => context.push(AppRoutes.kycDetails),
                  ),
                  if (status == 'failed')
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        data?['kycFailureReason'] ??
                            'Please ensure documents are clear and valid.',
                        style: GoogleFonts.inter(
                          color: AppTheme.error,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],

                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  String _maskIdNumber(String id) {
    if (id.length <= 4) return id;
    // Keep last 4 visible
    final visible = id.substring(id.length - 4);
    final maskedLength = id.length - 4;
    // Group masks for readability (e.g. AAAA BBBB 1234)
    if (id.length > 10) {
      // Like Aadhaar
      return 'XXXX XXXX $visible';
    }
    return '${'*' * maskedLength}$visible';
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    final date = timestamp.toDate();
    // Example: 14 Feb 2026, 10:42 AM
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }

  Widget _buildStatusCard(String status) {
    Color color;
    IconData icon;
    String title;
    String desc;

    switch (status) {
      case 'verified':
        color = const Color(0xFF10B981); // Emerald 500
        icon = Icons.check_circle_rounded;
        title = 'Verified';
        desc =
            'Your identity has been successfully verified. You have full access.';
        break;
      case 'pending':
        color = const Color(0xFFF59E0B); // Amber 500
        icon = Icons.hourglass_top_rounded;
        title = 'Under Review';
        desc =
            'We are currently reviewing your documents. This usually takes 24 hours.';
        break;
      case 'failed':
        color = const Color(0xFFEF4444); // Red 500
        icon = Icons.error_rounded;
        title = 'Verification Failed';
        desc =
            'We could not verify your identity. Please review the reason below and retry.';
        break;
      default:
        color = AppTheme.primary;
        icon = Icons.shield_outlined;
        title = 'Not Verified';
        desc = 'Complete verification to unlock all InvisPay features.';
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 48),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.outfit(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white70
                  : Colors.black54,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    bool isMono = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.textSecondary),
        const SizedBox(width: 12),
        Text(
          label,
          style: GoogleFonts.inter(
            color: AppTheme.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: isMono
              ? GoogleFonts.robotoMono(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black87,
                )
              : GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black87,
                ),
        ),
      ],
    );
  }

  Widget _buildDocumentItem(String idType) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                const Icon(Icons.file_present_rounded, color: AppTheme.primary),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Identity Proof',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Scanned copy of $idType',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const Spacer(),
          const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 20),
        ],
      ),
    );
  }
}
