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
    apiKey: 'AIzaSyDDGf76SMC80YPYSQb3tCE1UANnEvKIbBM',
    appId: '1:84036767534:android:a05af2c0ddc00a7dd3b4bf',
    messagingSenderId: '84036767534',
    projectId: 'swimming-world-branch-2',
    authDomain: 'swimming-world-branch-2.firebaseapp.com',
    storageBucket: 'swimming-world-branch-2.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDDGf76SMC80YPYSQb3tCE1UANnEvKIbBM',
    appId: '1:84036767534:android:a05af2c0ddc00a7dd3b4bf',
    messagingSenderId: '84036767534',
    projectId: 'swimming-world-branch-2',
    storageBucket: 'swimming-world-branch-2.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDDGf76SMC80YPYSQb3tCE1UANnEvKIbBM',
    appId: '1:84036767534:android:a05af2c0ddc00a7dd3b4bf',
    messagingSenderId: '84036767534',
    projectId: 'swimming-world-branch-2',
    storageBucket: 'swimming-world-branch-2.firebasestorage.app',
    iosBundleId: 'com.swimmingworld.branch2',
  );
}
