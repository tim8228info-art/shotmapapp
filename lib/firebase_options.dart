import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebase configuration options for Shot map.
///
/// These values are extracted from:
///   - android/app/google-services.json (Android)
///   - ios/Runner/GoogleService-Info.plist (iOS)
///   - Firebase Console → Project settings → Web app config (Web)
///
/// IMPORTANT: For Web platform, you must register a Web app in Firebase Console:
///   1. Go to Firebase Console → Project settings → General
///   2. Click "Add app" → Web (</> icon)
///   3. Register the app and copy the config values below
///   4. Also enable Google Sign-In in Authentication → Sign-in method
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  /// Web platform Firebase configuration.
  ///
  /// NOTE: Replace these values with your actual Firebase Web app config
  /// from Firebase Console → Project settings → General → Web apps.
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD3ivJIWDQkwPHi6rSq9TN-qO3dzWew3iA',
    appId: '1:123107533000:web:b1ff82cc555c875bba85fd',
    messagingSenderId: '123107533000',
    projectId: 'shotmap-app',
    authDomain: 'shotmap-app.firebaseapp.com',
    storageBucket: 'shotmap-app.firebasestorage.app',
  );

  /// Android platform Firebase configuration.
  /// Values from android/app/google-services.json.
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD3ivJIWDQkwPHi6rSq9TN-qO3dzWew3iA',
    appId: '1:123107533000:android:b1ff82cc555c875bba85fd',
    messagingSenderId: '123107533000',
    projectId: 'shotmap-app',
    storageBucket: 'shotmap-app.firebasestorage.app',
  );

  /// iOS platform Firebase configuration.
  /// Values from ios/Runner/GoogleService-Info.plist.
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDIyFqBLbT9OyONC-kRVHAfs8XgWYz3jlo',
    appId: '1:123107533000:ios:1a671bc15cbfd4ffba85fd',
    messagingSenderId: '123107533000',
    projectId: 'shotmap-app',
    storageBucket: 'shotmap-app.firebasestorage.app',
    iosBundleId: 'com.shotmap.pins',
    // CLIENT_ID from GoogleService-Info.plist (required for Google Sign-In on iOS)
    iosClientId: '123107533000-6q6h6gbvnhbqhm0bhfhqcksfa1ev3o3q.apps.googleusercontent.com',
  );
}
