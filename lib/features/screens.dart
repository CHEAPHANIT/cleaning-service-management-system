import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../core/constants.dart';
import '../core/file_download.dart';
import '../core/utils.dart';
import '../core/widgets.dart';
import '../data/models/models.dart';
import '../data/providers/app_providers.dart';
import '../data/remote/clean_now_api.dart';

part 'screens/splash_screen.dart';
part 'screens/onboarding_screen.dart';
part 'screens/login_screen.dart';
part 'screens/register_screen.dart';
part 'screens/cleaner_application_screen.dart';
part 'screens/unauthorized_screen.dart';
part 'screens/forgot_password_screen.dart';
part 'screens/shell_home_screens.dart';
part 'screens/admin_dashboard_screen.dart';
part 'screens/cleaner_screens.dart';
part 'screens/admin_customer_screens.dart';
part 'screens/admin_cleaner_management_screen.dart';
part 'screens/admin_operations_screens.dart';
part 'screens/service_screens.dart';
part 'screens/booking_screens.dart';
part 'screens/customer_screens.dart';
part 'screens/shared_screen_widgets.dart';

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

String dashboardRouteForRole(String role) => switch (role) {
  'admin' => AdminDashboardRoute.route,
  'cleaner' => CleanerDashboardRoute.route,
  _ => CustomerDashboardRoute.route,
};

class CustomerDashboardRoute {
  static const route = '/customer/dashboard';
}

class CustomerProfileRoute {
  static const route = '/customer/profile';
}

class CleanerDashboardRoute {
  static const route = '/cleaner/dashboard';
}

class CleanerAssignedJobsRoute {
  static const route = '/cleaner/assigned-jobs';
}

class AdminDashboardRoute {
  static const route = '/admin/dashboard';
}

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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            LoginScreen.route,
            (_) => false,
          );
        }
      });
      return const SizedBox.shrink();
    }
    if (requiredRole != null && user.role != requiredRole) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Navigator.pushReplacementNamed(
            context,
            dashboardRouteForRole(user.role),
          );
        }
      });
      return const SizedBox.shrink();
    }
    return child;
  }
}
