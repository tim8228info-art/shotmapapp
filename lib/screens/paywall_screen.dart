import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/subscription_service.dart';
import '../main_shell.dart';
import 'terms_screen.dart';
import 'privacy_screen.dart';

class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

  // Dark theme colors
  static const _bgTop = Color(0xFF0B1A2E);
  static const _bgBottom = Color(0xFF0F2540);
  static const _cardBg = Color(0xFF132A45);
  static const _priceBg = Color(0xFF1565C0);
  static const _ctaColor = Color(0xFF2196F3);
  static const _textWhite = Colors.white;
  static const _textGray = Color(0xFF8DA4BE);
  static const _checkGreen = Color(0xFF4CAF50);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgTop,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_bgTop, _bgBottom],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            child: Column(
              children: [
                const SizedBox(height: 24),
                // App icon
                _buildAppIcon(),
                const SizedBox(height: 20),
                // App name
                const Text(
                  'Shot Map',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: _textWhite,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'すべての機能を月額500円でご利用いただけます',
                  style: TextStyle(
                    fontSize: 14,
                    color: _textGray,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                // Feature card
                _buildFeatureCard(),
                const SizedBox(height: 20),
                // Pricing card
                _buildPricingCard(),
                const SizedBox(height: 20),
                // CTA button
                _buildCtaButton(context),
                const SizedBox(height: 16),
                // Apple-required subscription disclaimer (Guideline 3.1.2)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  decoration: BoxDecoration(
                    color: _cardBg.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'サブスクリプションは確認後、お客様のApple IDアカウントに請求されます。'
                    '現在の期間が終了する24時間以上前にキャンセルしない限り、'
                    'サブスクリプションは自動的に更新されます。'
                    '更新料金は現在の期間終了前の24時間以内に請求されます。'
                    '購入後、設定アプリからサブスクリプションの管理・キャンセルが可能です。',
                    style: TextStyle(fontSize: 11, color: _textGray, height: 1.6),
                    textAlign: TextAlign.left,
                  ),
                ),
                const SizedBox(height: 12),
                // Restore purchases button (required by Apple App Review)
                _buildRestoreButton(context),
                const SizedBox(height: 16),
                // Footer links
                _buildFooterLinks(context),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppIcon() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Center(
        child: Icon(
          Icons.location_on,
          size: 44,
          color: Color(0xFFE53935),
        ),
      ),
    );
  }

  Widget _buildFeatureCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          _buildFeatureRow(
            icon: Icons.location_on_outlined,
            iconBg: const Color(0xFF1E88E5),
            title: 'スポット無制限保存',
            subtitle: 'お気に入りの場所をいくつでも記録',
          ),
          const SizedBox(height: 18),
          _buildFeatureRow(
            icon: Icons.camera_alt_outlined,
            iconBg: const Color(0xFFE91E63),
            title: '写真付きで投稿・共有',
            subtitle: '風景・グルメ写真をマップに投稿',
          ),
          const SizedBox(height: 18),
          _buildFeatureRow(
            icon: Icons.trending_up,
            iconBg: const Color(0xFF43A047),
            title: 'トレンドスポット発見',
            subtitle: '世界中のユーザーの投稿をチェック',
          ),
          const SizedBox(height: 18),
          _buildFeatureRow(
            icon: Icons.share_outlined,
            iconBg: const Color(0xFFFF9800),
            title: 'SNS 共有機能',
            subtitle: 'Instagram・Xで友達にシェア',
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required Color iconBg,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: iconBg.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconBg, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _textWhite,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: _textGray,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: _checkGreen,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, color: Colors.white, size: 16),
        ),
      ],
    );
  }

  Widget _buildPricingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _priceBg.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '月額利用料金',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFFBBDEFB),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Text(
                '500円',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                '/ 月（税込）',
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFFBBDEFB),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildBadge(Icons.refresh, '1ヶ月ごとに自動更新'),
              const SizedBox(width: 10),
              _buildBadge(Icons.cancel_outlined, 'いつでもキャンセル可'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white.withValues(alpha: 0.9)),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCtaButton(BuildContext context) {
    return Consumer<SubscriptionService>(
      builder: (context, sub, _) {
        // Auto-navigate when subscription becomes active
        // (purchase confirmed via stream listener)
        if (sub.isSubscribed && !sub.isLoading) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const MainShell()),
              );
            }
          });
        }

        return SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: sub.isLoading
                ? null
                : () async {
                    // Start purchase flow - navigation will happen
                    // automatically when purchase is confirmed via listener
                    await sub.purchaseMonthlyPlan();
                    // If purchase completed synchronously (web),
                    // the Consumer above will trigger navigation
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: _ctaColor,
              foregroundColor: Colors.white,
              elevation: 8,
              shadowColor: _ctaColor.withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: sub.isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    '500円 / 月 で始める',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildRestoreButton(BuildContext context) {
    return Consumer<SubscriptionService>(
      builder: (context, sub, _) {
        return TextButton(
          onPressed: sub.isLoading
              ? null
              : () async {
                  await sub.restorePurchases();
                  if (context.mounted && sub.isSubscribed) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const MainShell()),
                    );
                  } else if (context.mounted && !sub.isSubscribed) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          '有効なサブスクリプションが見つかりませんでした',
                          style: TextStyle(fontSize: 13),
                        ),
                        backgroundColor: const Color(0xFF455A64),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.all(16),
                      ),
                    );
                  }
                },
          child: sub.isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _textGray,
                  ),
                )
              : const Text(
                  '以前の購入を復元',
                  style: TextStyle(
                    fontSize: 13,
                    color: _textGray,
                    decoration: TextDecoration.underline,
                    decorationColor: _textGray,
                  ),
                ),
        );
      },
    );
  }

  Widget _buildFooterLinks(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PrivacyScreen()),
          ),
          child: const Text(
            'プライバシーポリシー',
            style: TextStyle(
              fontSize: 12,
              color: _textGray,
              decoration: TextDecoration.underline,
              decorationColor: _textGray,
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            '・',
            style: TextStyle(fontSize: 12, color: _textGray),
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const TermsScreen()),
          ),
          child: const Text(
            'Shot Map 利用規約',
            style: TextStyle(
              fontSize: 12,
              color: _textGray,
              decoration: TextDecoration.underline,
              decorationColor: _textGray,
            ),
          ),
        ),
      ],
    );
  }
}
