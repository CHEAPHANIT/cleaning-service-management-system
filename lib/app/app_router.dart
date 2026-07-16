import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/widgets.dart';
import '../data/providers/app_providers.dart';
import '../features/screens.dart';
import 'route_names.dart';

final appRoutes = <String, WidgetBuilder>{
  SplashScreen.route: (_) => const SplashScreen(),
  OnboardingScreen.route: (_) => const OnboardingScreen(),
  LoginScreen.route: (_) => const LoginScreen(),
  RegisterScreen.route: (_) => const RegisterScreen(),
  CleanerApplicationScreen.route: (_) => const CleanerApplicationScreen(),
  UnauthorizedScreen.route: (_) => const UnauthorizedScreen(),
  ForgotPasswordScreen.route: (_) => const ForgotPasswordScreen(),
  ShellScreen.route: (_) => const AuthGate(child: ShellScreen()),
  CustomerDashboardRoute.route: (_) =>
      const AuthGate(requiredRole: 'customer', child: ShellScreen()),
  CustomerProfileRoute.route: (_) => const AuthGate(
    requiredRole: 'customer',
    child: ShellScreen(initialIndex: 3),
  ),
  CleanerDashboardRoute.route: (_) =>
      const AuthGate(requiredRole: 'cleaner', child: ShellScreen()),
  CleanerAssignedJobsRoute.route: (_) =>
      const AuthGate(requiredRole: 'cleaner', child: ShellScreen()),
  AdminDashboardRoute.route: (_) =>
      const AuthGate(requiredRole: 'admin', child: ShellScreen()),
  AdminCleanerApplicationsScreen.route: (_) => const AuthGate(
    requiredRole: 'admin',
    child: AdminCleanerApplicationsScreen(),
  ),
  AdminCleanerApplicationDetailScreen.route: (_) => const AuthGate(
    requiredRole: 'admin',
    child: AdminCleanerApplicationDetailScreen(),
  ),
  ServiceListScreen.route: (_) =>
      const AuthGate(requiredRole: 'customer', child: ServiceListScreen()),
  ServiceDetailScreen.route: (_) =>
      const AuthGate(requiredRole: 'customer', child: ServiceDetailScreen()),
  BookingFormScreen.route: (_) =>
      const AuthGate(requiredRole: 'customer', child: BookingFormScreen()),
  BookingSuccessScreen.route: (_) =>
      const AuthGate(requiredRole: 'customer', child: BookingSuccessScreen()),
  BookingDetailScreen.route: (_) =>
      const AuthGate(child: BookingDetailScreen()),
  ProductListScreen.route: (_) =>
      const AuthGate(requiredRole: 'customer', child: ProductListScreen()),
  ProductDetailScreen.route: (_) =>
      const AuthGate(requiredRole: 'customer', child: ProductDetailScreen()),
  NotificationScreen.route: (_) => const AuthGate(child: NotificationScreen()),
  EditProfileScreen.route: (_) => const AuthGate(child: EditProfileScreen()),
  ReviewScreen.route: (_) =>
      const AuthGate(requiredRole: 'customer', child: ReviewScreen()),
  TipsScreen.route: (_) =>
      const AuthGate(requiredRole: 'customer', child: TipsScreen()),
};

class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.child, this.requiredRole});

  final Widget child;
  final String? requiredRole;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.initialized) return const LoadingWidget();

    final user = auth.user;
    if (user == null) {
      _redirectAfterBuild(context, LoginScreen.route, clearHistory: true);
      return const SizedBox.shrink();
    }

    if (requiredRole != null && user.role != requiredRole) {
      _redirectAfterBuild(context, dashboardRouteForRole(user.role));
      return const SizedBox.shrink();
    }

    return child;
  }

  void _redirectAfterBuild(
    BuildContext context,
    String route, {
    bool clearHistory = false,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;

      if (clearHistory) {
        Navigator.pushNamedAndRemoveUntil(context, route, (_) => false);
      } else {
        Navigator.pushReplacementNamed(context, route);
      }
    });
  }
}
