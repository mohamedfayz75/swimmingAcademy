// Default Firebase Options configuration for Swimming Academy Management System - Branch 3 (Air Force)
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
    apiKey: 'AIzaSyBgyrmA8spee66izRAQnujzs7ob6EAumqw',
    appId: '1:487435251373:android:574b52aaa7864357b1a024',
    messagingSenderId: '487435251373',
    projectId: 'swimming-branch-3',
    authDomain: 'swimming-branch-3.firebaseapp.com',
    storageBucket: 'swimming-branch-3.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBgyrmA8spee66izRAQnujzs7ob6EAumqw',
    appId: '1:487435251373:android:574b52aaa7864357b1a024',
    messagingSenderId: '487435251373',
    projectId: 'swimming-branch-3',
    storageBucket: 'swimming-branch-3.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBgyrmA8spee66izRAQnujzs7ob6EAumqw',
    appId: '1:487435251373:android:574b52aaa7864357b1a024',
    messagingSenderId: '487435251373',
    projectId: 'swimming-branch-3',
    storageBucket: 'swimming-branch-3.firebasestorage.app',
    iosBundleId: 'com.swimmingworld.airforce',
  );
}
