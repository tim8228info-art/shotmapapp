import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Google Sign-In service for Firebase Authentication.
///
/// IMPORTANT: Before using this service, ensure the following Firebase Console settings:
///   1. Go to Firebase Console → Authentication → Sign-in method
///   2. Enable "Google" as a sign-in provider
///   3. Set your project support email
///   4. For iOS: Add your iOS client ID to GoogleService-Info.plist
///   5. For Android: Add SHA-1/SHA-256 fingerprints in Firebase Console → Project settings
///
/// For iOS (Swift Package Manager):
///   - Add GoogleSignIn-iOS package via Xcode:
///     File → Add Packages → https://github.com/google/GoogleSignIn-iOS
///   - Add the reversed client ID to Info.plist URL schemes
///
/// For Android:
///   - google-services.json must include oauth_client with client_type 3
///     (web client ID) for Google Sign-In to work
///
class GoogleSignInService {
  static const String _prefKeyGoogleUid = 'google_user_uid';
  static const String _prefKeyGoogleEmail = 'google_user_email';
  static const String _prefKeyGoogleDisplayName = 'google_display_name';
  static const String _prefKeyGooglePhotoUrl = 'google_photo_url';

  /// Perform Google Sign-In with Firebase Authentication.
  ///
  /// Returns [GoogleSignInResult] with user info on success,
  /// or an error message on failure.
  static Future<GoogleSignInResult> signIn() async {
    try {
      // Web platform: use signInWithPopup for better UX
      if (kIsWeb) {
        return await _signInWeb();
      }

      // Native (iOS/Android): use GoogleSignIn SDK
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

  /// Native Google Sign-In (iOS/Android) with Firebase Auth.
  static Future<GoogleSignInResult> _signInNative() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );

      // Trigger the Google Sign-In flow
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      // User canceled the sign-in
      if (googleUser == null) {
        return GoogleSignInResult(
          success: false,
          isCanceled: true,
        );
      }

      // Obtain auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a Firebase credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      // linkWithCredential is NOT used here to avoid complexity;
      // Firebase automatically handles email-based account linking
      // when "One account per email address" is enabled in Firebase Console.
      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      final User? user = userCredential.user;
      if (user == null) {
        return GoogleSignInResult(
          success: false,
          errorMessage: 'Firebase認証に失敗しました。もう一度お試しください。',
        );
      }

      // Cache user info for subsequent app launches
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

      // Check for specific error types
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

  /// Web platform Google Sign-In using Firebase Auth signInWithPopup.
  static Future<GoogleSignInResult> _signInWeb() async {
    try {
      final GoogleAuthProvider googleProvider = GoogleAuthProvider();
      googleProvider.addScope('email');
      googleProvider.addScope('profile');

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
      // Handle popup closed by user
      if (e.code == 'popup-closed-by-user' ||
          e.code == 'cancelled-popup-request') {
        return GoogleSignInResult(
          success: false,
          isCanceled: true,
        );
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

  /// Handle Firebase Auth specific errors with user-friendly messages.
  static GoogleSignInResult _handleFirebaseAuthError(
      FirebaseAuthException e) {
    if (kDebugMode) {
      debugPrint('[GoogleSignIn] FirebaseAuth error: ${e.code} - ${e.message}');
    }

    String errorMessage;
    switch (e.code) {
      case 'account-exists-with-different-credential':
        // This occurs when the same email is used with a different provider.
        // Guide the user to sign in with the existing provider.
        errorMessage =
            'このメールアドレスは既に別のログイン方法で登録されています。\n'
            '以前使用したログイン方法でサインインしてください。';
        break;
      case 'invalid-credential':
        errorMessage = '認証情報が無効です。もう一度お試しください。';
        break;
      case 'operation-not-allowed':
        errorMessage = 'Googleサインインが現在無効になっています。\n管理者にお問い合わせください。';
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
      default:
        errorMessage = '認証エラーが発生しました（${e.code}）。\nもう一度お試しください。';
    }

    return GoogleSignInResult(
      success: false,
      errorMessage: errorMessage,
    );
  }

  /// Cache user info in SharedPreferences for subsequent app launches.
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

  /// Sign out from both Google and Firebase.
  static Future<void> signOut() async {
    try {
      if (!kIsWeb) {
        final GoogleSignIn googleSignIn = GoogleSignIn();
        await googleSignIn.signOut();
      }
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[GoogleSignIn] Sign out error: $e');
      }
    }
  }

  /// Clear cached Google user data (used on logout/account deletion).
  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKeyGoogleUid);
    await prefs.remove(_prefKeyGoogleEmail);
    await prefs.remove(_prefKeyGoogleDisplayName);
    await prefs.remove(_prefKeyGooglePhotoUrl);
  }

  /// Check if there is a currently signed-in Firebase user.
  static bool get isSignedIn => FirebaseAuth.instance.currentUser != null;

  /// Get the current Firebase user (null if not signed in).
  static User? get currentUser => FirebaseAuth.instance.currentUser;
}

/// Result of Google Sign-In attempt.
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
