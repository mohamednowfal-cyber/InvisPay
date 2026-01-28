import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'package:invispay/core/theme/app_theme.dart';
import 'package:invispay/routes/app_routes.dart';
import 'package:invispay/services/auth_service.dart';
import 'package:invispay/widgets/common/base_screen.dart';
import 'package:invispay/widgets/common/custom_text_field.dart';
import 'package:invispay/widgets/common/primary_button.dart';

class KycDetailsScreen extends StatefulWidget {
  const KycDetailsScreen({super.key});

  @override
  State<KycDetailsScreen> createState() => _KycDetailsScreenState();
}

class _KycDetailsScreenState extends State<KycDetailsScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  final AuthService _auth = AuthService();
  String _selectedIdType = 'Aadhaar';

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return BaseScreen(
      appBar: AppBar(
        title: const Text('KYC Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context
              .go(AppRoutes.home), // Redirect to dashboard, not back loop
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Identity Verification',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please provide your official identification details. This information is encrypted and secure.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
            ),
            const SizedBox(height: 40),
            FormBuilder(
              key: _formKey,
              onChanged: () {
                _formKey.currentState!.save();
                setState(() {}); // refresh for dynamic validation UI
              },
              child: Column(
                children: [
                  // ID Type
                  _buildLabel('Select ID Type'),
                  const SizedBox(height: 8),
                  FormBuilderDropdown<String>(
                    name: 'id_type',
                    initialValue: 'Aadhaar',
                    onChanged: (val) {
                      setState(() {
                        _selectedIdType = val ?? 'Aadhaar';
                        // Clear ID Number field when type changes to prevent validation overlap
                        _formKey.currentState?.fields['id_number']
                            ?.didChange('');
                      });
                    },
                    decoration: _inputDecoration(
                      prefixIcon: Icons.badge_outlined,
                      hint: 'Select ID Type',
                    ),
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(),
                    ]),
                    items: ['Aadhaar', 'PAN', 'Passport']
                        .map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 24),

                  // Full Name
                  _buildLabel(_getNameLabel()),
                  const SizedBox(height: 8),
                  CustomTextField(
                    name: 'full_name',
                    hint: 'e.g. John Doe',
                    initialValue: user?.displayName,
                    prefixIcon: Icons.person_outline_rounded,
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(
                          errorText: 'Full name is required'),
                      (val) {
                        if (val == null || val.isEmpty) return null;
                        final nameRegex = RegExp(r'^[a-zA-Z\s]+$');
                        if (!nameRegex.hasMatch(val)) {
                          return 'Only alphabets and spaces allowed';
                        }
                        return null;
                      }
                    ]),
                  ),
                  const SizedBox(height: 24),

                  // ID Number
                  _buildLabel('ID Number'),
                  const SizedBox(height: 8),
                  CustomTextField(
                    name: 'id_number',
                    hint: _getIdHint(),
                    prefixIcon: Icons.numbers_rounded,
                    maxLength: _getIdMaxLength(), // strictly limit length
                    keyboardType: _selectedIdType == 'Aadhaar'
                        ? TextInputType.number
                        : TextInputType.text,
                    textCapitalization:
                        TextCapitalization.characters, // Auto CAPS
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'ID Number is required';
                      }
                      final trimmedVal = val.trim();

                      // Strict Aadhaar Validation
                      if (_selectedIdType == 'Aadhaar') {
                        if (!RegExp(r'^\d{12}$').hasMatch(trimmedVal)) {
                          return 'Aadhaar number must be exactly 12 digits';
                        }
                      }

                      // Strict PAN Validation: ABCDE1234F
                      if (_selectedIdType == 'PAN') {
                        if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$')
                            .hasMatch(trimmedVal)) {
                          return 'Enter a valid PAN number (e.g., ABCDE1234F)';
                        }
                      }

                      // Strict Passport Validation: A1234567 (1 Letter + 7 Digits)
                      // Note: Indian Passport logic varies but commonly 1 Alpha + 7 Digits is standard for validation request.
                      if (_selectedIdType == 'Passport') {
                        if (!RegExp(r'^[A-Z]{1}[0-9]{7}$')
                            .hasMatch(trimmedVal)) {
                          return 'Enter a valid passport number (e.g., A1234567)';
                        }
                      }

                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            // Dynamic Continue Button
            PrimaryButton(
              text: 'Continue to Upload',
              onPressed:
                  (_formKey.currentState?.isValid ?? false) ? _onNext : null,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _getNameLabel() {
    switch (_selectedIdType) {
      case 'Aadhaar':
        return 'Name as per Aadhaar Card';
      case 'PAN':
        return 'Name as per PAN Card';
      case 'Passport':
        return 'Name as per Passport';
      default:
        return 'Full Name';
    }
  }

  String _getIdHint() {
    switch (_selectedIdType) {
      case 'Aadhaar':
        return '12-digit Aadhaar Number';
      case 'PAN':
        return 'e.g. ABCDE1234F';
      case 'Passport':
        return 'e.g. A1234567';
      default:
        return 'Enter ID Number';
    }
  }

  int _getIdMaxLength() {
    switch (_selectedIdType) {
      case 'Aadhaar':
        return 12;
      case 'PAN':
        return 10;
      case 'Passport':
        return 8;
      default:
        return 20;
    }
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.textSecondary,
            letterSpacing: 0.5,
          ),
    );
  }

  InputDecoration _inputDecoration({
    required IconData prefixIcon,
    required String hint,
  }) {
    return InputDecoration(
      prefixIcon: Icon(prefixIcon, size: 20, color: AppTheme.textSecondary),
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white24),
      filled: true,
      fillColor: AppTheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.error),
      ),
    );
  }

  void _onNext() {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final values = _formKey.currentState!.value;
      // Auto-trim values before passing
      final cleanValues = {
        'fullName': values['full_name'].toString().trim(),
        'idType': values['id_type'],
        'idNumber': values['id_number']
            .toString()
            .trim(), // already auto-caps by field, but ensuring
      };

      context.push(
        AppRoutes.kycUpload,
        extra: cleanValues,
      );
    }
  }
}
