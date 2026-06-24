import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/local/database_helper.dart';
import 'data/providers/app_providers.dart';
import 'data/repositories/repositories.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = DatabaseHelper(enableApi: true);
  await database.initialize();

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
