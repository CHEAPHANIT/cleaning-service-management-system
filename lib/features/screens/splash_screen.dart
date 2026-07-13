part of '../screens.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  static const route = '/';
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _navigateWhenReady());
  }

  Future<void> _navigateWhenReady() async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    while (mounted && !context.read<AuthProvider>().initialized) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    if (mounted) {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      final route = auth.loggedIn
          ? dashboardRouteForRole(auth.user!.role)
          : (auth.onboarded ? LoginScreen.route : OnboardingScreen.route);
      Navigator.pushReplacementNamed(context, route);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _AppLogoMark(size: 94, showShadow: true),
          const SizedBox(height: 18),
          const Text(
            AppStrings.appName,
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 20),
          const CircularProgressIndicator(),
        ],
      ),
    ),
  );
}
