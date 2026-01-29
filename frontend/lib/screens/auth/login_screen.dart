import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:invispay/core/data/country_data.dart';
import 'package:invispay/core/theme/app_theme.dart';
import 'package:invispay/routes/app_routes.dart';
import 'package:invispay/services/auth_service.dart';
import 'package:invispay/services/database_service.dart';
import 'package:invispay/widgets/auth/country_code_selector.dart';
import 'package:invispay/widgets/common/base_screen.dart';
import 'package:invispay/widgets/common/animated_localize.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isSubmitting = false;
  String? _errorMessage;
  bool _isFormValid = false;
  final AuthService _authService = AuthService();
  final DatabaseService _dbService = DatabaseService();

  Country _selectedCountry = topCountries.first;

  Future<void> _checkKycAndRedirect(String uid) async {
    try {
      if (!mounted) return;

      // Fetch user data
      final userDoc = await _dbService.getUserData(uid);

      if (!mounted) return;

      if (userDoc == null || !userDoc.exists) {
        context.go(AppRoutes.home);
        return;
      }

      final data = userDoc.data() as Map<String, dynamic>? ?? {};
      final kycStatus =
          (data['kycStatus'] ?? 'not_started').toString().toLowerCase();

      // Route based on KYC status
      switch (kycStatus) {
        case 'verified':
        case 'pending':
          context.go(AppRoutes.home);
          break;

        case 'failed':
        case 'not_verified':
          context.go(AppRoutes.kycStatus);
          break;

        case 'not_started':
        default:
          context.go(AppRoutes.kyc);
          break;
      }
    } catch (e) {
      if (mounted) {
        // Fallback to Home on error to prevent being stuck
        context.go(AppRoutes.home);
      }
    }
  }

  void _onLogin() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      if (_isSubmitting) return; // Silent guard against double taps

      // NO visual loader as per requirements
      setState(() {
        _isSubmitting = true;
        _errorMessage = null;
      });

      try {
        final form = _formKey.currentState!.value;
        final email = form['email'];
        final password = form['password'];

        final cred = await _authService.signInWithEmail(
            email: email, password: password);

        if (cred.user != null) {
          // Navigate immediately or via KYC check
          await _checkKycAndRedirect(cred.user!.uid);
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
            final errorMsg = e.toString();
            if (errorMsg.contains('Firebase not configured')) {
              // In Demo Mode, go to Home directly and instantly
              context.go(AppRoutes.home);
            } else {
              // Set friendly inline error
              _errorMessage = 'Invalid email or password. Please try again.';
            }
          });
        }
      }
    }
  }

  void _validateForm() {
    final isValid = _formKey.currentState?.isValid ?? false;
    // Also check if fields are actually filled, not just valid (touched)
    final fields = _formKey.currentState?.fields ?? {};
    final hasEmail = fields['email']?.value != null &&
        fields['email']!.value.toString().isNotEmpty;
    final hasPassword = fields['password']?.value != null &&
        fields['password']!.value.toString().isNotEmpty;

    // We assume mobile is valid if CountrySelector is present, but it's optional for Login vs Email
    // If strict mobile is needed, add check here.
    // Current flow uses Email + Password for Auth. Mobile is extra.

    setState(() {
      _isFormValid = isValid && hasEmail && hasPassword;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        SystemNavigator.pop();
      },
      child: BaseScreen(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: Theme.of(context).brightness == Brightness.dark
              ? AppTheme.authGradientDark
              : AppTheme.authGradient,
          stops: const [0.0, 0.4, 1.0],
        ),
        child: SingleChildScrollView(
          // Premium Fintech Padding: Consistent margins, generous bottom space
          padding: const EdgeInsets.fromLTRB(20, 36, 20, 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                  height: 40), // Shifted upward for better spatial balance

              // Premium Logo Container
              Center(
                child: Hero(
                  tag: 'logo',
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/invispay_logo.png',
                      height: 52,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 36), // Balanced spacing above heading

              // Welcome Text
              AnimatedLocalize(
                text: (loc) => loc.welcomeBack,
                style: GoogleFonts.outfit(
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppTheme.authTitle
                      : AppTheme.authTitleLight,
                  height: 1.0,
                  letterSpacing: -1.5,
                ),
                maxLines: 1,
              ),
              const SizedBox(height: 20),
              AnimatedLocalize(
                text: (loc) => loc.invisibleWalletSub,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppTheme.authBody
                      : AppTheme.authBodyLight,
                  letterSpacing: 0.2,
                ),
              ),

              const SizedBox(height: 48),

              // Premium Auth Card Container
              Container(
                // Inner Padding: Breathing space (40) top/bottom, Balanced (24) horizontal
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withValues(alpha: 0.03)
                      : Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.white,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    FormBuilder(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      onChanged: () {
                        _formKey.currentState?.save();
                        _validateForm();
                      },
                      child: Column(
                        children: [
                          _buildMobileInput(),
                          const SizedBox(height: 24),
                          _buildInputField(
                            name: 'email',
                            label: (loc) => loc.emailLabel.toUpperCase(),
                            hint: (loc) => loc.enterEmail,
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return AppLocalizations.of(context)
                                    .requiredField;
                              }
                              if (!value.contains('@') ||
                                  !value.contains('.')) {
                                return AppLocalizations.of(context)
                                    .invalidEmail;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          _buildInputField(
                            name: 'password',
                            label: (loc) => loc.password.toUpperCase(),
                            hint: (loc) => loc.enterPassword,
                            icon: Icons.lock_outline_rounded,
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return AppLocalizations.of(context)
                                    .requiredField;
                              }
                              if (value.length < 6) {
                                return AppLocalizations.of(context)
                                    .minPasswordLength;
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),

                    // Inline Error Display
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded,
                                color: Color(0xFFEF4444), size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: GoogleFonts.inter(
                                  color: const Color(0xFFEF4444),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 40),

                    // Login Button
                    Container(
                      width: double.infinity,
                      height: 64, // Slightly compact to fit card
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: !_isFormValid
                            ? null
                            : const LinearGradient(
                                begin: Alignment.bottomLeft,
                                end: Alignment.topRight,
                                colors: AppTheme.authButtonGradient,
                              ),
                        color: !_isFormValid
                            ? Colors.white.withValues(alpha: 0.1)
                            : null,
                        boxShadow: [
                          if (_isFormValid)
                            BoxShadow(
                              color: const Color(0xFF0D9488)
                                  .withValues(alpha: 0.25),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: !_isFormValid ? null : _onLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          disabledBackgroundColor: Colors.transparent,
                          disabledForegroundColor: Colors.white24,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24)),
                          elevation: 0,
                        ),
                        child: AnimatedLocalize(
                          text: (loc) => loc.signInBtn,
                          style: GoogleFonts.outfit(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            color:
                                !_isFormValid ? Colors.white24 : Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              // Signup Link
              Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.0, 0.05),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: GestureDetector(
                    key: ValueKey(
                        AppLocalizations.of(context).locale.languageCode),
                    onTap: () => context.go(AppRoutes.signup),
                    child: RichText(
                      text: TextSpan(
                        text: AppLocalizations.of(context).dontHaveAccountMsg,
                        style: GoogleFonts.inter(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppTheme.authBody
                              : AppTheme.authBodyLight,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        children: [
                          TextSpan(
                            text: AppLocalizations.of(context).signup,
                            style: GoogleFonts.inter(
                              color: const Color(
                                  0xFF2DD4BF), // Brighter teal for contrast
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 8, bottom: 10),
          child: AnimatedLocalize(
            text: (loc) => loc.mobileNumber.toUpperCase(),
            style: GoogleFonts.inter(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppTheme.authBody.withValues(alpha: 0.8)
                  : AppTheme.authBodyLight.withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CountryCodeSelector(
              selectedCountry: _selectedCountry,
              onCountryChanged: (country) {
                setState(() {
                  _selectedCountry = country;
                  _formKey.currentState?.fields['mobile']?.reset();
                  _validateForm();
                });
              },
              // Ensure height matches text fields if needed,
              // but CountryCodeSelector has its own sizing.
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FormBuilderTextField(
                name: 'mobile',
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(_selectedCountry.validLengths
                      .reduce((a, b) => a > b ? a : b)),
                ],
                style:
                    GoogleFonts.inter(color: AppTheme.authTitle, fontSize: 16),
                validator: (value) {
                  // Mobile is technically optional for Login if Email is used,
                  // but visually it looks required. Let's make it required for form completeness visual.
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(context).requiredField;
                  }
                  if (!_selectedCountry.validLengths.contains(value.length)) {
                    return ''; // Generic hint for valid length
                  }
                  return null;
                },
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context).mobileNumber,
                  hintStyle: GoogleFonts.inter(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white24
                        : Colors.black26,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withValues(alpha: 0.05)
                      : const Color(0xFFF1F5F9),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 22), // Premium Padding
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white.withValues(alpha: 0.1)
                          : AppTheme.authBorder,
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide:
                        const BorderSide(color: AppTheme.authTeal, width: 2),
                  ),
                  errorStyle: GoogleFonts.inter(
                    color: AppTheme.authErrorMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInputField({
    required String name,
    required String Function(AppLocalizations) label,
    required String Function(AppLocalizations) hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Consumer(builder: (context, ref, child) {
      final loc = AppLocalizations.of(context);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 8, bottom: 10),
            child: AnimatedLocalize(
              text: label,
              style: GoogleFonts.inter(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppTheme.authBody.withValues(alpha: 0.8)
                    : AppTheme.authBodyLight.withValues(alpha: 0.8),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ),
          FormBuilderTextField(
            name: name,
            obscureText: obscureText,
            keyboardType: keyboardType,
            style: GoogleFonts.inter(color: AppTheme.authTitle, fontSize: 16),
            validator: validator,
            decoration: InputDecoration(
              hintText: hint(loc),
              hintStyle: GoogleFonts.inter(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white24
                    : Colors.black26,
              ),
              prefixIcon: Icon(
                icon,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white38
                    : Colors.black38,
                size: 22,
              ),
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.05)
                  : const Color(0xFFF1F5F9),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 22), // Premium Padding
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withValues(alpha: 0.1)
                      : AppTheme.authBorder,
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide:
                    const BorderSide(color: AppTheme.authTeal, width: 2),
              ),
              errorStyle: GoogleFonts.inter(
                color: AppTheme.authErrorMuted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      );
    });
  }
}
