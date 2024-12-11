import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'Web is not supported in this app.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'iOS is not supported in this app.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'macOS is not supported in this app.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'Windows is not supported in this app.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'Linux is not supported in this app.',
        );
      default:
        throw UnsupportedError(
          'Unknown platform ${defaultTargetPlatform}',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBPtBg7RPhc62ET3rsuiqj5a_hb4kZkNsI',  // from api_key[0].current_key
    appId: '1:1022559095772:android:003162aa088f9671459d19',  // from client_info.mobilesdk_app_id
    messagingSenderId: '1022559095772',  // from project_info.project_number
    projectId: 'hci-group-13',  // from project_info.project_id
    databaseURL: 'https://hci-group-13-default-rtdb.firebaseio.com',  // Your Realtime Database URL
  );
} 