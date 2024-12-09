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
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBzdxjTqXpD-Ig9-7Z3fBbd1sXX5vQltz4',
    appId: '1:293518669331:android:31feb1ef6e183b6c8b31e6',
    messagingSenderId: '293518669331',
    projectId: 'fihirana-jff',
    authDomain: 'fihirana-jff.firebaseapp.com',
    databaseURL: 'https://fihirana-jff-default-rtdb.firebaseio.com',
    storageBucket: 'fihirana-jff.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBzdxjTqXpD-Ig9-7Z3fBbd1sXX5vQltz4',
    appId: '1:293518669331:android:31feb1ef6e183b6c8b31e6',
    messagingSenderId: '293518669331',
    projectId: 'fihirana-jff',
    databaseURL: 'https://fihirana-jff-default-rtdb.firebaseio.com',
    storageBucket: 'fihirana-jff.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBzdxjTqXpD-Ig9-7Z3fBbd1sXX5vQltz4',
    appId: '1:293518669331:android:31feb1ef6e183b6c8b31e6',
    messagingSenderId: '293518669331',
    projectId: 'fihirana-jff',
    databaseURL: 'https://fihirana-jff-default-rtdb.firebaseio.com',
    storageBucket: 'fihirana-jff.firebasestorage.app',
    iosClientId: '293518669331-um9st6ar1dj57439ljhbvaml0ouoefsb.apps.googleusercontent.com',
    iosBundleId: 'com.manasseh.fihirana_jff',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBzdxjTqXpD-Ig9-7Z3fBbd1sXX5vQltz4',
    appId: '1:293518669331:android:31feb1ef6e183b6c8b31e6',
    messagingSenderId: '293518669331',
    projectId: 'fihirana-jff',
    databaseURL: 'https://fihirana-jff-default-rtdb.firebaseio.com',
    storageBucket: 'fihirana-jff.firebasestorage.app',
    iosClientId: '293518669331-um9st6ar1dj57439ljhbvaml0ouoefsb.apps.googleusercontent.com',
    iosBundleId: 'com.manasseh.fihirana_jff',
  );
}
