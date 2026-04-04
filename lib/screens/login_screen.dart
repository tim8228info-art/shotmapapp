import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../main_shell.dart';
import '../models/user_profile_provider.dart';
import '../services/subscription_service.dart';
import '../services/apple_sign_in_service.dart';
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
    // iPad adaptive padding
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final horizontalPadding = isTablet ? screenWidth * 0.15 : 32.0;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: const Color(0xFF3D8FBF)),
          Positioned.fill(
            child: Image.asset(
              'assets/images/fuji_bg.png',
              fit: BoxFit.cover,
              alignment: const Alignment(0.0, -0.3),
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
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.25),
            ),
          ),
          Positioned(
            bottom: 0, left: 0, right: 0, height: 460,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xAA000000), Color(0xDD000000)],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Padding(
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
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 88, height: 88,
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
          const Icon(Icons.location_on, size: 48, color: AppColors.primary),
          Positioned(
            bottom: 18, right: 18,
            child: Container(
              width: 26, height: 26,
              decoration: BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.camera_alt, size: 13, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginCard(BuildContext context, {bool isTablet = false}) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 36 : 28),
      constraints: const BoxConstraints(maxWidth: 500),
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
