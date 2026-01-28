import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:invispay/core/theme/app_theme.dart';
import 'package:invispay/routes/app_routes.dart';
import 'package:invispay/services/kyc_service.dart';
import 'package:invispay/widgets/common/base_screen.dart';
import 'package:invispay/widgets/common/primary_button.dart';

class KycDocumentUploadScreen extends StatefulWidget {
  final String fullName;
  final String idType;
  final String idNumber;

  const KycDocumentUploadScreen({
    super.key,
    required this.fullName,
    required this.idType,
    required this.idNumber,
  });

  @override
  State<KycDocumentUploadScreen> createState() =>
      _KycDocumentUploadScreenState();
}

class _KycDocumentUploadScreenState extends State<KycDocumentUploadScreen> {
  PlatformFile? _pickedFile;
  bool _isUploading = false;

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      );

      if (result != null) {
        final file = result.files.first;

        // Validate size (5MB limit as per storage rules)
        if (file.size > 5 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('File too large. Max 5MB allowed.')),
            );
          }
          return;
        }

        setState(() {
          _pickedFile = file;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking file: $e')),
        );
      }
    }
  }

  Future<void> _submitKyc() async {
    if (_pickedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a document to upload')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final kycService = KycService();
      final file = File(_pickedFile!.path!); // Ensure path is valid on mobile

      await kycService.submitKyc(
        fullName: widget.fullName,
        idType: widget.idType,
        idNumber: widget.idNumber,
        documentFile: file,
        fileExtension: _pickedFile!.extension ?? 'jpg',
      );

      if (mounted) {
        setState(() => _isUploading = false);
        // Show success, then redirect to Status Screen
        context.go(AppRoutes.kyc); // This routes to KycStatusScreen

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('✅ KYC Submitted Successfully! Verification in progress.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      appBar: AppBar(
        title: const Text('Upload Document'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Proof of Identity',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Upload a clear photo or PDF of your ${widget.idType}.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
            const SizedBox(height: 32),

            // Upload Area
            Stack(
              children: [
                GestureDetector(
                  onTap: _isUploading ? null : _pickFile,
                  child: Container(
                    height: 220,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _pickedFile != null
                            ? AppTheme.primary
                            : AppTheme.secondary.withValues(alpha: 0.1),
                        width: 2,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _pickedFile != null
                              ? Icons.file_present_rounded
                              : Icons.cloud_upload_outlined,
                          size: 56,
                          color: _pickedFile != null
                              ? AppTheme.primary
                              : AppTheme.secondary,
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            _pickedFile?.name ?? 'Tap to select Image or PDF',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _pickedFile != null
                                  ? AppTheme.textPrimary
                                  : AppTheme.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_pickedFile != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${(_pickedFile!.size / 1024).toStringAsFixed(1)} KB',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (_pickedFile != null && !_isUploading)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: () => setState(() => _pickedFile = null),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ),
              ],
            ),

            const Spacer(),

            PrimaryButton(
              text: 'Submit KYC',
              onPressed: _submitKyc,
              isLoading: _isUploading,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
