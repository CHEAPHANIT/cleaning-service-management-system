import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

import 'app.dart';
import 'data/local/database_helper.dart';
import 'data/providers/app_providers.dart';
import 'data/repositories/repositories.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = DatabaseHelper(enableApi: true);
  await database.initialize();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  const facebookAppId = String.fromEnvironment('FACEBOOK_APP_ID');
  if (facebookAppId.isNotEmpty) {
    await FacebookAuth.instance.webAndDesktopInitialize(
      appId: facebookAppId,
      cookie: true,
      xfbml: true,
      version: 'v20.0',
    );
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) =>
              AuthProvider(AuthRepository(true), database)..bootstrap(),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              ServiceProvider(ServiceRepository(database))..loadServices(),
        ),
        ChangeNotifierProvider(create: (_) => FavoriteProvider(database)),
        ChangeNotifierProvider(create: (_) => BookingProvider(database)),
        ChangeNotifierProvider(
          create: (_) => AdminDataProvider(database)..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => ProductProvider(ProductRepository(database)),
        ),
        ChangeNotifierProvider(create: (_) => NotificationProvider(database)),
      ],
      child: const CleanNowApp(),
    ),
  );
}
