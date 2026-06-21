// File generated manually based on google-services.json
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
        return windows;
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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDhCZaFRjKacioWOZuDezQkZRmWmcOAZk0',
    appId: '1:927335940649:android:ea7643e5793eeaf412d238',
    messagingSenderId: '927335940649',
    projectId: 'agesense-dbc8c',
    storageBucket: 'agesense-dbc8c.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCtfUS-6Rj886ILIAS5k0oNdRJOVrAN_hc',
    appId: '1:927335940649:web:5ba056064b959a3112d238',
    messagingSenderId: '927335940649',
    projectId: 'agesense-dbc8c',
    authDomain: 'agesense-dbc8c.firebaseapp.com',
    storageBucket: 'agesense-dbc8c.firebasestorage.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCawtKbrR19WWz7Rvncr6oDdveRlN2Fz98',
    appId: '1:927335940649:ios:00116e21512e046012d238',
    messagingSenderId: '927335940649',
    projectId: 'agesense-dbc8c',
    storageBucket: 'agesense-dbc8c.firebasestorage.app',
    iosBundleId: 'com.example.flutterApplication1',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCawtKbrR19WWz7Rvncr6oDdveRlN2Fz98',
    appId: '1:927335940649:ios:00116e21512e046012d238',
    messagingSenderId: '927335940649',
    projectId: 'agesense-dbc8c',
    storageBucket: 'agesense-dbc8c.firebasestorage.app',
    iosBundleId: 'com.example.flutterApplication1',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCtfUS-6Rj886ILIAS5k0oNdRJOVrAN_hc',
    appId: '1:927335940649:web:b95f6fab2a8a638612d238',
    messagingSenderId: '927335940649',
    projectId: 'agesense-dbc8c',
    authDomain: 'agesense-dbc8c.firebaseapp.com',
    storageBucket: 'agesense-dbc8c.firebasestorage.app',
  );
}
