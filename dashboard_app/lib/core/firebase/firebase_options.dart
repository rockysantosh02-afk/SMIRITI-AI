import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default Firebase options for the Smriti AI dashboard app.
/// 
/// For web: Uses values from firebase_web_config.txt
/// For Android: Requires google-services.json to be added to android/app/
/// For iOS: Requires GoogleService-Info.plist to be added to ios/Runner/
class DefaultFirebaseOptions {
  /// Web Firebase configuration
  /// Values sourced from: docs/firebase_web_config.txt
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "YOUR_FIREBASE_WEB_API_KEY",
    authDomain: "smiriti-ai.firebaseapp.com",
    projectId: "smiriti-ai",
    storageBucket: "smiriti-ai.firebasestorage.app",
    messagingSenderId: "YOUR_MESSAGING_SENDER_ID",
    appId: "YOUR_FIREBASE_APP_ID",
    measurementId: "YOUR_MEASUREMENT_ID",
  );

  /// Android Firebase configuration
  /// 
  /// To enable Android Firebase:
  /// 1. Go to Firebase Console > Project Settings > General
  /// 2. Add an Android app with package name: com.smriti.ai.dashboard
  /// 3. Download google-services.json
  /// 4. Place it in: dashboard_app/android/app/google-services.json
  /// 5. Uncomment the android section in pubspec.yaml google-services dependency
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "YOUR_ANDROID_API_KEY",
    authDomain: "smiriti-ai.firebaseapp.com",
    projectId: "smiriti-ai",
    storageBucket: "smiriti-ai.firebasestorage.app",
    messagingSenderId: "348047548865",
    appId: "1:348047548865:android:YOUR_APP_ID",
  );

  /// iOS Firebase configuration
  /// 
  /// To enable iOS Firebase:
  /// 1. Go to Firebase Console > Project Settings > General
  /// 2. Add an iOS app with bundle ID: com.smriti.ai.dashboard
  /// 3. Download GoogleService-Info.plist
  /// 4. Place it in: dashboard_app/ios/Runner/GoogleService-Info.plist
  /// 5. Update ios/Runner/Info.plist as needed
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: "YOUR_IOS_API_KEY",
    authDomain: "smiriti-ai.firebaseapp.com",
    projectId: "smiriti-ai",
    storageBucket: "smiriti-ai.firebasestorage.app",
    messagingSenderId: "348047548865",
    appId: "1:348047548865:ios:YOUR_APP_ID",
  );

  /// Returns the appropriate FirebaseOptions based on the current platform
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return ios; // macOS uses same config as iOS
      default:
        // Default to web for unsupported platforms (Windows, Linux)
        // These would need platform-specific configuration
        return web;
    }
  }
}
