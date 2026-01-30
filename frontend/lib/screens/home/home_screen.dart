import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:invispay/core/theme/app_theme.dart';
import 'package:invispay/providers/settings_provider.dart';
import 'package:invispay/routes/app_routes.dart';
import 'package:invispay/services/auth_service.dart';
import 'package:invispay/services/database_service.dart';
import 'package:invispay/widgets/common/base_screen.dart';
import 'package:invispay/widgets/common/animated_localize.dart';
import 'package:invispay/services/kyc_service.dart';
import 'package:intl/intl.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isBalanceVisible = true;
  final AuthService _auth = AuthService();
  final DatabaseService _db = DatabaseService();

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final isDemo = user == null || !_db.isConfigured;
    final uid = user?.uid ?? 'demo';

    return BaseScreen(
      appBar: AppBar(
        toolbarHeight: 0,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsetsDirectional.fromSTEB(24, 60, 24, 24),
        child: Column(
          children: [
            // Header & KYC
            isDemo
                ? _buildMockHomeHeader(context)
                : _buildHomeHeader(context, uid),
            const SizedBox(height: 24),

            // Balance Card with Entrance Animation
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: isDemo
                  ? _buildMockBalanceCard(context)
                  : _buildBalanceCard(context, uid),
            ),
// ... rest of build method ...
            const SizedBox(height: 24),

            // Quick Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionButtons(
                  context,
                  (loc) => loc.scan,
                  Icons.qr_code_scanner,
                  () {},
                ),
                _buildActionButtons(
                    context, (loc) => loc.send, Icons.send_rounded, () {
                  context.push(AppRoutes.makeTransaction);
                }),
                _buildActionButtons(
                  context,
                  (loc) => loc.request,
                  Icons.call_received_rounded,
                  () {
                    context.push(AppRoutes.requestMoney);
                  },
                ),
                _buildActionButtons(
                    context, (loc) => loc.historyLabel, Icons.history_rounded,
                    () {
                  context.go(AppRoutes.history);
                }),
              ],
            ),

            const SizedBox(height: 32),

            // Recent Activity Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AnimatedLocalize(
                  text: (loc) => loc.recentActivity,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                TextButton(
                  onPressed: () => context.push(AppRoutes.history),
                  child: AnimatedLocalize(
                    text: (loc) => loc.viewAll,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Mock Recent Items
            _buildRecentItem('Starbucks', '- ₹375.00', DateTime.now()),
            _buildRecentItem('Apple Store', '- ₹95,000.00', DateTime.now()),
            _buildRecentItem(
              'Salary',
              '+ ₹1,50,000.00',
              DateTime.now().subtract(const Duration(days: 1)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context, String uid) {
    final settings = ref.watch(settingsProvider);
    final isVisible = !settings.hideBalance && _isBalanceVisible;

    return StreamBuilder<DocumentSnapshot>(
      stream: _db.getUserStream(uid),
      builder: (context, userSnapshot) {
        final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
        final primaryId = userData?['primaryAccountId'];

        return StreamBuilder<QuerySnapshot>(
          stream: _db.getAccountsStream(uid),
          builder: (context, accountsSnapshot) {
            final docs = accountsSnapshot.data?.docs ?? [];
            if (docs.isEmpty) return const SizedBox.shrink();

            // Find primary account or fallback to first
            final primaryDoc = docs.firstWhere(
              (doc) =>
                  (doc.data() as Map<String, dynamic>)['number'] == primaryId,
              orElse: () => docs.first,
            );

            final data = primaryDoc.data() as Map<String, dynamic>;
            final balance = (data['balance'] ?? 0.0) as num;
            final type = data['type'] ?? 'Account';
            final id = data['number'] ?? 'Unknown';

            final balanceText =
                accountsSnapshot.connectionState == ConnectionState.waiting
                    ? '...'
                    : '₹ ${NumberFormat('#,##,###.##').format(balance)}';

            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.push('${AppRoutes.accountDetails}/$id'),
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.secondary,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.secondary.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                    gradient: LinearGradient(
                      begin: AlignmentDirectional.topStart,
                      end: AlignmentDirectional.bottomEnd,
                      colors: [AppTheme.secondary, AppTheme.primary],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                type.toUpperCase(),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              AnimatedLocalize(
                                text: (loc) => loc.totalBalance,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color:
                                          Colors.white.withValues(alpha: 0.7),
                                    ),
                              ),
                            ],
                          ),
                          InkWell(
                            onTap: () {
                              setState(() {
                                _isBalanceVisible = !_isBalanceVisible;
                              });
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Icon(
                                isVisible
                                    ? Icons.remove_red_eye_outlined
                                    : Icons.visibility_off_outlined,
                                color: Colors.white70,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      AnimatedCrossFade(
                        duration: const Duration(milliseconds: 200),
                        firstChild: Text(
                          balanceText,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                        secondChild: const Text(
                          '****',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                        crossFadeState: isVisible
                            ? CrossFadeState.showFirst
                            : CrossFadeState.showSecond,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '**** ${id.split('_').last}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.arrow_forward_ios_rounded,
                              color: Colors.white70, size: 14),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    String Function(AppLocalizations) label,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: AppTheme.primary),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 80,
          child: AnimatedLocalize(
            text: label,
            textAlign: TextAlign.center,
            useFittedBox: true,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentItem(String title, String amount, DateTime date) {
    final isCredit = amount.startsWith('+');
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: AppTheme.surface,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.backgroundLight,
          child: Icon(
            isCredit ? Icons.arrow_downward : Icons.shopping_bag_outlined,
            color: AppTheme.textSecondary,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          DateFormat('MMM d, h:mm a').format(date),
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Text(
          amount,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isCredit ? AppTheme.primary : AppTheme.textPrimary,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildHomeHeader(BuildContext context, String uid) {
    final l10n = AppLocalizations.of(context);
    return StreamBuilder<DocumentSnapshot>(
      stream: _db.getUserStream(uid),
      builder: (context, snapshot) {
        final userData = snapshot.data?.data() as Map<String, dynamic>?;
        final name = userData?['displayName'];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedLocalize(
                        text: (loc) => loc.welcome,
                        useFittedBox: true,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        name ?? 'InvisPay User',
                        style: Theme.of(context).textTheme.headlineMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                StreamBuilder<Map<String, dynamic>?>(
                  stream: KycService().kycStatusStream,
                  builder: (context, kycSnapshot) {
                    final kycData = kycSnapshot.data;
                    final status = kycData?['kycStatus'] ?? 'not_started';
                    return _buildKycStatusChip(context, status);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Search Bar (New Feature)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: l10n.translate('search_hint'),
                  hintStyle:
                      const TextStyle(color: Colors.white38, fontSize: 14),
                  border: InputBorder.none,
                  icon: const Icon(Icons.search, color: Colors.white38),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  filled: false,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildKycStatusChip(BuildContext context, String kycStatus) {
    final normalizedStatus = kycStatus.toString().toLowerCase();

    // Status configuration
    final Color statusColor;
    final IconData statusIcon;
    final String Function(AppLocalizations) statusTextBuilder;
    final bool isTappable;

    switch (normalizedStatus) {
      case 'verified':
        statusColor = const Color(0xFF10B981);
        statusIcon = Icons.check_circle_rounded;
        statusTextBuilder = (loc) => loc.kycStatusVerified;
        isTappable = false;
        break;
      case 'pending':
        statusColor = const Color(0xFFF59E0B);
        statusIcon = Icons.access_time_rounded;
        statusTextBuilder = (loc) => loc.kycStatusPending;
        isTappable = true;
        break;
      case 'failed':
      case 'not_verified':
        statusColor = const Color(0xFFEF4444);
        statusIcon = Icons.error_rounded;
        statusTextBuilder = (loc) => loc.kycStatusFailed;
        isTappable = true;
        break;
      case 'demo':
      case 'not_started':
      default:
        statusColor = const Color(0xFF64748B);
        statusIcon = Icons.shield_outlined;
        statusTextBuilder = (loc) => loc.kycVerification;
        isTappable = true;
        break;
    }

    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusIcon,
            color: statusColor,
            size: 16,
          ),
          const SizedBox(width: 6),
          AnimatedLocalize(
            text: statusTextBuilder,
            useFittedBox: true,
            style: TextStyle(
              color: statusColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );

    if (!isTappable) {
      return chip;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push(AppRoutes.kyc),
        borderRadius: BorderRadius.circular(20),
        child: chip,
      ),
    );
  }

  Widget _buildMockHomeHeader(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedLocalize(
                    text: (loc) => loc.welcome,
                    useFittedBox: true,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  AnimatedLocalize(
                    text: (loc) => loc.translate('demo_user'),
                    useFittedBox: true,
                    style: Theme.of(context).textTheme.headlineMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            StreamBuilder<Map<String, dynamic>?>(
              stream: KycService().kycStatusStream,
              builder: (context, kycSnapshot) {
                final kycData = kycSnapshot.data;
                final status = kycData?['kycStatus'] ?? 'not_started';
                return _buildKycStatusChip(context, status);
              },
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: TextField(
            decoration: InputDecoration(
              hintText: l10n.translate('search_hint'),
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
              border: InputBorder.none,
              icon: const Icon(Icons.search, color: Colors.white38),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              filled: false,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMockBalanceCard(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    final isVisible = !settings.hideBalance && _isBalanceVisible;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.secondary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.secondary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.secondary, AppTheme.primary],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AnimatedLocalize(
                text: (loc) => loc.totalBalance,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
              ),
              InkWell(
                onTap: () {
                  setState(() {
                    _isBalanceVisible = !_isBalanceVisible;
                  });
                },
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Icon(
                    isVisible
                        ? Icons.remove_red_eye_outlined
                        : Icons.visibility_off_outlined,
                    color: Colors.white70,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            firstChild: const Text(
              '₹ 8,450.00',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
            secondChild: const Text(
              '****',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
            crossFadeState: isVisible
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  l10n.cardEndingDigits('0000'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(Icons.wifi, color: Colors.white70),
            ],
          ),
        ],
      ),
    );
  }
}

class _KycBadge extends StatefulWidget {
  final String status;
  const _KycBadge({required this.status});

  @override
  State<_KycBadge> createState() => _KycBadgeState();
}

class _KycBadgeState extends State<_KycBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.6, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isVerified = widget.status.toLowerCase() == 'verified';
    final color = isVerified ? const Color(0xFF00E676) : AppTheme.accent;

    String statusText;
    if (widget.status.toLowerCase() == 'verified') {
      statusText = l10n.kycStatusVerified;
    } else if (widget.status.toLowerCase() == 'failed') {
      statusText = l10n.kycStatusFailed;
    } else {
      statusText = l10n.kycStatusPending;
    }

    final icon = isVerified ? Icons.check_circle : Icons.access_time_filled;

    return FadeTransition(
      opacity: _opacity,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF2D2D3A),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Text(
              statusText,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, color: color, size: 16),
          ],
        ),
      ),
    );
  }
}
