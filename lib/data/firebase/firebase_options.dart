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
    apiKey: 'AIzaSyDKoMDuOwBkjmUFg4Vmy73irLH7RRncK_8',
    appId: '1:923710235290:web:1e022affe9f6f61a67f523',
    messagingSenderId: '923710235290',
    projectId: 'swimming-world-academy',
    authDomain: 'swimming-world-academy.firebaseapp.com',
    storageBucket: 'swimming-world-academy.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDKoMDuOwBkjmUFg4Vmy73irLH7RRncK_8',
    appId: '1:923710235290:android:1e022affe9f6f61a67f523',
    messagingSenderId: '923710235290',
    projectId: 'swimming-world-academy',
    storageBucket: 'swimming-world-academy.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDKoMDuOwBkjmUFg4Vmy73irLH7RRncK_8',
    appId: '1:923710235290:ios:1e022affe9f6f61a67f523',
    messagingSenderId: '923710235290',
    projectId: 'swimming-world-academy',
    storageBucket: 'swimming-world-academy.firebasestorage.app',
    iosBundleId: 'com.swimmingworld.academy',
  );
}
