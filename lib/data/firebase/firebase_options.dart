// Default Firebase Options configuration for Swimming Academy Management System
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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA_DEMO_KEY_SWIMMING_WORLD_ACADEMY',
    appId: '1:1234567890:web:abcdef1234567890',
    messagingSenderId: '1234567890',
    projectId: 'swimming-world-academy',
    authDomain: 'swimming-world-academy.firebaseapp.com',
    storageBucket: 'swimming-world-academy.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA_DEMO_KEY_SWIMMING_WORLD_ACADEMY',
    appId: '1:1234567890:android:abcdef1234567890',
    messagingSenderId: '1234567890',
    projectId: 'swimming-world-academy',
    storageBucket: 'swimming-world-academy.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA_DEMO_KEY_SWIMMING_WORLD_ACADEMY',
    appId: '1:1234567890:ios:abcdef1234567890',
    messagingSenderId: '1234567890',
    projectId: 'swimming-world-academy',
    storageBucket: 'swimming-world-academy.appspot.com',
    iosBundleId: 'com.swimmingworld.academy',
  );
}
