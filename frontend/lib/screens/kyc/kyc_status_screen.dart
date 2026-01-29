import 'dart:io';
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
  final bool fromProfile;
  const KycStatusScreen({super.key, this.fromProfile = false});

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

    return StreamBuilder<Map<String, dynamic>?>(
      stream: _kycService.kycStatusStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        final data = snapshot.data;
        final status = data?['kycStatus'] ?? 'not_started';
        final kycData = data?['kycData'] as Map<String, dynamic>?;

        // Extract details for display
        final rawSubmittedAt = kycData?['submittedAt'];
        final idType = kycData?['idType'] ?? 'ID Card';
        final idNumber = kycData?['idNumber'] ?? '****';
        final documentUrl = kycData?['documentUrl'] as String?;
        final photoUrl = kycData?['photoUrl'] as String?; // Extract photo URL
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
              onPressed: () {
                if (widget.fromProfile) {
                  context.pop();
                } else {
                  context.go(AppRoutes.home);
                }
              },
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

                // 0. KYC Summary Section (At the Top, only if submitted)
                if (kycData != null) ...[
                  _buildSummarySection(
                    context: context,
                    idType: idType,
                    idNumber: maskedId,
                    submittedAt: rawSubmittedAt,
                    status: status,
                  ),
                  const SizedBox(height: 24),
                ],

                // 1. Status Card (Hero Section)
                _buildStatusCard(status),

                const SizedBox(height: 32),

                // 2. Submission Details (Details and Documents)
                if (kycData != null && status != 'verified') ...[
                  Text(
                    'Full Breakdown',
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
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow(
                          icon: Icons.calendar_today_rounded,
                          label: 'Submitted on',
                          value: _formatTimestamp(rawSubmittedAt),
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
                        if (photoUrl != null) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Divider(height: 1, thickness: 0.5),
                          ),
                          _buildDetailRow(
                            icon: Icons.camera_front_rounded,
                            label: 'Photo Status',
                            value: 'Captured via camera',
                            previewUrl: photoUrl,
                          ),
                        ],
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
                  _buildDocumentItem('$idType Document', documentUrl),
                  if (photoUrl != null) ...[
                    const SizedBox(height: 12),
                    _buildDocumentItem('Captured Photo', photoUrl,
                        isPhoto: true),
                  ],
                ],

                // 4. Action Buttons (Retry / Start)
                if ((status == 'not_started' && kycData == null) ||
                    status == 'failed') ...[
                  const SizedBox(height: 40),
                  PrimaryButton(
                    text: status == 'failed'
                        ? 'Try Again Verification'
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
                          fontWeight: FontWeight.w500,
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
    final visible = id.substring(id.length - 4);
    return '**** $visible';
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    DateTime date;

    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else if (timestamp is String) {
      date = DateTime.parse(timestamp);
    } else if (timestamp is DateTime) {
      date = timestamp;
    } else {
      return 'N/A';
    }

    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }

  Widget _buildSummarySection({
    required BuildContext context,
    required String idType,
    required String idNumber,
    required dynamic submittedAt,
    required String status,
  }) {
    final displayStatus = status.replaceAll('_', ' ').toUpperCase();
    final statusColor = _getStatusColor(status);

    return Container(
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'KYC SUMMARY',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: AppTheme.primary,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  displayStatus,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSummaryRow('Progress', _getProgressText(status)),
          const SizedBox(height: 12),
          _buildSummaryRow('ID Type', idType),
          const SizedBox(height: 12),
          _buildSummaryRow('ID Number', idNumber),
          const SizedBox(height: 12),
          _buildSummaryRow('Submitted', _formatTimestamp(submittedAt)),
        ],
      ),
    );
  }

  String _getProgressText(String status) {
    switch (status.toLowerCase()) {
      case 'verified':
        return 'Completed';
      case 'pending':
        return 'In Progress';
      default:
        return '0%';
    }
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: AppTheme.textSecondary,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'verified':
        return const Color(0xFF10B981);
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'failed':
        return const Color(0xFFEF4444);
      default:
        return AppTheme.primary;
    }
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
        title = 'KYC Verified';
        desc =
            'Your identity has been successfully verified. You now have full access to all bank-grade features.';
        break;
      case 'pending':
        color = const Color(0xFFF59E0B); // Amber 500
        icon = Icons.hourglass_top_rounded;
        title = 'KYC Pending';
        desc =
            'Your documents are currently under review by our compliance team. This typically takes 24–48 hours.';
        break;
      case 'failed':
        color = const Color(0xFFEF4444); // Red 500
        icon = Icons.error_rounded;
        title = 'Verification Failed';
        desc =
            'We could not verify your identity. Please review the failure reason and try again with clear documents.';
        break;
      default:
        color = AppTheme.primary;
        icon = Icons.shield_outlined;
        title = 'KYC Not Started';
        desc =
            'Verification has not begun. Start your KYC submission now to unlock secure, high-limit transactions.';
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
    String? previewUrl,
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
        if (previewUrl != null) ...[
          GestureDetector(
            onTap: () => _showPreview(previewUrl, false),
            child: Text(
              'View',
              style: GoogleFonts.inter(
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
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

  Widget _buildDocumentItem(String label, String? url, {bool isPhoto = false}) {
    if (url == null) return const SizedBox.shrink();

    final isPdf = !isPhoto &&
        (url.toLowerCase().contains('.pdf') ||
            url.toLowerCase().contains('alt=media'));

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
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildThumbnail(url, isPdf),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      isPdf ? 'PDF' : 'Image',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.textSecondary.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Uploaded successfully',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF10B981),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showPreview(url, isPdf),
            icon: const Icon(
              Icons.visibility_outlined,
              color: AppTheme.primary,
            ),
            tooltip: 'Preview',
          ),
        ],
      ),
    );
  }

  void _showPreview(String url, bool isPdf) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Preview',
      pageBuilder: (context, anim1, anim2) {
        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            leading: IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text('Preview', style: TextStyle(color: Colors.white)),
          ),
          body: Center(
            child: isPdf
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.picture_as_pdf_rounded,
                          color: Colors.white, size: 84),
                      const SizedBox(height: 20),
                      Text(
                        'PDF Viewer is not available in demo mode.',
                        style: GoogleFonts.inter(color: Colors.white70),
                      ),
                    ],
                  )
                : InteractiveViewer(
                    child: _isRemoteUrl(url)
                        ? Image.network(
                            url,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const CircularProgressIndicator(
                                  color: Colors.white);
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return const Text('Could not load image',
                                  style: TextStyle(color: Colors.white));
                            },
                          )
                        : Image.file(
                            File(url),
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Text('Local file not found',
                                  style: TextStyle(color: Colors.white));
                            },
                          ),
                  ),
          ),
        );
      },
    );
  }

  bool _isRemoteUrl(String url) => url.startsWith('http');

  Widget _buildThumbnail(String url, bool isPdf) {
    if (isPdf) {
      return const Icon(Icons.picture_as_pdf_rounded, color: AppTheme.primary);
    }

    if (_isRemoteUrl(url)) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.file_present_rounded, color: AppTheme.primary),
      );
    } else {
      final file = File(url);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.broken_image_rounded, color: AppTheme.primary),
        );
      }
      return const Icon(Icons.camera_front_rounded, color: AppTheme.primary);
    }
  }
}
