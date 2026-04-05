import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/paywall_screen.dart';
import 'screens/post_screen.dart';

import 'main_shell.dart';
import 'models/user_profile_provider.dart';
import 'services/subscription_service.dart';
import 'services/ugc_moderation_service.dart';
import 'package:hive_flutter/hive_flutter.dart';

// スクリーンショット用URLルーティング（Web開発用）
Widget _resolveWebScreen() {
  final screen = Uri.base.queryParameters['screen'];
  switch (screen) {
    case 'login':      return const LoginScreen();
    case 'trend':      return const MainShell(initialTab: 1);
    case 'post':       return const PostScreen();
    case 'prefecture': return const MainShell(initialTab: 3);
    case 'profile':    return const MainShell(initialTab: 4);
    case 'paywall':    return const PaywallScreen();
  }
  // Web プレビューはデフォルトでマップ画面を表示（ログイン不要）
  return const MainShell(initialTab: 0);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (required for Google Sign-In / Firebase Auth)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Firebase init may fail on web with placeholder config.
    // App can still render; Google Sign-In will show an error on attempt.
    debugPrint('[Firebase] Initialization error: $e');
  }

  // Initialize Hive (local DB for UGC moderation, settings, etc.)
  await Hive.initFlutter();
  await UgcModerationService.init();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Web: resolve screen from URL query params
  if (kIsWeb) {
    runApp(ShotmapApp(home: _resolveWebScreen()));
    return;
  }

  // Native: check login state. Subscription check happens inside SplashRouter.
  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool('is_logged_in') ?? false;

  final Widget home;
  if (isLoggedIn) {
    // Use SplashRouter: it waits for SubscriptionService to init,
    // then routes to MainShell or PaywallScreen accordingly.
    home = const _SplashRouter();
  } else {
    home = const LoginScreen();
  }

  runApp(ShotmapApp(home: home));
}

class ShotmapApp extends StatelessWidget {
  final Widget home;
  const ShotmapApp({super.key, required this.home});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProfileProvider()),
        ChangeNotifierProvider(create: (_) => SubscriptionService()),
      ],
      child: MaterialApp(
        title: 'Shot map',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: home,
        routes: {
          '/main': (_) => const MainShell(),
          '/login': (_) => const LoginScreen(),
        },
      ),
    );
  }
}

/// Splash router that waits for SubscriptionService to finish initialization,
/// then routes to the correct screen.
///
/// IMPORTANT: Uses ONLY the cached SharedPreferences value to decide routing.
/// Silent restore may detect Sandbox/TestFlight past purchases and set
/// isSubscribed=true, but we must NOT auto-skip the PaywallScreen based on
/// that. The user must explicitly purchase or restore on the PaywallScreen.
///
/// Routing logic:
/// - If cached pref says subscribed → go to MainShell (user paid before)
/// - Otherwise → always show PaywallScreen (even if silentRestore found subs)
class _SplashRouter extends StatefulWidget {
  const _SplashRouter();

  @override
  State<_SplashRouter> createState() => _SplashRouterState();
}

class _SplashRouterState extends State<_SplashRouter> {
  @override
  void initState() {
    super.initState();
    _waitAndRoute();
  }

  Future<void> _waitAndRoute() async {
    // Read the user-confirmed subscription state.
    // ONLY 'is_subscribed_confirmed' is set by explicit user actions
    // (purchase / restore on PaywallScreen). Silent restore never sets this.
    final prefs = await SharedPreferences.getInstance();
    final userConfirmedSubscribed =
        prefs.getBool('is_subscribed_confirmed') ?? false;

    // Still wait for init to complete so the service is ready
    final sub = context.read<SubscriptionService>();
    await sub.waitForInit();

    if (!mounted) return;

    // Route based on user-confirmed state ONLY.
    // If user previously completed a purchase/restore explicitly → MainShell.
    // Otherwise → always show PaywallScreen (even if silentRestore found subs).
    final Widget destination =
        userConfirmedSubscribed ? const MainShell() : const PaywallScreen();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => destination,
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Minimal splash screen while waiting for subscription check
    return const Scaffold(
      backgroundColor: Color(0xFF3D8FBF),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_on, size: 48, color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Shot map',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
            SizedBox(height: 24),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
