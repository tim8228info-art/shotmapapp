import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/paywall_screen.dart';
import 'screens/post_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/trend_screen.dart';
import 'screens/movie_screen.dart';
import 'main_shell.dart';
import 'models/user_profile_provider.dart';
import 'services/subscription_service.dart';

// スクリーンショット用URLルーティング（Web開発用）
Widget _resolveWebScreen() {
  final screen = Uri.base.queryParameters['screen'];
  switch (screen) {
    case 'main':       return const MainShell(initialTab: 0);
    case 'trend':      return const MainShell(initialTab: 1);
    case 'post':       return const PostScreen();
    case 'prefecture': return const MainShell(initialTab: 3);
    case 'profile':    return const MainShell(initialTab: 4);
    case 'paywall':    return const PaywallScreen();
  }
  return const LoginScreen();
}

Future<Widget> _resolveHome() async {
  // Web（スクリーンショット用）はURLパラメータで画面切替
  if (kIsWeb) return _resolveWebScreen();

  // ネイティブ：ログイン済みかチェック
  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
  if (isLoggedIn) {
    // サブスク状態は SubscriptionService が初期化後に確認するため
    // ここではメインシェルへ直接遷移（未サブスクならPaywallが表示される）
    return const MainShell();
  }
  return const LoginScreen();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  final homeWidget = await _resolveHome();
  runApp(ShotmapApp(home: homeWidget));
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
        title: 'Shotmap',
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
