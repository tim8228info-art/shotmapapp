// File generated for Firebase configuration
// Project: shotmap-app

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
        return android;
    }
  }

  // Android設定（google-services.jsonより）
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD3ivJIWDQkwPHi6rSq9TN-qO3dzWew3iA',
    appId: '1:123107533000:android:b1ff82cc555c875bba85fd',
    messagingSenderId: '123107533000',
    projectId: 'shotmap-app',
    storageBucket: 'shotmap-app.firebasestorage.app',
  );

  // iOS設定（GoogleService-Info.plistより）
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDIyFqBLbT9OyONC-kRVHAfs8XgWYz3jlo',
    appId: '1:123107533000:ios:1a671bc15cbfd4ffba85fd',
    messagingSenderId: '123107533000',
    projectId: 'shotmap-app',
    storageBucket: 'shotmap-app.firebasestorage.app',
    iosBundleId: 'com.shotmap.pins',
  );

  // Web設定（Maps JavaScript APIより）
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB8bm3RjpQ29OAw92YZiyaT7t23jQQFoJA',
    appId: '1:123107533000:web:shotmap',
    messagingSenderId: '123107533000',
    projectId: 'shotmap-app',
    storageBucket: 'shotmap-app.firebasestorage.app',
  );
}
