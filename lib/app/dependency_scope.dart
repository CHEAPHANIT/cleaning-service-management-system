import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/local/database_helper.dart';
import '../data/providers/app_providers.dart';
import '../data/repositories/repositories.dart';

/// Owns construction of the application-level dependencies.
class DependencyScope extends StatelessWidget {
  const DependencyScope({
    super.key,
    required this.database,
    required this.child,
  });

  final DatabaseHelper database;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
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
      child: child,
    );
  }
}
