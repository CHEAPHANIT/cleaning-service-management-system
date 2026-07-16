import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

import '../data/local/database_helper.dart';
import '../firebase_options.dart';
import 'clean_now_app.dart';
import 'dependency_scope.dart';

/// Initializes platform services and starts the application.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  final database = DatabaseHelper(enableApi: true);
  await database.initialize();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await _initializeFacebookAuth();

  runApp(DependencyScope(database: database, child: const CleanNowApp()));
}

Future<void> _initializeFacebookAuth() async {
  const appId = String.fromEnvironment('FACEBOOK_APP_ID');
  if (appId.isEmpty) return;

  await FacebookAuth.instance.webAndDesktopInitialize(
    appId: appId,
    cookie: true,
    xfbml: true,
    version: 'v20.0',
  );
}
