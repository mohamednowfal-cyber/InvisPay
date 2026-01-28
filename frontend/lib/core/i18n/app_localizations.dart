import 'package:flutter/material.dart';
import 'package:invispay/core/i18n/translations.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  String get currentLanguageName {
    final languageCode = locale.languageCode;
    switch (languageCode) {
      case 'hi':
        return 'हिन्दी (Hindi)';
      case 'ta':
        return 'தமிழ் (Tamil)';
      case 'te':
        return 'తెలుగు (Telugu)';
      case 'ml':
        return 'മലയാളം (Malayalam)';
      case 'kn':
        return 'ಕನ್ನಡ (Kannada)';
      case 'mr':
        return 'मराठी (Marathi)';
      case 'bn':
        return 'বাংলা (Bengali)';
      case 'gu':
        return 'ગુજરાતી (Gujarati)';
      case 'pa':
        return 'ਪੰਜਾਬੀ (Punjabi)';
      case 'or':
        return 'ଓଡ଼ିଆ (Odia)';
      case 'ur':
        return 'اردو (Urdu)';
      default:
        return 'English';
    }
  }

  String get rewardsEarned => translate('rewards_earned');
  String get referFriend => translate('refer_friend');

  String translate(String key, {List<String>? args}) {
    final translations =
        appTranslations[locale.languageCode] ?? appTranslations['en']!;
    String value = translations[key] ?? key;
    if (args != null) {
      for (int i = 0; i < args.length; i++) {
        value = value.replaceAll('{$i}', args[i]);
      }
    }
    return value;
  }

  // --- Common Phrases ---
  String get appName => translate('app_name');
  String get home => translate('home');
  String get welcome => translate('welcome');
  String get login => translate('login');
  String get signup => translate('signup');
  String get mobileNumber => translate('mobile_number');
  String get emailLabel => translate('email_label');
  String get enterEmail => translate('enter_email');
  String get enterPassword => translate('enter_password');
  String get password => translate('password');
  String get forgotPassword => translate('forgot_password');
  String get welcomeBack => translate('welcome_back');
  String get invisibleWalletSub => translate('invisible_wallet_sub');
  String get signInBtn => translate('sign_in_btn');
  String get dontHaveAccountMsg => translate('dont_have_account_msg');
  String get alreadyHaveAccountMsg => translate('already_have_account_msg');
  String get joinInvispay => translate('join_invispay');
  String get secureJourneySub => translate('secure_journey_sub');
  String get fullNameLabel => translate('full_name_label');
  String get enterFullName => translate('enter_full_name');
  String get confirmPasswordLabel => translate('confirm_password_label');
  String get repeatPasswordHint => translate('repeat_password_hint');
  String get passwordsDontMatch => translate('passwords_dont_match');
  String get createAccountBtn => translate('create_account_btn');
  String get requiredField => translate('required');
  String get invalidEmail => translate('invalid_email');
  String get minPasswordLength => translate('min_password_length');
  String get dontHaveAccount => translate('dont_have_account');
  String get alreadyHaveAccount => translate('already_have_account');

  // --- Home ---
  String get totalBalance => translate('total_balance');
  String get recentActivity => translate('recent_activity');
  String get viewAll => translate('view_all');
  String get scan => translate('scan');
  String get send => translate('send');
  String get request => translate('request');
  String get history => translate('history');
  String get historyLabel => translate('history_label');
  String get profile => translate('profile');
  String get accounts => translate('accounts');

  // --- Profile/Settings ---
  String get settings => translate('settings');
  String get language => translate('language');
  String get payCardsSub => translate('pay_cards_sub');
  String get yourQrSub => translate('your_qr_sub');
  String get autopaySub => translate('autopay_sub');
  String get languageSub => translate('language_sub');
  String get appearance => translate('appearance');
  String get security => translate('security');
  String get privacy => translate('privacy');
  String get support => translate('support');
  String get logout => translate('logout');
  String get appLock => translate('app_lock');
  String get autoLogout => translate('auto_logout');
  String get hideBalance => translate('hide_balance');
  String get profileVisibility => translate('profile_visibility');
  String get qrVisibility => translate('qr_visibility');
  String get notifications => translate('notifications');
  String get themeMode => translate('theme_mode');
  String get helpSupport => translate('help_support');
  String get termsPrivacy => translate('terms_privacy');
  String get appVersion => translate('app_version');

  // --- KYC ---
  String get kycVerification => translate('kyc_verification');
  String get kycStatusPending => translate('kyc_status_pending');
  String get kycStatusVerified => translate('kyc_status_verified');
  String get kycStatusFailed => translate('kyc_status_failed');
  String get completeKyc => translate('complete_kyc');
  String get retryKyc => translate('retry_kyc');

  // --- Transactions & History ---
  String get toFrom => translate('to_from');
  String get all => translate('all');
  String get sent => translate('sent');
  String get received => translate('received');
  String get noTransactions => translate('no_transactions');

  // --- Payments ---
  String get amountToSend => translate('amount_to_send');
  String get amountToRequest => translate('amount_to_request');
  String get recipientSearch => translate('recipient_search');
  String get recentContacts => translate('recent_contacts');
  String get recentlyPaid => translate('recently_paid');
  String get fromAccount => translate('from_account');
  String get notesOptional => translate('notes_optional');
  String get notesHint => translate('notes_hint');
  String get sendMoneyBtn => translate('send_money_btn');
  String get requestMoneyBtn => translate('request_money_btn');
  String get actionSuccessful => translate('action_successful');
  String get processingSend => translate('processing_send');
  String get processingRequest => translate('processing_request');

  // --- Accounts ---
  String get accountDetails => translate('account_details');
  String get bankInfo => translate('bank_info');
  String get bankName => translate('bank_name');
  String get branchName => translate('branch_name');
  String get ifscCode => translate('ifsc_code');
  String get linkedInfo => translate('linked_info');
  String get linkedMobile => translate('linked_mobile');
  String get linkedEmail => translate('linked_email');
  String get branchAddress => translate('branch_address');
  String get viewPassbook => translate('view_passbook');
  String get accountStatus => translate('account_status');
  String get createdOn => translate('created_on');
  String get active => translate('active');
  String get inactive => translate('inactive');
  String get noAccounts => translate('no_accounts');
  String get accountNotFound => translate('account_not_found');

  // --- Extras ---
  String get chooseLanguage => translate('choose_language');
  String get selectPreferredLanguage => translate('select_preferred_language');
  String get transferMoney => translate('transfer_money');
  String get savingsAccount => translate('savings_account');
  String get currentAccount => translate('current_account');
  String get account => translate('account');
  String get address => translate('address');
  String get notLinked => translate('not_linked');
  String get notAvailable => translate('not_available');
  String get demoUser => translate('demo_user');
  String get demoMode => translate('demo_mode');
  String get verified => translate('verified');
  String get verificationRequired => translate('verification_required');
  String get kycRequiredMsg => translate('kyc_required_msg');
  String get maybeLater => translate('maybe_later');
  String cardEndingDigits(String digits) =>
      translate('card_ending_digits', args: [digits]);
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return [
      'en',
      'hi',
      'ta',
      'te',
      'ml',
      'kn',
      'mr',
      'bn',
      'gu',
      'pa',
      'or',
      'ur'
    ].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
