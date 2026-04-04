import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Apple Sign In service for iOS/macOS.
/// Handles ASAuthorizationController with proper error handling,
/// iPad compatibility, and timeout/retry logic.
class AppleSignInService {
  static const String _prefKeyAppleUserId = 'apple_user_id';
  static const String _prefKeyAppleEmail = 'apple_user_email';
  static const String _prefKeyAppleDisplayName = 'apple_display_name';
  static const int _maxRetries = 2;

  /// Generate a random nonce for Apple Sign In security.
  static String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  /// SHA256 hash of the nonce for Apple.
  static String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Check if Apple Sign In is available on this device.
  static Future<bool> isAvailable() async {
    if (kIsWeb) return false;
    try {
      return await SignInWithApple.isAvailable();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AppleSignIn] isAvailable error: $e');
      }
      return false;
    }
  }

  /// Perform Apple Sign In with automatic retry on transient failures.
  /// Returns [AppleSignInResult] with user info on success,
  /// or an error message on failure.
  static Future<AppleSignInResult> signIn() async {
    AppleSignInResult? lastResult;
    for (int attempt = 0; attempt <= _maxRetries; attempt++) {
      lastResult = await _attemptSignIn();
      if (lastResult.success || lastResult.isCanceled) {
        return lastResult;
      }
      // Only retry on network/transient errors, not auth failures
      if (attempt < _maxRetries) {
        final isRetryable = lastResult.errorMessage?.contains('接続') == true ||
            lastResult.errorMessage?.contains('タイムアウト') == true;
        if (!isRetryable) return lastResult;
        if (kDebugMode) {
          debugPrint('[AppleSignIn] Retry attempt ${attempt + 1}/$_maxRetries');
        }
        await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
      }
    }
    return lastResult!;
  }

  /// Single sign-in attempt.
  static Future<AppleSignInResult> _attemptSignIn() async {
    try {
      final rawNonce = _generateNonce();
      final hashedNonce = _sha256ofString(rawNonce);

      // Use WebAuthenticationOptions for proper iPad presentation context.
      // The sign_in_with_apple plugin handles ASAuthorizationController
      // delegate and presentationContextProviding internally.
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      ).timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw AppleSignInException('認証がタイムアウトしました。もう一度お試しください。');
        },
      );

      // Extract user info from credential
      final userIdentifier = credential.userIdentifier ?? '';
      final email = credential.email;
      final givenName = credential.givenName;
      final familyName = credential.familyName;

      // Build display name
      String displayName = '';
      if (givenName != null && givenName.isNotEmpty) {
        displayName = givenName;
        if (familyName != null && familyName.isNotEmpty) {
          displayName = '$familyName $givenName'; // Japanese order
        }
      }

      // Apple only sends name/email on FIRST sign in.
      // Cache them for subsequent logins.
      final prefs = await SharedPreferences.getInstance();

      if (userIdentifier.isNotEmpty) {
        await prefs.setString(_prefKeyAppleUserId, userIdentifier);
      }

      // Save email if provided (first sign-in only)
      if (email != null && email.isNotEmpty) {
        await prefs.setString(_prefKeyAppleEmail, email);
      }

      // Save display name if provided (first sign-in only)
      if (displayName.isNotEmpty) {
        await prefs.setString(_prefKeyAppleDisplayName, displayName);
      }

      // On subsequent logins, retrieve cached name/email
      final cachedEmail = prefs.getString(_prefKeyAppleEmail) ?? email ?? '';
      final cachedName =
          displayName.isNotEmpty
              ? displayName
              : (prefs.getString(_prefKeyAppleDisplayName) ?? 'Appleユーザー');

      // Authorization token for server verification
      final identityToken = credential.identityToken;
      final authorizationCode = credential.authorizationCode;

      if (kDebugMode) {
        debugPrint('[AppleSignIn] Success: user=$userIdentifier');
        debugPrint('[AppleSignIn] hasIdentityToken=${identityToken != null}');
        debugPrint('[AppleSignIn] hasAuthCode=${authorizationCode.isNotEmpty}');
      }

      return AppleSignInResult(
        success: true,
        userIdentifier: userIdentifier,
        displayName: cachedName,
        email: cachedEmail,
        identityToken: identityToken,
        authorizationCode: authorizationCode,
        rawNonce: rawNonce,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      // Handle specific Apple Sign In errors
      String errorMessage;
      switch (e.code) {
        case AuthorizationErrorCode.canceled:
          errorMessage = 'サインインがキャンセルされました';
          break;
        case AuthorizationErrorCode.failed:
          errorMessage = '認証に失敗しました。もう一度お試しください。';
          break;
        case AuthorizationErrorCode.invalidResponse:
          errorMessage = 'Appleからの応答が無効です。もう一度お試しください。';
          break;
        case AuthorizationErrorCode.notHandled:
          errorMessage = '認証リクエストを処理できませんでした。';
          break;
        case AuthorizationErrorCode.notInteractive:
          errorMessage = '認証画面を表示できませんでした。';
          break;
        case AuthorizationErrorCode.unknown:
          errorMessage = '不明なエラーが発生しました。もう一度お試しください。';
          break;
      }

      if (kDebugMode) {
        debugPrint('[AppleSignIn] AuthError: ${e.code} - ${e.message}');
      }

      return AppleSignInResult(
        success: false,
        errorMessage: errorMessage,
        isCanceled: e.code == AuthorizationErrorCode.canceled,
      );
    } on AppleSignInException catch (e) {
      return AppleSignInResult(
        success: false,
        errorMessage: e.message,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AppleSignIn] Unexpected error: $e');
      }
      return AppleSignInResult(
        success: false,
        errorMessage: '接続エラーが発生しました。ネットワーク接続を確認してもう一度お試しください。',
      );
    }
  }

  /// Check credential state for existing Apple user.
  /// Used on app startup to verify the user is still authorized.
  static Future<bool> checkCredentialState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(_prefKeyAppleUserId);
      if (userId == null || userId.isEmpty) return false;

      final state = await SignInWithApple.getCredentialState(userId);
      return state == CredentialState.authorized;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AppleSignIn] checkCredentialState error: $e');
      }
      return false;
    }
  }

  /// Clear cached Apple user data (used on logout/account deletion).
  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKeyAppleUserId);
    await prefs.remove(_prefKeyAppleEmail);
    await prefs.remove(_prefKeyAppleDisplayName);
  }
}

/// Result of Apple Sign In attempt.
class AppleSignInResult {
  final bool success;
  final String userIdentifier;
  final String displayName;
  final String email;
  final String? identityToken;
  final String? authorizationCode;
  final String? rawNonce;
  final String? errorMessage;
  final bool isCanceled;

  AppleSignInResult({
    required this.success,
    this.userIdentifier = '',
    this.displayName = '',
    this.email = '',
    this.identityToken,
    this.authorizationCode,
    this.rawNonce,
    this.errorMessage,
    this.isCanceled = false,
  });
}

/// Custom exception for Apple Sign In.
class AppleSignInException implements Exception {
  final String message;
  AppleSignInException(this.message);

  @override
  String toString() => 'AppleSignInException: $message';
}
