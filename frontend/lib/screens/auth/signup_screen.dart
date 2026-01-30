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
import 'package:invispay/widgets/auth/logo_container.dart';
import 'package:invispay/widgets/common/base_screen.dart';
import 'package:invispay/widgets/common/animated_localize.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isLoading = false;

  final AuthService _authService = AuthService();
  final DatabaseService _dbService = DatabaseService();

  Country _selectedCountry = topCountries.first;

  // Helper to check if form is fully valid to enable the button
  bool get _canSignup =>
      !_isLoading && (_formKey.currentState?.isValid ?? false);

  void _onSignup() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final form = _formKey.currentState!.value;

      setState(() => _isLoading = true);

      try {
        final mobile = form['mobile'];
        final email = form['email'];
        final password = form['password'];
        final fullMobile = '${_selectedCountry.code}$mobile';
        final name = form['name'];

        final cred = await _authService.signUpWithEmail(
          email: email,
          password: password,
        );

        if (cred.user != null) {
          try {
            await cred.user!.updateDisplayName(name);
            await _dbService.createUserProfile(cred.user!, mobile: fullMobile);
          } catch (e) {
            // print("Profile creation warning: $e");
            // If profile creation fails (e.g. mock mode), we proceed anyway
            // to allow the user to enter the app.
          }
        }

        if (mounted) {
          setState(() => _isLoading = false);
          // Navigate to KYC to complete setup, or Home.
          // Using go() to clear stack history for a fresh start.
          context.go(AppRoutes.kyc);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Signup Failed: ${e.toString()}'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: Theme.of(context).brightness == Brightness.dark
            ? AppTheme.authGradientDark
            : AppTheme.authGradient,
        stops: const [0.0, 0.4, 1.0],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Premium Full-Width Logo Background
            const LogoContainer(
              logoAsset: 'assets/icons/Logo.png',
              size: 200,
              isFullWidth: true,
            ),

            // 2. Rest of content with matching vertical rhythm
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  // Welcome Text
                  AnimatedLocalize(
                    text: (loc) => loc.joinInvispay,
                    useFittedBox: true,
                    textAlign: TextAlign.start,
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
                    text: (loc) => loc.secureJourneySub,
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 40),
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
                            setState(() {}); // Trigger rebuild for button state
                          },
                          child: Column(
                            children: [
                              _buildInputField(
                                name: 'name',
                                label: (loc) => loc.fullNameLabel.toUpperCase(),
                                hint: (loc) => loc.enterFullName,
                                icon: Icons.person_outline_rounded,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return AppLocalizations.of(context)
                                        .requiredField;
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),
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
                                  final emailRegex =
                                      RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                                  if (!emailRegex.hasMatch(value)) {
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
                              const SizedBox(height: 24),
                              _buildInputField(
                                name: 'confirm_password',
                                label: (loc) =>
                                    loc.confirmPasswordLabel.toUpperCase(),
                                hint: (loc) => loc.repeatPasswordHint,
                                icon: Icons.lock_outline_rounded,
                                obscureText: true,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return AppLocalizations.of(context)
                                        .requiredField;
                                  }
                                  final password = _formKey.currentState
                                      ?.fields['password']?.value as String?;
                                  if (value != password) {
                                    return AppLocalizations.of(context)
                                        .passwordsDontMatch;
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Signup Button
                        Container(
                          width: double.infinity,
                          height: 64, // Slightly compact to fit card
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            gradient: _canSignup
                                ? const LinearGradient(
                                    begin: Alignment.bottomLeft,
                                    end: Alignment.topRight,
                                    colors: AppTheme.authButtonGradient,
                                  )
                                : null,
                            color: _canSignup
                                ? null
                                : Colors.white.withValues(alpha: 0.1),
                            boxShadow: [
                              if (_canSignup)
                                BoxShadow(
                                  color: const Color(0xFF0D9488)
                                      .withValues(alpha: 0.25),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _canSignup ? _onSignup : null,
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
                            child: _isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : AnimatedLocalize(
                                    text: (loc) => loc.createAccountBtn,
                                    useFittedBox: true,
                                    style: GoogleFonts.outfit(
                                      fontSize: 19,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                      color: _canSignup
                                          ? Colors.white
                                          : Colors.white24,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
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
                        onTap: () => context.go(AppRoutes.login),
                        child: RichText(
                          text: TextSpan(
                            text: AppLocalizations.of(context)
                                .alreadyHaveAccountMsg,
                            style: GoogleFonts.inter(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? AppTheme.authBody
                                  : AppTheme.authBodyLight,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                            children: [
                              TextSpan(
                                text: AppLocalizations.of(context).login,
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
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
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
                });
              },
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
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
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
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
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
