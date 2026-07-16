import 'package:flutter/material.dart';

import '../features/screens.dart';
import 'app_router.dart';
import 'app_theme.dart';

class CleanNowApp extends StatelessWidget {
  const CleanNowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CleanNow',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routes: appRoutes,
      initialRoute: SplashScreen.route,
    );
  }
}
