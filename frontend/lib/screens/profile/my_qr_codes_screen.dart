import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:invispay/core/i18n/app_localizations.dart';
import 'package:invispay/core/theme/app_theme.dart';
import 'package:invispay/services/auth_service.dart';
import 'package:invispay/services/database_service.dart';
import 'package:invispay/widgets/common/base_screen.dart';
import 'package:invispay/providers/settings_provider.dart';
import 'package:invispay/providers/qr_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class MyQrCodesScreen extends ConsumerStatefulWidget {
  const MyQrCodesScreen({super.key});

  @override
  ConsumerState<MyQrCodesScreen> createState() => _MyQrCodesScreenState();
}

class _MyQrCodesScreenState extends ConsumerState<MyQrCodesScreen> {
  bool _isDataLoaded = false;
  final ScreenshotController _screenshotController = ScreenshotController();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    final auth = AuthService();
    final db = DatabaseService();
    final user = auth.currentUser;
    final uid = user?.uid ?? 'demo';
    final selectedAccount = ref.watch(qrSelectionProvider);

    return BaseScreen(
      appBar: AppBar(
        title: Text(l10n.translate('your_qr'),
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      child: settings.qrVisibility
          ? StreamBuilder<QuerySnapshot>(
              stream: db.getAccountsStream(uid),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _buildErrorState(
                      context, l10n, snapshot.error.toString());
                }

                if (snapshot.connectionState == ConnectionState.waiting &&
                    !_isDataLoaded) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.connectionState == ConnectionState.active &&
                    !snapshot.hasData) {
                  _isDataLoaded = true;
                  return _buildNoAccountsState(context, l10n);
                }

                final accounts = <QrAccount>[];

                // 1. Add Bank Accounts & Wallet (Demo + Firestore)
                final Set<String> seenNumbers = {};

                // Add mandatory Demo Accounts first as per request
                final demoAccounts = [
                  {
                    'id': 'demo_sbi',
                    'name': 'State Bank of India',
                    'number': '9012',
                    'type': 'Bank',
                    'vpa': '$uid.sbi@invispay'
                  },
                  {
                    'id': 'demo_wallet',
                    'name': 'InvisPay Wallet',
                    'number': '1098',
                    'type': 'Wallet',
                    'vpa': '$uid.wallet@invispay'
                  },
                  {
                    'id': 'demo_hdfc',
                    'name': 'HDFC Bank',
                    'number': '2345',
                    'type': 'Bank',
                    'vpa': '$uid.hdfc@invispay'
                  },
                ];

                for (var demo in demoAccounts) {
                  accounts.add(QrAccount(
                    id: demo['id']!,
                    name: demo['name']!,
                    number: demo['number']!,
                    type: demo['type']!,
                    vpa: demo['vpa']!,
                  ));
                  seenNumbers.add(demo['number']!);
                }

                final docs = snapshot.data?.docs ?? [];
                for (var doc in docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  if (data['isActive'] == true) {
                    final number = data['number']?.toString() ?? '';
                    final last4 = number.length > 4
                        ? number.substring(number.length - 4)
                        : number;

                    if (!seenNumbers.contains(last4)) {
                      final type =
                          data['type']?.toString().contains('Wallet') == true
                              ? 'Wallet'
                              : 'Bank';
                      accounts.add(QrAccount(
                        id: doc.id,
                        name: data['bankName'] ?? 'Bank Account',
                        number: last4,
                        type: type,
                        vpa: '$uid.${type.toLowerCase()}@invispay',
                      ));
                    }
                  }
                }

                if (accounts.isEmpty) {
                  _isDataLoaded = true;
                  return _buildNoAccountsState(context, l10n);
                }

                if (selectedAccount == null && accounts.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ref
                        .read(qrSelectionProvider.notifier)
                        .selectAccount(accounts.first);
                  });
                }

                final current = selectedAccount ?? accounts.first;
                _isDataLoaded = true;

                return Column(
                  children: [
                    _buildAccountSelector(context, accounts, current),
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: ScaleTransition(
                                  scale: Tween<double>(begin: 0.98, end: 1.0)
                                      .animate(CurvedAnimation(
                                          parent: animation,
                                          curve: Curves.easeOutCubic)),
                                  child: child,
                                ),
                              );
                            },
                            child: Container(
                              key: ValueKey(current.id),
                              child: _buildQrCard(context, uid, current),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            )
          : _buildPrivacyMessage(context, l10n),
    );
  }

  Widget _buildAccountSelector(
      BuildContext context, List<QrAccount> accounts, QrAccount current) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      height: 84, // Slightly increased height for touch comfort
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // Premium Slate
        borderRadius: BorderRadius.circular(24), // Premium radius
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: LayoutBuilder(builder: (context, constraints) {
        return Theme(
          data: Theme.of(context).copyWith(
            popupMenuTheme: PopupMenuThemeData(
              color: const Color(0xFF1E293B), // Matches trigger
              elevation: 16,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              textStyle: GoogleFonts.inter(color: Colors.white),
            ),
          ),
          child: PopupMenuButton<QrAccount>(
            offset: const Offset(0, 90), // Forces menu strictly below
            constraints: BoxConstraints.tightFor(
                width: constraints.maxWidth), // Matches container width
            tooltip: '',
            itemBuilder: (context) {
              return accounts.map((account) {
                final isSelected = account.id == current.id;
                return PopupMenuItem<QrAccount>(
                  value: account,
                  height: 60, // Reduced base height
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4), // Reduced padding
                  child: _buildSelectorItem(account, isSelected: isSelected),
                );
              }).toList();
            },
            onSelected: (value) {
              ref.read(qrSelectionProvider.notifier).selectAccount(value);
            },
            child: Container(
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSelectorItem(current,
                        isSelected: false, forDisplay: true),
                  ),
                  const Icon(Icons.keyboard_arrow_down_rounded,
                      color: Colors.white70, size: 28),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSelectorItem(QrAccount account,
      {required bool isSelected, bool forDisplay = false}) {
    return Container(
      height: forDisplay ? 84 : 72,
      margin: forDisplay
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      padding:
          const EdgeInsets.symmetric(horizontal: 16), // Standardized padding
      decoration: BoxDecoration(
        color: isSelected && !forDisplay
            ? AppTheme.primary.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(16), // rounded selection in list
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
            child: Center(
              child: Icon(
                _getIconForType(account.type),
                size: 24,
                color:
                    isSelected && !forDisplay ? AppTheme.primary : Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  account.name,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold, // Bold bank name
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _getSubtitle(account), // Account type + masked number
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (!forDisplay)
            Visibility(
              visible: isSelected,
              maintainSize: true,
              maintainAnimation: true,
              maintainState: true,
              child: const Icon(
                Icons.check_circle_rounded, // Active selection indicator
                color: AppTheme.primary,
                size: 22,
              ),
            ),
        ],
      ),
    );
  }

  String _getSubtitle(QrAccount account) {
    String label = account.type == 'Bank' ? 'Savings' : account.type;
    return '$label • **** ${account.number}';
  }

  IconData _getIconForType(String type) {
    if (type == 'Wallet') return Icons.account_balance_wallet_rounded;
    return Icons.account_balance_rounded; // Only Bank and Wallet types remain
  }

  Widget _buildQrCard(BuildContext context, String uid, QrAccount account) {
    final qrData = jsonEncode({
      'uid': uid,
      'acc': account.number,
      'type': account.type,
      'v': 1,
    });

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Screenshot(
          controller: _screenshotController,
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 240.0,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Colors.black,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Scan to pay',
                  style: GoogleFonts.outfit(
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
                    fontSize: 24,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  account.name,
                  style: GoogleFonts.inter(
                    color: Colors.black54,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 48),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildActionButton(
                Icons.share_rounded, 'Share', () => _shareQrCode(account, uid)),
            const SizedBox(width: 32),
            _buildActionButton(Icons.save_alt_rounded, 'Download',
                () => _downloadQrCode(account)),
            const SizedBox(width: 32),
            _buildActionButton(
                Icons.copy_rounded, 'Copy UPI', () => _copyUpiId(account, uid)),
          ],
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(32),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _shareQrCode(QrAccount account, String uid) async {
    try {
      final image = await _screenshotController.capture();
      if (image == null) throw Exception('Capture failed');

      final directory = await getTemporaryDirectory();
      final imagePath = '${directory.path}/qr_${account.id}.png';
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(image);

      String upi = account.vpa ?? '$uid${account.vpaSuffix}';

      await Share.shareXFiles(
        [XFile(imagePath)],
        text: 'Pay to ${account.name} via InvisPay\nUPI: $upi',
        subject: 'InvisPay QR code',
      );
    } catch (e) {
      debugPrint('Share error: $e');
    }
  }

  void _downloadQrCode(QrAccount account) async {
    try {
      final image = await _screenshotController.capture();
      if (image == null) throw Exception('Capture failed');

      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) throw Exception('Storage inaccessible');

      final fileName =
          'InvisPay_QR_${account.name.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.png';
      final imagePath = '${directory.path}/$fileName';
      await File(imagePath).writeAsBytes(image);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('QR code saved to Downloads'),
            backgroundColor: AppTheme.primary,
          ),
        );
      }
    } catch (e) {
      debugPrint('Download error: $e');
    }
  }

  void _copyUpiId(QrAccount account, String uid) {
    String upiId = account.vpa ?? '$uid${account.vpaSuffix}';
    Clipboard.setData(ClipboardData(text: upiId));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('UPI ID copied: $upiId'),
        backgroundColor: AppTheme.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildErrorState(
      BuildContext context, AppLocalizations l10n, String error) {
    return Center(
        child: Text('Error loading accounts',
            style: TextStyle(color: Colors.white)));
  }

  Widget _buildNoAccountsState(BuildContext context, AppLocalizations l10n) {
    return Center(
        child:
            Text('No accounts found', style: TextStyle(color: Colors.white)));
  }

  Widget _buildPrivacyMessage(BuildContext context, AppLocalizations l10n) {
    return Center(
        child: Text('QR visibility is disabled',
            style: TextStyle(color: Colors.white)));
  }
}
