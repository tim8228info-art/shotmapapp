import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../main_shell.dart';
import '../models/user_profile_provider.dart';
import '../services/subscription_service.dart';
import '../services/apple_sign_in_service.dart';
import '../services/google_sign_in_service.dart';
import 'paywall_screen.dart';
import 'terms_screen.dart';
import 'privacy_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  bool _isLoading = false;
  String? _loadingProvider; // which button is loading

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _saveLoginState({
    required String provider,
    required String displayName,
    String? email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', true);
    await prefs.setString('login_provider', provider);
    await prefs.setString('display_name', displayName);
    if (email != null) await prefs.setString('user_email', email);
  }

  Future<void> _navigateAfterLogin(BuildContext context) async {
    final sub = context.read<SubscriptionService>();
    if (sub.isLoading) {
      await Future.delayed(const Duration(milliseconds: 800));
    }
    if (!context.mounted) return;

    if (sub.isSubscribed) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const MainShell(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const PaywallScreen()),
      );
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message, style: const TextStyle(fontSize: 13)),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFE53935),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: '閉じる',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  // ─── Apple Sign In (real implementation) ───
  Future<void> _onAppleSignIn(BuildContext context) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _loadingProvider = 'apple';
    });

    try {
      // Check availability first (iPad support included)
      final isAvailable = await AppleSignInService.isAvailable();

      if (!isAvailable) {
        if (!mounted) return;
        // Fallback for devices where Apple Sign In is not available
        if (kIsWeb) {
          // Web demo mode
          await _completeSocialLogin(
            context: this.context,
            provider: 'apple',
            displayName: 'Appleユーザー',
          );
          return;
        }
        _showErrorSnackBar('このデバイスではApple IDサインインを利用できません');
        return;
      }

      // Perform actual Apple Sign In (includes automatic retry for transient errors)
      final result = await AppleSignInService.signIn();

      if (!mounted) return;

      if (result.success) {
        await _completeSocialLogin(
          context: this.context,
          provider: 'apple',
          displayName: result.displayName,
          email: result.email,
        );
      } else if (result.isCanceled) {
        // User canceled - do nothing, just reset state
        if (kDebugMode) {
          debugPrint('[Login] Apple Sign In canceled by user');
        }
      } else {
        // Show error dialog with retry option (better UX than snackbar for auth errors)
        _showSignInErrorDialog(
          result.errorMessage ?? '認証エラーが発生しました',
          onRetry: () => _onAppleSignIn(context),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Login] Apple Sign In unexpected error: $e');
      }
      if (mounted) {
        _showSignInErrorDialog(
          '接続エラーが発生しました。\nネットワーク接続を確認してもう一度お試しください。',
          onRetry: () => _onAppleSignIn(context),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadingProvider = null;
        });
      }
    }
  }

  /// Show an error dialog with retry option for sign-in failures.
  /// More visible and actionable than a SnackBar for authentication errors.
  void _showSignInErrorDialog(String message, {VoidCallback? onRetry}) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Color(0xFFE53935), size: 24),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'サインインエラー',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 14, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              '閉じる',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          if (onRetry != null)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                onRetry();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('もう一度試す'),
            ),
        ],
      ),
    );
  }

  // ─── Google Sign In ───
  Future<void> _onGoogleSignIn(BuildContext context) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _loadingProvider = 'google';
    });

    try {
      final result = await GoogleSignInService.signIn();

      if (!mounted) return;

      if (result.success) {
        await _completeSocialLogin(
          context: this.context,
          provider: 'google',
          displayName: result.displayName,
          email: result.email.isNotEmpty ? result.email : null,
        );

        // Update avatar with Google profile photo if available
        if (result.photoUrl.isNotEmpty && mounted) {
          final profileProvider = this.context.read<UserProfileProvider>();
          profileProvider.updateAvatar(result.photoUrl);
        }
      } else if (result.isCanceled) {
        // User canceled - do nothing
        if (kDebugMode) {
          debugPrint('[Login] Google Sign In canceled by user');
        }
      } else {
        _showSignInErrorDialog(
          result.errorMessage ?? '認証エラーが発生しました',
          onRetry: () => _onGoogleSignIn(context),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Login] Google Sign In unexpected error: $e');
      }
      if (mounted) {
        _showSignInErrorDialog(
          '接続エラーが発生しました。\nネットワーク接続を確認してもう一度お試しください。',
          onRetry: () => _onGoogleSignIn(context),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadingProvider = null;
        });
      }
    }
  }

  /// Google brand guideline compliant button.
  /// White background, Google "G" logo, and Japanese text.
  Widget _buildGoogleSignInButton(BuildContext context) {
    final isCurrentLoading = _isLoading && _loadingProvider == 'google';
    final isDisabled = _isLoading && !isCurrentLoading;

    return GestureDetector(
      onTap: isDisabled ? null : () => _onGoogleSignIn(context),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isDisabled ? 0.5 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFDADCE0), width: 1.5),
          ),
          child: Center(
            child: isCurrentLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Color(0xFF4285F4),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Google "G" logo (SVG-accurate colors)
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CustomPaint(
                          painter: _GoogleLogoPainter(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Googleでログイン',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3C4043),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // ─── Common login completion ───
  Future<void> _completeSocialLogin({
    required BuildContext context,
    required String provider,
    required String displayName,
    String? email,
  }) async {
    await _saveLoginState(
      provider: provider,
      displayName: displayName,
      email: email,
    );

    if (!context.mounted) return;
    final profileProvider = context.read<UserProfileProvider>();
    profileProvider.updateProfile(
      name: displayName,
      bio: profileProvider.bio,
      customId: profileProvider.customId,
      instagramUrl: profileProvider.instagramUrl,
      youtubeUrl: profileProvider.youtubeUrl,
      xUrl: profileProvider.xUrl,
      tiktokUrl: profileProvider.tiktokUrl,
    );

    if (!context.mounted) return;
    await _navigateAfterLogin(context);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;
    final isLandscape = screenWidth > screenHeight;
    // iPad 13インチ ランドスケープ対応
    final isLargeTablet = screenWidth > 1000;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── 背景色 ──
          Container(color: const Color(0xFF3D8FBF)),
          // ── 背景画像 ──
          Positioned.fill(
            child: Image.asset(
              'assets/images/fuji_bg.png',
              fit: BoxFit.cover,
              alignment: isLandscape
                  ? const Alignment(0.0, -0.2)
                  : const Alignment(0.0, -0.3),
              errorBuilder: (_, __, ___) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF5BA4CF), Color(0xFF2E7CB8)],
                  ),
                ),
              ),
            ),
          ),
          // ── ダークオーバーレイ ──
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.25),
            ),
          ),
          // ── 下部グラデーション ──
          Positioned(
            bottom: 0, left: 0, right: 0,
            height: isLandscape ? screenHeight * 0.85 : 460,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.55),
                    Colors.black.withValues(alpha: 0.80),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
          // ── コンテンツ ──
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: isLargeTablet && isLandscape
                    ? _buildLandscapeTabletLayout(context)
                    : _buildPortraitLayout(context, isTablet: isTablet),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// iPhone / iPad ポートレート用レイアウト（従来と同じ縦並び）
  Widget _buildPortraitLayout(BuildContext context, {bool isTablet = false}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = isTablet ? screenWidth * 0.15 : 32.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Column(
        children: [
          const SizedBox(height: 50),
          _buildLogo(),
          const SizedBox(height: 14),
          Text(
            'Shot map',
            style: TextStyle(
              fontSize: isTablet ? 44 : 38,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 1.5,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'あなたの「お気に入り」が',
            style: TextStyle(
              fontSize: isTablet ? 16 : 14,
              fontWeight: FontWeight.w400,
              color: Colors.white.withValues(alpha: 0.92),
              shadows: [Shadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 6)],
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            '誰かの「最高の景色」になる。',
            style: TextStyle(
              fontSize: isTablet ? 16 : 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              shadows: [Shadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 6)],
            ),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          _buildLoginCard(context, isTablet: isTablet),
          const SizedBox(height: 44),
        ],
      ),
    );
  }

  /// iPad 13インチ ランドスケープ用レイアウト
  /// iPhoneと全く同じ要素を横幅を活かしてセンタリング配置
  Widget _buildLandscapeTabletLayout(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── ロゴ（iPhoneと同じ） ──
              _buildLogo(size: 100),
              const SizedBox(height: 18),
              // ── アプリ名 ──
              Text(
                'Shot map',
                style: TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 1.5,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // ── サブタイトル（iPhoneと同じ） ──
              Text(
                'あなたの「お気に入り」が',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withValues(alpha: 0.92),
                  shadows: [Shadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 6)],
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                '誰かの「最高の景色」になる。',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  shadows: [Shadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 6)],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),
              // ── ログインカード（iPhoneと同じデザイン） ──
              _buildLoginCard(context, isTablet: true),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo({double size = 88}) {
    final iconSize = size * 0.545; // 48/88
    final cameraSize = size * 0.295; // 26/88
    final cameraIconSize = size * 0.148; // 13/88
    final cameraBottom = size * 0.205; // 18/88
    final cameraRight = size * 0.205;
    final cameraBorderWidth = size * 0.023; // 2/88

    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.30),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.location_on, size: iconSize, color: AppColors.primary),
          Positioned(
            bottom: cameraBottom, right: cameraRight,
            child: Container(
              width: cameraSize, height: cameraSize,
              decoration: BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: cameraBorderWidth),
              ),
              child: Icon(Icons.camera_alt, size: cameraIconSize, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginCard(BuildContext context, {bool isTablet = false}) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 36 : 28),
      constraints: BoxConstraints(maxWidth: isTablet ? 540 : 500),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.22),
            blurRadius: 36,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'はじめましょう',
            style: TextStyle(
              fontSize: isTablet ? 24 : 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '1分で登録完了！あなたの発見を共有しよう',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),

          // Apple Sign In
          _buildSocialButton(
            context: context,
            label: 'Appleでサインイン',
            color: Colors.black,
            icon: Icons.apple,
            provider: 'apple',
            onTap: () => _onAppleSignIn(context),
          ),
          const SizedBox(height: 12),

          // Google Sign In
          _buildGoogleSignInButton(context),
          const SizedBox(height: 20),

          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              children: [
                Text('ログインすることで',
                    style: TextStyle(fontSize: 10, color: AppColors.textHint)),
                GestureDetector(
                  onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const TermsScreen())),
                  child: Text('利用規約',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.primary,
                      )),
                ),
                Text('と',
                    style: TextStyle(fontSize: 10, color: AppColors.textHint)),
                GestureDetector(
                  onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PrivacyScreen())),
                  child: Text('プライバシーポリシー',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.primary,
                      )),
                ),
                Text('に同意します',
                    style: TextStyle(fontSize: 10, color: AppColors.textHint)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton({
    required BuildContext context,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required String provider,
    Color textColor = Colors.white,
    bool hasBorder = false,
    IconData? icon,
  }) {
    final isCurrentLoading = _isLoading && _loadingProvider == provider;
    final isDisabled = _isLoading && !isCurrentLoading;

    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isDisabled ? 0.5 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 52,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(14),
            border: hasBorder ? Border.all(color: AppColors.border, width: 1.5) : null,
            boxShadow: hasBorder
                ? null
                : [
                    BoxShadow(
                      color: color.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Center(
            child: isCurrentLoading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: textColor,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: textColor, size: 22),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Custom painter that draws the official Google "G" logo.
/// Follows Google branding guidelines with the four-color mark.
class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double cx = w / 2;
    final double cy = h / 2;
    final double r = w * 0.45;

    // Draw a simplified Google "G" logo using arcs
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.18
      ..strokeCap = StrokeCap.butt;

    // Blue arc (right portion / top-right)
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      -0.4, // start angle
      -2.2, // sweep angle (counterclockwise)
      false,
      paint,
    );

    // Green arc (bottom-left)
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      2.1,
      1.0,
      false,
      paint,
    );

    // Yellow arc (bottom)
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      1.1,
      1.0,
      false,
      paint,
    );

    // Red arc (top-left)
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      -2.6,
      1.0,
      false,
      paint,
    );

    // Horizontal bar of the "G" (blue)
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(cx - w * 0.02, cy - h * 0.08, w * 0.48, h * 0.16),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
