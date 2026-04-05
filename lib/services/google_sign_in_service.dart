import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Google Sign-In service for Firebase Authentication.
///
/// ■ iOS セットアップ（CocoaPods 経由 — SPM 不要）
///   google_sign_in プラグインが Podfile に GoogleSignIn ~> 8.0 を
///   自動で追加するため、手動での SPM 追加は不要です。
///   必要なのは下記 2 点のみです:
///
///   1. GoogleService-Info.plist に CLIENT_ID / REVERSED_CLIENT_ID を追加する
///      → Firebase Console → Authentication → Google を有効化後、
///        最新の GoogleService-Info.plist をダウンロードして Runner/ に置く
///
///   2. Info.plist の CFBundleURLSchemes に REVERSED_CLIENT_ID を設定する
///      → すでに $(REVERSED_CLIENT_ID) を参照するよう設定済み。
///        Xcode の Build Settings → User-Defined に
///        REVERSED_CLIENT_ID = (GoogleService-Info.plist の値) を追加するだけでOK
///
///   3. AppDelegate.swift に GIDSignIn.sharedInstance.handle(url) を追加する
///      → 実装済み
///
/// ■ Android セットアップ
///   google-services.json に OAuth クライアント (client_type: 3) が含まれている
///   必要があります。Firebase Console で Google Sign-In を有効化すると
///   自動的に追加されます。最新の google-services.json を
///   android/app/ に置き直してください。
///
/// ■ アカウント重複ポリシー
///   Firebase Console の Authentication → Settings →
///   "Email address uniqueness" を "Prevent creation of multiple accounts with
///   the same email address" (= One account per email) に設定している場合:
///   同じメールアドレスで Apple ID と Google の両方でログインしようとすると
///   `account-exists-with-different-credential` エラーが発生します。
///   このサービスは、その場合に既存アカウントへ Google クレデンシャルを
///   自動リンクして一つのアカウントに統合します。
///
class GoogleSignInService {
  static const String _prefKeyGoogleUid = 'google_user_uid';
  static const String _prefKeyGoogleEmail = 'google_user_email';
  static const String _prefKeyGoogleDisplayName = 'google_display_name';
  static const String _prefKeyGooglePhotoUrl = 'google_photo_url';

  // GoogleSignIn インスタンスをクラスレベルで保持し、
  // signIn() と signOut() で同一インスタンスを共有する。
  //
  // serverClientId: Android の google-services.json に含まれる
  // ANDROID_CLIENT_ID ではなく、OAuth 2.0 の「ウェブクライアント ID」を指定する。
  // Firebase Console → Authentication → Sign-in method → Google →
  // 「ウェブSDK構成」に表示されるクライアントIDを使用する。
  // iOS は GoogleService-Info.plist の CLIENT_ID が自動的に使用されるため不要。
  // serverClientId: OAuth 2.0 ウェブクライアント ID（client_type: 3）
  // google-services.json の oauth_client から取得
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId:
        '123107533000-8q5kiogihgfkrql554mu28a89hher0p5.apps.googleusercontent.com',
  );

  /// Google Sign-In を実行して FirebaseAuth と連携する。
  ///
  /// 戻り値: [GoogleSignInResult]
  ///   - success: true  → ログイン成功
  ///   - isCanceled: true → ユーザーがキャンセル
  ///   - errorMessage: non-null → エラー詳細
  static Future<GoogleSignInResult> signIn() async {
    try {
      if (kIsWeb) {
        return await _signInWeb();
      }
      return await _signInNative();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[GoogleSignIn] Unexpected error: $e');
      }
      return GoogleSignInResult(
        success: false,
        errorMessage: '接続エラーが発生しました。\nネットワーク接続を確認してもう一度お試しください。',
      );
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Native (iOS / Android) サインイン
  // ─────────────────────────────────────────────────────────────
  static Future<GoogleSignInResult> _signInNative() async {
    try {
      // Google サインイン画面を表示
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // ユーザーがキャンセルした場合
      if (googleUser == null) {
        return GoogleSignInResult(success: false, isCanceled: true);
      }

      // Google OAuth トークンを取得
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Firebase 用クレデンシャルを作成
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Firebase にサインイン（アカウント重複時は自動リンクを試みる）
      final UserCredential userCredential =
          await _signInWithCredentialHandlingDuplicate(credential);

      final User? user = userCredential.user;
      if (user == null) {
        return GoogleSignInResult(
          success: false,
          errorMessage: 'Firebase認証に失敗しました。もう一度お試しください。',
        );
      }

      await _cacheUserInfo(user);

      return GoogleSignInResult(
        success: true,
        uid: user.uid,
        displayName: user.displayName ?? googleUser.displayName ?? 'Googleユーザー',
        email: user.email ?? googleUser.email,
        photoUrl: user.photoURL ?? googleUser.photoUrl ?? '',
      );
    } on FirebaseAuthException catch (e) {
      return _handleFirebaseAuthError(e);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[GoogleSignIn] Native sign-in error: $e');
      }
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('network') || errorStr.contains('timeout')) {
        return GoogleSignInResult(
          success: false,
          errorMessage: 'ネットワークエラーが発生しました。\n接続を確認してもう一度お試しください。',
        );
      }
      return GoogleSignInResult(
        success: false,
        errorMessage: 'Googleサインインに失敗しました。\nもう一度お試しください。',
      );
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Web サインイン (signInWithPopup)
  // ─────────────────────────────────────────────────────────────
  static Future<GoogleSignInResult> _signInWeb() async {
    try {
      final GoogleAuthProvider googleProvider = GoogleAuthProvider()
        ..addScope('email')
        ..addScope('profile');

      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithPopup(googleProvider);

      final User? user = userCredential.user;
      if (user == null) {
        return GoogleSignInResult(
          success: false,
          errorMessage: 'Firebase認証に失敗しました。もう一度お試しください。',
        );
      }

      await _cacheUserInfo(user);

      return GoogleSignInResult(
        success: true,
        uid: user.uid,
        displayName: user.displayName ?? 'Googleユーザー',
        email: user.email ?? '',
        photoUrl: user.photoURL ?? '',
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'popup-closed-by-user' ||
          e.code == 'cancelled-popup-request') {
        return GoogleSignInResult(success: false, isCanceled: true);
      }
      return _handleFirebaseAuthError(e);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[GoogleSignIn] Web sign-in error: $e');
      }
      return GoogleSignInResult(
        success: false,
        errorMessage: 'Googleサインインに失敗しました。\nもう一度お試しください。',
      );
    }
  }

  // ─────────────────────────────────────────────────────────────
  // アカウント重複を処理しながら Firebase サインイン
  //
  // Firebase の "One account per email" が有効な場合、
  // 同じメールアドレスで別プロバイダ（Apple ID 等）が既にある状態で
  // Google サインインすると account-exists-with-different-credential が発生する。
  //
  // このメソッドでは:
  //   1. まず通常の signInWithCredential を試みる
  //   2. account-exists-with-different-credential の場合:
  //      - Firebase に既存プロバイダでサインイン済みなら Google クレデンシャルをリンク
  //      - 未サインインの場合はユーザーに既存方法でのログインを案内するエラーを返す
  //
  // 注意: Apple ID 側でのサインインが完了していない（未 Firebase ログイン）状態では
  //       自動リンクは行えない。ユーザーに「Appleでサインイン」を促すメッセージを出す。
  // ─────────────────────────────────────────────────────────────
  static Future<UserCredential> _signInWithCredentialHandlingDuplicate(
      OAuthCredential googleCredential) async {
    try {
      return await FirebaseAuth.instance
          .signInWithCredential(googleCredential);
    } on FirebaseAuthException catch (e) {
      if (e.code != 'account-exists-with-different-credential') {
        rethrow; // 他のエラーはそのまま上位へ
      }

      // ── アカウント重複の自動リンク処理 ─────────────────────────────
      if (kDebugMode) {
        debugPrint('[GoogleSignIn] account-exists-with-different-credential: '
            'attempting auto-link. email=${e.email}');
      }

      // 既に Firebase にサインイン済みのユーザーがいる場合（Apple ID 等でログイン済み）
      // → Google クレデンシャルをリンクしてアカウントを統合する
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        try {
          final linked = await currentUser.linkWithCredential(googleCredential);
          if (kDebugMode) {
            debugPrint('[GoogleSignIn] Auto-linked Google to existing account: '
                '${currentUser.uid}');
          }
          return linked;
        } catch (linkError) {
          if (kDebugMode) {
            debugPrint('[GoogleSignIn] Auto-link failed: $linkError');
          }
          // リンク失敗時は元の重複エラーを再 throw
          rethrow;
        }
      }

      // Firebase 未サインイン状態 → 自動リンク不可。元のエラーを再 throw して
      // _handleFirebaseAuthError で適切なメッセージを表示する
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Firebase Auth エラーをユーザー向けメッセージに変換
  // ─────────────────────────────────────────────────────────────
  static GoogleSignInResult _handleFirebaseAuthError(FirebaseAuthException e) {
    if (kDebugMode) {
      debugPrint('[GoogleSignIn] FirebaseAuth error: ${e.code} - ${e.message}');
    }

    final String errorMessage;
    switch (e.code) {
      case 'account-exists-with-different-credential':
        // Firebase の "One account per email" が有効な場合に発生する。
        // 同じメールアドレスで Apple ID が登録済みのケースが最も多い。
        errorMessage =
            'このメールアドレスは既に別のログイン方法（Apple IDなど）で登録されています。\n\n'
            '「Appleでサインイン」をお試しください。\n'
            'Appleでサインイン後、次回以降はGoogleでもログインできるようになります。';
        break;
      case 'invalid-credential':
        errorMessage = '認証情報が無効です。もう一度お試しください。';
        break;
      case 'operation-not-allowed':
        // Firebase Console で Google プロバイダが未有効化
        errorMessage = 'Googleサインインが現在無効になっています。\n'
            'Firebase Console → Authentication → Sign-in method で\n'
            'Googleを有効化してください。';
        break;
      case 'user-disabled':
        errorMessage = 'このアカウントは無効化されています。\nサポートにお問い合わせください。';
        break;
      case 'network-request-failed':
        errorMessage = 'ネットワークエラーが発生しました。\n接続を確認してもう一度お試しください。';
        break;
      case 'too-many-requests':
        errorMessage = 'リクエストが多すぎます。\n少し時間を置いてからお試しください。';
        break;
      case 'user-not-found':
        errorMessage = 'アカウントが見つかりません。\n新規登録してください。';
        break;
      default:
        errorMessage = '認証エラーが発生しました（${e.code}）。\nもう一度お試しください。';
    }

    return GoogleSignInResult(success: false, errorMessage: errorMessage);
  }

  // ─────────────────────────────────────────────────────────────
  // ユーザー情報を SharedPreferences にキャッシュ
  // ─────────────────────────────────────────────────────────────
  static Future<void> _cacheUserInfo(User user) async {
    final prefs = await SharedPreferences.getInstance();
    if (user.uid.isNotEmpty) {
      await prefs.setString(_prefKeyGoogleUid, user.uid);
    }
    if (user.email != null && user.email!.isNotEmpty) {
      await prefs.setString(_prefKeyGoogleEmail, user.email!);
    }
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      await prefs.setString(_prefKeyGoogleDisplayName, user.displayName!);
    }
    if (user.photoURL != null && user.photoURL!.isNotEmpty) {
      await prefs.setString(_prefKeyGooglePhotoUrl, user.photoURL!);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // サインアウト (Google + Firebase 両方)
  // ─────────────────────────────────────────────────────────────
  static Future<void> signOut() async {
    try {
      if (!kIsWeb) {
        await _googleSignIn.signOut();
      }
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[GoogleSignIn] Sign out error: $e');
      }
    }
  }

  /// キャッシュされた Google ユーザーデータを削除（ログアウト・アカウント削除時）
  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKeyGoogleUid);
    await prefs.remove(_prefKeyGoogleEmail);
    await prefs.remove(_prefKeyGoogleDisplayName);
    await prefs.remove(_prefKeyGooglePhotoUrl);
  }

  /// Firebase に現在サインイン済みのユーザーがいるか
  static bool get isSignedIn => FirebaseAuth.instance.currentUser != null;

  /// 現在の Firebase ユーザー（未サインインなら null）
  static User? get currentUser => FirebaseAuth.instance.currentUser;
}

// ─────────────────────────────────────────────────────────────
// Google Sign-In の結果を表すデータクラス
// ─────────────────────────────────────────────────────────────
class GoogleSignInResult {
  final bool success;
  final String uid;
  final String displayName;
  final String email;
  final String photoUrl;
  final String? errorMessage;
  final bool isCanceled;

  GoogleSignInResult({
    required this.success,
    this.uid = '',
    this.displayName = '',
    this.email = '',
    this.photoUrl = '',
    this.errorMessage,
    this.isCanceled = false,
  });
}
