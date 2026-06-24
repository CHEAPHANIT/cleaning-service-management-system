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
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';
import '../core/file_download.dart';
import '../core/utils.dart';
import '../core/widgets.dart';
import '../data/models/models.dart';
import '../data/providers/app_providers.dart';

final appRoutes = <String, WidgetBuilder>{
  SplashScreen.route: (_) => const SplashScreen(),
  OnboardingScreen.route: (_) => const OnboardingScreen(),
  LoginScreen.route: (_) => const LoginScreen(),
  RegisterScreen.route: (_) => const RegisterScreen(),
  ForgotPasswordScreen.route: (_) => const ForgotPasswordScreen(),
  ShellScreen.route: (_) => const ShellScreen(),
  ServiceListScreen.route: (_) => const ServiceListScreen(),
  ServiceDetailScreen.route: (_) => const ServiceDetailScreen(),
  BookingFormScreen.route: (_) => const BookingFormScreen(),
  BookingSuccessScreen.route: (_) => const BookingSuccessScreen(),
  BookingDetailScreen.route: (_) => const BookingDetailScreen(),
  ProductListScreen.route: (_) => const ProductListScreen(),
  ProductDetailScreen.route: (_) => const ProductDetailScreen(),
  NotificationScreen.route: (_) => const NotificationScreen(),
  EditProfileScreen.route: (_) => const EditProfileScreen(),
  ReviewScreen.route: (_) => const ReviewScreen(),
  TipsScreen.route: (_) => const TipsScreen(),
};

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
          ? ShellScreen.route
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
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.cleaning_services_rounded,
              color: Colors.white,
              size: 48,
            ),
          ),
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

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  static const route = '/onboarding';
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final controller = PageController();
  int index = 0;
  final pages = const [
    (
      'Professional Cleaning Service',
      'Book trusted cleaners for your home, office, or apartment.',
      Icons.verified_user_outlined,
    ),
    (
      'Easy Booking',
      'Choose service, date, time, and location in a few steps.',
      Icons.event_available_outlined,
    ),
    (
      'Track Your Service',
      'Follow your booking status from pending to completed.',
      Icons.timeline_outlined,
    ),
  ];

  Future<void> finish() async {
    await context.read<AuthProvider>().completeOnboarding();
    if (mounted) Navigator.pushReplacementNamed(context, LoginScreen.route);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(onPressed: finish, child: const Text('Skip')),
          ),
          Expanded(
            child: PageView.builder(
              controller: controller,
              itemCount: pages.length,
              onPageChanged: (value) => setState(() => index = value),
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(pages[i].$3, size: 120, color: AppColors.primary),
                    const SizedBox(height: 36),
                    Text(
                      pages[i].$1,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      pages[i].$2,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              pages.length,
              (i) => Container(
                width: index == i ? 26 : 8,
                height: 8,
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: index == i ? AppColors.primary : Colors.black12,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: CustomButton(
              label: index == pages.length - 1 ? 'Get Started' : 'Next',
              icon: Icons.arrow_forward_rounded,
              onPressed: () => index == pages.length - 1
                  ? finish()
                  : controller.nextPage(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                    ),
            ),
          ),
        ],
      ),
    ),
  );
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  static const route = '/login';
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController();
  final password = TextEditingController();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Welcome back')),
    body: AuthScaffold(
      children: [
        const Text(
          'Log in to book and manage your cleaning services.',
          style: TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 20),
        Form(
          key: form,
          child: Column(
            children: [
              CustomTextField(
                controller: email,
                label: 'Email',
                validator: Validators.email,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: password,
                label: 'Password',
                validator: Validators.required,
                obscureText: true,
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () =>
                Navigator.pushNamed(context, ForgotPasswordScreen.route),
            child: const Text('Forgot password?'),
          ),
        ),
        Consumer<AuthProvider>(
          builder: (_, auth, __) => Column(
            children: [
              if (auth.error != null) ErrorText(auth.error!),
              CustomButton(
                label: 'Log In',
                icon: Icons.login_rounded,
                loading: auth.loading,
                onPressed: () async {
                  if (!form.currentState!.validate()) return;
                  final ok = await auth.login(email.text.trim(), password.text);
                  if (ok && context.mounted)
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      ShellScreen.route,
                      (_) => false,
                    );
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: auth.loading
                          ? null
                          : () async {
                              final ok = await auth.loginDemoRole('admin');
                              if (ok && context.mounted) {
                                Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  ShellScreen.route,
                                  (_) => false,
                                );
                              }
                            },
                      icon: const Icon(Icons.admin_panel_settings_outlined),
                      label: const Text('Admin Demo'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: auth.loading
                          ? null
                          : () async {
                              final ok = await auth.loginDemoRole('cleaner');
                              if (ok && context.mounted) {
                                Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  ShellScreen.route,
                                  (_) => false,
                                );
                              }
                            },
                      icon: const Icon(Icons.cleaning_services_outlined),
                      label: const Text('Cleaner Demo'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pushNamed(context, RegisterScreen.route),
          child: const Text('Create a new account'),
        ),
      ],
    ),
  );
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  static const route = '/register';
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController();
  final email = TextEditingController();
  final phone = TextEditingController();
  final password = TextEditingController();
  final confirm = TextEditingController();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Create account')),
    body: AuthScaffold(
      children: [
        Form(
          key: form,
          child: Column(
            children: [
              CustomTextField(
                controller: name,
                label: 'Full name',
                validator: (v) => Validators.required(v, 'Full name'),
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: email,
                label: 'Email',
                validator: Validators.email,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: phone,
                label: 'Phone number',
                validator: Validators.phone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: password,
                label: 'Password',
                validator: Validators.password,
                obscureText: true,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: confirm,
                label: 'Confirm password',
                validator: (v) => Validators.confirmPassword(v, password.text),
                obscureText: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Consumer<AuthProvider>(
          builder: (_, auth, __) => Column(
            children: [
              if (auth.error != null) ErrorText(auth.error!),
              CustomButton(
                label: 'Register',
                icon: Icons.person_add_alt_1_rounded,
                loading: auth.loading,
                onPressed: () async {
                  if (!form.currentState!.validate()) return;
                  final ok = await auth.register(
                    name.text.trim(),
                    email.text.trim(),
                    phone.text.trim(),
                    password.text,
                  );
                  if (ok && context.mounted)
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      ShellScreen.route,
                      (_) => false,
                    );
                },
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  static const route = '/forgot';
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController();
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Reset password')),
    body: AuthScaffold(
      children: [
        Form(
          key: form,
          child: CustomTextField(
            controller: email,
            label: 'Email',
            validator: Validators.email,
          ),
        ),
        const SizedBox(height: 16),
        Consumer<AuthProvider>(
          builder: (_, auth, __) => Column(
            children: [
              if (auth.error != null) ErrorText(auth.error!),
              CustomButton(
                label: 'Send reset email',
                icon: Icons.mark_email_read_outlined,
                loading: auth.loading,
                onPressed: () async {
                  if (!form.currentState!.validate()) return;
                  final ok = await auth.resetPassword(email.text.trim());
                  if (ok && context.mounted)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Password reset email sent.'),
                      ),
                    );
                },
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});
  static const route = '/app';
  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int index = 0;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.read<AuthProvider>().user;
    context.read<FavoriteProvider>().load(user?.id);
    final bookingProvider = context.read<BookingProvider>();
    final notificationProvider = context.read<NotificationProvider>();
    final adminDataProvider = context.read<AdminDataProvider>();
    bookingProvider.loadForRole(user);
    bookingProvider.startRealtime(user);
    notificationProvider.load(user?.id);
    notificationProvider.startRealtime(user?.id);
    adminDataProvider.load();
    if (user?.role == 'admin') {
      adminDataProvider.startRealtime();
    } else {
      adminDataProvider.stopRealtime();
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthProvider>().user?.role ?? 'customer';
    final pages = switch (role) {
      'admin' => [
        const AdminDashboardScreen(),
        const RoleBookingManagementScreen(),
        const AdminCleanerManagementScreen(),
        const AdminUserManagementScreen(),
        const AdminFinanceScreen(),
      ],
      'cleaner' => [
        const CleanerDashboardScreen(),
        const CleanerScheduleScreen(),
        const CleanerProfileScreen(),
      ],
      _ => [
        const HomeScreen(),
        const BookingFormScreen(inShell: true),
        const BookingHistoryScreen(),
        const ProfileScreen(),
      ],
    };
    final destinations = switch (role) {
      'admin' => const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        NavigationDestination(
          icon: Icon(Icons.fact_check_outlined),
          selectedIcon: Icon(Icons.fact_check),
          label: 'Bookings',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_search_outlined),
          selectedIcon: Icon(Icons.person_search),
          label: 'Cleaners',
        ),
        NavigationDestination(
          icon: Icon(Icons.groups_outlined),
          selectedIcon: Icon(Icons.groups),
          label: 'Customers',
        ),
        NavigationDestination(
          icon: Icon(Icons.bar_chart_outlined),
          selectedIcon: Icon(Icons.bar_chart),
          label: 'Reports',
        ),
      ],
      'cleaner' => const [
        NavigationDestination(
          icon: Icon(Icons.work_outline_rounded),
          selectedIcon: Icon(Icons.work_rounded),
          label: 'Jobs',
        ),
        NavigationDestination(
          icon: Icon(Icons.calendar_today_outlined),
          selectedIcon: Icon(Icons.calendar_today_rounded),
          label: 'Schedule',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(Icons.person_rounded),
          label: 'Profile',
        ),
      ],
      _ => const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.calendar_today_outlined),
          selectedIcon: Icon(Icons.calendar_today),
          label: 'Book',
        ),
        NavigationDestination(
          icon: Icon(Icons.access_time),
          selectedIcon: Icon(Icons.access_time_filled),
          label: 'History',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    };
    if (index >= pages.length) index = 0;
    return Scaffold(
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: destinations,
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final serviceProvider = context.watch<ServiceProvider>();
    final bookings = context.watch<BookingProvider>().bookings;
    final services = _customerHomeServices(serviceProvider.services);
    final nextBooking = _nextCustomerBooking(bookings);
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        toolbarHeight: 68,
        titleSpacing: 22,
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFF1087DD),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 19,
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'CleanPro',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 2),
                Text(
                  'Customer Portal',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          const _NotificationAction(),
          IconButton(
            tooltip: 'Logout',
            onPressed: () async {
              final navigator = Navigator.of(context);
              await context.read<AuthProvider>().logout();
              navigator.pushNamedAndRemoveUntil(
                LoginScreen.route,
                (_) => false,
              );
            },
            icon: const Icon(Icons.logout_outlined),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: serviceProvider.loadServices,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
          children: [
            const SizedBox(height: 8),
            _CustomerHomeHero(
              userName: auth.user?.fullName.split(' ').first ?? 'there',
              nextBooking: nextBooking,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Our Services',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                ),
                TextButton.icon(
                  onPressed: () =>
                      Navigator.pushNamed(context, ServiceListScreen.route),
                  label: const Text('View All'),
                  iconAlignment: IconAlignment.end,
                  icon: const Icon(Icons.arrow_forward, size: 15),
                ),
              ],
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: services.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.86,
              ),
              itemBuilder: (context, index) {
                final option = services[index];
                return _CustomerHomeServiceCard(
                  option: option,
                  onTap: () => _openCustomerHomeService(context, option),
                );
              },
            ),
            const SizedBox(height: 20),
            _FirstTimeDiscountCard(
              onBook: () =>
                  Navigator.pushNamed(context, ServiceListScreen.route),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerHomeHero extends StatelessWidget {
  const _CustomerHomeHero({required this.userName, required this.nextBooking});

  final String userName;
  final BookingModel? nextBooking;

  @override
  Widget build(BuildContext context) {
    final booking = nextBooking;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1087DD), Color(0xFF43A6ED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(0).copyWith(
          bottomLeft: const Radius.circular(18),
          bottomRight: const Radius.circular(18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back!',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Book your next cleaning service',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.26)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Next Booking',
                        style: TextStyle(
                          color: Color(0xFFD8EEFF),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF63B8F2),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        booking == null ? 'Ready' : 'Confirmed',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  booking?.serviceName ?? 'Deep Cleaning',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: Color(0xFFD8EEFF),
                      size: 15,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        _customerNextBookingLabel(booking),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.star_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 3),
                    const Text(
                      '4.9',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerHomeServiceCard extends StatelessWidget {
  const _CustomerHomeServiceCard({required this.option, required this.onTap});

  final _CustomerServiceOption option;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InteractiveSurface(
    borderRadius: 12,
    onTap: onTap,
    child: Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDE6EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  option.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: option.color.withValues(alpha: 0.12),
                    child: Icon(option.icon, color: option.color, size: 36),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.04),
                        Colors.black.withValues(alpha: 0.18),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 10,
                  top: 10,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: option.color,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.16),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(option.icon, color: Colors.white, size: 21),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF081C33),
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    option.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF42566B),
                      fontSize: 10,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Text(
                          'From ${_adminMoney(option.price)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF0783D5),
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        option.duration,
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          color: Color(0xFF42566B),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _FirstTimeDiscountCard extends StatelessWidget {
  const _FirstTimeDiscountCard({required this.onBook});

  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) => InteractiveSurface(
    borderRadius: 14,
    child: Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFEAF6FF),
            const Color(0xFFEAFBFF).withValues(alpha: 0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFB9DDF7)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF168BDB),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.trending_up, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'First Time Discount',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Get 20% off on your first booking!',
                  style: TextStyle(color: Color(0xFF42566B), fontSize: 11),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 36,
                  child: ElevatedButton(
                    onPressed: onBook,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(92, 36),
                      backgroundColor: const Color(0xFF168BDB),
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Book Now',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _CustomerServiceOption {
  const _CustomerServiceOption({
    required this.title,
    required this.description,
    required this.price,
    required this.duration,
    required this.icon,
    required this.color,
    required this.imageUrl,
    this.service,
  });

  final String title;
  final String description;
  final double price;
  final String duration;
  final IconData icon;
  final Color color;
  final String imageUrl;
  final ServiceModel? service;
}

List<_CustomerServiceOption> _customerHomeServices(
  List<ServiceModel> services,
) {
  ServiceModel? match(String query) {
    final normalized = query.toLowerCase();
    for (final service in services) {
      final haystack = '${service.name} ${service.category}'.toLowerCase();
      if (haystack.contains(normalized)) return service;
    }
    return null;
  }

  _CustomerServiceOption option({
    required String title,
    required String description,
    required double fallbackPrice,
    required String duration,
    required IconData icon,
    required Color color,
    required String query,
    required String fallbackImage,
  }) {
    final service = match(query);
    return _CustomerServiceOption(
      title: title,
      description: description,
      price: service?.basePrice ?? fallbackPrice,
      duration: service == null
          ? duration
          : _customerDurationRange(service.durationMinutes),
      icon: icon,
      color: color,
      imageUrl: service?.imageUrl ?? fallbackImage,
      service: service,
    );
  }

  return [
    option(
      title: 'Home Cleaning',
      description: 'Complete house cleaning service',
      fallbackPrice: 49,
      duration: '2-3 hours',
      icon: Icons.home_outlined,
      color: const Color(0xFF2F80ED),
      query: 'home',
      fallbackImage: DemoImages.home,
    ),
    option(
      title: 'Office Cleaning',
      description: 'Professional workspace cleaning',
      fallbackPrice: 89,
      duration: '3-4 hours',
      icon: Icons.business_outlined,
      color: const Color(0xFFB642F5),
      query: 'office',
      fallbackImage: DemoImages.office,
    ),
    option(
      title: 'Deep Cleaning',
      description: 'Thorough deep cleaning service',
      fallbackPrice: 129,
      duration: '4-6 hours',
      icon: Icons.auto_awesome,
      color: const Color(0xFF0D83D8),
      query: 'deep',
      fallbackImage: DemoImages.deep,
    ),
    option(
      title: 'Move In/Out',
      description: 'Moving cleaning service',
      fallbackPrice: 149,
      duration: '4-5 hours',
      icon: Icons.delete_outline,
      color: const Color(0xFFFF6A00),
      query: 'move',
      fallbackImage: DemoImages.cleaner,
    ),
    option(
      title: 'Sofa Cleaning',
      description: 'Furniture deep cleaning',
      fallbackPrice: 39,
      duration: '1-2 hours',
      icon: Icons.chair_outlined,
      color: const Color(0xFFE83FA5),
      query: 'sofa',
      fallbackImage: DemoImages.sofa,
    ),
    option(
      title: 'Carpet Cleaning',
      description: 'Professional carpet care',
      fallbackPrice: 59,
      duration: '2-3 hours',
      icon: Icons.grid_view_rounded,
      color: const Color(0xFF6759FF),
      query: 'carpet',
      fallbackImage: DemoImages.carpet,
    ),
    option(
      title: 'Bathroom Cleaning',
      description: 'Deep bathroom sanitization',
      fallbackPrice: 29,
      duration: '1 hour',
      icon: Icons.bathtub_outlined,
      color: const Color(0xFF05BBD3),
      query: 'bathroom',
      fallbackImage:
          'https://images.unsplash.com/photo-1620626011761-996317b8d101?auto=format&fit=crop&w=900&q=80',
    ),
    option(
      title: 'Kitchen Cleaning',
      description: 'Complete kitchen service',
      fallbackPrice: 49,
      duration: '1-2 hours',
      icon: Icons.soup_kitchen_outlined,
      color: const Color(0xFFFF9800),
      query: 'kitchen',
      fallbackImage:
          'https://images.unsplash.com/photo-1556911220-bff31c812dba?auto=format&fit=crop&w=900&q=80',
    ),
    option(
      title: 'Window Cleaning',
      description: 'Crystal clear windows',
      fallbackPrice: 39,
      duration: '1-2 hours',
      icon: Icons.air,
      color: const Color(0xFF168BDB),
      query: 'window',
      fallbackImage: DemoImages.deep,
    ),
  ];
}

String _customerDurationRange(int minutes) {
  if (minutes <= 75) return '1 hour';
  if (minutes <= 120) return '1-2 hours';
  if (minutes <= 180) return '2-3 hours';
  if (minutes <= 240) return '3-4 hours';
  return '4-6 hours';
}

BookingModel? _nextCustomerBooking(List<BookingModel> bookings) {
  final upcoming =
      bookings
          .where(
            (booking) => !const [
              'Completed',
              'Cancelled',
              'Rejected',
            ].contains(booking.status),
          )
          .toList()
        ..sort((a, b) {
          final left = DateTime.tryParse(a.bookingDate) ?? DateTime(2100);
          final right = DateTime.tryParse(b.bookingDate) ?? DateTime(2100);
          return left.compareTo(right);
        });
  return upcoming.isEmpty ? null : upcoming.first;
}

String _customerNextBookingLabel(BookingModel? booking) {
  if (booking == null) return 'Tomorrow, 10:00 AM';
  final date = DateTime.tryParse(booking.bookingDate);
  final label = date == null ? booking.bookingDate : prettyDate(date);
  return '$label, ${booking.bookingTime}';
}

void _openCustomerHomeService(
  BuildContext context,
  _CustomerServiceOption option,
) {
  final service = option.service;
  if (service == null) {
    Navigator.pushNamed(context, ServiceListScreen.route);
    return;
  }
  Navigator.pushNamed(context, ServiceDetailScreen.route, arguments: service);
}

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final bookings = context.watch<BookingProvider>().bookings;
    final adminData = context.watch<AdminDataProvider>();
    final pending = bookings.where((item) => item.status == 'Pending').length;
    final activeBookings = bookings
        .where(
          (item) => const [
            'Accepted',
            'Cleaner Assigned',
            'On the Way',
            'Arrived',
            'In Progress',
          ].contains(item.status),
        )
        .length;
    final completed = bookings
        .where((item) => item.status == 'Completed')
        .length;
    final completedRevenue = bookings
        .where((item) => item.status == 'Completed')
        .fold<double>(0, (sum, item) => sum + item.totalPrice);
    final activeCleaners = adminData.cleaners
        .where((item) => item.isActive)
        .length;
    final customers = adminData.users
        .where((item) => item.role == 'customer')
        .length;
    final visibleBookings = bookings.isEmpty
        ? _demoAdminBookings
        : bookings
              .take(5)
              .map(
                (booking) => _AdminBookingPreview(
                  serviceName: booking.serviceName,
                  customerName: booking.customerName,
                  cleanerName: booking.cleanerName.isEmpty
                      ? 'Not Assigned'
                      : booking.cleanerName,
                  status: booking.status,
                  price: booking.totalPrice,
                ),
              )
              .toList();
    final performers = _adminPerformers(adminData.cleaners, bookings);
    final totalBookings = bookings.isEmpty ? 248 : bookings.length;
    final dashboardCleaners = activeCleaners == 0 ? 32 : activeCleaners;
    final dashboardCustomers = customers == 0 ? 1247 : customers;
    final dashboardRevenue = completedRevenue == 0 ? 28450.0 : completedRevenue;
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        toolbarHeight: 70,
        titleSpacing: 32,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${AppStrings.appName} Admin',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 2),
            const Text(
              'Management Portal',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          const _NotificationAction(),
          IconButton(
            tooltip: 'Logout',
            onPressed: () async {
              final auth = context.read<AuthProvider>();
              final navigator = Navigator.of(context);
              await auth.logout();
              navigator.pushNamedAndRemoveUntil(
                LoginScreen.route,
                (_) => false,
              );
            },
            icon: const Icon(Icons.logout_outlined),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final bookingProvider = context.read<BookingProvider>();
          final adminData = context.read<AdminDataProvider>();
          final user = context.read<AuthProvider>().user;
          await bookingProvider.loadForRole(user);
          await adminData.load();
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFDDE6EE)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF6FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.dashboard_rounded,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${AppStrings.appName} Admin Dashboard',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat(
                            'EEEE, MMMM d, yyyy',
                          ).format(DateTime.now()),
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: _AdminMetricCard(
                    icon: Icons.calendar_today_outlined,
                    iconColor: const Color(0xFF2F80ED),
                    label: 'Total Bookings',
                    value: NumberFormat.decimalPattern().format(totalBookings),
                    trend: '+ 12.5%',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _AdminMetricCard(
                    icon: Icons.person_search_outlined,
                    iconColor: const Color(0xFF168BDB),
                    label: 'Active Cleaners',
                    value: '$dashboardCleaners',
                    trend: '+ 2',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _AdminMetricCard(
                    icon: Icons.groups_2_outlined,
                    iconColor: const Color(0xFFB642F5),
                    label: 'Total Customers',
                    value: NumberFormat.decimalPattern().format(
                      dashboardCustomers,
                    ),
                    trend: '+ 18.2%',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _AdminMetricCard(
                    icon: Icons.attach_money,
                    iconColor: const Color(0xFF0D83D8),
                    label: 'Monthly Revenue',
                    value: _adminMoney(dashboardRevenue),
                    trend: '+ 24.8%',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            const _AdminDashboardTitle('Recent Bookings'),
            const SizedBox(height: 10),
            for (final booking in visibleBookings)
              _AdminBookingCard(booking: booking),
            const SizedBox(height: 12),
            const _AdminDashboardTitle('Top Performers'),
            const SizedBox(height: 10),
            _AdminPerformerList(performers: performers),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _AdminSummaryTile(
                    icon: Icons.schedule_outlined,
                    value: bookings.isEmpty ? 23 : pending,
                    label: 'Pending\nAssignments',
                    color: const Color(0xFF1D92E6),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _AdminSummaryTile(
                    icon: Icons.check_circle_outline,
                    value: bookings.isEmpty ? 186 : completed,
                    label: activeBookings > 0
                        ? 'Active\nBookings'
                        : 'Completed Today',
                    color: const Color(0xFF4BA9E8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminBookingPreview {
  const _AdminBookingPreview({
    required this.serviceName,
    required this.customerName,
    required this.cleanerName,
    required this.status,
    required this.price,
  });

  final String serviceName;
  final String customerName;
  final String cleanerName;
  final String status;
  final double price;
}

class _AdminPerformer {
  const _AdminPerformer({
    required this.name,
    required this.jobs,
    required this.earnings,
    required this.rating,
  });

  final String name;
  final int jobs;
  final double earnings;
  final double rating;
}

const _demoAdminBookings = [
  _AdminBookingPreview(
    serviceName: 'Deep Cleaning',
    customerName: 'John Doe',
    cleanerName: 'Sarah Johnson',
    status: 'Completed',
    price: 129,
  ),
  _AdminBookingPreview(
    serviceName: 'Home Cleaning',
    customerName: 'Jane Smith',
    cleanerName: 'Mike Chen',
    status: 'In Progress',
    price: 79,
  ),
  _AdminBookingPreview(
    serviceName: 'Office Cleaning',
    customerName: 'Bob Wilson',
    cleanerName: 'Not Assigned',
    status: 'Pending',
    price: 99,
  ),
  _AdminBookingPreview(
    serviceName: 'Sofa Cleaning',
    customerName: 'Alice Brown',
    cleanerName: 'Emily Davis',
    status: 'Accepted',
    price: 39,
  ),
];

const _demoAdminPerformers = [
  _AdminPerformer(name: 'Sarah Johnson', jobs: 45, earnings: 5670, rating: 4.9),
  _AdminPerformer(name: 'Mike Chen', jobs: 42, earnings: 5320, rating: 4.8),
  _AdminPerformer(name: 'Emily Davis', jobs: 38, earnings: 4940, rating: 4.7),
];

List<_AdminPerformer> _adminPerformers(
  List<UserModel> cleaners,
  List<BookingModel> bookings,
) {
  if (cleaners.isEmpty) return _demoAdminPerformers;
  final performers = <_AdminPerformer>[
    for (final cleaner in cleaners)
      _AdminPerformer(
        name: cleaner.fullName,
        jobs: bookings.where((item) => item.cleanerId == cleaner.id).length,
        earnings: bookings
            .where((item) => item.cleanerId == cleaner.id)
            .fold<double>(0, (sum, item) => sum + item.cleanerPay),
        rating: 4.9 - (cleaners.indexOf(cleaner) * 0.1),
      ),
  ]..sort((a, b) => b.jobs.compareTo(a.jobs));
  return performers.take(3).toList();
}

String _adminMoney(num value) {
  final rounded = value.round();
  return '\$${NumberFormat.decimalPattern().format(rounded)}';
}

class _AdminDashboardTitle extends StatelessWidget {
  const _AdminDashboardTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w900,
      color: AppColors.text,
    ),
  );
}

class _AdminMetricCard extends StatelessWidget {
  const _AdminMetricCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.trend,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String trend;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 174),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFDDE6EE)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: iconColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: Colors.white, size: 21),
        ),
        const SizedBox(height: 14),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppColors.muted, fontSize: 13),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF6FF),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            trend,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF0D6FB8),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
}

class _AdminBookingCard extends StatelessWidget {
  const _AdminBookingCard({required this.booking});

  final _AdminBookingPreview booking;

  @override
  Widget build(BuildContext context) => InteractiveSurface(
    borderRadius: 12,
    lift: 2,
    child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDE6EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  booking.serviceName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                _adminMoney(booking.price),
                style: const TextStyle(
                  color: Color(0xFF0074D9),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            booking.customerName,
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.person_search_outlined,
                size: 16,
                color: AppColors.muted,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  booking.cleanerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ),
              _AdminStatusBadge(status: booking.status),
            ],
          ),
        ],
      ),
    ),
  );
}

class _AdminStatusBadge extends StatelessWidget {
  const _AdminStatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'Completed' => const Color(0xFFDCEEFF),
      'In Progress' => const Color(0xFFFFE4C6),
      'Accepted' => const Color(0xFFDCEBFF),
      _ => const Color(0xFFFFF1B8),
    };
    final textColor = switch (status) {
      'Completed' => const Color(0xFF0D6FB8),
      'In Progress' => const Color(0xFFE56C00),
      'Accepted' => const Color(0xFF2369D8),
      _ => const Color(0xFFB88700),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _AdminPerformerList extends StatelessWidget {
  const _AdminPerformerList({required this.performers});

  final List<_AdminPerformer> performers;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFDDE6EE)),
    ),
    child: Column(
      children: [
        for (var i = 0; i < performers.length; i++) ...[
          _AdminPerformerRow(index: i + 1, performer: performers[i]),
          if (i != performers.length - 1)
            const Divider(height: 1, color: Color(0xFFE8EEF4)),
        ],
      ],
    ),
  );
}

class _AdminPerformerRow extends StatelessWidget {
  const _AdminPerformerRow({required this.index, required this.performer});

  final int index;
  final _AdminPerformer performer;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(13),
    child: Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: const Color(0xFF4BA9E8),
          child: Text(
            '#$index',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                performer.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 3),
              Text(
                '${performer.jobs} jobs - ${_adminMoney(performer.earnings)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
        const Icon(Icons.star_rounded, color: Color(0xFFFFB000), size: 18),
        const SizedBox(width: 2),
        Text(
          performer.rating.toStringAsFixed(1),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ],
    ),
  );
}

class _AdminSummaryTile extends StatelessWidget {
  const _AdminSummaryTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    height: 114,
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.white, size: 27),
        const Spacer(),
        Text(
          '$value',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            height: 1.15,
          ),
        ),
      ],
    ),
  );
}

class CleanerDashboardScreen extends StatefulWidget {
  const CleanerDashboardScreen({super.key});

  @override
  State<CleanerDashboardScreen> createState() => _CleanerDashboardScreenState();
}

class _CleanerDashboardScreenState extends State<CleanerDashboardScreen> {
  @override
  void initState() {
    super.initState();
    _restoreDemoCleanerJobs().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<BookingProvider>();
    final hasLiveData = provider.bookings.isNotEmpty;
    final sourceJobs = hasLiveData ? provider.bookings : _demoCleanerJobs;
    final jobs = sourceJobs
        .where(
          (item) => [
            'Accepted',
            'Cleaner Assigned',
            'On the Way',
            'Arrived',
            'In Progress',
          ].contains(item.status),
        )
        .toList();
    final earnings = sourceJobs
        .where((booking) => booking.status == 'Completed')
        .fold<double>(0, (sum, booking) => sum + booking.cleanerPay);

    return Scaffold(
      appBar: _CleanerPortalAppBar(auth: auth),
      body: RefreshIndicator(
        onRefresh: () => provider.loadForRole(auth.user),
        child: ListView(
          children: [
            _CleanerJobsSummary(jobCount: jobs.length, earnings: earnings),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              child: Column(
                children: [
                  for (final booking in jobs)
                    _CleanerJobCard(
                      booking: booking,
                      onViewDetails: () async {
                        await Navigator.pushNamed(
                          context,
                          BookingDetailScreen.route,
                          arguments: booking,
                        );
                        if (mounted) setState(() {});
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CleanerPortalAppBar extends AppBar {
  _CleanerPortalAppBar({required AuthProvider auth})
    : super(
        centerTitle: false,
        toolbarHeight: 70,
        titleSpacing: 4,
        title: const Row(
          children: [
            _CleanerLogo(),
            SizedBox(width: 10),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CleanPro',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                Text(
                  'Cleaner Portal',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          const _NotificationAction(compact: true),
          Builder(
            builder: (context) => IconButton(
              constraints: const BoxConstraints.tightFor(width: 32, height: 48),
              padding: const EdgeInsets.all(4),
              tooltip: 'Logout',
              onPressed: () async {
                final navigator = Navigator.of(context);
                await auth.logout();
                navigator.pushNamedAndRemoveUntil(
                  LoginScreen.route,
                  (_) => false,
                );
              },
              icon: const Icon(Icons.logout_outlined),
            ),
          ),
        ],
      );
}

class _CleanerLogo extends StatelessWidget {
  const _CleanerLogo();

  @override
  Widget build(BuildContext context) => Container(
    width: 30,
    height: 30,
    decoration: const BoxDecoration(
      color: Color(0xFF32D29B),
      shape: BoxShape.circle,
    ),
    child: const Icon(Icons.auto_awesome, color: Colors.white, size: 17),
  );
}

class _CleanerJobsSummary extends StatelessWidget {
  const _CleanerJobsSummary({required this.jobCount, required this.earnings});

  final int jobCount;
  final double earnings;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(20, 26, 20, 25),
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF27D09A), Color(0xFF52D8AC)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(19),
        bottomRight: Radius.circular(19),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Today's Jobs",
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          DateFormat('EEEE, MMMM d, y').format(DateTime.now()),
          style: const TextStyle(color: Colors.white, fontSize: 11),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(
                child: _CleanerSummaryMetric(
                  label: 'Total Jobs Today',
                  value: '$jobCount',
                ),
              ),
              Expanded(
                child: _CleanerSummaryMetric(
                  label: 'Total Earnings',
                  value: money(earnings),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _CleanerSummaryMetric extends StatelessWidget {
  const _CleanerSummaryMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
      const SizedBox(height: 3),
      Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
      ),
    ],
  );
}

class _CleanerJobCard extends StatelessWidget {
  const _CleanerJobCard({required this.booking, required this.onViewDetails});

  final BookingModel booking;
  final VoidCallback onViewDetails;

  @override
  Widget build(BuildContext context) {
    final baseHours = math.max(1, (booking.estimatedDuration / 60).round());
    final upperHours = baseHours + (baseHours >= 4 ? 2 : 1);
    final displayStatus = switch (booking.status) {
      'Accepted' || 'Cleaner Assigned' => 'Assigned',
      _ => booking.status,
    };
    final statusColor = switch (booking.status) {
      'Completed' => const Color(0xFF00BF68),
      'In Progress' => const Color(0xFFFF9D00),
      'Arrived' => const Color(0xFFFF6300),
      'On the Way' => const Color(0xFFB63CFF),
      _ => const Color(0xFF2E7CFF),
    };
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(13, 14, 13, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.serviceName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      booking.customerName,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    money(booking.totalPrice),
                    style: const TextStyle(
                      color: Color(0xFF19CA8B),
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$baseHours-$upperHours hours',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 11),
          _CleanerJobInfo(
            icon: Icons.schedule_outlined,
            text: booking.bookingTime,
          ),
          const SizedBox(height: 7),
          _CleanerJobInfo(
            icon: Icons.location_on_outlined,
            text: booking.address,
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  displayStatus,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: onViewDetails,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'View Details →',
                        maxLines: 1,
                        style: TextStyle(
                          color: AppColors.primaryDark,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CleanerJobInfo extends StatelessWidget {
  const _CleanerJobInfo({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 15, color: AppColors.muted),
      const SizedBox(width: 7),
      Expanded(
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppColors.muted, fontSize: 11),
        ),
      ),
    ],
  );
}

final _demoCleanerJobs = <BookingModel>[
  const BookingModel(
    id: 101,
    userId: 11,
    serviceId: 2,
    serviceName: 'Deep Cleaning',
    customerName: 'John Doe',
    phone: '+1 555 0101',
    address: '123 Main St, Apt 4B, New York, NY',
    propertyType: 'Apartment',
    rooms: 3,
    bathrooms: 2,
    bookingDate: '2026-06-20',
    bookingTime: '10:00 AM',
    extraServices: [],
    specialInstruction:
        'Please focus on kitchen and bathroom. Keys with doorman.',
    paymentMethod: 'Cash',
    basePrice: 129,
    extraPrice: 0,
    totalPrice: 129,
    estimatedDuration: 240,
    cleanerId: 2,
    cleanerName: 'Cleaner Demo',
    cleanerPay: 48,
    status: 'Cleaner Assigned',
  ),
  const BookingModel(
    id: 102,
    userId: 12,
    serviceId: 1,
    serviceName: 'Home Cleaning',
    customerName: 'Jane Smith',
    phone: '+1 555 0102',
    address: '456 Oak Ave, Brooklyn, NY',
    propertyType: 'House',
    rooms: 2,
    bathrooms: 1,
    bookingDate: '2026-06-20',
    bookingTime: '02:00 PM',
    extraServices: [],
    paymentMethod: 'Card',
    basePrice: 79,
    extraPrice: 0,
    totalPrice: 79,
    estimatedDuration: 120,
    cleanerId: 2,
    cleanerName: 'Cleaner Demo',
    cleanerPay: 24,
    status: 'Cleaner Assigned',
  ),
  const BookingModel(
    id: 103,
    userId: 13,
    serviceId: 3,
    serviceName: 'Office Cleaning',
    customerName: 'Tech Corp Inc',
    phone: '+1 555 0103',
    address: '789 Business Blvd, Manhattan, NY',
    propertyType: 'Office',
    rooms: 5,
    bathrooms: 2,
    bookingDate: '2026-06-20',
    bookingTime: '09:00 AM',
    extraServices: [],
    paymentMethod: 'Card',
    basePrice: 99,
    extraPrice: 0,
    totalPrice: 99,
    estimatedDuration: 180,
    cleanerId: 2,
    cleanerName: 'Cleaner Demo',
    cleanerPay: 36,
    status: 'Cleaner Assigned',
  ),
];

const _demoCleanerJobStoragePrefix = 'cleannow_demo_cleaner_job_';

Future<void> _restoreDemoCleanerJobs() async {
  try {
    final preferences = await SharedPreferences.getInstance();
    for (var index = 0; index < _demoCleanerJobs.length; index++) {
      final id = _demoCleanerJobs[index].id;
      if (id == null) continue;
      var restored = _demoCleanerJobs[index];
      final stored = preferences.getString('$_demoCleanerJobStoragePrefix$id');
      if (stored != null && stored.isNotEmpty) {
        try {
          restored = BookingModel.fromJson(
            Map<String, dynamic>.from(jsonDecode(stored) as Map),
          );
        } catch (_) {
          // The lightweight status below can still be restored.
        }
      }
      final storedStatus = preferences.getString(
        '$_demoCleanerJobStoragePrefix${id}_status',
      );
      _demoCleanerJobs[index] = storedStatus == null
          ? restored
          : restored.copyWith(status: storedStatus);
    }
  } catch (_) {
    // Keep the built-in demo jobs if browser storage is unavailable.
  }
}

Future<void> _saveDemoCleanerJob(BookingModel booking) async {
  if (booking.id == null) return;
  try {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      '$_demoCleanerJobStoragePrefix${booking.id}_status',
      booking.status,
    );
    await preferences.setString(
      '$_demoCleanerJobStoragePrefix${booking.id}',
      jsonEncode(booking.toJson()),
    );
  } catch (_) {
    // The in-memory update still keeps the current session consistent.
  }
}

class CleanerScheduleScreen extends StatefulWidget {
  const CleanerScheduleScreen({super.key});

  @override
  State<CleanerScheduleScreen> createState() => _CleanerScheduleScreenState();
}

class _CleanerScheduleScreenState extends State<CleanerScheduleScreen> {
  DateTime month = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime selectedDate = DateTime.now();
  bool initialized = false;

  List<BookingModel> _jobs(BuildContext context) {
    final live = context.watch<BookingProvider>().bookings;
    return live.isEmpty ? _demoCleanerJobs : live;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (initialized) return;
    initialized = true;
    final jobs = _jobs(context);
    if (jobs.isNotEmpty) {
      final firstDate = DateTime.tryParse(jobs.first.bookingDate);
      if (firstDate != null) {
        month = DateTime(firstDate.year, firstDate.month);
        selectedDate = firstDate;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final jobs = _jobs(context);
    final selectedJobs = jobs.where((booking) {
      final date = DateTime.tryParse(booking.bookingDate);
      return date != null && _cleanerSameDay(date, selectedDate);
    }).toList()..sort((a, b) => a.bookingTime.compareTo(b.bookingTime));
    final firstDay = DateTime(month.year, month.month, 1);
    final leadingCells = firstDay.weekday % 7;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final cellCount = ((leadingCells + daysInMonth + 6) ~/ 7) * 7;

    return Scaffold(
      appBar: _CleanerPortalAppBar(auth: auth),
      body: RefreshIndicator(
        onRefresh: () => context.read<BookingProvider>().loadForRole(auth.user),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 17, 20, 15),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Work Schedule',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'View your upcoming jobs',
                    style: TextStyle(color: AppColors.muted, fontSize: 11),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(13, 15, 13, 13),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                DateFormat('MMMM y').format(month),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Previous month',
                              visualDensity: VisualDensity.compact,
                              onPressed: () => _changeMonth(-1, jobs),
                              icon: const Icon(Icons.chevron_left),
                            ),
                            IconButton(
                              tooltip: 'Next month',
                              visualDensity: VisualDensity.compact,
                              onPressed: () => _changeMonth(1, jobs),
                              icon: const Icon(Icons.chevron_right),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            for (final label in [
                              'Sun',
                              'Mon',
                              'Tue',
                              'Wed',
                              'Thu',
                              'Fri',
                              'Sat',
                            ])
                              Expanded(
                                child: Text(
                                  label,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 7),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 7,
                                childAspectRatio: 1,
                              ),
                          itemCount: cellCount,
                          itemBuilder: (context, index) {
                            final day = index - leadingCells + 1;
                            if (day < 1 || day > daysInMonth) {
                              return const SizedBox.shrink();
                            }
                            final date = DateTime(month.year, month.month, day);
                            final selected = _cleanerSameDay(
                              date,
                              selectedDate,
                            );
                            final today = _cleanerSameDay(date, DateTime.now());
                            final hasJobs = jobs.any((booking) {
                              final jobDate = DateTime.tryParse(
                                booking.bookingDate,
                              );
                              return jobDate != null &&
                                  _cleanerSameDay(jobDate, date);
                            });
                            return Padding(
                              padding: const EdgeInsets.all(2),
                              child: InkWell(
                                onTap: () =>
                                    setState(() => selectedDate = date),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? const Color(0xFF32D29B)
                                        : today
                                        ? const Color(0xFFE3F9F1)
                                        : hasJobs
                                        ? AppColors.secondary
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Text(
                                        '$day',
                                        style: TextStyle(
                                          color: selected
                                              ? Colors.white
                                              : AppColors.text,
                                          fontSize: 11,
                                          fontWeight: selected || today
                                              ? FontWeight.w800
                                              : FontWeight.w500,
                                        ),
                                      ),
                                      if (hasJobs)
                                        Positioned(
                                          bottom: 3,
                                          child: Container(
                                            width: 4,
                                            height: 4,
                                            decoration: BoxDecoration(
                                              color: selected
                                                  ? Colors.white
                                                  : const Color(0xFF32D29B),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Jobs on ${DateFormat('MMMM d').format(selectedDate)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 11),
                  if (selectedJobs.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Column(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            color: AppColors.muted,
                            size: 34,
                          ),
                          SizedBox(height: 9),
                          Text(
                            'No jobs scheduled for this day',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    for (final booking in selectedJobs)
                      _CleanerScheduleJobCard(
                        booking: booking,
                        onTap: () async {
                          await Navigator.pushNamed(
                            context,
                            BookingDetailScreen.route,
                            arguments: booking,
                          );
                          if (mounted) setState(() {});
                        },
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _changeMonth(int offset, List<BookingModel> jobs) {
    final next = DateTime(month.year, month.month + offset);
    final matchingDates = jobs
        .map((booking) => DateTime.tryParse(booking.bookingDate))
        .whereType<DateTime>()
        .where((date) => date.year == next.year && date.month == next.month)
        .toList();
    setState(() {
      month = next;
      selectedDate = matchingDates.isEmpty
          ? DateTime(next.year, next.month, 1)
          : matchingDates.first;
    });
  }
}

bool _cleanerSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

class _CleanerScheduleJobCard extends StatelessWidget {
  const _CleanerScheduleJobCard({required this.booking, required this.onTap});

  final BookingModel booking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 11),
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border),
    ),
    child: InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.serviceName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      booking.customerName,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                money(booking.totalPrice),
                style: const TextStyle(
                  color: Color(0xFF19CA8B),
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _CleanerJobInfo(
            icon: Icons.schedule_outlined,
            text: booking.bookingTime,
          ),
          const SizedBox(height: 6),
          _CleanerJobInfo(
            icon: Icons.location_on_outlined,
            text: booking.address,
          ),
        ],
      ),
    ),
  );
}

class CleanerProfileScreen extends StatelessWidget {
  const CleanerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user!;
    final liveJobs = context.watch<BookingProvider>().bookings;
    final jobs = liveJobs.isEmpty ? _demoCleanerJobs : liveJobs;
    final completed = jobs.where((booking) => booking.status == 'Completed');
    final completedCount = completed.length;
    final earned = completed.fold<double>(
      0,
      (sum, booking) => sum + booking.cleanerPay,
    );
    final shownCompleted = completedCount == 0 ? 127 : completedCount;
    final shownEarnings = earned == 0 ? 8450 : earned;

    return Scaffold(
      appBar: _CleanerPortalAppBar(auth: auth),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF27D09A), Color(0xFF52D8AC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 34,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      child: Text(
                        user.fullName.isEmpty
                            ? 'C'
                            : user.fullName[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 27,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.fullName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Text(
                            'Professional Cleaner',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Row(
                            children: [
                              Icon(Icons.star, color: Colors.white, size: 15),
                              SizedBox(width: 4),
                              Text(
                                '4.9',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  '(127 reviews)',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 9,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _CleanerHeroMetric(
                        icon: Icons.calendar_today_outlined,
                        label: 'Jobs Completed',
                        value: '$shownCompleted',
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: _CleanerHeroMetric(
                        icon: Icons.star_outline,
                        label: 'Average Rating',
                        value: '4.9',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _CleanerProfileTitle('Performance Stats'),
                Row(
                  children: [
                    Expanded(
                      child: _CleanerPerformanceCard(
                        icon: Icons.attach_money_rounded,
                        iconColor: Color(0xFF20C77A),
                        label: 'Total Earnings',
                        value: money(shownEarnings),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: _CleanerPerformanceCard(
                        icon: Icons.workspace_premium_outlined,
                        iconColor: Color(0xFF8B5CF6),
                        label: 'Success Rate',
                        value: '98%',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const _CleanerProfileTitle('Achievements'),
                const Row(
                  children: [
                    Expanded(
                      child: _CleanerAchievementCard(
                        icon: Icons.emoji_events_outlined,
                        color: Color(0xFFFFB020),
                        title: 'Top Performer',
                        description: 'Highest rating this month',
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: _CleanerAchievementCard(
                        icon: Icons.calendar_today_outlined,
                        color: Color(0xFF3B82F6),
                        title: '100 Jobs',
                        description: 'Completed 100+ jobs',
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: _CleanerAchievementCard(
                        icon: Icons.star_outline,
                        color: Color(0xFF8B5CF6),
                        title: 'Perfect Score',
                        description: '10 consecutive 5-star ratings',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const _CleanerProfileTitle('Personal Information'),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      _CleanerProfileInfoTile(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        value: user.email,
                        onTap: () => Navigator.pushNamed(
                          context,
                          EditProfileScreen.route,
                        ),
                      ),
                      const Divider(height: 1),
                      _CleanerProfileInfoTile(
                        icon: Icons.phone_outlined,
                        label: 'Phone',
                        value: user.phone,
                        onTap: () => Navigator.pushNamed(
                          context,
                          EditProfileScreen.route,
                        ),
                      ),
                      const Divider(height: 1),
                      _CleanerProfileInfoTile(
                        icon: Icons.location_on_outlined,
                        label: 'Service Area',
                        value: user.address.isEmpty
                            ? 'Manhattan, Brooklyn'
                            : user.address,
                        onTap: () => Navigator.pushNamed(
                          context,
                          EditProfileScreen.route,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const _CleanerProfileTitle('Recent Reviews'),
                const _CleanerPortalReviewCard(
                  customer: 'John Doe',
                  date: 'May 28, 2026',
                  rating: 5,
                  comment: 'Excellent service! Very thorough and professional.',
                ),
                const _CleanerPortalReviewCard(
                  customer: 'Jane Smith',
                  date: 'May 25, 2026',
                  rating: 5,
                  comment: 'Great attention to detail. Will book again!',
                ),
                const _CleanerPortalReviewCard(
                  customer: 'Mike Chen',
                  date: 'May 20, 2026',
                  rating: 4,
                  comment: 'Good job overall. Very punctual.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CleanerHeroMetric extends StatelessWidget {
  const _CleanerHeroMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white70, size: 14),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 9),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

class _CleanerProfileTitle extends StatelessWidget {
  const _CleanerProfileTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      text,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
    ),
  );
}

class _CleanerPerformanceCard extends StatelessWidget {
  const _CleanerPerformanceCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 35,
          height: 35,
          decoration: BoxDecoration(
            color: iconColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 19),
        ),
        const SizedBox(height: 9),
        Text(
          label,
          style: const TextStyle(color: AppColors.muted, fontSize: 9),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
        ),
      ],
    ),
  );
}

class _CleanerAchievementCard extends StatelessWidget {
  const _CleanerAchievementCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(7, 10, 7, 9),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(height: 7),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 3),
        Text(
          description,
          maxLines: 3,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 8,
            height: 1.2,
          ),
        ),
      ],
    ),
  );
}

class _CleanerProfileInfoTile extends StatelessWidget {
  const _CleanerProfileInfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.all(13),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFE3F9F1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF19B982), size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.muted, size: 19),
        ],
      ),
    ),
  );
}

class _CleanerPortalReviewCard extends StatelessWidget {
  const _CleanerPortalReviewCard({
    required this.customer,
    required this.date,
    required this.rating,
    required this.comment,
  });

  final String customer;
  final String date;
  final int rating;
  final String comment;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    date,
                    style: const TextStyle(color: AppColors.muted, fontSize: 9),
                  ),
                ],
              ),
            ),
            for (var index = 0; index < rating; index++)
              const Icon(Icons.star, color: Color(0xFFFFC107), size: 13),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          comment,
          style: const TextStyle(color: AppColors.muted, fontSize: 11),
        ),
      ],
    ),
  );
}

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  State<AdminUserManagementScreen> createState() =>
      _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  final searchController = TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminDataProvider>();
    final bookings = context.watch<BookingProvider>().bookings;
    final customers = _adminCustomerProfiles(
      provider.users.where((item) => item.role == 'customer').toList(),
      bookings,
    );
    final query = searchController.text.trim().toLowerCase();
    final filteredCustomers = customers.where((customer) {
      return query.isEmpty ||
          customer.name.toLowerCase().contains(query) ||
          customer.email.toLowerCase().contains(query) ||
          customer.phone.toLowerCase().contains(query) ||
          customer.address.toLowerCase().contains(query);
    }).toList();
    final active = customers.where((item) => item.active).length;
    final revenue = customers.fold<double>(
      0,
      (sum, item) => sum + item.totalSpent,
    );
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        toolbarHeight: 70,
        titleSpacing: 32,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${AppStrings.appName} Admin',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 2),
            const Text(
              'Management Portal',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: () async {
              final auth = context.read<AuthProvider>();
              final navigator = Navigator.of(context);
              await auth.logout();
              navigator.pushNamedAndRemoveUntil(
                LoginScreen.route,
                (_) => false,
              );
            },
            icon: const Icon(Icons.logout_outlined),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: provider.load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
          children: [
            const Text(
              'Customer Management',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            const Text(
              'Manage customer accounts',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search customers...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: () {
                          searchController.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.close),
                      ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _CustomerSummaryCard(
                    value: '${customers.length}',
                    label: 'Total',
                    color: const Color(0xFF0E60B8),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _CustomerSummaryCard(
                    value: '$active',
                    label: 'Active',
                    color: const Color(0xFF168BDB),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _CustomerSummaryCard(
                    value: _adminMoney(revenue),
                    label: 'Revenue',
                    color: const Color(0xFF0783D5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (filteredCustomers.isEmpty)
              const EmptyStateWidget(
                title: 'No matching customers',
                message: 'Try another search term.',
                icon: Icons.group_outlined,
              )
            else
              for (final customer in filteredCustomers) ...[
                _AdminCustomerCard(
                  customer: customer,
                  onViewProfile: () => _showCustomerProfile(context, customer),
                ),
                const SizedBox(height: 12),
              ],
          ],
        ),
      ),
    );
  }
}

class _CustomerSummaryCard extends StatelessWidget {
  const _CustomerSummaryCard({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    height: 58,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFDDE6EE)),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF47647D), fontSize: 10),
        ),
      ],
    ),
  );
}

class _AdminCustomerCard extends StatelessWidget {
  const _AdminCustomerCard({
    required this.customer,
    required this.onViewProfile,
  });

  final _AdminCustomerProfile customer;
  final VoidCallback onViewProfile;

  @override
  Widget build(BuildContext context) => InteractiveSurface(
    borderRadius: 14,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDE6EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _CustomerStatusBadge(customer.active),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.star_rounded,
                          size: 15,
                          color: Color(0xFFFFBD00),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          customer.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _adminMoney(customer.totalSpent),
                    style: const TextStyle(
                      color: Color(0xFF0783D5),
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Total Spent',
                    style: TextStyle(color: Color(0xFF42566B), fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          _CustomerInfoRow(icon: Icons.email_outlined, text: customer.email),
          const SizedBox(height: 8),
          _CustomerInfoRow(icon: Icons.phone_outlined, text: customer.phone),
          const SizedBox(height: 8),
          _CustomerInfoRow(
            icon: Icons.location_on_outlined,
            text: customer.address,
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE1E9F0)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _CustomerMetric(
                  value: '${customer.bookings}',
                  label: 'Bookings',
                ),
              ),
              Expanded(
                child: _CustomerMetric(
                  value: '${customer.completionRate}%',
                  label: 'Complete',
                ),
              ),
              Expanded(
                child: _CustomerMetric(
                  value: customer.lastBookingLabel,
                  label: 'Last Booking',
                  compact: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: ElevatedButton(
              onPressed: onViewProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1087DD),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'View Full Profile',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _CustomerStatusBadge extends StatelessWidget {
  const _CustomerStatusBadge(this.active);

  final bool active;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: active ? const Color(0xFFDCEEFF) : Colors.white,
      borderRadius: BorderRadius.circular(999),
      border: active
          ? null
          : Border.all(color: const Color(0xFFE1E9F0), width: 1),
    ),
    child: Text(
      active ? 'Active' : 'Inactive',
      style: TextStyle(
        color: active ? const Color(0xFF0D6FB8) : const Color(0xFF475569),
        fontSize: 10,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _CustomerInfoRow extends StatelessWidget {
  const _CustomerInfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 15, color: const Color(0xFF5E7388)),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Color(0xFF42566B), fontSize: 12),
        ),
      ),
    ],
  );
}

class _CustomerMetric extends StatelessWidget {
  const _CustomerMetric({
    required this.value,
    required this.label,
    this.compact = false,
  });

  final String value;
  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: const Color(0xFF081C33),
          fontSize: compact ? 11 : 13,
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Color(0xFF47647D), fontSize: 10),
      ),
    ],
  );
}

class _AdminCustomerProfile {
  const _AdminCustomerProfile({
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.active,
    required this.rating,
    required this.bookings,
    required this.completedBookings,
    required this.totalSpent,
    required this.lastBooking,
    this.history = const [],
    this.sourceUser,
  });

  final String name;
  final String email;
  final String phone;
  final String address;
  final bool active;
  final double rating;
  final int bookings;
  final int completedBookings;
  final double totalSpent;
  final DateTime? lastBooking;
  final List<BookingModel> history;
  final UserModel? sourceUser;

  int get completionRate =>
      bookings == 0 ? 0 : (completedBookings / bookings * 100).round();

  String get lastBookingLabel =>
      lastBooking == null ? 'None' : DateFormat('MMM d').format(lastBooking!);
}

List<_AdminCustomerProfile> _adminCustomerProfiles(
  List<UserModel> users,
  List<BookingModel> bookings,
) {
  if (users.isEmpty && bookings.isEmpty) return _demoAdminCustomers;
  final profiles = <_AdminCustomerProfile>[];
  for (final user in users) {
    final userBookings = bookings
        .where(
          (booking) =>
              booking.userId == user.id ||
              booking.customerName == user.fullName,
        )
        .toList();
    profiles.add(
      _customerProfileFromBookings(
        name: user.fullName,
        email: user.email,
        phone: user.phone,
        address: user.address.isEmpty ? 'Phnom Penh' : user.address,
        active: user.isActive,
        rating: 4.8,
        bookings: userBookings,
        sourceUser: user,
      ),
    );
  }
  final knownNames = {for (final profile in profiles) profile.name};
  final groupedBookings = <String, List<BookingModel>>{};
  for (final booking in bookings) {
    if (knownNames.contains(booking.customerName)) continue;
    groupedBookings.putIfAbsent(booking.customerName, () => []).add(booking);
  }
  for (final entry in groupedBookings.entries) {
    profiles.add(
      _customerProfileFromBookings(
        name: entry.key,
        email: _adminCustomerEmail(entry.key),
        phone: entry.value.first.phone,
        address: entry.value.first.address,
        active: entry.value.any((item) => item.status != 'Cancelled'),
        rating: 4.7,
        bookings: entry.value,
      ),
    );
  }
  return profiles.isEmpty ? _demoAdminCustomers : profiles;
}

_AdminCustomerProfile _customerProfileFromBookings({
  required String name,
  required String email,
  required String phone,
  required String address,
  required bool active,
  required double rating,
  required List<BookingModel> bookings,
  UserModel? sourceUser,
}) {
  final completed = bookings
      .where((booking) => booking.status == 'Completed')
      .length;
  final totalSpent = bookings
      .where((booking) => booking.status != 'Cancelled')
      .fold<double>(0, (sum, booking) => sum + booking.totalPrice);
  final dates =
      bookings
          .map((booking) => DateTime.tryParse(booking.bookingDate))
          .whereType<DateTime>()
          .toList()
        ..sort((a, b) => b.compareTo(a));
  return _AdminCustomerProfile(
    name: name,
    email: email,
    phone: phone,
    address: address,
    active: active,
    rating: rating,
    bookings: bookings.length,
    completedBookings: completed,
    totalSpent: totalSpent,
    lastBooking: dates.isEmpty ? null : dates.first,
    history: bookings,
    sourceUser: sourceUser,
  );
}

final _demoAdminCustomers = <_AdminCustomerProfile>[
  _AdminCustomerProfile(
    name: 'John Doe',
    email: 'john.doe@email.com',
    phone: '+1 (555) 123-4567',
    address: '123 Main St, Apt 4B, New York, NY',
    active: true,
    rating: 4.8,
    bookings: 12,
    completedBookings: 11,
    totalSpent: 1248,
    lastBooking: DateTime(2026, 5, 28),
  ),
  _AdminCustomerProfile(
    name: 'Jane Smith',
    email: 'jane.smith@email.com',
    phone: '+1 (555) 234-5678',
    address: '456 Oak Ave, Manhattan, NY',
    active: true,
    rating: 4.9,
    bookings: 8,
    completedBookings: 8,
    totalSpent: 672,
    lastBooking: DateTime(2026, 6, 2),
  ),
  _AdminCustomerProfile(
    name: 'Alice Brown',
    email: 'alice.brown@email.com',
    phone: '+1 (555) 456-7890',
    address: '321 Park Ave, Queens, NY',
    active: true,
    rating: 4.7,
    bookings: 5,
    completedBookings: 5,
    totalSpent: 589,
    lastBooking: DateTime(2026, 5, 20),
  ),
  _AdminCustomerProfile(
    name: 'Tom Green',
    email: 'tom.green@email.com',
    phone: '+1 (555) 567-8901',
    address: '654 Elm St, Bronx, NY',
    active: false,
    rating: 4.5,
    bookings: 3,
    completedBookings: 2,
    totalSpent: 178,
    lastBooking: DateTime(2026, 4, 28),
  ),
  _AdminCustomerProfile(
    name: 'Bob Wilson',
    email: 'bob.wilson@email.com',
    phone: '+1 (555) 678-9012',
    address: '789 Business Blvd, Brooklyn, NY',
    active: true,
    rating: 4.6,
    bookings: 7,
    completedBookings: 6,
    totalSpent: 1686,
    lastBooking: DateTime(2026, 6, 3),
  ),
];

void _showCustomerProfile(
  BuildContext context,
  _AdminCustomerProfile customer,
) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => _CustomerProfileDialog(
      customer: customer,
      onDeactivate: customer.sourceUser == null || !customer.active
          ? null
          : () async {
              final provider = context.read<AdminDataProvider>();
              await provider.saveUser(
                customer.sourceUser!.copyWith(isActive: false),
              );
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
              _showAdminToast(context, '${customer.name} marked inactive');
            },
    ),
  );
}

class _CustomerProfileDialog extends StatelessWidget {
  const _CustomerProfileDialog({required this.customer, this.onDeactivate});

  final _AdminCustomerProfile customer;
  final Future<void> Function()? onDeactivate;

  @override
  Widget build(BuildContext context) {
    final latestBooking = _latestCustomerBooking(customer);
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Material(
            color: Colors.white,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF0F8DE0), Color(0xFF48B7FF)],
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.22,
                              ),
                              child: Text(
                                customer.name.isEmpty
                                    ? '?'
                                    : customer.name[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    customer.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Row(
                                    children: [
                                      _CustomerHeaderBadge(customer.active),
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.star_rounded,
                                        color: Color(0xFFFFE15A),
                                        size: 15,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        customer.rating.toStringAsFixed(0),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton.filled(
                              tooltip: 'Close',
                              onPressed: () => Navigator.pop(context),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.2,
                                ),
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _CustomerProfileHeaderStat(
                                value: '${customer.bookings}',
                                label: 'Bookings',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _CustomerProfileHeaderStat(
                                value: _adminMoney(customer.totalSpent),
                                label: 'Total Spent',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _CustomerProfileHeaderStat(
                                value: '${customer.completionRate}%',
                                label: 'Complete',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _CustomerProfileSectionTitle(
                          'Contact Information',
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F0F7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              _CustomerInfoRow(
                                icon: Icons.email_outlined,
                                text: customer.email,
                              ),
                              const SizedBox(height: 8),
                              _CustomerInfoRow(
                                icon: Icons.phone_outlined,
                                text: customer.phone,
                              ),
                              const SizedBox(height: 8),
                              _CustomerInfoRow(
                                icon: Icons.location_on_outlined,
                                text: customer.address,
                              ),
                              const SizedBox(height: 8),
                              const _CustomerInfoRow(
                                icon: Icons.calendar_today_outlined,
                                text: 'Member since March 2026',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        const _CustomerProfileSectionTitle(
                          'Account Statistics',
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _CustomerAccountStatCard(
                                icon: Icons.check_circle_outline,
                                label: 'Completed',
                                value: '${customer.completedBookings} jobs',
                                color: const Color(0xFF168BDB),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _CustomerAccountStatCard(
                                icon: Icons.access_time,
                                label: 'Last Booking',
                                value: customer.lastBookingLabel,
                                color: const Color(0xFF238FE5),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        const _CustomerProfileSectionTitle('Booking History'),
                        const SizedBox(height: 10),
                        latestBooking == null
                            ? const _CustomerHistoryEmpty()
                            : _CustomerHistoryCard(booking: latestBooking),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: OutlinedButton.icon(
                            onPressed: onDeactivate == null
                                ? null
                                : () => onDeactivate!.call(),
                            icon: const Icon(Icons.block_outlined, size: 15),
                            label: Text(
                              customer.active ? 'Deactivate' : 'Inactive',
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.danger,
                              side: const BorderSide(color: Color(0xFFFFB8B8)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomerHeaderBadge extends StatelessWidget {
  const _CustomerHeaderBadge(this.active);

  final bool active;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      active ? 'Active' : 'Inactive',
      style: TextStyle(
        color: active ? const Color(0xFF1087DD) : const Color(0xFF64748B),
        fontSize: 9,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

class _CustomerProfileHeaderStat extends StatelessWidget {
  const _CustomerProfileHeaderStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    height: 66,
    padding: const EdgeInsets.symmetric(horizontal: 8),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _CustomerProfileSectionTitle extends StatelessWidget {
  const _CustomerProfileSectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: const TextStyle(
      color: Color(0xFF081C33),
      fontSize: 13,
      fontWeight: FontWeight.w900,
    ),
  );
}

class _CustomerAccountStatCard extends StatelessWidget {
  const _CustomerAccountStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    height: 56,
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xFFE8F0F7),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF42566B),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
        ),
      ],
    ),
  );
}

class _CustomerHistoryCard extends StatelessWidget {
  const _CustomerHistoryCard({required this.booking});

  final BookingModel booking;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: const Color(0xFFE8F0F7),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                booking.serviceName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF081C33),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${booking.cleanerName.isEmpty ? 'Not assigned' : booking.cleanerName} - ${_adminBookingDateLabel(booking)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF42566B), fontSize: 10),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _adminMoney(booking.totalPrice),
              style: const TextStyle(
                color: Color(0xFF0783D5),
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFDCEEFF),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                booking.status,
                style: const TextStyle(
                  color: Color(0xFF0D6FB8),
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _CustomerHistoryEmpty extends StatelessWidget {
  const _CustomerHistoryEmpty();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFE8F0F7),
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Text(
      'No booking history yet.',
      style: TextStyle(color: Color(0xFF42566B), fontSize: 12),
    ),
  );
}

BookingModel? _latestCustomerBooking(_AdminCustomerProfile customer) {
  final history = List<BookingModel>.of(customer.history);
  if (history.isEmpty) return _demoBookingForCustomer(customer);
  history.sort((a, b) {
    final left = DateTime.tryParse(a.bookingDate) ?? DateTime(1900);
    final right = DateTime.tryParse(b.bookingDate) ?? DateTime(1900);
    return right.compareTo(left);
  });
  return history.first;
}

BookingModel? _demoBookingForCustomer(_AdminCustomerProfile customer) {
  if (customer.lastBooking == null) return null;
  return BookingModel(
    id: 9000,
    userId: 0,
    serviceId: 1,
    serviceName: switch (customer.name) {
      'Alice Brown' => 'Sofa Cleaning',
      'Bob Wilson' => 'Office Cleaning',
      'Tom Green' => 'Carpet Cleaning',
      _ => 'Home Cleaning',
    },
    customerName: customer.name,
    phone: customer.phone,
    address: customer.address,
    propertyType: 'House',
    rooms: 2,
    bathrooms: 1,
    bookingDate: DateFormat('yyyy-MM-dd').format(customer.lastBooking!),
    bookingTime: '10:00 AM',
    extraServices: const [],
    paymentMethod: 'Cash',
    basePrice: customer.totalSpent / customer.bookings.clamp(1, 999),
    extraPrice: 0,
    totalPrice: customer.totalSpent / customer.bookings.clamp(1, 999),
    estimatedDuration: 120,
    cleanerName: switch (customer.name) {
      'Alice Brown' => 'Emily Davis',
      'Bob Wilson' => 'Sarah Johnson',
      _ => 'Cleaner Demo',
    },
    status: customer.active ? 'Completed' : 'Cancelled',
  );
}

class AdminCleanerManagementScreen extends StatefulWidget {
  const AdminCleanerManagementScreen({super.key});

  @override
  State<AdminCleanerManagementScreen> createState() =>
      _AdminCleanerManagementScreenState();
}

class _AdminCleanerManagementScreenState
    extends State<AdminCleanerManagementScreen> {
  final searchController = TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminDataProvider>();
    final bookings = context.watch<BookingProvider>().bookings;
    final sourceCleaners = provider.users
        .where((item) => item.role == 'cleaner')
        .toList();
    final cleaners = sourceCleaners.isEmpty
        ? _demoAdminCleaners
        : sourceCleaners;
    final query = searchController.text.trim().toLowerCase();
    final filteredCleaners = cleaners.where((cleaner) {
      return query.isEmpty ||
          cleaner.fullName.toLowerCase().contains(query) ||
          cleaner.email.toLowerCase().contains(query) ||
          cleaner.phone.toLowerCase().contains(query) ||
          cleaner.address.toLowerCase().contains(query);
    }).toList();
    final available = cleaners.where((cleaner) {
      final jobs = bookings
          .where((booking) => booking.cleanerId == cleaner.id)
          .toList();
      return _cleanerAvailabilityStatus(cleaner, jobs) == 'Available';
    }).length;
    final busy = cleaners.where((cleaner) {
      final jobs = bookings
          .where((booking) => booking.cleanerId == cleaner.id)
          .toList();
      return _cleanerAvailabilityStatus(cleaner, jobs) == 'Busy';
    }).length;
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        toolbarHeight: 70,
        titleSpacing: 32,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${AppStrings.appName} Admin',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 2),
            const Text(
              'Management Portal',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: () async {
              final auth = context.read<AuthProvider>();
              final navigator = Navigator.of(context);
              await auth.logout();
              navigator.pushNamedAndRemoveUntil(
                LoginScreen.route,
                (_) => false,
              );
            },
            icon: const Icon(Icons.logout_outlined),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: provider.load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cleaner\nManagement',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          height: 1.35,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Manage cleaning staff',
                        style: TextStyle(color: AppColors.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 118,
                  height: 58,
                  child: ElevatedButton.icon(
                    onPressed: () => showAddCleanerSheet(context),
                    icon: const Icon(Icons.person_add_alt_1, size: 16),
                    label: const Text(
                      'Add\nCleaner',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, height: 1.15),
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(118, 58),
                      backgroundColor: const Color(0xFF168BDB),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search cleaners...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: () {
                          searchController.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.close),
                      ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _CleanerSummaryCard(
                    value: cleaners.length,
                    label: 'Total',
                    color: const Color(0xFF0E60B8),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _CleanerSummaryCard(
                    value: available,
                    label: 'Available',
                    color: const Color(0xFF168BDB),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _CleanerSummaryCard(
                    value: busy,
                    label: 'Busy',
                    color: const Color(0xFFFF4A16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (filteredCleaners.isEmpty)
              const EmptyStateWidget(
                title: 'No matching cleaners',
                message: 'Try another search term or add a new cleaner.',
                icon: Icons.person_search_outlined,
              )
            else
              for (final cleaner in filteredCleaners)
                _AdminCleanerCard(
                  cleaner: cleaner,
                  jobs: bookings
                      .where((item) => item.cleanerId == cleaner.id)
                      .toList(),
                  onEdit: () => showCleanerDetailSheet(
                    context,
                    cleaner: cleaner,
                    jobs: bookings
                        .where((item) => item.cleanerId == cleaner.id)
                        .toList(),
                  ),
                  onAssign: () => _showAssignableBookings(context, cleaner),
                ),
          ],
        ),
      ),
    );
  }
}

final _demoAdminCleaners = <UserModel>[
  const UserModel(
    id: 101,
    firebaseUid: 'demo-cleaner-sarah',
    fullName: 'Sarah Johnson',
    email: 'sarah.j@email.com',
    phone: '+1 (555) 987-6543',
    role: 'cleaner',
    address: 'Manhattan, Brooklyn',
    hourlyRate: 12,
    isActive: true,
  ),
  const UserModel(
    id: 102,
    firebaseUid: 'demo-cleaner-mike',
    fullName: 'Mike Chen',
    email: 'mike.c@email.com',
    phone: '+1 (555) 876-5432',
    role: 'cleaner',
    address: 'Queens, Brooklyn',
    hourlyRate: 12,
    isActive: false,
  ),
  const UserModel(
    id: 103,
    firebaseUid: 'demo-cleaner-emily',
    fullName: 'Emily Davis',
    email: 'emily.d@email.com',
    phone: '+1 (555) 765-4321',
    role: 'cleaner',
    address: 'Manhattan',
    hourlyRate: 11,
    isActive: true,
  ),
  const UserModel(
    id: 104,
    firebaseUid: 'demo-cleaner-john',
    fullName: 'John Smith',
    email: 'john.s@email.com',
    phone: '+1 (555) 654-3210',
    role: 'cleaner',
    address: 'Bronx, Queens',
    hourlyRate: 10,
    isActive: false,
  ),
];

class _CleanerSummaryCard extends StatelessWidget {
  const _CleanerSummaryCard({
    required this.value,
    required this.label,
    required this.color,
  });

  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    height: 58,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFDDE6EE)),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$value',
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF47647D), fontSize: 10),
        ),
      ],
    ),
  );
}

class _AdminCleanerCard extends StatelessWidget {
  const _AdminCleanerCard({
    required this.cleaner,
    required this.jobs,
    required this.onEdit,
    required this.onAssign,
  });

  final UserModel cleaner;
  final List<BookingModel> jobs;
  final VoidCallback onEdit;
  final VoidCallback onAssign;

  @override
  Widget build(BuildContext context) {
    final completed = jobs.where((item) => item.status == 'Completed').length;
    final index = _demoAdminCleaners.indexWhere(
      (item) => item.id == cleaner.id,
    );
    final fallbackCompleted = index < 0 ? 95 : [125, 116, 102, 87][index];
    final earnings = jobs.fold<double>(0, (sum, item) => sum + item.cleanerPay);
    final fallbackEarnings = index < 0
        ? cleaner.hourlyRate * 480
        : [8450.0, 7920.0, 6780.0, 5630.0][index];
    final rating = index < 0 ? 4.8 : [4.9, 4.8, 4.7, 4.6][index];
    final displayCompleted = jobs.isEmpty ? fallbackCompleted : completed;
    final displayEarnings = earnings == 0 ? fallbackEarnings : earnings;
    final status = _cleanerAvailabilityStatus(cleaner, jobs);
    return InteractiveSurface(
      borderRadius: 12,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFDDE6EE)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              cleaner.fullName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _CleanerAvailabilityBadge(status),
                const SizedBox(width: 6),
                const Icon(
                  Icons.star_rounded,
                  color: Color(0xFFFFB000),
                  size: 16,
                ),
                const SizedBox(width: 2),
                Text(
                  rating.toStringAsFixed(1),
                  style: const TextStyle(
                    color: Color(0xFF102A43),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _CleanerInfoRow(icon: Icons.email_outlined, text: cleaner.email),
            const SizedBox(height: 8),
            const _CleanerInfoRow(
              icon: Icons.lock_outline,
              text: 'Temporary password: demo123',
            ),
            const SizedBox(height: 8),
            _CleanerInfoRow(icon: Icons.phone_outlined, text: cleaner.phone),
            const SizedBox(height: 8),
            _CleanerInfoRow(
              icon: Icons.location_on_outlined,
              text: cleaner.address.isEmpty ? 'Phnom Penh' : cleaner.address,
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFE1E9F0)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _CleanerMetric(
                    icon: Icons.calendar_today_outlined,
                    value: '$displayCompleted',
                    label: 'Completed',
                  ),
                ),
                Expanded(
                  child: _CleanerMetric(
                    icon: Icons.check_circle_outline,
                    value: '98%',
                    label: 'Success',
                  ),
                ),
                Expanded(
                  child: _CleanerMetric(
                    icon: Icons.attach_money,
                    value: _adminMoney(displayEarnings),
                    label: 'Earnings',
                    valueColor: const Color(0xFF0D83D8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1, color: Color(0xFFE1E9F0)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: ElevatedButton(
                      onPressed: onEdit,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(36),
                        backgroundColor: const Color(0xFF1087DD),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('View Details'),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: OutlinedButton(
                      onPressed: status == 'Available' ? onAssign : null,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(36),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Assign Job'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CleanerAvailabilityBadge extends StatelessWidget {
  const _CleanerAvailabilityBadge(this.status);

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'Available' => const Color(0xFFDCEEFF),
      'Busy' => const Color(0xFFFFE4C6),
      _ => const Color(0xFFF1F5F9),
    };
    final textColor = switch (status) {
      'Available' => const Color(0xFF0D6FB8),
      'Busy' => const Color(0xFFE56C00),
      _ => const Color(0xFF475569),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _CleanerInfoRow extends StatelessWidget {
  const _CleanerInfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 15, color: const Color(0xFF5E7388)),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Color(0xFF42566B), fontSize: 12),
        ),
      ),
    ],
  );
}

class _CleanerMetric extends StatelessWidget {
  const _CleanerMetric({
    required this.icon,
    required this.value,
    required this.label,
    this.valueColor = const Color(0xFF102A43),
  });

  final IconData icon;
  final String value;
  final String label;
  final Color valueColor;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Icon(icon, size: 13, color: const Color(0xFF6B7F92)),
      const SizedBox(height: 6),
      Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: valueColor,
          fontSize: 13,
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 3),
      Text(
        label,
        style: const TextStyle(color: Color(0xFF47647D), fontSize: 10),
      ),
    ],
  );
}

Future<void> _showAssignableBookings(
  BuildContext context,
  UserModel cleaner,
) async {
  final admin = context.read<AuthProvider>().user;
  if (admin == null) return;
  final bookingProvider = context.read<BookingProvider>();
  final liveBookings = bookingProvider.bookings
      .where(_isAvailablePendingBooking)
      .toList();
  final bookings = liveBookings.isEmpty
      ? _demoAdminManagementBookings.where(_isAvailablePendingBooking).toList()
      : liveBookings;

  final selectedBooking = await showDialog<BookingModel>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) =>
        _AssignJobDialog(cleaner: cleaner, bookings: bookings),
  );
  if (selectedBooking == null || !context.mounted) return;

  await _waitForModalRouteToSettle();
  if (!context.mounted) return;
  if (liveBookings.contains(selectedBooking)) {
    try {
      await bookingProvider.assignCleaner(selectedBooking, cleaner, admin);
    } catch (error) {
      if (context.mounted) _showAdminToast(context, error.toString());
      return;
    }
  }
  if (!context.mounted) return;
  _showAdminToast(context, 'Job assigned to ${cleaner.fullName}');
}

bool _isAvailablePendingBooking(BookingModel booking) =>
    booking.cleanerId == null && booking.status == 'Accepted';

bool _cleanerHasActiveJob(UserModel cleaner, List<BookingModel> bookings) =>
    bookings.any(
      (booking) =>
          booking.cleanerId == cleaner.id &&
          !const [
            'Completed',
            'Cancelled',
            'Rejected',
          ].contains(booking.status),
    );

String _cleanerAvailabilityStatus(UserModel cleaner, List<BookingModel> jobs) {
  if (_cleanerHasActiveJob(cleaner, jobs)) return 'Busy';
  if (!cleaner.isActive) return 'Off Duty';
  return cleaner.availabilityStatus == 'Busy' ? 'Busy' : 'Available';
}

class _AssignJobDialog extends StatefulWidget {
  const _AssignJobDialog({required this.cleaner, required this.bookings});

  final UserModel cleaner;
  final List<BookingModel> bookings;

  @override
  State<_AssignJobDialog> createState() => _AssignJobDialogState();
}

class _AssignJobDialogState extends State<_AssignJobDialog> {
  BookingModel? selectedBooking;

  @override
  Widget build(BuildContext context) => Dialog(
    insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Assign Job',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF081C33),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Assigning to ${widget.cleaner.fullName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF42566B),
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Available Pending Jobs',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            if (widget.bookings.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: EmptyStateWidget(
                  title: 'No pending jobs',
                  message: 'Pending unassigned bookings will appear here.',
                  icon: Icons.assignment_outlined,
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 390),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: widget.bookings.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final booking = widget.bookings[index];
                    return _AssignableBookingCard(
                      booking: booking,
                      selected: identical(selectedBooking, booking),
                      onTap: () => setState(() => selectedBooking = booking),
                    );
                  },
                ),
              ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: selectedBooking == null
                          ? null
                          : () => Navigator.pop(context, selectedBooking),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF168BDB),
                        disabledBackgroundColor: const Color(0xFFE2EDF5),
                        disabledForegroundColor: const Color(0xFF51687D),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Assign Job'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _AssignableBookingCard extends StatelessWidget {
  const _AssignableBookingCard({
    required this.booking,
    required this.selected,
    required this.onTap,
  });

  final BookingModel booking;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(18),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFEAF6FF) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selected ? const Color(0xFF168BDB) : const Color(0xFFD7E1EA),
          width: selected ? 2 : 1.2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.serviceName,
                  style: const TextStyle(
                    color: Color(0xFF081C33),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  booking.customerName,
                  style: const TextStyle(
                    color: Color(0xFF405570),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  booking.address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF405570),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_adminBookingDateLabel(booking)} at ${booking.bookingTime}',
                  style: const TextStyle(
                    color: Color(0xFF405570),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _adminMoney(booking.totalPrice),
            style: const TextStyle(
              color: Color(0xFF0783D5),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    ),
  );
}

String _adminBookingDateLabel(BookingModel booking) {
  final date = DateTime.tryParse(booking.bookingDate);
  return date == null
      ? booking.bookingDate
      : DateFormat('yyyy-MM-dd').format(date);
}

Future<void> showCleanerDetailSheet(
  BuildContext context, {
  required UserModel cleaner,
  required List<BookingModel> jobs,
}) async {
  final parentContext = context;
  final hasActiveJob = _cleanerHasActiveJob(cleaner, jobs);
  var selectedStatus = _cleanerAvailabilityStatus(cleaner, jobs);
  final action = await showModalBottomSheet<_CleanerDetailAction>(
    context: parentContext,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => DraggableScrollableSheet(
      initialChildSize: 0.86,
      minChildSize: 0.62,
      maxChildSize: 0.94,
      expand: false,
      builder: (context, scrollController) => StatefulBuilder(
        builder: (context, setSheetState) {
          final stats = _cleanerDisplayStats(cleaner, jobs);
          Future<void> updateAvailability(String status) async {
            if (hasActiveJob && status != 'Busy') {
              _showAdminToast(
                parentContext,
                'This cleaner stays Busy until the assigned task is completed or cancelled.',
              );
              return;
            }
            setSheetState(() => selectedStatus = status);
            final provider = parentContext.read<AdminDataProvider>();
            await provider.saveUser(
              cleaner.copyWith(
                isActive: status != 'Off Duty',
                availabilityStatus: status,
              ),
            );
            if (context.mounted) _showAvailabilityUpdatedToast(context);
          }

          return Container(
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: ListView(
              controller: scrollController,
              padding: EdgeInsets.zero,
              children: [
                _CleanerDetailHero(
                  cleaner: cleaner,
                  stats: stats,
                  onClose: () => Navigator.pop(sheetContext),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _AdminDashboardTitle('Availability Status'),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _AvailabilityOption(
                            label: 'Available',
                            selected: selectedStatus == 'Available',
                            onTap: () => updateAvailability('Available'),
                          ),
                          const SizedBox(width: 8),
                          _AvailabilityOption(
                            label: 'Busy',
                            selected: selectedStatus == 'Busy',
                            onTap: () => updateAvailability('Busy'),
                          ),
                          const SizedBox(width: 8),
                          _AvailabilityOption(
                            label: 'Off Duty',
                            selected: selectedStatus == 'Off Duty',
                            onTap: () => updateAvailability('Off Duty'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const _AdminDashboardTitle('Contact Information'),
                      const SizedBox(height: 10),
                      _AdminContactBox(
                        rows: [
                          (Icons.email_outlined, cleaner.email),
                          (Icons.phone_outlined, cleaner.phone),
                          (
                            Icons.location_on_outlined,
                            cleaner.address.isEmpty
                                ? 'Phnom Penh'
                                : cleaner.address,
                          ),
                          (Icons.calendar_today_outlined, 'Joined March 2025'),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const _AdminDashboardTitle('Specialties'),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: const [
                          _SpecialtyChip('Deep Cleaning'),
                          _SpecialtyChip('Move In/Out'),
                          _SpecialtyChip('Office'),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const _AdminDashboardTitle('Recent Reviews'),
                      const SizedBox(height: 10),
                      const _CleanerReviewCard(
                        name: 'John Doe',
                        text: 'Exceptional work! Very thorough.',
                      ),
                      const SizedBox(height: 8),
                      const _CleanerReviewCard(
                        name: 'Alice Brown',
                        text: 'Sarah is always punctual and professional.',
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 44,
                              child: OutlinedButton.icon(
                                onPressed: () => Navigator.pop(
                                  sheetContext,
                                  _CleanerDetailAction.deactivate,
                                ),
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 16,
                                ),
                                label: const Text('Deactivate'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.danger,
                                  side: const BorderSide(
                                    color: Color(0xFFFFB8B8),
                                  ),
                                  minimumSize: const Size.fromHeight(44),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 44,
                              child: ElevatedButton.icon(
                                onPressed: () => Navigator.pop(
                                  sheetContext,
                                  _CleanerDetailAction.editProfile,
                                ),
                                icon: const Icon(Icons.edit_outlined, size: 16),
                                label: const Text('Edit Profile'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF168BDB),
                                  minimumSize: const Size.fromHeight(44),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ),
  );

  if (!parentContext.mounted) return;
  switch (action) {
    case _CleanerDetailAction.editProfile:
      await _waitForModalRouteToSettle();
      if (!parentContext.mounted) return;
      await showEditCleanerSheet(parentContext, cleaner: cleaner);
    case _CleanerDetailAction.deactivate:
      await _waitForModalRouteToSettle();
      if (!parentContext.mounted) return;
      await parentContext.read<AdminDataProvider>().saveUser(
        cleaner.copyWith(isActive: false),
      );
    case null:
      break;
  }
}

enum _CleanerDetailAction { editProfile, deactivate }

Future<void> _waitForModalRouteToSettle() async {
  await WidgetsBinding.instance.endOfFrame;
  await Future<void>.delayed(const Duration(milliseconds: 350));
}

({int completed, double earnings, double rating, int demoIndex})
_cleanerDisplayStats(UserModel cleaner, List<BookingModel> jobs) {
  final completed = jobs.where((item) => item.status == 'Completed').length;
  final index = _demoAdminCleaners.indexWhere((item) => item.id == cleaner.id);
  final fallbackCompleted = index < 0 ? 95 : [125, 116, 102, 87][index];
  final earnings = jobs.fold<double>(0, (sum, item) => sum + item.cleanerPay);
  final fallbackEarnings = index < 0
      ? cleaner.hourlyRate * 480
      : [8450.0, 7920.0, 6780.0, 5630.0][index];
  final rating = index < 0 ? 4.8 : [4.9, 4.8, 4.7, 4.6][index];
  return (
    completed: jobs.isEmpty ? fallbackCompleted : completed,
    earnings: earnings == 0 ? fallbackEarnings : earnings,
    rating: rating,
    demoIndex: index,
  );
}

void _showAvailabilityUpdatedToast(BuildContext context) {
  _showAdminToast(context, 'Availability updated');
}

void _showAdminToast(BuildContext context, String message) {
  final overlay = Overlay.of(context, rootOverlay: true);
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => Positioned(
      top: MediaQuery.of(context).padding.top + 22,
      left: 86,
      right: 86,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF0D6FB8),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  message,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  overlay.insert(entry);
  Future<void>.delayed(const Duration(seconds: 2), entry.remove);
}

class _CleanerDetailHero extends StatelessWidget {
  const _CleanerDetailHero({
    required this.cleaner,
    required this.stats,
    required this.onClose,
  });

  final UserModel cleaner;
  final ({int completed, double earnings, double rating, int demoIndex}) stats;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
    decoration: const BoxDecoration(
      gradient: LinearGradient(colors: [Color(0xFF168BDB), Color(0xFF4BA9E8)]),
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    child: Column(
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.white.withValues(alpha: 0.18),
              child: Text(
                cleaner.fullName.isEmpty
                    ? '?'
                    : cleaner.fullName[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cleaner.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFFFD43B),
                        size: 16,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${stats.rating.toStringAsFixed(1)} rating',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton.filled(
              tooltip: 'Close',
              onPressed: onClose,
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.18),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _CleanerDetailStat(
                value: '${stats.completed}',
                label: 'Jobs',
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: _CleanerDetailStat(value: '98%', label: 'Success'),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _CleanerDetailStat(
                value: _adminMoney(stats.earnings),
                label: 'Earned',
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _CleanerDetailStat extends StatelessWidget {
  const _CleanerDetailStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    height: 58,
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _AvailabilityOption extends StatelessWidget {
  const _AvailabilityOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  Color get _selectedBackground => switch (label) {
    'Available' => const Color(0xFFEAF6FF),
    'Busy' => const Color(0xFFFFF3E8),
    _ => const Color(0xFFF1F5F9),
  };

  Color get _selectedBorder => switch (label) {
    'Available' => const Color(0xFF0D6FB8),
    'Busy' => const Color(0xFFFF6A00),
    _ => const Color(0xFF94A3B8),
  };

  Color get _selectedText => switch (label) {
    'Available' => const Color(0xFF0A5FA3),
    'Busy' => const Color(0xFFE56C00),
    _ => const Color(0xFF475569),
  };

  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? _selectedBackground : const Color(0xFFE8F0F6),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? _selectedBorder : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? _selectedText : const Color(0xFF47647D),
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    ),
  );
}

class _SpecialtyChip extends StatelessWidget {
  const _SpecialtyChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xFFEAF6FF),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: Color(0xFF0D6FB8),
        fontSize: 10,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _CleanerReviewCard extends StatelessWidget {
  const _CleanerReviewCard({required this.name, required this.text});

  final String name;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFE6F0F8),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                text,
                style: const TextStyle(color: Color(0xFF47647D), fontSize: 10),
              ),
            ],
          ),
        ),
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star_rounded, color: Color(0xFFFFB000), size: 14),
            Icon(Icons.star_rounded, color: Color(0xFFFFB000), size: 14),
            Icon(Icons.star_rounded, color: Color(0xFFFFB000), size: 14),
            Icon(Icons.star_rounded, color: Color(0xFFFFB000), size: 14),
            Icon(Icons.star_rounded, color: Color(0xFFFFB000), size: 14),
          ],
        ),
      ],
    ),
  );
}

class AdminServiceManagementScreen extends StatelessWidget {
  const AdminServiceManagementScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final services = context.watch<ServiceProvider>().services;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Services'),
        actions: [
          IconButton(
            tooltip: 'Add service',
            onPressed: () => showServiceEditor(context),
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          RoleNoticeCard(
            title: 'Service package management',
            message:
                'Requirement allows admin management to be simulated locally. These cards expose package data for review and testing.',
            icon: Icons.tune_outlined,
          ),
          const SizedBox(height: 12),
          for (final service in services)
            Card(
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    service.imageUrl,
                    width: 58,
                    height: 58,
                    fit: BoxFit.cover,
                  ),
                ),
                title: Text(service.name),
                subtitle: Text(
                  '${service.category} • ${money(service.basePrice)} • ${service.durationMinutes} min • ${service.cleanersRequired} cleaner(s)',
                ),
                trailing: Wrap(
                  spacing: 4,
                  children: [
                    Chip(label: Text(service.isActive ? 'Active' : 'Hidden')),
                    IconButton(
                      tooltip: 'Edit service',
                      onPressed: () => showServiceEditor(context, service),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      tooltip: 'Hide service',
                      onPressed: () => context
                          .read<ServiceProvider>()
                          .deleteService(service),
                      icon: const Icon(Icons.visibility_off_outlined),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class RoleBookingManagementScreen extends StatefulWidget {
  const RoleBookingManagementScreen({super.key});

  @override
  State<RoleBookingManagementScreen> createState() =>
      _RoleBookingManagementScreenState();
}

class _RoleBookingManagementScreenState
    extends State<RoleBookingManagementScreen> {
  final searchController = TextEditingController();
  String selectedStatus = 'All';

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<BookingProvider>();
    final role = auth.user?.role ?? 'customer';
    final visibleBookings = role == 'cleaner'
        ? provider.bookings
              .where(
                (item) => [
                  'Accepted',
                  'Cleaner Assigned',
                  'On the Way',
                  'Arrived',
                  'In Progress',
                  'Completed',
                ].contains(item.status),
              )
              .toList()
        : provider.bookings;
    if (role == 'admin') {
      final sourceBookings = visibleBookings.isEmpty
          ? _demoAdminManagementBookings
          : visibleBookings;
      final query = searchController.text.trim().toLowerCase();
      final filteredBookings = sourceBookings.where((booking) {
        final matchesStatus =
            selectedStatus == 'All' || booking.status == selectedStatus;
        final matchesSearch =
            query.isEmpty ||
            booking.serviceName.toLowerCase().contains(query) ||
            booking.customerName.toLowerCase().contains(query) ||
            booking.cleanerName.toLowerCase().contains(query) ||
            booking.address.toLowerCase().contains(query);
        return matchesStatus && matchesSearch;
      }).toList();
      return Scaffold(
        appBar: AppBar(
          centerTitle: false,
          toolbarHeight: 70,
          titleSpacing: 32,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${AppStrings.appName} Admin',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Management Portal',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: [
            const _NotificationAction(),
            IconButton(
              tooltip: 'Logout',
              onPressed: () async {
                final auth = context.read<AuthProvider>();
                final navigator = Navigator.of(context);
                await auth.logout();
                navigator.pushNamedAndRemoveUntil(
                  LoginScreen.route,
                  (_) => false,
                );
              },
              icon: const Icon(Icons.logout_outlined),
            ),
          ],
        ),
        body: provider.loading
            ? const LoadingWidget()
            : RefreshIndicator(
                onRefresh: () => provider.loadForRole(auth.user),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
                  children: [
                    const Text(
                      'Booking Management',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Manage all bookings',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search bookings...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: searchController.text.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Clear search',
                                onPressed: () {
                                  searchController.clear();
                                  setState(() {});
                                },
                                icon: const Icon(Icons.close),
                              ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _AdminBookingStatusFilters(
                      selectedStatus: selectedStatus,
                      bookings: sourceBookings,
                      onSelected: (status) =>
                          setState(() => selectedStatus = status),
                    ),
                    const SizedBox(height: 14),
                    if (filteredBookings.isEmpty)
                      const EmptyStateWidget(
                        title: 'No matching bookings',
                        message:
                            'Try another search term or choose a different status.',
                        icon: Icons.manage_search_outlined,
                      )
                    else
                      for (final booking in filteredBookings)
                        _AdminManagementBookingCard(booking: booking),
                  ],
                ),
              ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Job Status')),
      body: provider.loading
          ? const LoadingWidget()
          : RefreshIndicator(
              onRefresh: () => provider.loadForRole(auth.user),
              child: visibleBookings.isEmpty
                  ? ListView(
                      children: [
                        EmptyStateWidget(
                          title: role == 'admin'
                              ? 'No bookings yet'
                              : 'No assigned jobs',
                          message: role == 'admin'
                              ? 'Create a customer booking, then return here to manage it.'
                              : 'Accepted or assigned jobs will appear here.',
                        ),
                      ],
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        for (final booking in visibleBookings)
                          BookingManagementTile(booking: booking),
                      ],
                    ),
            ),
    );
  }
}

final _demoAdminManagementBookings = <BookingModel>[
  const BookingModel(
    id: 1,
    userId: 1,
    serviceId: 2,
    serviceName: 'Deep Cleaning',
    customerName: 'John Doe',
    phone: '+855 100 200 300',
    address: '123 Main St, Apt 4B',
    propertyType: 'Apartment',
    rooms: 3,
    bathrooms: 2,
    bookingDate: '2026-06-05',
    bookingTime: '10:00 AM',
    extraServices: [],
    paymentMethod: 'Cash',
    basePrice: 129,
    extraPrice: 0,
    totalPrice: 129,
    estimatedDuration: 240,
    cleanerId: 2,
    cleanerName: 'Sarah Johnson',
    cleanerPay: 45,
    status: 'Accepted',
  ),
  const BookingModel(
    id: 2,
    userId: 2,
    serviceId: 1,
    serviceName: 'Home Cleaning',
    customerName: 'Jane Smith',
    phone: '+855 111 222 333',
    address: '456 Oak Ave',
    propertyType: 'House',
    rooms: 2,
    bathrooms: 1,
    bookingDate: '2026-06-02',
    bookingTime: '02:00 PM',
    extraServices: [],
    paymentMethod: 'Card',
    basePrice: 79,
    extraPrice: 0,
    totalPrice: 79,
    estimatedDuration: 120,
    cleanerId: 3,
    cleanerName: 'Mike Chen',
    cleanerPay: 32,
    status: 'In Progress',
  ),
  const BookingModel(
    id: 3,
    userId: 3,
    serviceId: 3,
    serviceName: 'Office Cleaning',
    customerName: 'Bob Wilson',
    phone: '+855 222 333 444',
    address: '789 Business Blvd',
    propertyType: 'Office',
    rooms: 4,
    bathrooms: 2,
    bookingDate: '2026-06-03',
    bookingTime: '09:00 AM',
    extraServices: [],
    paymentMethod: 'Cash',
    basePrice: 99,
    extraPrice: 0,
    totalPrice: 99,
    estimatedDuration: 180,
    status: 'Pending',
  ),
  const BookingModel(
    id: 4,
    userId: 4,
    serviceId: 5,
    serviceName: 'Sofa Cleaning',
    customerName: 'Alice Brown',
    phone: '+855 333 444 555',
    address: '321 Park Ave',
    propertyType: 'Apartment',
    rooms: 1,
    bathrooms: 1,
    bookingDate: '2026-05-28',
    bookingTime: '11:00 AM',
    extraServices: [],
    paymentMethod: 'Card',
    basePrice: 39,
    extraPrice: 0,
    totalPrice: 39,
    estimatedDuration: 90,
    cleanerId: 4,
    cleanerName: 'Emily Davis',
    cleanerPay: 20,
    status: 'Completed',
  ),
  const BookingModel(
    id: 5,
    userId: 5,
    serviceId: 6,
    serviceName: 'Carpet Cleaning',
    customerName: 'Tom Green',
    phone: '+855 444 555 666',
    address: '654 Elm St',
    propertyType: 'House',
    rooms: 2,
    bathrooms: 1,
    bookingDate: '2026-05-25',
    bookingTime: '03:00 PM',
    extraServices: [],
    paymentMethod: 'Cash',
    basePrice: 59,
    extraPrice: 0,
    totalPrice: 59,
    estimatedDuration: 120,
    status: 'Cancelled',
  ),
];

class _AdminBookingStatusFilters extends StatelessWidget {
  const _AdminBookingStatusFilters({
    required this.selectedStatus,
    required this.bookings,
    required this.onSelected,
  });

  final String selectedStatus;
  final List<BookingModel> bookings;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    const statuses = [
      'All',
      'Pending',
      'Accepted',
      'Cleaner Assigned',
      'On the Way',
      'Arrived',
      'In Progress',
      'Completed',
      'Cancelled',
      'Rejected',
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final status in statuses)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(
                  '$status (${_bookingCountForStatus(status, bookings)})',
                ),
                selected: selectedStatus == status,
                onSelected: (_) => onSelected(status),
                showCheckmark: false,
                selectedColor: const Color(0xFFEAF6FF),
                backgroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFFDDE6EE)),
                labelStyle: TextStyle(
                  color: selectedStatus == status
                      ? AppColors.primaryDark
                      : AppColors.text,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

int _bookingCountForStatus(String status, List<BookingModel> bookings) {
  if (status == 'All') return bookings.length;
  return bookings.where((booking) => booking.status == status).length;
}

class _AdminManagementBookingCard extends StatelessWidget {
  const _AdminManagementBookingCard({required this.booking});

  final BookingModel booking;

  @override
  Widget build(BuildContext context) {
    final cleanerName = booking.cleanerName.isEmpty
        ? 'Not assigned'
        : booking.cleanerName;
    final canAccept = booking.status == 'Pending';
    final canAssign = booking.status == 'Accepted' && booking.cleanerId == null;
    return InteractiveSurface(
      borderRadius: 12,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFDDE6EE)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    children: [
                      Text(
                        booking.serviceName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '#${booking.id ?? '-'}',
                        style: const TextStyle(
                          color: Color(0xFF47647D),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  _adminMoney(booking.totalPrice),
                  style: const TextStyle(
                    color: Color(0xFF0074D9),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _AdminStatusBadge(status: booking.status),
            const SizedBox(height: 11),
            _AdminBookingInfoRow(
              icon: Icons.person_outline,
              text: booking.customerName,
            ),
            const SizedBox(height: 8),
            _AdminBookingInfoRow(
              icon: Icons.person_search_outlined,
              text: cleanerName,
              emphasized: booking.cleanerName.isNotEmpty,
              italic: booking.cleanerName.isEmpty,
            ),
            const SizedBox(height: 8),
            _AdminBookingInfoRow(
              icon: Icons.calendar_today_outlined,
              text:
                  '${DateFormat('MMM d, yyyy').format(DateTime.parse(booking.bookingDate))} - ${booking.bookingTime}',
            ),
            const SizedBox(height: 8),
            _AdminBookingInfoRow(
              icon: Icons.location_on_outlined,
              text: booking.address,
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFE8EEF4)),
            const SizedBox(height: 10),
            if (canAccept) ...[
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 38,
                      child: ElevatedButton.icon(
                        onPressed: () => _updateAdminBookingStatus(
                          context,
                          booking,
                          'Accepted',
                        ),
                        icon: const Icon(Icons.check_rounded, size: 17),
                        label: const Text('Accept'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 38,
                      child: OutlinedButton.icon(
                        onPressed: () => _updateAdminBookingStatus(
                          context,
                          booking,
                          'Rejected',
                        ),
                        icon: const Icon(Icons.close_rounded, size: 17),
                        label: const Text('Reject'),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                if (canAssign) ...[
                  Expanded(
                    child: SizedBox(
                      height: 38,
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            showCleanerAssignment(context, booking),
                        icon: const Icon(Icons.person_add_alt_1, size: 17),
                        label: const Text('Assign Cleaner'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: SizedBox(
                    height: 38,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        BookingDetailScreen.route,
                        arguments: booking,
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(38),
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('View Details'),
                          SizedBox(width: 4),
                          Icon(Icons.chevron_right, size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _updateAdminBookingStatus(
  BuildContext context,
  BookingModel booking,
  String status,
) async {
  final admin = context.read<AuthProvider>().user;
  if (admin == null) return;
  try {
    await context.read<BookingProvider>().updateStatus(booking, status, admin);
    if (context.mounted) {
      _showAdminToast(context, 'Booking ${status.toLowerCase()}');
    }
  } catch (error) {
    if (context.mounted) _showAdminToast(context, error.toString());
  }
}

class _AdminBookingInfoRow extends StatelessWidget {
  const _AdminBookingInfoRow({
    required this.icon,
    required this.text,
    this.emphasized = false,
    this.italic = false,
  });

  final IconData icon;
  final String text;
  final bool emphasized;
  final bool italic;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 15, color: const Color(0xFF5E7388)),
      const SizedBox(width: 9),
      Expanded(
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: const Color(0xFF42566B),
            fontSize: 12,
            fontWeight: emphasized ? FontWeight.w800 : FontWeight.w500,
            fontStyle: italic ? FontStyle.italic : FontStyle.normal,
          ),
        ),
      ),
    ],
  );
}

class AdminFinanceScreen extends StatelessWidget {
  const AdminFinanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final liveBookings = context.watch<BookingProvider>().bookings;
    final adminData = context.watch<AdminDataProvider>();
    final bookings = liveBookings.isEmpty
        ? _demoAdminManagementBookings
        : liveBookings;
    final completed = bookings.where((item) => item.status == 'Completed');
    final liveRevenue = completed.fold<double>(
      0,
      (sum, item) => sum + item.totalPrice,
    );
    final totalRevenue = liveRevenue == 0 ? 28450.0 : liveRevenue;
    final customers = adminData.users
        .where((item) => item.role == 'customer')
        .length;
    final activeCleaners = adminData.cleaners
        .where((item) => item.isActive)
        .length;
    final performers = _adminPerformers(adminData.cleaners, liveBookings);
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        toolbarHeight: 70,
        titleSpacing: 32,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${AppStrings.appName} Admin',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 2),
            const Text(
              'Management Portal',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: () async {
              final auth = context.read<AuthProvider>();
              final navigator = Navigator.of(context);
              await auth.logout();
              navigator.pushNamedAndRemoveUntil(
                LoginScreen.route,
                (_) => false,
              );
            },
            icon: const Icon(Icons.logout_outlined),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reports & Analytics',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Business insights and statistics',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 38,
                child: ElevatedButton.icon(
                  onPressed: () => showExportSheet(context, bookings),
                  icon: const Icon(Icons.file_download_outlined, size: 16),
                  label: const Text('Export'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(88, 38),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    backgroundColor: const Color(0xFF1087DD),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _ReportMetricCard(
                  icon: Icons.attach_money,
                  iconColor: const Color(0xFF168BDB),
                  label: 'Total Revenue',
                  value: _adminMoney(totalRevenue),
                  trend: '+ 24.8%',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ReportMetricCard(
                  icon: Icons.calendar_today_outlined,
                  iconColor: const Color(0xFF2F80ED),
                  label: 'Total Bookings',
                  value: '${liveBookings.isEmpty ? 248 : bookings.length}',
                  trend: '+ 12.5%',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ReportMetricCard(
                  icon: Icons.groups_2_outlined,
                  iconColor: const Color(0xFFB642F5),
                  label: 'Active Customers',
                  value: NumberFormat.decimalPattern().format(
                    customers == 0 ? 1247 : customers,
                  ),
                  trend: '+ 18.2%',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ReportMetricCard(
                  icon: Icons.person_search_outlined,
                  iconColor: const Color(0xFFFF6A00),
                  label: 'Active Cleaners',
                  value: '${activeCleaners == 0 ? 32 : activeCleaners}',
                  trend: '+ 2',
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _ReportChartCard(
            title: 'Monthly Revenue',
            icon: Icons.bar_chart_outlined,
            child: const _RevenueLineChart(),
          ),
          const SizedBox(height: 16),
          _ReportChartCard(
            title: 'Monthly Bookings',
            icon: Icons.calendar_today_outlined,
            child: const _BookingsBarChart(),
          ),
          const SizedBox(height: 18),
          const _AdminDashboardTitle('Service Popularity'),
          const SizedBox(height: 10),
          for (final service in _reportServices)
            _ServicePopularityCard(service: service),
          const SizedBox(height: 16),
          const _AdminDashboardTitle('Top Performing Cleaners'),
          const SizedBox(height: 10),
          _AdminPerformerList(performers: performers),
          const SizedBox(height: 18),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.7,
            children: const [
              _ReportShortcutCard(label: 'Daily Report'),
              _ReportShortcutCard(label: 'Monthly Report'),
              _ReportShortcutCard(label: 'Income Report'),
              _ReportShortcutCard(label: 'Performance'),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReportService {
  const _ReportService({
    required this.rank,
    required this.name,
    required this.bookings,
    required this.revenue,
    required this.progress,
  });

  final int rank;
  final String name;
  final int bookings;
  final double revenue;
  final double progress;
}

const _reportServices = [
  _ReportService(
    rank: 1,
    name: 'Home Cleaning',
    bookings: 85,
    revenue: 6715,
    progress: 1,
  ),
  _ReportService(
    rank: 2,
    name: 'Deep Cleaning',
    bookings: 62,
    revenue: 7998,
    progress: 0.72,
  ),
  _ReportService(
    rank: 3,
    name: 'Office Cleaning',
    bookings: 45,
    revenue: 4455,
    progress: 0.53,
  ),
  _ReportService(
    rank: 4,
    name: 'Sofa Cleaning',
    bookings: 38,
    revenue: 1482,
    progress: 0.45,
  ),
  _ReportService(
    rank: 5,
    name: 'Carpet Cleaning',
    bookings: 32,
    revenue: 1888,
    progress: 0.38,
  ),
];

class _ReportMetricCard extends StatelessWidget {
  const _ReportMetricCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.trend,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String trend;

  @override
  Widget build(BuildContext context) => InteractiveSurface(
    borderRadius: 12,
    lift: 2,
    child: Container(
      constraints: const BoxConstraints(minHeight: 120),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDE6EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: iconColor,
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.muted, fontSize: 11),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 5),
          Text(
            trend,
            style: const TextStyle(
              color: Color(0xFF0D6FB8),
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    ),
  );
}

class _ReportChartCard extends StatelessWidget {
  const _ReportChartCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) => InteractiveSurface(
    borderRadius: 12,
    lift: 2,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDE6EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Icon(icon, color: const Color(0xFF5E7388), size: 20),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(height: 170, child: child),
        ],
      ),
    ),
  );
}

class _RevenueLineChart extends StatefulWidget {
  const _RevenueLineChart();

  @override
  State<_RevenueLineChart> createState() => _RevenueLineChartState();
}

class _RevenueLineChartState extends State<_RevenueLineChart> {
  static const values = [3800.0, 4300.0, 4000.0, 5200.0, 5000.0, 3600.0];
  int? activeIndex;

  void _updateHover(Offset position, Size size) {
    final index = _chartIndexForPosition(position, size, values.length);
    if (index != activeIndex) setState(() => activeIndex = index);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxHeight);
      return MouseRegion(
        onHover: (event) => _updateHover(event.localPosition, size),
        onExit: (_) => setState(() => activeIndex = null),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) => _updateHover(details.localPosition, size),
          onPanUpdate: (details) => _updateHover(details.localPosition, size),
          child: CustomPaint(
            painter: _LineChartPainter(
              values: values,
              maxValue: 6000,
              activeIndex: activeIndex,
            ),
            child: const SizedBox.expand(),
          ),
        ),
      );
    },
  );
}

class _BookingsBarChart extends StatefulWidget {
  const _BookingsBarChart();

  @override
  State<_BookingsBarChart> createState() => _BookingsBarChartState();
}

class _BookingsBarChartState extends State<_BookingsBarChart> {
  static const values = [45.0, 52.0, 48.0, 61.0, 58.0, 42.0];
  int? activeIndex;

  void _updateHover(Offset position, Size size) {
    final index = _chartIndexForPosition(position, size, values.length);
    if (index != activeIndex) setState(() => activeIndex = index);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxHeight);
      return MouseRegion(
        onHover: (event) => _updateHover(event.localPosition, size),
        onExit: (_) => setState(() => activeIndex = null),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) => _updateHover(details.localPosition, size),
          onPanUpdate: (details) => _updateHover(details.localPosition, size),
          child: CustomPaint(
            painter: _BarChartPainter(values: values, activeIndex: activeIndex),
            child: const SizedBox.expand(),
          ),
        ),
      );
    },
  );
}

const _reportChartLeft = 34.0;
const _reportChartRight = 4.0;
const _reportChartTop = 8.0;
const _reportChartBottomPadding = 22.0;
const _reportChartLabels = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];

int? _chartIndexForPosition(Offset position, Size size, int count) {
  final left = _reportChartLeft;
  final width = size.width - left - _reportChartRight;
  if (width <= 0 || count == 0) return null;
  final relativeX = (position.dx - left).clamp(0.0, width);
  final index = (relativeX / width * (count - 1)).round();
  return index.clamp(0, count - 1);
}

class _LineChartPainter extends CustomPainter {
  const _LineChartPainter({
    required this.values,
    required this.maxValue,
    this.activeIndex,
  });

  final List<double> values;
  final double maxValue;
  final int? activeIndex;

  @override
  void paint(Canvas canvas, Size size) {
    const labels = _reportChartLabels;
    const left = _reportChartLeft;
    final bottom = size.height - _reportChartBottomPadding;
    const top = _reportChartTop;
    final width = size.width - left - _reportChartRight;
    final height = bottom - top;
    final gridPaint = Paint()
      ..color = const Color(0xFFE4ECF3)
      ..strokeWidth = 1;
    final axisPaint = Paint()
      ..color = const Color(0xFF9AACBC)
      ..strokeWidth = 1;
    final textPainter = TextPainter(textDirection: ui.TextDirection.ltr);

    for (var i = 0; i <= 4; i++) {
      final y = top + height * i / 4;
      canvas.drawLine(Offset(left, y), Offset(left + width, y), gridPaint);
      final value = (maxValue - maxValue * i / 4).round().toString();
      textPainter.text = TextSpan(
        text: value,
        style: const TextStyle(color: Color(0xFF5E7388), fontSize: 9),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(0, y - 6));
    }
    canvas.drawLine(Offset(left, top), Offset(left, bottom), axisPaint);
    canvas.drawLine(
      Offset(left, bottom),
      Offset(left + width, bottom),
      axisPaint,
    );

    final points = <Offset>[
      for (var i = 0; i < values.length; i++)
        Offset(
          left + width * i / (values.length - 1),
          bottom - (values[i] / maxValue) * height,
        ),
    ];
    final linePaint = Paint()
      ..color = const Color(0xFF1087DD)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(path, linePaint);
    final dotPaint = Paint()..color = Colors.white;
    final dotBorder = Paint()
      ..color = const Color(0xFF1087DD)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < points.length; i++) {
      canvas.drawCircle(points[i], 3, dotPaint);
      canvas.drawCircle(points[i], 3, dotBorder);
      textPainter.text = TextSpan(
        text: labels[i],
        style: const TextStyle(color: Color(0xFF5E7388), fontSize: 9),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(points[i].dx - textPainter.width / 2, bottom + 7),
      );
    }
    final selected = activeIndex;
    if (selected != null && selected >= 0 && selected < points.length) {
      final point = points[selected];
      final guidePaint = Paint()
        ..color = const Color(0xFFDCE7F0)
        ..strokeWidth = 1;
      canvas.drawLine(
        Offset(point.dx, top),
        Offset(point.dx, bottom),
        guidePaint,
      );
      canvas.drawCircle(point, 4, dotPaint);
      canvas.drawCircle(point, 4, dotBorder);
      _drawReportTooltip(
        canvas,
        size,
        anchor: point,
        title: labels[selected],
        detail: 'revenue : ${values[selected].round()}',
        detailColor: const Color(0xFF1087DD),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) =>
      oldDelegate.activeIndex != activeIndex ||
      oldDelegate.values != values ||
      oldDelegate.maxValue != maxValue;
}

class _BarChartPainter extends CustomPainter {
  const _BarChartPainter({required this.values, this.activeIndex});

  final List<double> values;
  final int? activeIndex;

  @override
  void paint(Canvas canvas, Size size) {
    const labels = _reportChartLabels;
    const left = _reportChartLeft;
    final bottom = size.height - _reportChartBottomPadding;
    const top = _reportChartTop;
    final width = size.width - left - _reportChartRight;
    final height = bottom - top;
    final maxValue = 80.0;
    final gridPaint = Paint()
      ..color = const Color(0xFFE4ECF3)
      ..strokeWidth = 1;
    final axisPaint = Paint()
      ..color = const Color(0xFF9AACBC)
      ..strokeWidth = 1;
    final barPaint = Paint()..color = const Color(0xFF168BDB);
    final activeBarPaint = Paint()..color = const Color(0xFFC9CED3);
    final textPainter = TextPainter(textDirection: ui.TextDirection.ltr);
    for (var i = 0; i <= 4; i++) {
      final y = top + height * i / 4;
      canvas.drawLine(Offset(left, y), Offset(left + width, y), gridPaint);
      final value = (maxValue - maxValue * i / 4).round().toString();
      textPainter.text = TextSpan(
        text: value,
        style: const TextStyle(color: Color(0xFF5E7388), fontSize: 9),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(8, y - 6));
    }
    canvas.drawLine(Offset(left, top), Offset(left, bottom), axisPaint);
    canvas.drawLine(
      Offset(left, bottom),
      Offset(left + width, bottom),
      axisPaint,
    );
    final gap = width / values.length;
    final barWidth = gap * 0.66;
    for (var i = 0; i < values.length; i++) {
      final x = left + gap * i + (gap - barWidth) / 2;
      final barHeight = values[i] / maxValue * height;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, bottom - barHeight, barWidth, barHeight),
        const Radius.circular(6),
      );
      canvas.drawRRect(rect, i == activeIndex ? activeBarPaint : barPaint);
      textPainter.text = TextSpan(
        text: labels[i],
        style: const TextStyle(color: Color(0xFF5E7388), fontSize: 9),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x + barWidth / 2 - textPainter.width / 2, bottom + 7),
      );
    }
    final selected = activeIndex;
    if (selected != null && selected >= 0 && selected < values.length) {
      final gap = width / values.length;
      final barWidth = gap * 0.66;
      final x = left + gap * selected + (gap - barWidth) / 2;
      final barHeight = values[selected] / maxValue * height;
      final anchor = Offset(x + barWidth / 2, bottom - barHeight);
      _drawReportTooltip(
        canvas,
        size,
        anchor: anchor,
        title: labels[selected],
        detail: 'bookings : ${values[selected].round()}',
        detailColor: const Color(0xFF168BDB),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) =>
      oldDelegate.activeIndex != activeIndex || oldDelegate.values != values;
}

void _drawReportTooltip(
  Canvas canvas,
  Size size, {
  required Offset anchor,
  required String title,
  required String detail,
  required Color detailColor,
}) {
  final titlePainter = TextPainter(
    text: TextSpan(
      text: title,
      style: const TextStyle(
        color: Color(0xFF081C33),
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    ),
    textDirection: ui.TextDirection.ltr,
  )..layout();
  final detailPainter = TextPainter(
    text: TextSpan(
      text: detail,
      style: TextStyle(
        color: detailColor,
        fontSize: 12,
        fontWeight: FontWeight.w800,
      ),
    ),
    textDirection: ui.TextDirection.ltr,
  )..layout();
  final tooltipWidth = math.max(titlePainter.width, detailPainter.width) + 22;
  const tooltipHeight = 58.0;
  var left = anchor.dx - tooltipWidth / 2;
  left = left.clamp(2.0, size.width - tooltipWidth - 2);
  var top = anchor.dy - tooltipHeight - 12;
  if (top < 2) top = anchor.dy + 12;
  top = top.clamp(2.0, size.height - tooltipHeight - 2);
  final rect = RRect.fromRectAndRadius(
    Rect.fromLTWH(left, top, tooltipWidth, tooltipHeight),
    const Radius.circular(8),
  );
  canvas.drawRRect(
    rect.shift(const Offset(0, 2)),
    Paint()..color = Colors.black.withValues(alpha: 0.06),
  );
  canvas.drawRRect(rect, Paint()..color = Colors.white);
  canvas.drawRRect(
    rect,
    Paint()
      ..color = const Color(0xFFD7E1EA)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1,
  );
  titlePainter.paint(canvas, Offset(left + 11, top + 9));
  detailPainter.paint(canvas, Offset(left + 11, top + 31));
}

class _ServicePopularityCard extends StatelessWidget {
  const _ServicePopularityCard({required this.service});

  final _ReportService service;

  @override
  Widget build(BuildContext context) => InteractiveSurface(
    borderRadius: 12,
    lift: 2,
    child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDE6EE)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 15,
                backgroundColor: const Color(0xFFE5F4FF),
                child: Text(
                  '#${service.rank}',
                  style: const TextStyle(
                    color: Color(0xFF1087DD),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${service.bookings} bookings',
                      style: const TextStyle(
                        color: Color(0xFF47647D),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _adminMoney(service.revenue),
                    style: const TextStyle(
                      color: Color(0xFF0074D9),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Revenue',
                    style: TextStyle(color: Color(0xFF47647D), fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: service.progress,
              minHeight: 6,
              backgroundColor: const Color(0xFFE4ECF3),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF1087DD)),
            ),
          ),
        ],
      ),
    ),
  );
}

class _ReportShortcutCard extends StatelessWidget {
  const _ReportShortcutCard({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => InteractiveSurface(
    borderRadius: 10,
    lift: 2,
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDDE6EE)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.description_outlined,
            color: Color(0xFF1087DD),
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    ),
  );
}

class CleanerPayScreen extends StatelessWidget {
  const CleanerPayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    final bookings = context.watch<BookingProvider>().bookings;
    final completed = bookings.where((item) => item.status == 'Completed');
    final pending = bookings.where((item) => item.status != 'Completed');
    final earned = completed.fold<double>(
      0,
      (sum, item) => sum + item.cleanerPay,
    );
    final upcoming = pending.fold<double>(
      0,
      (sum, item) => sum + item.cleanerPay,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('My Pay')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: StatCard(label: 'Earned', value: money(earned)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatCard(label: 'Upcoming', value: money(upcoming)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          StatCard(label: 'Hourly Rate', value: money(user.hourlyRate)),
          const SectionHeader(title: 'Salary by Job'),
          for (final booking in bookings)
            ListTile(
              leading: Icon(
                booking.status == 'Completed'
                    ? Icons.paid_outlined
                    : Icons.schedule_outlined,
              ),
              title: Text(booking.serviceName),
              subtitle: Text(
                '${prettyDate(DateTime.parse(booking.bookingDate))} • ${booking.status}',
              ),
              trailing: Text(money(booking.cleanerPay)),
            ),
        ],
      ),
    );
  }
}

class ServiceListScreen extends StatelessWidget {
  const ServiceListScreen({super.key, this.inShell = false});
  static const route = '/services';
  final bool inShell;
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ServiceProvider>();
    final favoriteProvider = context.watch<FavoriteProvider>();
    final userId = context.watch<AuthProvider>().user?.id;
    final list = provider.filtered;
    return Scaffold(
      appBar: inShell
          ? null
          : AppBar(
              leading: BackButton(
                style: IconButton.styleFrom(foregroundColor: AppColors.text),
              ),
              title: const Text('Services'),
            ),
      body: RefreshIndicator(
        onRefresh: provider.loadServices,
        child: Column(
          children: [
            if (inShell)
              const SafeArea(child: SectionHeader(title: 'Services')),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Search for Service',
                      ),
                      onChanged: provider.updateSearch,
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.text,
                      side: const BorderSide(color: AppColors.border),
                    ),
                    onPressed: () {},
                    icon: const Icon(Icons.tune_outlined),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: provider.categories.map((category) {
                  final selected = provider.category == category;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      avatar: Icon(
                        serviceCategoryIcon(category),
                        size: 16,
                        color: selected ? Colors.white : AppColors.primaryDark,
                      ),
                      label: Text(category),
                      selected: selected,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : AppColors.text,
                        fontWeight: FontWeight.w800,
                      ),
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: AppColors.border),
                      onSelected: (_) => provider.updateCategory(category),
                    ),
                  );
                }).toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: DropdownButtonFormField(
                initialValue: provider.sort,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.sort_outlined),
                  labelText: 'Sort services',
                ),
                items: const ['Popular', 'Price', 'Rating']
                    .map(
                      (e) =>
                          DropdownMenuItem(value: e, child: Text('Sort by $e')),
                    )
                    .toList(),
                onChanged: (v) => provider.updateSort(v!),
              ),
            ),
            Expanded(
              child: provider.loading
                  ? const LoadingWidget()
                  : provider.error != null
                  ? ErrorView(
                      message: provider.error!,
                      onRetry: provider.loadServices,
                    )
                  : list.isEmpty
                  ? const EmptyStateWidget(
                      title: 'No services found',
                      message: 'Try another search or category.',
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: .78,
                          ),
                      itemCount: list.length,
                      itemBuilder: (_, index) {
                        final service = list[index];
                        return ServiceGridCard(
                          service: service,
                          favorite: favoriteProvider.isFavorite(service.id),
                          onFavorite: () => requireLogin(
                            context,
                            () => favoriteProvider.toggle(userId!, service),
                          ),
                          onTap: () => Navigator.pushNamed(
                            context,
                            ServiceDetailScreen.route,
                            arguments: service,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class ServiceDetailScreen extends StatefulWidget {
  const ServiceDetailScreen({super.key});
  static const route = '/service-detail';

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  int selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final service = ModalRoute.of(context)!.settings.arguments as ServiceModel;
    final favoriteProvider = context.watch<FavoriteProvider>();
    final userId = context.watch<AuthProvider>().user?.id;
    final galleryImages = _serviceGalleryImages(service);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(service.name),
        actions: [
          IconButton(
            tooltip: 'Save service',
            onPressed: () => requireLogin(
              context,
              () => favoriteProvider.toggle(userId!, service),
            ),
            icon: Icon(
              favoriteProvider.isFavorite(service.id)
                  ? Icons.favorite
                  : Icons.favorite_border,
              color: favoriteProvider.isFavorite(service.id)
                  ? AppColors.danger
                  : AppColors.text,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 104),
        children: [
          _ServiceDetailHero(service: service),
          const SizedBox(height: 16),
          Row(
            children: [
              _ServiceMetricPill(
                icon: Icons.schedule_outlined,
                label: '${service.durationMinutes} min',
              ),
              const SizedBox(width: 8),
              _ServiceMetricPill(
                icon: Icons.star_rounded,
                iconColor: AppColors.accent,
                label: '${service.rating} rating',
              ),
              const SizedBox(width: 8),
              const _ServiceMetricPill(
                icon: Icons.verified_outlined,
                label: 'Verified',
              ),
            ],
          ),
          const SizedBox(height: 18),
          _ServiceDetailTabs(
            selectedIndex: selectedTab,
            onSelected: (index) => setState(() => selectedTab = index),
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeOut,
            child: switch (selectedTab) {
              0 => _ServiceAboutView(service: service),
              1 => _ServiceGalleryView(images: galleryImages),
              _ => _ServiceReviewView(rating: service.rating),
            },
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Price',
                      style: TextStyle(color: AppColors.muted),
                    ),
                    Text(
                      money(service.basePrice),
                      style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 150,
                child: CustomButton(
                  label: 'Book Now',
                  icon: Icons.event_available,
                  onPressed: () => requireLogin(
                    context,
                    () => Navigator.pushNamed(
                      context,
                      BookingFormScreen.route,
                      arguments: service,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceDetailHero extends StatelessWidget {
  const _ServiceDetailHero({required this.service});

  final ServiceModel service;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(14),
    child: Stack(
      children: [
        Image.network(
          service.imageUrl,
          height: 250,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            height: 250,
            color: const Color(0xFFEAF6FF),
            child: const Center(
              child: Icon(
                Icons.cleaning_services_outlined,
                color: AppColors.primary,
                size: 54,
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.56),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: const Text(
                  'Professional Cleaning',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                service.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 8),
              const Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    color: Colors.white,
                    size: 16,
                  ),
                  SizedBox(width: 5),
                  Text(
                    'Phnom Penh',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ServiceMetricPill extends StatelessWidget {
  const _ServiceMetricPill({
    required this.icon,
    required this.label,
    this.iconColor = AppColors.primary,
  });

  final IconData icon;
  final String label;
  final Color iconColor;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 17),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    ),
  );
}

class _ServiceDetailTabs extends StatelessWidget {
  const _ServiceDetailTabs({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    const tabs = [
      (Icons.info_outline, 'About'),
      (Icons.photo_library_outlined, 'Gallery'),
      (Icons.reviews_outlined, 'Review'),
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF6FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          for (var index = 0; index < tabs.length; index++)
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(9),
                onTap: () => onSelected(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 40,
                  decoration: BoxDecoration(
                    color: selectedIndex == index
                        ? Colors.white
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: selectedIndex == index
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              blurRadius: 12,
                              offset: const Offset(0, 5),
                            ),
                          ]
                        : const [],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        tabs[index].$1,
                        color: selectedIndex == index
                            ? AppColors.primary
                            : AppColors.muted,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        tabs[index].$2,
                        style: TextStyle(
                          color: selectedIndex == index
                              ? AppColors.primaryDark
                              : AppColors.muted,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ServiceAboutView extends StatelessWidget {
  const _ServiceAboutView({required this.service});

  final ServiceModel service;

  @override
  Widget build(BuildContext context) => Column(
    key: const ValueKey('about'),
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _ServiceSectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'About Service',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              service.description,
              style: const TextStyle(color: AppColors.muted, height: 1.5),
            ),
            const SizedBox(height: 16),
            const _ServiceProviderTile(),
          ],
        ),
      ),
      const SizedBox(height: 14),
      _ServiceSectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Included Tasks',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  [
                        'Dusting',
                        'Floor cleaning',
                        'Bathroom cleaning',
                        'Kitchen cleaning',
                        'Window wiping',
                        'Trash removal',
                      ]
                      .map(
                        (task) => Chip(
                          avatar: const Icon(Icons.check_circle, size: 16),
                          label: Text(task),
                          backgroundColor: const Color(0xFFEAF6FF),
                          side: BorderSide.none,
                        ),
                      )
                      .toList(),
            ),
            const SizedBox(height: 18),
            const Text(
              'Excluded Tasks',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              'Pest control, heavy furniture moving, and outdoor garden cleaning are not included.',
              style: TextStyle(color: AppColors.muted, height: 1.45),
            ),
          ],
        ),
      ),
    ],
  );
}

class _ServiceProviderTile extends StatelessWidget {
  const _ServiceProviderTile();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      children: [
        const CircleAvatar(
          radius: 23,
          backgroundImage: NetworkImage(DemoImages.cleaner),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Jenny Wilson',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
              ),
              SizedBox(height: 3),
              Text(
                'Certified service provider',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          tooltip: 'Message provider',
          onPressed: () {},
          icon: const Icon(Icons.chat_bubble_outline),
        ),
        const SizedBox(width: 6),
        IconButton.filledTonal(
          tooltip: 'Call provider',
          onPressed: () {},
          icon: const Icon(Icons.call_outlined),
        ),
      ],
    ),
  );
}

class _ServiceGalleryView extends StatelessWidget {
  const _ServiceGalleryView({required this.images});

  final List<String> images;

  @override
  Widget build(BuildContext context) => Column(
    key: const ValueKey('gallery'),
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Service Gallery',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
      ),
      const SizedBox(height: 8),
      const Text(
        'Preview rooms, surfaces, and finishing details from CleanPro service sessions.',
        style: TextStyle(color: AppColors.muted, height: 1.45),
      ),
      const SizedBox(height: 14),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: images.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: .9,
        ),
        itemBuilder: (context, index) => ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                images[index],
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFFEAF6FF),
                  child: const Icon(
                    Icons.image_outlined,
                    color: AppColors.primary,
                  ),
                ),
              ),
              Positioned(
                left: 10,
                bottom: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.44),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    'View ${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

class _ServiceReviewView extends StatelessWidget {
  const _ServiceReviewView({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) => Column(
    key: const ValueKey('review'),
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _ServiceSectionCard(
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF6FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  rating.toStringAsFixed(1),
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Text(
                'Customers love the punctual cleaners, clear pricing, and careful finishing touches.',
                style: TextStyle(color: AppColors.muted, height: 1.4),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      const _ServiceReviewCard(
        name: 'Sokha Lim',
        date: '2 days ago',
        text:
            'The cleaner arrived on time, handled the kitchen carefully, and left the floors spotless.',
      ),
      const SizedBox(height: 10),
      const _ServiceReviewCard(
        name: 'Maya Chen',
        date: 'Last week',
        text:
            'Easy booking and very tidy work. I liked that the price was clear before confirming.',
      ),
      const SizedBox(height: 10),
      const _ServiceReviewCard(
        name: 'Dara Kim',
        date: 'May 2026',
        text:
            'Good attention to corners and windows. I would book the same service again.',
      ),
    ],
  );
}

class _ServiceReviewCard extends StatelessWidget {
  const _ServiceReviewCard({
    required this.name,
    required this.date,
    required this.text,
  });

  final String name;
  final String date;
  final String text;

  @override
  Widget build(BuildContext context) => _ServiceSectionCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFFEAF6FF),
              child: Text(
                name.characters.first,
                style: const TextStyle(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  Text(
                    date,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: List.generate(
                5,
                (_) => const Icon(
                  Icons.star_rounded,
                  color: AppColors.accent,
                  size: 15,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          text,
          style: const TextStyle(color: AppColors.muted, height: 1.45),
        ),
      ],
    ),
  );
}

class _ServiceSectionCard extends StatelessWidget {
  const _ServiceSectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border),
    ),
    child: child,
  );
}

List<String> _serviceGalleryImages(ServiceModel service) => [
  service.imageUrl,
  DemoImages.home,
  DemoImages.deep,
  DemoImages.office,
  DemoImages.sofa,
  DemoImages.carpet,
];

class BookingFormScreen extends StatefulWidget {
  const BookingFormScreen({super.key, this.inShell = false});
  static const route = '/booking-form';
  final bool inShell;
  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  final address = TextEditingController();
  final note = TextEditingController();
  int step = 0;
  ServiceModel? selectedService;
  String propertyType = 'House';
  int bedrooms = 2;
  int bathrooms = 1;
  DateTime? date;
  TimeOfDay? time;
  bool initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (initialized) return;
    initialized = true;
    final route = ModalRoute.of(context);
    final arg = route?.settings.arguments;
    if (arg is ServiceModel) selectedService = arg;
    address.text = context.read<AuthProvider>().user?.address ?? '';
    final services = context.read<ServiceProvider>();
    if (services.services.isEmpty) Future.microtask(services.loadServices);
  }

  @override
  void dispose() {
    address.dispose();
    note.dispose();
    super.dispose();
  }

  bool get canContinue {
    if (step == 0) return selectedService != null;
    if (step == 1) {
      return date != null && time != null && address.text.trim().isNotEmpty;
    }
    return true;
  }

  double get totalPrice {
    final service = selectedService;
    if (service == null) return 0;
    return PriceCalculator.total(
      service.basePrice,
      bedrooms,
      bathrooms,
      const [],
    );
  }

  int get estimatedDuration {
    final service = selectedService;
    if (service == null) return 0;
    return PriceCalculator.duration(
      service.durationMinutes,
      bedrooms,
      bathrooms,
      const [],
    );
  }

  void nextStep() {
    if (!canContinue) return;
    setState(() => step = (step + 1).clamp(0, 2));
  }

  void previousStep() => setState(() => step = (step - 1).clamp(0, 2));

  Future<void> confirmBooking() async {
    final service = selectedService;
    final user = context.read<AuthProvider>().user;
    if (service == null || user?.id == null || date == null || time == null) {
      return;
    }
    final booking = BookingModel(
      userId: user!.id!,
      serviceId: service.id,
      serviceName: service.name,
      customerName: user.fullName,
      phone: user.phone,
      address: address.text.trim(),
      propertyType: propertyType,
      rooms: bedrooms,
      bathrooms: bathrooms,
      bookingDate: DateFormat('yyyy-MM-dd').format(date!),
      bookingTime: time!.format(context),
      extraServices: const [],
      specialInstruction: note.text.trim(),
      paymentMethod: 'Cash',
      basePrice: service.basePrice,
      extraPrice: totalPrice - service.basePrice,
      totalPrice: totalPrice,
      estimatedDuration: estimatedDuration,
      serviceImage: service.imageUrl,
    );
    final bookingProvider = context.read<BookingProvider>();
    final ok = await bookingProvider.create(booking);
    if (!mounted) return;
    if (ok) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        BookingSuccessScreen.route,
        ModalRoute.withName(ShellScreen.route),
        arguments: bookingProvider.lastCreatedBooking,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not create booking. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ServiceProvider>();
    final services = provider.services
        .where((service) => service.isActive)
        .toList(growable: false);
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const _CustomerBookingHeader(),
            _BookingStepHeader(step: step),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: switch (step) {
                  0 => _BookingServiceStep(
                    key: const ValueKey('service-step'),
                    services: services,
                    loading: provider.loading,
                    selected: selectedService,
                    onSelected: (service) =>
                        setState(() => selectedService = service),
                    onContinue: canContinue ? nextStep : null,
                  ),
                  1 => _BookingDetailsStep(
                    key: const ValueKey('details-step'),
                    propertyType: propertyType,
                    bedrooms: bedrooms,
                    bathrooms: bathrooms,
                    date: date,
                    time: time,
                    address: address,
                    note: note,
                    canContinue: canContinue,
                    onPropertyChanged: (value) =>
                        setState(() => propertyType = value),
                    onBedroomsChanged: (value) =>
                        setState(() => bedrooms = value),
                    onBathroomsChanged: (value) =>
                        setState(() => bathrooms = value),
                    onDateChanged: (value) => setState(() => date = value),
                    onTimeChanged: (value) => setState(() => time = value),
                    onBack: previousStep,
                    onContinue: nextStep,
                    onTextChanged: () => setState(() {}),
                  ),
                  _ => _BookingConfirmStep(
                    key: const ValueKey('confirm-step'),
                    service: selectedService!,
                    propertyType: propertyType,
                    bedrooms: bedrooms,
                    bathrooms: bathrooms,
                    date: date!,
                    time: time!,
                    address: address.text.trim(),
                    totalPrice: totalPrice,
                    loading: context.watch<BookingProvider>().loading,
                    onBack: previousStep,
                    onConfirm: confirmBooking,
                  ),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerBookingHeader extends StatelessWidget {
  const _CustomerBookingHeader();

  @override
  Widget build(BuildContext context) => Container(
    color: Colors.white,
    padding: const EdgeInsets.fromLTRB(24, 18, 24, 14),
    child: Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFF1488DD),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CleanPro',
                style: TextStyle(
                  color: Color(0xFF081C33),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Customer Portal',
                style: TextStyle(color: Color(0xFF42566B), fontSize: 11),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Logout',
          onPressed: () => context.read<AuthProvider>().logout(),
          icon: const Icon(Icons.logout, color: Color(0xFF5A6F84)),
        ),
      ],
    ),
  );
}

class _BookingStepHeader extends StatelessWidget {
  const _BookingStepHeader({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(
        top: BorderSide(color: Color(0xFFDDE6EE)),
        bottom: BorderSide(color: Color(0xFFDDE6EE)),
      ),
    ),
    padding: const EdgeInsets.fromLTRB(24, 16, 24, 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'New Booking',
          style: TextStyle(
            color: Color(0xFF081C33),
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (var i = 0; i < 3; i++) ...[
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 4,
                  decoration: BoxDecoration(
                    color: i <= step
                        ? const Color(0xFF1488DD)
                        : const Color(0xFFE1EBF3),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              if (i < 2)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 9),
                  child: Icon(
                    Icons.chevron_right,
                    size: 15,
                    color: Color(0xFF5A6F84),
                  ),
                ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Step ${step + 1} of 3: ${switch (step) {
            0 => 'Service',
            1 => 'Details',
            _ => 'Confirm',
          }}',
          style: const TextStyle(color: Color(0xFF42566B), fontSize: 12),
        ),
      ],
    ),
  );
}

class _BookingServiceStep extends StatelessWidget {
  const _BookingServiceStep({
    super.key,
    required this.services,
    required this.loading,
    required this.selected,
    required this.onSelected,
    required this.onContinue,
  });

  final List<ServiceModel> services;
  final bool loading;
  final ServiceModel? selected;
  final ValueChanged<ServiceModel> onSelected;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    if (loading && services.isEmpty) return const LoadingWidget();
    if (services.isEmpty) {
      return const EmptyStateWidget(
        title: 'No services available',
        message: 'Services will appear here once they are active.',
        icon: Icons.cleaning_services_outlined,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Service',
          style: TextStyle(
            color: Color(0xFF081C33),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        for (final service in services.take(6))
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _BookingServiceRow(
              service: service,
              selected: selected?.id == service.id,
              onTap: () => onSelected(service),
            ),
          ),
        const SizedBox(height: 4),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: FilledButton(
            onPressed: onContinue,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1488DD),
              disabledBackgroundColor: const Color(0xFFE1EBF3),
              foregroundColor: Colors.white,
              disabledForegroundColor: const Color(0xFF42566B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Continue',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ],
    );
  }
}

class _BookingServiceRow extends StatelessWidget {
  const _BookingServiceRow({
    required this.service,
    required this.selected,
    required this.onTap,
  });

  final ServiceModel service;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InteractiveSurface(
    borderRadius: 12,
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFEAF6FF) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? const Color(0xFF1488DD) : const Color(0xFFDDE6EE),
          width: selected ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              service.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF081C33),
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            _adminMoney(service.basePrice),
            style: const TextStyle(
              color: Color(0xFF0783D5),
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 160),
            child: selected
                ? const Icon(
                    Icons.check_circle,
                    key: ValueKey('selected'),
                    color: Color(0xFF1488DD),
                    size: 22,
                  )
                : const SizedBox(key: ValueKey('empty'), width: 22),
          ),
        ],
      ),
    ),
  );
}

class _BookingDetailsStep extends StatelessWidget {
  const _BookingDetailsStep({
    super.key,
    required this.propertyType,
    required this.bedrooms,
    required this.bathrooms,
    required this.date,
    required this.time,
    required this.address,
    required this.note,
    required this.canContinue,
    required this.onPropertyChanged,
    required this.onBedroomsChanged,
    required this.onBathroomsChanged,
    required this.onDateChanged,
    required this.onTimeChanged,
    required this.onBack,
    required this.onContinue,
    required this.onTextChanged,
  });

  final String propertyType;
  final int bedrooms;
  final int bathrooms;
  final DateTime? date;
  final TimeOfDay? time;
  final TextEditingController address;
  final TextEditingController note;
  final bool canContinue;
  final ValueChanged<String> onPropertyChanged;
  final ValueChanged<int> onBedroomsChanged;
  final ValueChanged<int> onBathroomsChanged;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<TimeOfDay> onTimeChanged;
  final VoidCallback onBack;
  final VoidCallback onContinue;
  final VoidCallback onTextChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Property Type',
        style: TextStyle(
          color: Color(0xFF081C33),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 10),
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.78,
        children: [
          for (final item in const [
            ('House', Icons.home_outlined),
            ('Condo', Icons.apartment_outlined),
            ('Apartment', Icons.business_outlined),
            ('Office', Icons.business_center_outlined),
          ])
            _PropertyTypeTile(
              label: item.$1,
              icon: item.$2,
              selected: propertyType == item.$1,
              onTap: () => onPropertyChanged(item.$1),
            ),
        ],
      ),
      const SizedBox(height: 18),
      Row(
        children: [
          Expanded(
            child: _LabeledDropdown<int>(
              label: 'Bedrooms',
              value: bedrooms,
              items: const [1, 2, 3, 4, 5],
              itemLabel: (value) => '$value',
              onChanged: onBedroomsChanged,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _LabeledDropdown<int>(
              label: 'Bathrooms',
              value: bathrooms,
              items: const [1, 2, 3, 4, 5],
              itemLabel: (value) => '$value',
              onChanged: onBathroomsChanged,
            ),
          ),
        ],
      ),
      const SizedBox(height: 18),
      _BookingDateField(date: date, onChanged: onDateChanged),
      const SizedBox(height: 18),
      _BookingTimeField(time: time, onChanged: onTimeChanged),
      const SizedBox(height: 18),
      _BookingTextArea(
        controller: address,
        icon: Icons.location_on_outlined,
        label: 'Address',
        hint: 'Enter your full address',
        onChanged: onTextChanged,
      ),
      const SizedBox(height: 18),
      _BookingTextArea(
        controller: note,
        icon: Icons.chat_bubble_outline,
        label: 'Special Instructions (Optional)',
        hint: 'Any special requirements or instructions',
        onChanged: onTextChanged,
      ),
      const SizedBox(height: 22),
      _BookingStepActions(
        backLabel: 'Back',
        nextLabel: 'Continue',
        nextEnabled: canContinue,
        onBack: onBack,
        onNext: onContinue,
      ),
    ],
  );
}

class _PropertyTypeTile extends StatelessWidget {
  const _PropertyTypeTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InteractiveSurface(
    borderRadius: 12,
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFEAF6FF) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? const Color(0xFF1488DD) : const Color(0xFFDDE6EE),
          width: selected ? 1.5 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: selected ? const Color(0xFF1488DD) : const Color(0xFF5A6F84),
            size: 22,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF081C33),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    ),
  );
}

class _LabeledDropdown<T> extends StatelessWidget {
  const _LabeledDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          color: Color(0xFF081C33),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 8),
      DropdownButtonFormField<T>(
        initialValue: value,
        decoration: const InputDecoration(contentPadding: EdgeInsets.all(14)),
        items: [
          for (final item in items)
            DropdownMenuItem(value: item, child: Text(itemLabel(item))),
        ],
        onChanged: (value) {
          if (value != null) onChanged(value);
        },
      ),
    ],
  );
}

class _BookingDateField extends StatelessWidget {
  const _BookingDateField({required this.date, required this.onChanged});

  final DateTime? date;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) => _BookingPickerField(
    icon: Icons.calendar_month_outlined,
    label: 'Date',
    value: date == null ? 'mm/dd/yyyy' : DateFormat('MM/dd/yyyy').format(date!),
    onTap: () async {
      final now = DateTime.now();
      final value = await showDatePicker(
        context: context,
        firstDate: DateTime(now.year, now.month, now.day),
        lastDate: now.add(const Duration(days: 365)),
        initialDate: date ?? now.add(const Duration(days: 1)),
      );
      if (value != null) onChanged(value);
    },
  );
}

class _BookingTimeField extends StatelessWidget {
  const _BookingTimeField({required this.time, required this.onChanged});

  final TimeOfDay? time;
  final ValueChanged<TimeOfDay> onChanged;

  @override
  Widget build(BuildContext context) => _BookingPickerField(
    icon: Icons.access_time,
    label: 'Time',
    value: time?.format(context) ?? 'Select time',
    trailing: Icons.expand_more,
    onTap: () async {
      final value = await showTimePicker(
        context: context,
        initialTime: time ?? const TimeOfDay(hour: 8, minute: 0),
      );
      if (value != null) onChanged(value);
    },
  );
}

class _BookingPickerField extends StatelessWidget {
  const _BookingPickerField({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.trailing = Icons.calendar_today,
  });

  final IconData icon;
  final String label;
  final String value;
  final IconData trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(icon, size: 14, color: const Color(0xFF081C33)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF081C33),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      InteractiveSurface(
        borderRadius: 12,
        onTap: onTap,
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFDDE6EE)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    color: value == 'mm/dd/yyyy' || value == 'Select time'
                        ? const Color(0xFF8A9AAD)
                        : const Color(0xFF081C33),
                    fontSize: 13,
                  ),
                ),
              ),
              Icon(trailing, size: 18, color: const Color(0xFF081C33)),
            ],
          ),
        ),
      ),
    ],
  );
}

class _BookingTextArea extends StatelessWidget {
  const _BookingTextArea({
    required this.controller,
    required this.icon,
    required this.label,
    required this.hint,
    required this.onChanged,
  });

  final TextEditingController controller;
  final IconData icon;
  final String label;
  final String hint;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(icon, size: 14, color: const Color(0xFF081C33)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF081C33),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      TextField(
        controller: controller,
        minLines: 2,
        maxLines: 3,
        onChanged: (_) => onChanged(),
        decoration: InputDecoration(
          hintText: hint,
          contentPadding: const EdgeInsets.all(14),
        ),
      ),
    ],
  );
}

class _BookingConfirmStep extends StatelessWidget {
  const _BookingConfirmStep({
    super.key,
    required this.service,
    required this.propertyType,
    required this.bedrooms,
    required this.bathrooms,
    required this.date,
    required this.time,
    required this.address,
    required this.totalPrice,
    required this.loading,
    required this.onBack,
    required this.onConfirm,
  });

  final ServiceModel service;
  final String propertyType;
  final int bedrooms;
  final int bathrooms;
  final DateTime date;
  final TimeOfDay time;
  final String address;
  final double totalPrice;
  final bool loading;
  final VoidCallback onBack;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFDDE6EE)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Booking Summary',
              style: TextStyle(
                color: Color(0xFF081C33),
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 16),
            _SummaryRow(label: 'Service', value: service.name),
            _SummaryRow(label: 'Property', value: propertyType),
            _SummaryRow(
              label: 'Rooms',
              value: '$bedrooms bed, $bathrooms bath',
            ),
            _SummaryRow(
              label: 'Date & Time',
              value:
                  '${DateFormat('yyyy-MM-dd').format(date)} at ${time.format(context)}',
            ),
            _SummaryRow(label: 'Address', value: address),
            const Divider(height: 26, color: Color(0xFFDDE6EE)),
            Row(
              children: [
                const Icon(
                  Icons.attach_money,
                  color: Color(0xFF0783D5),
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Total Price',
                    style: TextStyle(
                      color: Color(0xFF081C33),
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  _adminMoney(totalPrice),
                  style: const TextStyle(
                    color: Color(0xFF0783D5),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Estimated price. Final price may vary based on actual work.',
              style: TextStyle(color: Color(0xFF42566B), fontSize: 10),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      _BookingStepActions(
        backLabel: 'Back',
        nextLabel: 'Confirm Booking',
        nextEnabled: !loading,
        nextLoading: loading,
        onBack: onBack,
        onNext: onConfirm,
      ),
    ],
  );
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 11),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Color(0xFF42566B), fontSize: 12),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: Color(0xFF081C33),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
}

class _BookingStepActions extends StatelessWidget {
  const _BookingStepActions({
    required this.backLabel,
    required this.nextLabel,
    required this.nextEnabled,
    required this.onBack,
    required this.onNext,
    this.nextLoading = false,
  });

  final String backLabel;
  final String nextLabel;
  final bool nextEnabled;
  final bool nextLoading;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: SizedBox(
          height: 48,
          child: OutlinedButton(
            onPressed: onBack,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF081C33),
              side: const BorderSide(color: Color(0xFFDDE6EE)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              backLabel,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: SizedBox(
          height: 48,
          child: FilledButton(
            onPressed: nextEnabled ? onNext : null,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1488DD),
              disabledBackgroundColor: const Color(0xFFE1EBF3),
              foregroundColor: Colors.white,
              disabledForegroundColor: const Color(0xFF42566B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: nextLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    nextLabel,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
          ),
        ),
      ),
    ],
  );
}

class BookingSuccessScreen extends StatelessWidget {
  const BookingSuccessScreen({super.key});
  static const route = '/booking-success';
  @override
  Widget build(BuildContext context) {
    final argument = ModalRoute.of(context)?.settings.arguments;
    final booking = argument is BookingModel ? argument : null;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 146,
                  height: 146,
                  decoration: const BoxDecoration(
                    color: AppColors.secondary,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.celebration_rounded,
                      size: 82,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Booking Completed',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your booking for service has been successfully booked.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 80),
                CustomButton(
                  label: 'View Booking Detail',
                  icon: Icons.receipt_long,
                  onPressed: () {
                    final currentUser = context.read<AuthProvider>().user;
                    if (booking?.id == null ||
                        currentUser?.id == null ||
                        booking!.userId != currentUser!.id) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Booking detail is unavailable.'),
                        ),
                      );
                      return;
                    }
                    Navigator.pushNamed(
                      context,
                      BookingDetailScreen.route,
                      arguments: booking,
                    );
                  },
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context,
                    ShellScreen.route,
                    (_) => false,
                  ),
                  icon: const Icon(Icons.search_outlined),
                  label: const Text('Discover More Service'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<BookingProvider>();
    final bookings = provider.bookings
        .where((booking) => booking.userId == auth.user?.id)
        .toList();
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _customerPortalAppBar(context),
      body: !auth.loggedIn
          ? const EmptyStateWidget(
              title: 'Login required',
              message: 'Please log in to see your bookings.',
            )
          : provider.loading
          ? const LoadingWidget()
          : RefreshIndicator(
              onRefresh: () => context.read<BookingProvider>().loadForRole(
                context.read<AuthProvider>().user,
              ),
              child: bookings.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
                      children: const [
                        _CustomerHistoryTitle(),
                        SizedBox(height: 16),
                        EmptyStateWidget(
                          title: 'No booking history yet.',
                          message: 'You have not made any bookings yet.',
                          icon: Icons.receipt_long_outlined,
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
                      itemCount: bookings.length + 1,
                      separatorBuilder: (_, index) =>
                          SizedBox(height: index == 0 ? 16 : 14),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return const _CustomerHistoryTitle();
                        }
                        return _CustomerBookingHistoryCard(
                          booking: bookings[index - 1],
                        );
                      },
                    ),
            ),
    );
  }
}

PreferredSizeWidget _customerPortalAppBar(BuildContext context) => AppBar(
  centerTitle: false,
  toolbarHeight: 68,
  titleSpacing: 24,
  title: Row(
    children: [
      Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: const Color(0xFF0D83D8),
          borderRadius: BorderRadius.circular(99),
        ),
        child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
      ),
      const SizedBox(width: 10),
      const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'CleanPro',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 2),
          Text(
            'Customer Portal',
            style: TextStyle(
              color: Color(0xFF42566B),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ],
  ),
  actions: [
    const _NotificationAction(),
    IconButton(
      tooltip: 'Logout',
      onPressed: () async {
        final navigator = Navigator.of(context);
        await context.read<AuthProvider>().logout();
        navigator.pushNamedAndRemoveUntil(LoginScreen.route, (_) => false);
      },
      icon: const Icon(Icons.logout_outlined, color: Color(0xFF4A5C70)),
    ),
    const SizedBox(width: 14),
  ],
);

class _NotificationAction extends StatelessWidget {
  const _NotificationAction({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider?>();
    final unread = provider?.unreadCount ?? 0;
    return IconButton(
      tooltip: unread == 0 ? 'Notifications' : '$unread unread notifications',
      constraints: compact
          ? const BoxConstraints.tightFor(width: 32, height: 48)
          : null,
      padding: compact ? const EdgeInsets.all(4) : null,
      onPressed: () => Navigator.pushNamed(context, NotificationScreen.route),
      icon: Badge(
        isLabelVisible: unread > 0,
        label: Text(unread > 99 ? '99+' : '$unread'),
        child: const Icon(Icons.notifications_outlined),
      ),
    );
  }
}

class _CustomerHistoryTitle extends StatelessWidget {
  const _CustomerHistoryTitle();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Booking History',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
      ),
      SizedBox(height: 6),
      Text(
        'View all your bookings',
        style: TextStyle(color: Color(0xFF42566B), fontSize: 11),
      ),
    ],
  );
}

class _CustomerBookingHistoryCard extends StatelessWidget {
  const _CustomerBookingHistoryCard({required this.booking});

  final BookingModel booking;

  @override
  Widget build(BuildContext context) {
    final completed = booking.status == 'Completed';
    final canCancel = ['Pending', 'Accepted'].contains(booking.status);
    return InkWell(
      onTap: () => Navigator.pushNamed(
        context,
        BookingDetailScreen.route,
        arguments: booking,
      ),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFDDE6EE)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    booking.serviceName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  money(booking.totalPrice),
                  style: const TextStyle(
                    color: Color(0xFF0077D9),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            _CustomerHistoryStatusPill(booking.status),
            const SizedBox(height: 12),
            _CustomerHistoryInfoRow(
              icon: Icons.calendar_today_outlined,
              title: _customerHistoryDate(booking),
              subtitle: booking.bookingTime,
            ),
            const SizedBox(height: 9),
            _CustomerHistorySingleInfo(
              icon: Icons.location_on_outlined,
              text: booking.address,
            ),
            if (booking.cleanerName.isNotEmpty) ...[
              const SizedBox(height: 9),
              _CustomerHistoryCleanerRow(booking: booking),
            ],
            if (canCancel || completed) ...[
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFDDE6EE)),
              const SizedBox(height: 9),
              if (canCancel)
                SizedBox(
                  height: 29,
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _confirmCustomerBookingCancel(
                      context,
                      booking,
                      persist: true,
                    ),
                    icon: const Icon(Icons.close, size: 15),
                    label: const Text('Cancel Booking'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF3045),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(29),
                      textStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 31,
                        child: ElevatedButton.icon(
                          onPressed: () => _showCustomerRatingSheet(
                            context,
                            booking,
                            persist: true,
                          ),
                          icon: const Icon(Icons.star_border_rounded, size: 15),
                          label: const Text('Rate Service'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D83D8),
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(31),
                            textStyle: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 31,
                        child: OutlinedButton.icon(
                          onPressed: () => _showCustomerReviewSheet(
                            context,
                            booking,
                            persist: true,
                          ),
                          icon: const Icon(Icons.chat_bubble_outline, size: 15),
                          label: const Text('Review'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0F172A),
                            side: const BorderSide(color: Color(0xFFDDE6EE)),
                            minimumSize: const Size.fromHeight(31),
                            textStyle: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CustomerHistoryStatusPill extends StatelessWidget {
  const _CustomerHistoryStatusPill(this.status);

  final String status;

  @override
  Widget build(BuildContext context) {
    final background = switch (status) {
      'Completed' => const Color(0xFFD6F8E2),
      'Cancelled' || 'Rejected' => const Color(0xFFFFDADD),
      'Accepted' => const Color(0xFFDCE8FF),
      _ => const Color(0xFFFFF0C2),
    };
    final foreground = switch (status) {
      'Completed' => const Color(0xFF00984A),
      'Cancelled' || 'Rejected' => const Color(0xFFE02D3C),
      'Accepted' => const Color(0xFF2369D8),
      _ => const Color(0xFF9A6400),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: foreground,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _CustomerHistoryInfoRow extends StatelessWidget {
  const _CustomerHistoryInfoRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: const Color(0xFF64748B), size: 14),
      const SizedBox(width: 8),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(color: Color(0xFF42566B), fontSize: 10),
            ),
          ],
        ),
      ),
    ],
  );
}

class _CustomerHistorySingleInfo extends StatelessWidget {
  const _CustomerHistorySingleInfo({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: const Color(0xFF64748B), size: 14),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Color(0xFF42566B), fontSize: 10),
        ),
      ),
    ],
  );
}

class _CustomerHistoryCleanerRow extends StatelessWidget {
  const _CustomerHistoryCleanerRow({required this.booking});

  final BookingModel booking;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Icon(Icons.person_outline, color: Color(0xFF64748B), size: 14),
      const SizedBox(width: 8),
      Flexible(
        child: Text(
          booking.cleanerName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
        ),
      ),
      const SizedBox(width: 4),
      const Icon(Icons.star_rounded, color: Color(0xFFFFB629), size: 13),
      Text(
        ' ${_customerCleanerRating(booking.cleanerName)}',
        style: const TextStyle(color: Color(0xFF42566B), fontSize: 10),
      ),
    ],
  );
}

String _customerHistoryDate(BookingModel booking) {
  final date = DateTime.tryParse(booking.bookingDate);
  if (date == null) return booking.bookingDate;
  return DateFormat('EEE, MMM d, yyyy').format(date);
}

String _customerCleanerRating(String cleaner) => switch (cleaner) {
  'Sarah Johnson' => '4.9',
  'Mike Chen' => '4.8',
  'Emily Davis' => '4.7',
  _ => '4.8',
};

Future<void> _showCustomerReviewSheet(
  BuildContext context,
  BookingModel booking, {
  required bool persist,
}) async {
  final comment = TextEditingController();
  final tags = <String>{};
  const quickTags = [
    'Thorough',
    'Punctual',
    'Professional',
    'Friendly',
    'Detail-oriented',
    'Efficient',
  ];
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setSheetState) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CustomerSheetHeader(
                    title: 'Write a Review',
                    onClose: () => Navigator.pop(sheetContext),
                  ),
                  const SizedBox(height: 14),
                  _CustomerSheetBookingSummary(
                    title: booking.serviceName,
                    subtitle:
                        'Cleaner: ${booking.cleanerName.isEmpty ? 'Assigned cleaner' : booking.cleanerName}\n${booking.bookingDate.split('T').first} at ${booking.bookingTime}',
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Your Review',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: comment,
                    maxLines: 4,
                    maxLength: 500,
                    decoration: const InputDecoration(
                      hintText:
                          'Describe your experience in detail. What did the cleaner do well? What could be improved?',
                      hintStyle: TextStyle(fontSize: 11),
                      counterStyle: TextStyle(fontSize: 10),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Quick Tags',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      for (final tag in quickTags)
                        ChoiceChip(
                          label: Text(' + $tag'),
                          selected: tags.contains(tag),
                          onSelected: (selected) => setSheetState(() {
                            if (selected) {
                              tags.add(tag);
                            } else {
                              tags.remove(tag);
                            }
                          }),
                          labelStyle: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                          visualDensity: VisualDensity.compact,
                          side: BorderSide.none,
                          selectedColor: const Color(0xFFDCEEFF),
                          backgroundColor: const Color(0xFFEAF4FB),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 36,
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            child: const Text('Cancel'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 36,
                          child: ElevatedButton(
                            onPressed: () async {
                              final text = [
                                comment.text.trim(),
                                if (tags.isNotEmpty) tags.join(', '),
                              ].where((item) => item.isNotEmpty).join('\n');
                              await _submitCustomerReview(
                                sheetContext,
                                booking,
                                rating: 5,
                                comment: text,
                                persist: persist,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE7F1F8),
                              foregroundColor: const Color(0xFF3E5B74),
                              minimumSize: const Size.fromHeight(36),
                            ),
                            child: const Text('Post Review'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
  comment.dispose();
}

Future<void> _confirmCustomerBookingCancel(
  BuildContext context,
  BookingModel booking, {
  required bool persist,
  VoidCallback? onPreviewCancel,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Cancel booking?'),
      content: Text(
        'This will cancel your ${booking.serviceName} booking on '
        '${_customerHistoryDate(booking)} at ${booking.bookingTime}.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Keep Booking'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFFF3045),
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Cancel Booking'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;

  if (!persist) {
    onPreviewCancel?.call();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Booking cancelled.')));
    return;
  }

  final user = context.read<AuthProvider>().user;
  if (user == null) return;
  await context.read<BookingProvider>().cancel(booking, user);
  if (context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Booking cancelled.')));
  }
}

Future<void> _showCustomerRatingSheet(
  BuildContext context,
  BookingModel booking, {
  required bool persist,
}) async {
  final comment = TextEditingController();
  var rating = 0;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setSheetState) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CustomerSheetHeader(
                    title: 'Rate Your Service',
                    onClose: () => Navigator.pop(sheetContext),
                  ),
                  const SizedBox(height: 16),
                  _CustomerSheetBookingSummary(
                    title: booking.serviceName,
                    subtitle:
                        '${booking.cleanerName.isEmpty ? 'Assigned cleaner' : booking.cleanerName} • ${booking.bookingDate.split('T').first}',
                  ),
                  const SizedBox(height: 18),
                  const Center(
                    child: Text(
                      'How was your experience?',
                      style: TextStyle(color: Color(0xFF42566B), fontSize: 11),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var index = 1; index <= 5; index++)
                          IconButton(
                            tooltip: '$index stars',
                            visualDensity: VisualDensity.compact,
                            onPressed: () =>
                                setSheetState(() => rating = index),
                            icon: Icon(
                              index <= rating
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              color: const Color(0xFF64748B),
                              size: 34,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Additional comments (optional)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: comment,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Share your experience...',
                      hintStyle: TextStyle(fontSize: 11),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 36,
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            child: const Text('Skip'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 36,
                          child: ElevatedButton(
                            onPressed: rating == 0
                                ? null
                                : () => _submitCustomerReview(
                                    sheetContext,
                                    booking,
                                    rating: rating,
                                    comment: comment.text.trim(),
                                    persist: persist,
                                  ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE7F1F8),
                              foregroundColor: const Color(0xFF3E5B74),
                              disabledBackgroundColor: const Color(0xFFE7F1F8),
                              disabledForegroundColor: const Color(0xFF7690A5),
                              minimumSize: const Size.fromHeight(36),
                            ),
                            child: const Text('Submit Rating'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
  comment.dispose();
}

class _CustomerSheetHeader extends StatelessWidget {
  const _CustomerSheetHeader({required this.title, required this.onClose});

  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
      ),
      IconButton(
        tooltip: 'Close',
        onPressed: onClose,
        icon: const Icon(Icons.close, color: Color(0xFF64748B), size: 20),
      ),
    ],
  );
}

class _CustomerSheetBookingSummary extends StatelessWidget {
  const _CustomerSheetBookingSummary({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFE7F1F8),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(
            color: Color(0xFF42566B),
            fontSize: 11,
            height: 1.55,
          ),
        ),
      ],
    ),
  );
}

Future<void> _submitCustomerReview(
  BuildContext context,
  BookingModel booking, {
  required int rating,
  required String comment,
  required bool persist,
}) async {
  if (persist && booking.id != null) {
    try {
      await context.read<BookingProvider>().database.addReview(
        ReviewModel(
          bookingId: booking.id!,
          serviceId: booking.serviceId,
          userId: booking.userId,
          rating: rating,
          comment: comment,
        ),
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('A review already exists for this booking.'),
          ),
        );
      }
      return;
    }
  }
  if (context.mounted) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Thank you for your feedback.')),
    );
  }
}

class BookingDetailScreen extends StatelessWidget {
  const BookingDetailScreen({super.key});
  static const route = '/booking-detail';
  @override
  Widget build(BuildContext context) {
    final argument = ModalRoute.of(context)?.settings.arguments;
    final currentUser = context.watch<AuthProvider>().user;
    if (argument is! BookingModel || argument.id == null) {
      return const _BookingDetailAccessError(
        message: 'This booking could not be found.',
      );
    }
    final booking = argument;
    final role = currentUser?.role ?? 'customer';
    if (role == 'customer' && booking.userId != currentUser?.id) {
      return const _BookingDetailAccessError(
        message: 'You do not have permission to view this booking.',
      );
    }
    if (role == 'cleaner' && booking.cleanerId != currentUser?.id) {
      return const _BookingDetailAccessError(
        message: 'This job is assigned to another cleaner.',
      );
    }
    final canCancel = ['Pending', 'Accepted'].contains(booking.status);
    if (role == 'admin') return _AdminBookingDetailView(booking: booking);
    if (role == 'cleaner') return _CleanerJobDetailView(booking: booking);
    return Scaffold(
      appBar: AppBar(title: Text('Booking #${booking.id ?? '-'}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (booking.serviceImage.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                booking.serviceImage,
                height: 180,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  booking.serviceName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              StatusBadge(booking.status),
            ],
          ),
          const SizedBox(height: 12),
          DetailRow('Customer', booking.customerName),
          DetailRow('Phone', booking.phone),
          DetailRow('Address', booking.address),
          DetailRow(
            'Property',
            '${booking.propertyType}, ${booking.rooms} room(s), ${booking.bathrooms} bathroom(s)',
          ),
          DetailRow(
            'Date',
            '${prettyDate(DateTime.parse(booking.bookingDate))} at ${booking.bookingTime}',
          ),
          DetailRow(
            'Extras',
            booking.extraServices.isEmpty
                ? 'None'
                : booking.extraServices.join(', '),
          ),
          DetailRow(
            'Instruction',
            booking.specialInstruction.isEmpty
                ? 'None'
                : booking.specialInstruction,
          ),
          DetailRow('Total', money(booking.totalPrice)),
          DetailRow('Payment', '${booking.paymentMethod} • Unpaid'),
          const SectionHeader(title: 'Status Timeline'),
          for (final status in [
            'Pending',
            'Accepted',
            'Cleaner Assigned',
            'On the Way',
            'Arrived',
            'In Progress',
            'Completed',
          ])
            ListTile(
              leading: Icon(
                status == booking.status
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: status == booking.status
                    ? AppColors.primary
                    : AppColors.muted,
              ),
              title: Text(status),
            ),
          if (canCancel)
            OutlinedButton.icon(
              onPressed: () async {
                await context.read<BookingProvider>().cancel(
                  booking,
                  currentUser!,
                );
                if (context.mounted) Navigator.pop(context);
              },
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Cancel Booking'),
            ),
          if (booking.status == 'Completed')
            CustomButton(
              label: 'Add Review',
              icon: Icons.star_outline,
              onPressed: () => Navigator.pushNamed(
                context,
                ReviewScreen.route,
                arguments: booking,
              ),
            ),
        ],
      ),
    );
  }
}

class _BookingDetailAccessError extends StatelessWidget {
  const _BookingDetailAccessError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Booking Detail')),
    body: EmptyStateWidget(
      title: 'Booking unavailable',
      message: message,
      icon: Icons.lock_outline,
    ),
  );
}

class _CleanerJobDetailView extends StatefulWidget {
  const _CleanerJobDetailView({required this.booking});

  final BookingModel booking;

  @override
  State<_CleanerJobDetailView> createState() => _CleanerJobDetailViewState();
}

class _CleanerJobDetailViewState extends State<_CleanerJobDetailView> {
  static const _steps = [
    _CleanerTrackingStep(
      label: 'Assigned',
      databaseStatus: 'Cleaner Assigned',
      icon: Icons.task_alt_rounded,
      color: Color(0xFF2E7CFF),
    ),
    _CleanerTrackingStep(
      label: 'On the Way',
      databaseStatus: 'On the Way',
      icon: Icons.near_me_rounded,
      color: Color(0xFFB63CFF),
    ),
    _CleanerTrackingStep(
      label: 'Arrived',
      databaseStatus: 'Arrived',
      icon: Icons.location_on_rounded,
      color: Color(0xFFFF6300),
    ),
    _CleanerTrackingStep(
      label: 'In Progress',
      databaseStatus: 'In Progress',
      icon: Icons.schedule_rounded,
      color: Color(0xFFFF9D00),
    ),
    _CleanerTrackingStep(
      label: 'Completed',
      databaseStatus: 'Completed',
      icon: Icons.check_rounded,
      color: Color(0xFF00BF68),
    ),
  ];

  late BookingModel booking;
  late int currentStep;
  late final TextEditingController completionNotes;
  final ImagePicker imagePicker = ImagePicker();
  Timer? notesSaveTimer;
  bool updating = false;
  bool savingDocumentation = false;

  @override
  void initState() {
    super.initState();
    booking = widget.booking;
    currentStep = _stepForStatus(booking.status);
    completionNotes = TextEditingController(text: booking.completionNotes);
  }

  @override
  void dispose() {
    notesSaveTimer?.cancel();
    completionNotes.dispose();
    super.dispose();
  }

  int _stepForStatus(String status) => switch (status) {
    'On the Way' => 1,
    'Arrived' => 2,
    'In Progress' => 3,
    'Completed' => 4,
    _ => 0,
  };

  Future<void> _advanceTo(int index) async {
    if (updating || index != currentStep + 1 || index >= _steps.length) return;
    if (index == 4 && booking.afterPhotos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Upload an after photo before completing the job.'),
        ),
      );
      return;
    }
    final nextStatus = _steps[index].databaseStatus;
    setState(() {
      updating = true;
      currentStep = index;
      booking = booking.copyWith(status: nextStatus);
    });
    if (index == 4) {
      await _updateDemoBookingCache();
    } else {
      unawaited(_updateDemoBookingCache());
    }
    if (!mounted) return;

    final provider = context.read<BookingProvider>();
    final isPersistedJob = provider.bookings.any(
      (item) => item.id == booking.id,
    );
    if (isPersistedJob) {
      await provider.updateStatus(
        booking,
        nextStatus,
        context.read<AuthProvider>().user!,
      );
    }
    if (!mounted) return;
    setState(() => updating = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Job updated to ${_steps[index].label}.')),
    );
  }

  Future<void> _pickDocumentationPhotos({required bool before}) async {
    try {
      final selected = await imagePicker.pickMultiImage(
        imageQuality: 72,
        maxWidth: 1600,
      );
      if (selected.isEmpty || !mounted) return;
      final existing = before ? booking.beforePhotos : booking.afterPhotos;
      final availableSlots = math.max(0, 5 - existing.length);
      final encoded = <String>[];
      for (final file in selected.take(availableSlots)) {
        final bytes = await file.readAsBytes();
        final mimeType = file.mimeType ?? 'image/jpeg';
        encoded.add('data:$mimeType;base64,${base64Encode(bytes)}');
      }
      if (!mounted) return;
      setState(() {
        booking = before
            ? booking.copyWith(beforePhotos: [...existing, ...encoded])
            : booking.copyWith(afterPhotos: [...existing, ...encoded]);
      });
      await _persistDocumentation();
      if (selected.length > availableSlots && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You can attach up to 5 photos.')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the photo gallery.')),
      );
    }
  }

  Future<void> _removeDocumentationPhoto({
    required bool before,
    required int index,
  }) async {
    final photos = List<String>.of(
      before ? booking.beforePhotos : booking.afterPhotos,
    )..removeAt(index);
    setState(() {
      booking = before
          ? booking.copyWith(beforePhotos: photos)
          : booking.copyWith(afterPhotos: photos);
    });
    await _persistDocumentation();
  }

  void _updateCompletionNotes(String value) {
    booking = booking.copyWith(completionNotes: value.trim());
    unawaited(_updateDemoBookingCache());
    notesSaveTimer?.cancel();
    notesSaveTimer = Timer(
      const Duration(milliseconds: 450),
      _persistDocumentation,
    );
  }

  Future<void> _persistDocumentation() async {
    await _updateDemoBookingCache();
    if (!mounted) return;
    final provider = context.read<BookingProvider>();
    if (provider.bookings.any((item) => item.id == booking.id)) {
      await provider.updateDocumentation(booking);
    }
  }

  Future<void> _saveDocumentationAndExit() async {
    if (savingDocumentation) return;
    if (currentStep == 3 && booking.afterPhotos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least one after photo before completing.'),
        ),
      );
      return;
    }

    notesSaveTimer?.cancel();
    setState(() {
      savingDocumentation = true;
      booking = booking.copyWith(completionNotes: completionNotes.text.trim());
    });
    try {
      await _persistDocumentation();
      if (currentStep == 3) await _advanceTo(4);
      if (!mounted) return;
      Navigator.pop(context, booking);
    } catch (_) {
      if (!mounted) return;
      setState(() => savingDocumentation = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save the job documentation.')),
      );
    }
  }

  Future<void> _updateDemoBookingCache() async {
    final index = _demoCleanerJobs.indexWhere((item) => item.id == booking.id);
    if (index >= 0) {
      _demoCleanerJobs[index] = booking;
      await _saveDemoCleanerJob(booking);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: _CleanerPortalAppBar(auth: auth),
      bottomNavigationBar: NavigationBar(
        height: 62,
        selectedIndex: 0,
        onDestinationSelected: (_) => Navigator.maybePop(context),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.work_outline_rounded),
            selectedIcon: Icon(Icons.work_rounded),
            label: 'Jobs',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today_rounded),
            label: 'Schedule',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _CleanerJobDetailHeader(booking: booking),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
            child: Column(
              children: [
                _CleanerTrackingCard(
                  steps: _steps,
                  currentStep: currentStep,
                  updating: updating,
                  onStepPressed: _advanceTo,
                ),
                const SizedBox(height: 18),
                _CleanerJobDetailsCard(booking: booking),
                const SizedBox(height: 18),
                _CleanerTaskDocumentationCard(
                  beforePhotos: booking.beforePhotos,
                  afterPhotos: booking.afterPhotos,
                  notesController: completionNotes,
                  onNotesChanged: _updateCompletionNotes,
                  onPickBefore: () => _pickDocumentationPhotos(before: true),
                  onPickAfter: () => _pickDocumentationPhotos(before: false),
                  onRemoveBefore: (index) =>
                      _removeDocumentationPhoto(before: true, index: index),
                  onRemoveAfter: (index) =>
                      _removeDocumentationPhoto(before: false, index: index),
                  actionLabel: currentStep == 3
                      ? 'Save & Complete Job'
                      : 'Save Documentation',
                  saving: savingDocumentation,
                  onSave: _saveDocumentationAndExit,
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Directions to ${booking.address}',
                                ),
                              ),
                            ),
                        icon: const Icon(Icons.near_me_outlined, size: 18),
                        label: const Text('Get Directions'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _showCleanerCustomerContact(context, booking),
                        icon: const Icon(Icons.chat_bubble_outline, size: 18),
                        label: const Text('Contact'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CleanerTrackingStep {
  const _CleanerTrackingStep({
    required this.label,
    required this.databaseStatus,
    required this.icon,
    required this.color,
  });

  final String label;
  final String databaseStatus;
  final IconData icon;
  final Color color;
}

class _CleanerJobDetailHeader extends StatelessWidget {
  const _CleanerJobDetailHeader({required this.booking});

  final BookingModel booking;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(18, 14, 18, 15),
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(bottom: BorderSide(color: AppColors.border)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  '← Back',
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const Spacer(),
            Text(
              'Job #${booking.id ?? '-'}',
              style: const TextStyle(color: AppColors.muted, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          booking.serviceName,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
      ],
    ),
  );
}

class _CleanerTrackingCard extends StatelessWidget {
  const _CleanerTrackingCard({
    required this.steps,
    required this.currentStep,
    required this.updating,
    required this.onStepPressed,
  });

  final List<_CleanerTrackingStep> steps;
  final int currentStep;
  final bool updating;
  final ValueChanged<int> onStepPressed;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Job Status',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        for (var index = 0; index < steps.length; index++) ...[
          _CleanerTrackingStepTile(
            step: steps[index],
            completed: index <= currentStep,
            current: index == currentStep,
            enabled: !updating && index == currentStep + 1,
            onTap: () => onStepPressed(index),
          ),
          if (index != steps.length - 1) const SizedBox(height: 10),
        ],
      ],
    ),
  );
}

class _CleanerTrackingStepTile extends StatelessWidget {
  const _CleanerTrackingStepTile({
    required this.step,
    required this.completed,
    required this.current,
    required this.enabled,
    required this.onTap,
  });

  final _CleanerTrackingStep step;
  final bool completed;
  final bool current;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: completed ? const Color(0xFFF0FCF8) : Colors.white,
    borderRadius: BorderRadius.circular(13),
    child: InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(13),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: completed ? const Color(0xFF17CF91) : AppColors.border,
            width: current ? 1.3 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: completed ? step.color : const Color(0xFFE8F0F6),
                shape: BoxShape.circle,
              ),
              child: Icon(step.icon, color: Colors.white, size: 17),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                step.label,
                style: TextStyle(
                  color: completed ? AppColors.text : AppColors.muted,
                  fontSize: 13,
                  fontWeight: current ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            if (completed)
              const Icon(
                Icons.check_circle_outline_rounded,
                color: Color(0xFF13CD8D),
                size: 18,
              ),
          ],
        ),
      ),
    ),
  );
}

class _CleanerJobDetailsCard extends StatelessWidget {
  const _CleanerJobDetailsCard({required this.booking});

  final BookingModel booking;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Job Details',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 16),
        _CleanerDetailItem(
          icon: Icons.schedule_outlined,
          label: 'Date & Time',
          value:
              '${DateFormat('EEEE, MMMM d, y').format(DateTime.parse(booking.bookingDate))}\n${booking.bookingTime}',
        ),
        _CleanerDetailItem(
          icon: Icons.location_on_outlined,
          label: 'Location',
          value: booking.address,
        ),
        _CleanerDetailItem(
          icon: Icons.home_outlined,
          label: 'Property Details',
          value:
              '${booking.propertyType} • ${booking.rooms} bed, ${booking.bathrooms} bath',
        ),
        _CleanerDetailItem(
          icon: Icons.attach_money_rounded,
          label: 'Payment',
          value: money(booking.totalPrice),
          valueColor: const Color(0xFF10BE7E),
          strong: true,
        ),
        const Divider(height: 20),
        _CleanerDetailItem(
          icon: Icons.chat_bubble_outline,
          label: 'Special Instructions',
          value: booking.specialInstruction.isEmpty
              ? 'No special instructions provided.'
              : booking.specialInstruction,
          highlighted: true,
          last: true,
        ),
      ],
    ),
  );
}

class _CleanerTaskDocumentationCard extends StatelessWidget {
  const _CleanerTaskDocumentationCard({
    required this.beforePhotos,
    required this.afterPhotos,
    required this.notesController,
    required this.onNotesChanged,
    required this.onPickBefore,
    required this.onPickAfter,
    required this.onRemoveBefore,
    required this.onRemoveAfter,
    required this.actionLabel,
    required this.saving,
    required this.onSave,
  });

  final List<String> beforePhotos;
  final List<String> afterPhotos;
  final TextEditingController notesController;
  final ValueChanged<String> onNotesChanged;
  final VoidCallback onPickBefore;
  final VoidCallback onPickAfter;
  final ValueChanged<int> onRemoveBefore;
  final ValueChanged<int> onRemoveAfter;
  final String actionLabel;
  final bool saving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Task Documentation',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 14),
        _CleanerPhotoUploadField(
          label: beforePhotos.isEmpty
              ? 'Upload Before Photos'
              : 'Add Before Photos',
          photos: beforePhotos,
          onPick: onPickBefore,
          onRemove: onRemoveBefore,
        ),
        const SizedBox(height: 10),
        _CleanerPhotoUploadField(
          label: afterPhotos.isEmpty
              ? 'Upload After Photos'
              : 'Add After Photos',
          photos: afterPhotos,
          onPick: onPickAfter,
          onRemove: onRemoveAfter,
        ),
        const SizedBox(height: 10),
        TextField(
          controller: notesController,
          onChanged: onNotesChanged,
          minLines: 3,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Add completion notes...',
            contentPadding: EdgeInsets.all(13),
          ),
        ),
        const SizedBox(height: 14),
        CustomButton(
          label: actionLabel,
          icon: actionLabel == 'Save & Complete Job'
              ? Icons.task_alt_rounded
              : Icons.save_outlined,
          loading: saving,
          onPressed: onSave,
        ),
      ],
    ),
  );
}

class _CleanerPhotoUploadField extends StatelessWidget {
  const _CleanerPhotoUploadField({
    required this.label,
    required this.photos,
    required this.onPick,
    required this.onRemove,
  });

  final String label;
  final List<String> photos;
  final VoidCallback onPick;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SizedBox(
        width: double.infinity,
        height: 47,
        child: CustomPaint(
          painter: _CleanerDashedBorderPainter(),
          child: InkWell(
            onTap: photos.length >= 5 ? null : onPick,
            borderRadius: BorderRadius.circular(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.camera_alt_outlined,
                  color: AppColors.muted,
                  size: 17,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    photos.length >= 5 ? 'Maximum 5 Photos' : label,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      if (photos.isNotEmpty) ...[
        const SizedBox(height: 9),
        SizedBox(
          height: 68,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: photos.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) => Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: Image.memory(
                    base64Decode(photos[index].split(',').last),
                    width: 68,
                    height: 68,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: -5,
                  right: -5,
                  child: InkWell(
                    onTap: () => onRemove(index),
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: AppColors.danger,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ],
  );
}

class _CleanerDashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(12)),
      );
    final paint = Paint()
      ..color = const Color(0xFFD7E2EA)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, math.min(distance + 4, metric.length)),
          paint,
        );
        distance += 8;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CleanerDetailItem extends StatelessWidget {
  const _CleanerDetailItem({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.strong = false,
    this.highlighted = false,
    this.last = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool strong;
  final bool highlighted;
  final bool last;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: last ? 0 : 13),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.muted, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Container(
                width: double.infinity,
                padding: highlighted
                    ? const EdgeInsets.all(10)
                    : EdgeInsets.zero,
                decoration: highlighted
                    ? BoxDecoration(
                        color: const Color(0xFFE7F1F8),
                        borderRadius: BorderRadius.circular(9),
                      )
                    : null,
                child: Text(
                  value,
                  style: TextStyle(
                    color: valueColor ?? AppColors.muted,
                    fontSize: strong ? 15 : 11,
                    fontWeight: strong ? FontWeight.w900 : FontWeight.w400,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

void _showCleanerCustomerContact(BuildContext context, BookingModel booking) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              booking.customerName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(booking.phone, style: const TextStyle(color: AppColors.muted)),
            const SizedBox(height: 16),
            CustomButton(
              label: 'Close',
              icon: Icons.close,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    ),
  );
}

class _AdminBookingDetailView extends StatelessWidget {
  const _AdminBookingDetailView({required this.booking});

  final BookingModel booking;

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(booking.bookingDate);
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        toolbarHeight: 66,
        titleSpacing: 32,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${AppStrings.appName} Admin',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 2),
            const Text(
              'Management Portal',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: () async {
              final auth = context.read<AuthProvider>();
              final navigator = Navigator.of(context);
              await auth.logout();
              navigator.pushNamedAndRemoveUntil(
                LoginScreen.route,
                (_) => false,
              );
            },
            icon: const Icon(Icons.logout_outlined),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Container(
        color: const Color(0xFF000000).withValues(alpha: 0.32),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              constraints: const BoxConstraints(minHeight: 620),
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Booking #${booking.id ?? '-'}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              booking.serviceName,
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _AdminStatusBadge(status: booking.status),
                      const Spacer(),
                      Text(
                        _adminMoney(booking.totalPrice),
                        style: const TextStyle(
                          color: Color(0xFF0074D9),
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  if (booking.cleanerId != null ||
                      booking.cleanerName.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    _AdminBookingProgress(status: booking.status),
                  ],
                  const SizedBox(height: 20),
                  const _AdminDashboardTitle('Service Details'),
                  const SizedBox(height: 10),
                  _AdminDetailInfoBox(
                    rows: [
                      ('Service', booking.serviceName),
                      ('Property', _adminPropertyLabel(booking)),
                      (
                        'Duration',
                        _adminDurationLabel(booking.estimatedDuration),
                      ),
                      ('Date', DateFormat('MMM d, yyyy').format(date)),
                      ('Time', booking.bookingTime),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const _AdminDashboardTitle('Customer'),
                  const SizedBox(height: 10),
                  _AdminContactBox(
                    rows: [
                      (Icons.person_outline, booking.customerName),
                      (Icons.phone_outlined, booking.phone),
                      (
                        Icons.email_outlined,
                        _adminCustomerEmail(booking.customerName),
                      ),
                      (Icons.location_on_outlined, booking.address),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const _AdminDashboardTitle('Assigned Cleaner'),
                  const SizedBox(height: 10),
                  _AdminCleanerAssignmentBox(booking: booking),
                  const SizedBox(height: 18),
                  const _AdminDashboardTitle('Payment Summary'),
                  const SizedBox(height: 10),
                  _AdminDetailInfoBox(
                    rows: [
                      ('Base Price', _adminMoney(booking.basePrice)),
                      ('Extras', _adminMoney(booking.extraPrice)),
                      ('Cleaner Pay', _adminMoney(booking.cleanerPay)),
                      ('Total', _adminMoney(booking.totalPrice)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminBookingProgress extends StatelessWidget {
  const _AdminBookingProgress({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    const steps = ['Pending', 'Accepted', 'In Progress', 'Completed'];
    final currentIndex = switch (status) {
      'Accepted' || 'Cleaner Assigned' => 1,
      'On the Way' || 'Arrived' || 'In Progress' => 2,
      'Completed' => 3,
      _ => 0,
    };
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F0F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Progress',
            style: TextStyle(
              color: Color(0xFF47647D),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (var i = 0; i < steps.length; i++) ...[
                _ProgressDot(active: i <= currentIndex),
                if (i != steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: i < currentIndex
                          ? const Color(0xFF1087DD)
                          : const Color(0xFFBFD0DF),
                    ),
                  ),
              ],
            ],
          ),
          const SizedBox(height: 7),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final step in steps)
                Expanded(
                  child: Text(
                    step,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF47647D),
                      fontSize: 9,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressDot extends StatelessWidget {
  const _ProgressDot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: 10,
    backgroundColor: active ? const Color(0xFF1087DD) : const Color(0xFFBFD0DF),
    child: active
        ? const Icon(Icons.check, color: Colors.white, size: 12)
        : null,
  );
}

class _AdminDetailInfoBox extends StatelessWidget {
  const _AdminDetailInfoBox({required this.rows});

  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFE6F0F8),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      children: [
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    row.$1,
                    style: const TextStyle(
                      color: Color(0xFF47647D),
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    row.$2,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

class _AdminContactBox extends StatelessWidget {
  const _AdminContactBox({required this.rows});

  final List<(IconData, String)> rows;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFE6F0F8),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      children: [
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                Icon(row.$1, size: 15, color: const Color(0xFF5E7388)),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    row.$2,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF42566B),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

class _AdminCleanerAssignmentBox extends StatelessWidget {
  const _AdminCleanerAssignmentBox({required this.booking});

  final BookingModel booking;

  @override
  Widget build(BuildContext context) {
    final hasCleaner =
        booking.cleanerId != null || booking.cleanerName.isNotEmpty;
    if (!hasCleaner) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFE6F0F8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'No cleaner assigned',
          style: TextStyle(
            color: Color(0xFF5E7388),
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }
    final cleanerName = booking.cleanerName;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F0F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 17,
            backgroundColor: Color(0xFFDCEEFF),
            child: Icon(
              Icons.person_search_outlined,
              color: Color(0xFF0D6FB8),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              cleanerName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.text,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _adminDurationLabel(int minutes) {
  final hours = minutes / 60;
  if (hours <= 1) return '1 hour';
  if (hours <= 2) return '1-2 hours';
  return '${hours.ceil()} hours';
}

String _adminPropertyLabel(BookingModel booking) {
  final service = booking.serviceName.toLowerCase();
  if (service.contains('carpet')) return 'Living room carpet';
  if (service.contains('sofa')) return '${booking.rooms}-seat sofa';
  return '${booking.rooms}-seat ${booking.propertyType.toLowerCase()}';
}

String _adminCustomerEmail(String name) {
  final value = name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '.');
  if (value.isEmpty) return 'customer@email.com';
  return '$value@email.com';
}

class FavoriteScreen extends StatelessWidget {
  const FavoriteScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoriteProvider>().favorites;
    final services = context.watch<ServiceProvider>().services;
    final userId = context.watch<AuthProvider>().user?.id;
    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: favorites.isEmpty
          ? const EmptyStateWidget(
              title: 'No favorites',
              message: 'Tap the heart on any service to save it.',
              icon: Icons.favorite_border,
            )
          : ListView(
              children: [
                for (final item in favorites)
                  ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        item.serviceImage,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      ),
                    ),
                    title: Text(item.serviceName),
                    subtitle: Text(money(item.servicePrice)),
                    trailing: IconButton(
                      onPressed: () {
                        final service = services.firstWhere(
                          (s) => s.id == item.serviceId,
                        );
                        context.read<FavoriteProvider>().toggle(
                          userId!,
                          service,
                        );
                      },
                      icon: const Icon(Icons.delete_outline),
                    ),
                    onTap: () => Navigator.pushNamed(
                      context,
                      ServiceDetailScreen.route,
                      arguments: services.firstWhere(
                        (s) => s.id == item.serviceId,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});
  static const route = '/products';
  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(context.read<ProductProvider>().load);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Cleaning Add-ons')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search supplies and add-ons',
              ),
              onChanged: provider.updateSearch,
            ),
          ),
          Expanded(
            child: provider.loading
                ? const LoadingWidget()
                : provider.error != null
                ? ErrorView(message: provider.error!, onRetry: provider.load)
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: .68,
                        ),
                    itemCount: provider.filtered.length,
                    itemBuilder: (_, i) {
                      final product = provider.filtered[i];
                      return InkWell(
                        onTap: () => Navigator.pushNamed(
                          context,
                          ProductDetailScreen.route,
                          arguments: product,
                        ),
                        child: Card(
                          elevation: 0.8,
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Center(
                                    child: Image.network(
                                      product.imageUrl,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                                Text(
                                  product.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  money(product.price),
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key});
  static const route = '/product-detail';
  @override
  Widget build(BuildContext context) {
    final product = ModalRoute.of(context)!.settings.arguments as ProductModel;
    return Scaffold(
      appBar: AppBar(title: Text(product.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Image.network(product.imageUrl, height: 260, fit: BoxFit.contain),
          Text(
            product.title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          Text(
            product.category,
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 10),
          Text(
            money(product.price),
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Recommended as a cleaning supply or add-on item. ${product.description}',
          ),
          const SizedBox(height: 18),
          CustomButton(
            label: 'Save add-on',
            icon: Icons.bookmark_add_outlined,
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Saved locally for demo.')),
            ),
          ),
        ],
      ),
    );
  }
}

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});
  static const route = '/notifications';

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final userId = context.read<AuthProvider>().user?.id;
      context.read<NotificationProvider>().markAllRead(userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = context.watch<NotificationProvider>().notifications;
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: items.isEmpty
          ? const EmptyStateWidget(
              title: 'No notifications',
              message: 'Booking updates will appear here.',
              icon: Icons.notifications_none,
            )
          : ListView(
              children: [
                for (final item in items)
                  ListTile(
                    leading: Icon(
                      item.isRead
                          ? Icons.notifications_none
                          : Icons.notifications_active,
                      color: AppColors.primary,
                    ),
                    title: Text(item.title),
                    subtitle: Text(item.message),
                  ),
              ],
            ),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _savedAddresses = <_CustomerSavedAddress>[];
  final _paymentMethods = <_CustomerPaymentMethod>[];
  String? _appliedPromotionCode;
  OverlayEntry? _promotionsOverlay;
  String? _editingField;
  String? _loadedUserUid;
  bool _addressesLoading = false;

  @override
  void dispose() {
    _closePromotionsSheet();
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _syncControllers(UserModel user) {
    if (_loadedUserUid == user.firebaseUid) return;
    _loadedUserUid = user.firebaseUid;
    _name.text = user.fullName;
    _email.text = user.email;
    _phone.text = user.phone;
    _savedAddresses.clear();
    _addressesLoading = true;
    unawaited(_loadCustomerAddresses(user));
    _paymentMethods
      ..clear()
      ..addAll(const [
        _CustomerPaymentMethod(
          title: 'Cash on service',
          subtitle: 'Pay after your cleaner completes the job',
          icon: Icons.payments_outlined,
          isDefault: true,
        ),
      ]);
  }

  Future<void> _loadCustomerAddresses(UserModel user) async {
    final addresses = <_CustomerSavedAddress>[];
    try {
      if (user.id != null) {
        final decoded = await context
            .read<BookingProvider>()
            .database
            .customerAddresses(user.id!);
        addresses.addAll(
          decoded.map(
            (item) =>
                _CustomerSavedAddress.fromJson(Map<String, dynamic>.from(item)),
          ),
        );
      }
      if (addresses.isEmpty && user.address.trim().isNotEmpty) {
        addresses.add(
          _CustomerSavedAddress(
            title: 'Home',
            address: user.address.trim(),
            isDefault: true,
          ),
        );
      }
    } catch (_) {
      // A new customer intentionally starts without saved addresses.
    }
    if (!mounted || _loadedUserUid != user.firebaseUid) return;
    setState(() {
      _savedAddresses
        ..clear()
        ..addAll(addresses);
      _addressesLoading = false;
    });
  }

  Future<void> _saveCustomerAddresses(UserModel user) async {
    if (user.id == null) return;
    await context.read<BookingProvider>().database.saveCustomerAddresses(
      user.id!,
      _savedAddresses.map((item) => item.toJson()).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    if (user == null)
      return const EmptyStateWidget(
        title: 'Login required',
        message: 'Please log in to manage your profile.',
      );
    _syncControllers(user);
    final bookings = context
        .watch<BookingProvider>()
        .bookings
        .where((booking) => booking.userId == user.id)
        .toList();
    final completedBookings = bookings
        .where((booking) => booking.status == 'Completed')
        .length;
    final totalBookings = bookings.length;
    final averageRating = completedBookings == 0 ? '—' : '4.8';
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _customerPortalAppBar(context),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 26),
        children: [
          _CustomerProfileHero(
            name: user.fullName.trim().isEmpty ? 'Customer' : user.fullName,
            email: user.email,
            totalBookings: totalBookings,
            averageRating: averageRating,
          ),
          const SizedBox(height: 20),
          const _CustomerProfileSectionHeader(title: 'Personal Information'),
          const SizedBox(height: 10),
          _CustomerProfileGroupedCard(
            child: Column(
              children: [
                _CustomerEditableProfileRow(
                  icon: Icons.person_outline,
                  title: 'Full Name',
                  value: user.fullName,
                  controller: _name,
                  editing: _editingField == 'name',
                  keyboardType: TextInputType.name,
                  onEdit: () => setState(() => _editingField = 'name'),
                  onCancel: () {
                    _name.text = user.fullName;
                    setState(() => _editingField = null);
                  },
                  onSave: () => _saveCustomerProfileField(context, user),
                ),
                const Divider(height: 1, color: Color(0xFFDDE6EE)),
                _CustomerEditableProfileRow(
                  icon: Icons.email_outlined,
                  title: 'Email',
                  value: user.email,
                  controller: _email,
                  editing: _editingField == 'email',
                  keyboardType: TextInputType.emailAddress,
                  onEdit: () => setState(() => _editingField = 'email'),
                  onCancel: () {
                    _email.text = user.email;
                    setState(() => _editingField = null);
                  },
                  onSave: () => _saveCustomerProfileField(context, user),
                ),
                const Divider(height: 1, color: Color(0xFFDDE6EE)),
                _CustomerEditableProfileRow(
                  icon: Icons.phone_outlined,
                  title: 'Phone',
                  value: user.phone,
                  controller: _phone,
                  editing: _editingField == 'phone',
                  keyboardType: TextInputType.phone,
                  onEdit: () => setState(() => _editingField = 'phone'),
                  onCancel: () {
                    _phone.text = user.phone;
                    setState(() => _editingField = null);
                  },
                  onSave: () => _saveCustomerProfileField(context, user),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _CustomerProfileSectionHeader(
            title: 'Saved Addresses',
            action: '+ Add New',
            onAction: () => _showAddCustomerAddressSheet(context),
          ),
          const SizedBox(height: 10),
          if (_addressesLoading)
            const Center(child: CircularProgressIndicator())
          else if (_savedAddresses.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFDDE6EE)),
              ),
              child: const Text(
                'No saved addresses yet. Add an address when you are ready.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            )
          else
            for (var index = 0; index < _savedAddresses.length; index++) ...[
              _CustomerAddressCard(
                title: _savedAddresses[index].title,
                address: _savedAddresses[index].address,
                isDefault: _savedAddresses[index].isDefault,
              ),
              if (index != _savedAddresses.length - 1)
                const SizedBox(height: 10),
            ],
          const SizedBox(height: 22),
          const _CustomerProfileSectionHeader(title: 'Settings'),
          const SizedBox(height: 10),
          _CustomerProfileGroupedCard(
            child: Column(
              children: [
                _CustomerProfileNavRow(
                  icon: Icons.notifications_none,
                  title: 'Notifications',
                  subtitle: 'Manage notification preferences',
                  onTap: () =>
                      Navigator.pushNamed(context, NotificationScreen.route),
                ),
                const Divider(height: 1, color: Color(0xFFDDE6EE)),
                _CustomerProfileNavRow(
                  icon: Icons.credit_card_outlined,
                  title: 'Payment Methods',
                  subtitle: 'Manage your payment options',
                  onTap: () => _showPaymentMethodsSheet(context),
                ),
                const Divider(height: 1, color: Color(0xFFDDE6EE)),
                _CustomerProfileNavRow(
                  icon: Icons.card_giftcard_outlined,
                  title: 'Promotions & Discounts',
                  subtitle: 'View available offers',
                  onTap: () => _showPromotionsSheet(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveCustomerProfileField(
    BuildContext context,
    UserModel user,
  ) async {
    final name = _name.text.trim();
    final email = _email.text.trim();
    final phone = _phone.text.trim();
    if (name.isEmpty) {
      _showCustomerProfileToast(context, 'Full name is required.');
      return;
    }
    if (Validators.email(email) != null) {
      _showCustomerProfileToast(context, 'Enter a valid email address.');
      return;
    }
    if (Validators.phone(phone) != null) {
      _showCustomerProfileToast(context, 'Enter a valid phone number.');
      return;
    }
    await context.read<AuthProvider>().updateProfile(
      name,
      phone,
      user.address,
      email: email,
    );
    if (!context.mounted) return;
    setState(() => _editingField = null);
    _showCustomerProfileToast(context, 'Profile updated.');
  }

  Future<void> _showAddCustomerAddressSheet(BuildContext context) async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    final label = TextEditingController();
    final street = TextEditingController();
    final city = TextEditingController();
    final postalCode = TextEditingController();
    var makeDefault = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CustomerSheetHeader(
                      title: 'Add New Address',
                      onClose: () => Navigator.pop(sheetContext),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: label,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Address label',
                        hintText: 'Home, Office, School',
                        prefixIcon: Icon(Icons.bookmark_border),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: street,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Street address or location',
                        hintText: '123 Main St, Apt 4B',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: city,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'City',
                              hintText: 'New York',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: postalCode,
                            keyboardType: TextInputType.text,
                            decoration: const InputDecoration(
                              labelText: 'ZIP / Postal',
                              hintText: '10001',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    CheckboxListTile(
                      value: makeDefault,
                      onChanged: (value) =>
                          setSheetState(() => makeDefault = value ?? false),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: const Text(
                        'Set as default address',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 42,
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(sheetContext),
                              child: const Text('Cancel'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SizedBox(
                            height: 42,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final title = label.text.trim();
                                final streetAddress = street.text.trim();
                                final cityText = city.text.trim();
                                final postalText = postalCode.text.trim();
                                if (title.isEmpty || streetAddress.isEmpty) {
                                  _showCustomerProfileToast(
                                    sheetContext,
                                    'Address label and street address are required.',
                                  );
                                  return;
                                }
                                final fullAddress = [
                                  streetAddress,
                                  cityText,
                                  postalText,
                                ].where((item) => item.isNotEmpty).join(', ');
                                final shouldBeDefault =
                                    makeDefault || _savedAddresses.isEmpty;
                                setState(() {
                                  if (shouldBeDefault) {
                                    for (
                                      var index = 0;
                                      index < _savedAddresses.length;
                                      index++
                                    ) {
                                      final item = _savedAddresses[index];
                                      _savedAddresses[index] =
                                          _CustomerSavedAddress(
                                            title: item.title,
                                            address: item.address,
                                          );
                                    }
                                  }
                                  _savedAddresses.add(
                                    _CustomerSavedAddress(
                                      title: title,
                                      address: fullAddress,
                                      isDefault: shouldBeDefault,
                                    ),
                                  );
                                });
                                await _saveCustomerAddresses(user);
                                if (shouldBeDefault && context.mounted) {
                                  await context
                                      .read<AuthProvider>()
                                      .updateProfile(
                                        user.fullName,
                                        user.phone,
                                        fullAddress,
                                        email: user.email,
                                      );
                                }
                                if (!sheetContext.mounted) return;
                                Navigator.pop(sheetContext);
                                _showCustomerProfileToast(
                                  context,
                                  'Address added.',
                                );
                              },
                              icon: const Icon(Icons.add_location_alt_outlined),
                              label: const Text('Save Address'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    label.dispose();
    street.dispose();
    city.dispose();
    postalCode.dispose();
  }

  Future<void> _showPaymentMethodsSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CustomerSheetHeader(
                    title: 'Payment Methods',
                    onClose: () => Navigator.pop(sheetContext),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Choose how you want to pay for future bookings.',
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 14),
                  for (var index = 0; index < _paymentMethods.length; index++)
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: index == _paymentMethods.length - 1 ? 0 : 10,
                      ),
                      child: _CustomerPaymentMethodCard(
                        method: _paymentMethods[index],
                        onSetDefault: () {
                          setState(() {
                            for (
                              var itemIndex = 0;
                              itemIndex < _paymentMethods.length;
                              itemIndex++
                            ) {
                              final item = _paymentMethods[itemIndex];
                              _paymentMethods[itemIndex] =
                                  _CustomerPaymentMethod(
                                    title: item.title,
                                    subtitle: item.subtitle,
                                    icon: item.icon,
                                    isDefault: itemIndex == index,
                                  );
                            }
                          });
                          setSheetState(() {});
                        },
                      ),
                    ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final added = await _showAddPaymentMethodSheet(
                          sheetContext,
                        );
                        if (added == true) setSheetState(() {});
                      },
                      icon: const Icon(Icons.add_card_outlined),
                      label: const Text('Add Card'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<bool?> _showAddPaymentMethodSheet(BuildContext context) async {
    final cardName = TextEditingController();
    final cardNumber = TextEditingController();
    final expiry = TextEditingController();
    final cvv = TextEditingController();
    var makeDefault = _paymentMethods.isEmpty;

    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CustomerSheetHeader(
                      title: 'Add Card',
                      onClose: () => Navigator.pop(sheetContext, false),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: cardName,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Name on card',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: cardNumber,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Card number',
                        hintText: '1234 5678 9012 3456',
                        prefixIcon: Icon(Icons.credit_card_outlined),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: expiry,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Expiry',
                              hintText: 'MM/YY',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: cvv,
                            keyboardType: TextInputType.number,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'CVV',
                              hintText: '123',
                            ),
                          ),
                        ),
                      ],
                    ),
                    CheckboxListTile(
                      value: makeDefault,
                      onChanged: (value) =>
                          setSheetState(() => makeDefault = value ?? false),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: const Text(
                        'Set as default payment method',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 42,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final name = cardName.text.trim();
                          final digits = cardNumber.text.replaceAll(
                            RegExp(r'\D'),
                            '',
                          );
                          if (name.isEmpty || digits.length < 12) {
                            _showCustomerProfileToast(
                              sheetContext,
                              'Enter a valid card name and number.',
                            );
                            return;
                          }
                          setState(() {
                            if (makeDefault) {
                              for (
                                var index = 0;
                                index < _paymentMethods.length;
                                index++
                              ) {
                                final item = _paymentMethods[index];
                                _paymentMethods[index] = _CustomerPaymentMethod(
                                  title: item.title,
                                  subtitle: item.subtitle,
                                  icon: item.icon,
                                );
                              }
                            }
                            final lastFour = digits.substring(
                              digits.length - 4,
                            );
                            _paymentMethods.add(
                              _CustomerPaymentMethod(
                                title: 'Card ending $lastFour',
                                subtitle:
                                    '$name • expires ${expiry.text.trim().isEmpty ? 'not set' : expiry.text.trim()}',
                                icon: Icons.credit_card_outlined,
                                isDefault: makeDefault,
                              ),
                            );
                          });
                          Navigator.pop(sheetContext, true);
                          _showCustomerProfileToast(context, 'Card added.');
                        },
                        icon: const Icon(Icons.lock_outline),
                        label: const Text('Save Card'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    cardName.dispose();
    cardNumber.dispose();
    expiry.dispose();
    cvv.dispose();
    return added;
  }

  void _showPromotionsSheet(BuildContext context) {
    if (_promotionsOverlay != null) return;
    const offers = [
      _CustomerPromotion(
        code: 'WELCOME15',
        title: '15% off your next booking',
        description:
            'Best for first-time or returning customers booking any home service.',
        detail: 'Valid on bookings above \$40.',
        icon: Icons.local_offer_outlined,
      ),
      _CustomerPromotion(
        code: 'DEEP20',
        title: '\$20 off deep cleaning',
        description:
            'Recommended when booking Deep Cleaning or Move In/Out service.',
        detail: 'Valid until the end of this month.',
        icon: Icons.auto_awesome,
      ),
      _CustomerPromotion(
        code: 'WEEKDAY10',
        title: '10% weekday saver',
        description: 'Use this when booking Monday to Thursday appointments.',
        detail: 'Cannot combine with other offers.',
        icon: Icons.calendar_month_outlined,
      ),
    ];

    final overlay = Overlay.of(context, rootOverlay: true);
    _promotionsOverlay = OverlayEntry(
      builder: (overlayContext) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _closePromotionsSheet,
              child: const ColoredBox(color: Color(0x8A000000)),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: 0.78,
              widthFactor: 1,
              child: Material(
                color: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                ),
                clipBehavior: Clip.antiAlias,
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _CustomerSheetHeader(
                              title: 'Promotions & Discounts',
                              onClose: _closePromotionsSheet,
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Apply an offer now and it will be ready for your next booking.',
                              style: TextStyle(
                                color: AppColors.muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(18, 4, 18, 20),
                          itemCount: offers.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, index) {
                            final offer = offers[index];
                            return _CustomerPromotionCard(
                              promotion: offer,
                              applied: _appliedPromotionCode == offer.code,
                              onApply: () {
                                setState(
                                  () => _appliedPromotionCode = offer.code,
                                );
                                _promotionsOverlay?.markNeedsBuild();
                                _showCustomerProfileToast(
                                  context,
                                  '${offer.code} applied for your next booking.',
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    overlay.insert(_promotionsOverlay!);
  }

  void _closePromotionsSheet() {
    final overlay = _promotionsOverlay;
    if (overlay == null) return;
    _promotionsOverlay = null;
    overlay.remove();
    overlay.dispose();
  }
}

class _CustomerSavedAddress {
  const _CustomerSavedAddress({
    required this.title,
    required this.address,
    this.isDefault = false,
  });

  final String title;
  final String address;
  final bool isDefault;

  factory _CustomerSavedAddress.fromJson(Map<String, dynamic> json) =>
      _CustomerSavedAddress(
        title: json['title']?.toString() ?? '',
        address: json['address']?.toString() ?? '',
        isDefault:
            json['isDefault'] == true ||
            json['is_default'] == true ||
            json['is_default'] == 1,
      );

  Map<String, dynamic> toJson() => {
    'title': title,
    'address': address,
    'is_default': isDefault,
  };
}

class _CustomerPaymentMethod {
  const _CustomerPaymentMethod({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.isDefault = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool isDefault;
}

class _CustomerPromotion {
  const _CustomerPromotion({
    required this.code,
    required this.title,
    required this.description,
    required this.detail,
    required this.icon,
  });

  final String code;
  final String title;
  final String description;
  final String detail;
  final IconData icon;
}

class _CustomerPaymentMethodCard extends StatelessWidget {
  const _CustomerPaymentMethodCard({
    required this.method,
    required this.onSetDefault,
  });

  final _CustomerPaymentMethod method;
  final VoidCallback onSetDefault;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: method.isDefault ? const Color(0xFFEAF6FF) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: method.isDefault ? AppColors.primary : AppColors.border,
      ),
    ),
    child: Row(
      children: [
        _CustomerProfileIcon(method.icon),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      method.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (method.isDefault) ...[
                    const SizedBox(width: 8),
                    const _CustomerDefaultBadge(),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                method.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
        if (!method.isDefault)
          TextButton(onPressed: onSetDefault, child: const Text('Default'))
        else
          const Icon(Icons.check_circle, color: AppColors.primary),
      ],
    ),
  );
}

class _CustomerPromotionCard extends StatelessWidget {
  const _CustomerPromotionCard({
    required this.promotion,
    required this.applied,
    required this.onApply,
  });

  final _CustomerPromotion promotion;
  final bool applied;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: applied ? const Color(0xFFEAF6FF) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: applied ? AppColors.primary : AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _CustomerProfileIcon(promotion.icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    promotion.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    promotion.description,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      promotion.code,
                      style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      promotion.detail,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 34,
                child: applied
                    ? FilledButton.icon(
                        onPressed: null,
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Applied'),
                      )
                    : OutlinedButton(
                        onPressed: onApply,
                        child: const Text('Apply'),
                      ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _CustomerDefaultBadge extends StatelessWidget {
  const _CustomerDefaultBadge();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(99),
    ),
    child: const Text(
      'Default',
      style: TextStyle(
        color: Colors.white,
        fontSize: 9,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

class _CustomerProfileHero extends StatelessWidget {
  const _CustomerProfileHero({
    required this.name,
    required this.email,
    required this.totalBookings,
    required this.averageRating,
  });

  final String name;
  final String email;
  final int totalBookings;
  final String averageRating;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF168BDB), Color(0xFF2F9BE4)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
    ),
    child: Column(
      children: [
        Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(99),
              ),
              child: const Icon(
                Icons.person_outline,
                color: Colors.white,
                size: 36,
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: _CustomerProfileStatTile(
                icon: Icons.calendar_today_outlined,
                label: 'Total Bookings',
                value: '$totalBookings',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _CustomerProfileStatTile(
                icon: Icons.star_border_rounded,
                label: 'Avg Rating',
                value: averageRating,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _CustomerProfileStatTile extends StatelessWidget {
  const _CustomerProfileStatTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white, size: 14),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

class _CustomerProfileSectionHeader extends StatelessWidget {
  const _CustomerProfileSectionHeader({
    required this.title,
    this.action,
    this.onAction,
  });

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
        ),
      ),
      if (action != null)
        TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(
            visualDensity: VisualDensity.compact,
            foregroundColor: const Color(0xFF0077D9),
          ),
          child: Text(action!, style: const TextStyle(fontSize: 12)),
        ),
    ],
  );
}

class _CustomerProfileGroupedCard extends StatelessWidget {
  const _CustomerProfileGroupedCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFDDE6EE)),
    ),
    clipBehavior: Clip.antiAlias,
    child: child,
  );
}

class _CustomerEditableProfileRow extends StatelessWidget {
  const _CustomerEditableProfileRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.controller,
    required this.editing,
    required this.keyboardType,
    required this.onEdit,
    required this.onCancel,
    required this.onSave,
  });

  final IconData icon;
  final String title;
  final String value;
  final TextEditingController controller;
  final bool editing;
  final TextInputType keyboardType;
  final VoidCallback onEdit;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    child: Row(
      crossAxisAlignment: editing
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        _CustomerProfileIcon(icon),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              if (editing)
                TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  autofocus: true,
                  style: const TextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: title,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                )
              else
                Text(
                  value.isEmpty ? 'Not set' : value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF42566B),
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        if (editing) ...[
          IconButton(
            tooltip: 'Save',
            visualDensity: VisualDensity.compact,
            onPressed: onSave,
            icon: const Icon(Icons.check, color: Color(0xFF0D83D8), size: 20),
          ),
          IconButton(
            tooltip: 'Cancel',
            visualDensity: VisualDensity.compact,
            onPressed: onCancel,
            icon: const Icon(Icons.close, color: Color(0xFF64748B), size: 20),
          ),
        ] else
          IconButton(
            tooltip: 'Edit $title',
            visualDensity: VisualDensity.compact,
            onPressed: onEdit,
            icon: const Icon(
              Icons.chevron_right,
              color: Color(0xFF64748B),
              size: 22,
            ),
          ),
      ],
    ),
  );
}

class _CustomerProfileNavRow extends StatelessWidget {
  const _CustomerProfileNavRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Row(
        children: [
          _CustomerProfileIcon(icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF42566B),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Color(0xFF64748B), size: 22),
        ],
      ),
    ),
  );
}

class _CustomerProfileIcon extends StatelessWidget {
  const _CustomerProfileIcon(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    width: 32,
    height: 32,
    decoration: BoxDecoration(
      color: const Color(0xFFEAF6FF),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Icon(icon, color: const Color(0xFF0D83D8), size: 17),
  );
}

class _CustomerAddressCard extends StatelessWidget {
  const _CustomerAddressCard({
    required this.title,
    required this.address,
    this.isDefault = false,
  });

  final String title;
  final String address;
  final bool isDefault;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFDDE6EE)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _CustomerProfileIcon(Icons.location_on_outlined),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (isDefault) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF168BDB),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: const Text(
                        'Default',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 7),
              Text(
                address,
                style: const TextStyle(
                  color: Color(0xFF42566B),
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

void _showCustomerProfileToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  static const route = '/edit-profile';
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController();
  final phone = TextEditingController();
  final address = TextEditingController();
  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user!;
    name.text = user.fullName;
    phone.text = user.phone;
    address.text = user.address;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Edit Profile')),
    body: Form(
      key: form,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CustomTextField(
            controller: name,
            label: 'Full name',
            validator: (v) => Validators.required(v, 'Name'),
          ),
          const SizedBox(height: 12),
          CustomTextField(
            controller: phone,
            label: 'Phone number',
            validator: Validators.phone,
          ),
          const SizedBox(height: 12),
          CustomTextField(controller: address, label: 'Address', maxLines: 3),
          const SizedBox(height: 18),
          CustomButton(
            label: 'Save Profile',
            icon: Icons.save_outlined,
            onPressed: () async {
              if (!form.currentState!.validate()) return;
              await context.read<AuthProvider>().updateProfile(
                name.text.trim(),
                phone.text.trim(),
                address.text.trim(),
              );
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
    ),
  );
}

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});
  static const route = '/review';
  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  int rating = 0;
  final comment = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final booking = ModalRoute.of(context)!.settings.arguments as BookingModel;
    return Scaffold(
      appBar: AppBar(title: const Text('Review service')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            booking.serviceName,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          RatingBarWidget(
            rating: rating,
            onChanged: (value) => setState(() => rating = value),
          ),
          CustomTextField(controller: comment, label: 'Comment', maxLines: 4),
          const SizedBox(height: 18),
          CustomButton(
            label: 'Submit Review',
            icon: Icons.star_rounded,
            onPressed: () async {
              if (rating == 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Rating is required.')),
                );
                return;
              }
              await context.read<BookingProvider>().database.addReview(
                ReviewModel(
                  bookingId: booking.id!,
                  serviceId: booking.serviceId,
                  userId: booking.userId,
                  rating: rating,
                  comment: comment.text.trim(),
                ),
              );
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

class TipsScreen extends StatelessWidget {
  const TipsScreen({super.key});
  static const route = '/tips';
  @override
  Widget build(BuildContext context) {
    const tips = [
      (
        'Daily reset',
        'Spend ten minutes clearing counters and taking out trash before surfaces collect residue.',
      ),
      (
        'Bathroom sparkle',
        'Let cleaner sit for five minutes before scrubbing so it can break down buildup.',
      ),
      (
        'Kitchen care',
        'Clean top-to-bottom: cabinets, counters, appliances, then floors.',
      ),
      (
        'Move-out checklist',
        'Book deep cleaning after furniture is removed for the most accurate result.',
      ),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Cleaning Tips')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final tip in tips)
            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.tips_and_updates_outlined,
                  color: AppColors.primary,
                ),
                title: Text(tip.$1),
                subtitle: Text(tip.$2),
              ),
            ),
        ],
      ),
    );
  }
}

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) =>
      ListView(padding: const EdgeInsets.all(20), children: children);
}

class ErrorText extends StatelessWidget {
  const ErrorText(this.message, {super.key});
  final String message;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(message, style: const TextStyle(color: AppColors.danger)),
  );
}

class CounterRow extends StatelessWidget {
  const CounterRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      IconButton(
        onPressed: () => onChanged(value - 1),
        icon: const Icon(Icons.remove_circle_outline),
      ),
      SizedBox(width: 30, child: Text('$value', textAlign: TextAlign.center)),
      IconButton(
        onPressed: () => onChanged(value + 1),
        icon: const Icon(Icons.add_circle_outline),
      ),
    ],
  );
}

class PriceSummaryCard extends StatelessWidget {
  const PriceSummaryCard({
    super.key,
    required this.base,
    required this.extra,
    required this.total,
    required this.duration,
  });
  final double base;
  final double extra;
  final double total;
  final int duration;
  @override
  Widget build(BuildContext context) => InteractiveSurface(
    borderRadius: 8,
    lift: 2,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Price Details',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            const SizedBox(height: 10),
            DetailRow('Price', money(base)),
            DetailRow('Apps Fee', money(2.50)),
            DetailRow('Promo Code', 'CTAAPP'),
            DetailRow('Extra service', money(extra)),
            DetailRow('Duration', '$duration minutes'),
            const Divider(),
            DetailRow('Total price', money(total + 2.50), strong: true),
          ],
        ),
      ),
    ),
  );
}

class DetailRow extends StatelessWidget {
  const DetailRow(this.label, this.value, {super.key, this.strong = false});
  final String label;
  final String value;
  final bool strong;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(label, style: const TextStyle(color: AppColors.muted)),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: strong ? FontWeight.w900 : FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
}

class RoleNoticeCard extends StatelessWidget {
  const RoleNoticeCard({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
  });
  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) => InteractiveSurface(
    borderRadius: 8,
    lift: 2,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary, size: 34),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(message, style: const TextStyle(color: AppColors.muted)),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class StatCard extends StatelessWidget {
  const StatCard({super.key, required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => InteractiveSurface(
    borderRadius: 8,
    lift: 2,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppColors.muted)),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    ),
  );
}

class BookingManagementTile extends StatelessWidget {
  const BookingManagementTile({super.key, required this.booking});
  final BookingModel booking;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    final cleanerNextStatus = switch (booking.status) {
      'Accepted' || 'Cleaner Assigned' => 'On the Way',
      'On the Way' => 'Arrived',
      'Arrived' => 'In Progress',
      'In Progress' => 'Completed',
      _ => null,
    };
    final statuses = user.role == 'admin'
        ? const [
            'Pending',
            'Accepted',
            'Cleaner Assigned',
            'In Progress',
            'Completed',
            'Cancelled',
            'Rejected',
          ]
        : const [
            'Cleaner Assigned',
            'On the Way',
            'Arrived',
            'In Progress',
            'Completed',
          ];
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    booking.serviceName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                StatusBadge(booking.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${prettyDate(DateTime.parse(booking.bookingDate))} at ${booking.bookingTime}',
              style: const TextStyle(color: AppColors.muted),
            ),
            Text(booking.address),
            if (booking.cleanerName.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Cleaner: ${booking.cleanerName} • Pay ${money(booking.cleanerPay)}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (user.role == 'admin')
                  ActionChip(
                    avatar: const Icon(Icons.assignment_ind_outlined),
                    label: Text(
                      booking.cleanerId == null ? 'Assign cleaner' : 'Reassign',
                    ),
                    onPressed: () => showCleanerAssignment(context, booking),
                  ),
                for (final status in statuses)
                  ActionChip(
                    label: Text(status),
                    onPressed:
                        booking.status == status ||
                            booking.status == 'Cancelled' ||
                            booking.status == 'Rejected' ||
                            (user.role == 'cleaner' &&
                                status != cleanerNextStatus)
                        ? null
                        : () => context.read<BookingProvider>().updateStatus(
                            booking,
                            status,
                            user,
                          ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class FeaturedServiceCard extends StatelessWidget {
  const FeaturedServiceCard({
    super.key,
    required this.service,
    required this.favorite,
    required this.onFavorite,
    required this.onTap,
  });
  final ServiceModel service;
  final bool favorite;
  final VoidCallback onFavorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 14),
    child: InteractiveSurface(
      borderRadius: 8,
      child: SizedBox(
        width: 170,
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Image.network(
                      service.imageUrl,
                      height: 112,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      left: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          money(service.basePrice),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 6,
                      top: 6,
                      child: IconButton.filled(
                        visualDensity: VisualDensity.compact,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: favorite
                              ? AppColors.danger
                              : AppColors.muted,
                        ),
                        onPressed: onFavorite,
                        icon: Icon(
                          favorite ? Icons.favorite : Icons.favorite_border,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: AppColors.accent,
                            size: 17,
                          ),
                          Text(
                            ' ${service.rating} (532)',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        service.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      const Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            color: AppColors.muted,
                            size: 14,
                          ),
                          Expanded(
                            child: Text(
                              ' Phnom Penh',
                              style: TextStyle(
                                color: AppColors.muted,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class ServiceGridCard extends StatelessWidget {
  const ServiceGridCard({
    super.key,
    required this.service,
    required this.favorite,
    required this.onFavorite,
    required this.onTap,
  });
  final ServiceModel service;
  final bool favorite;
  final VoidCallback onFavorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InteractiveSurface(
    borderRadius: 8,
    child: Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(service.imageUrl, fit: BoxFit.cover),
                  Positioned(
                    left: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        money(service.basePrice),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 6,
                    top: 6,
                    child: IconButton.filled(
                      visualDensity: VisualDensity.compact,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: favorite
                            ? AppColors.danger
                            : AppColors.muted,
                      ),
                      onPressed: onFavorite,
                      icon: Icon(
                        favorite ? Icons.favorite : Icons.favorite_border,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: AppColors.accent,
                        size: 16,
                      ),
                      Text(
                        ' ${service.rating} (532)',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    service.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  const Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: AppColors.muted,
                      ),
                      Expanded(
                        child: Text(
                          ' Phnom Penh',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class ProfileMenuTile extends StatelessWidget {
  const ProfileMenuTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InteractiveSurface(
    borderRadius: 10,
    lift: onTap == null ? 0 : 2,
    enabled: onTap != null,
    child: ListTile(
      leading: Icon(icon, color: AppColors.text),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: subtitle == null
          ? null
          : Text(subtitle!, style: const TextStyle(color: AppColors.muted)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.muted),
      onTap: onTap,
    ),
  );
}

IconData serviceCategoryIcon(String category) {
  final value = category.toLowerCase();
  if (value.contains('paint')) return Icons.format_paint_outlined;
  if (value.contains('electric')) return Icons.electrical_services_outlined;
  if (value.contains('plumb')) return Icons.plumbing_outlined;
  if (value.contains('office')) return Icons.business_center_outlined;
  if (value.contains('sofa')) return Icons.chair_outlined;
  if (value.contains('carpet')) return Icons.grid_view_outlined;
  if (value.contains('deep')) return Icons.auto_awesome_outlined;
  return Icons.cleaning_services_outlined;
}

class UserManagementTile extends StatelessWidget {
  const UserManagementTile({
    super.key,
    required this.user,
    required this.onEdit,
    required this.onDelete,
  });
  final UserModel user;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor: user.isActive ? AppColors.primary : AppColors.muted,
        child: Icon(
          user.role == 'admin'
              ? Icons.admin_panel_settings_outlined
              : Icons.person_outline,
          color: Colors.white,
        ),
      ),
      title: Text(user.fullName),
      subtitle: Text('${user.email}\n${user.phone}'),
      isThreeLine: true,
      trailing: Wrap(
        spacing: 4,
        children: [
          Chip(label: Text(user.role)),
          IconButton(
            tooltip: 'Edit',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Delete',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    ),
  );
}

class CleanerManagementTile extends StatelessWidget {
  const CleanerManagementTile({
    super.key,
    required this.cleaner,
    required this.jobs,
    required this.onEdit,
    required this.onDelete,
  });
  final UserModel cleaner;
  final List<BookingModel> jobs;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final completed = jobs.where((item) => item.status == 'Completed').length;
    final pay = jobs.fold<double>(0, (sum, item) => sum + item.cleanerPay);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.cleaning_services, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cleaner.fullName,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      Text(
                        '${cleaner.phone} • ${money(cleaner.hourlyRate)}/hour',
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Edit',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: 'Delete',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                Chip(label: Text('${jobs.length} job(s)')),
                Chip(label: Text('$completed completed')),
                Chip(label: Text('${money(pay)} pay')),
                Chip(label: Text(cleaner.isActive ? 'Active' : 'Inactive')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showUserEditor(
  BuildContext context, {
  UserModel? user,
  String role = 'customer',
}) async {
  final name = TextEditingController(text: user?.fullName ?? '');
  final email = TextEditingController(text: user?.email ?? '');
  final phone = TextEditingController(text: user?.phone ?? '');
  final address = TextEditingController(text: user?.address ?? '');
  final rate = TextEditingController(text: '${user?.hourlyRate ?? 8}');
  var selectedRole = user?.role ?? role;
  var active = user?.isActive ?? true;
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(user == null ? 'Add user' : 'Edit user'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(controller: name, label: 'Full name'),
              const SizedBox(height: 10),
              CustomTextField(controller: email, label: 'Email'),
              const SizedBox(height: 10),
              CustomTextField(controller: phone, label: 'Phone'),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: selectedRole,
                decoration: const InputDecoration(labelText: 'Role'),
                items: const ['customer', 'cleaner', 'admin']
                    .map(
                      (item) =>
                          DropdownMenuItem(value: item, child: Text(item)),
                    )
                    .toList(),
                onChanged: (value) => setState(() => selectedRole = value!),
              ),
              const SizedBox(height: 10),
              CustomTextField(controller: address, label: 'Address'),
              const SizedBox(height: 10),
              CustomTextField(
                controller: rate,
                label: 'Hourly rate',
                keyboardType: TextInputType.number,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: active,
                title: const Text('Active'),
                onChanged: (value) => setState(() => active = value),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () async {
              final model = UserModel(
                id: user?.id,
                firebaseUid:
                    user?.firebaseUid ??
                    'admin-${email.text.trim().toLowerCase()}-${DateTime.now().millisecondsSinceEpoch}',
                fullName: name.text.trim().isEmpty
                    ? 'New User'
                    : name.text.trim(),
                email: email.text.trim(),
                phone: phone.text.trim(),
                role: selectedRole,
                address: address.text.trim(),
                hourlyRate: double.tryParse(rate.text) ?? 8,
                isActive: active,
                createdAt: user?.createdAt,
              );
              await context.read<AdminDataProvider>().saveUser(model);
              if (context.mounted) Navigator.pop(dialogContext);
            },
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save'),
          ),
        ],
      ),
    ),
  );
}

Future<void> showAddCleanerSheet(BuildContext context) async {
  final form = GlobalKey<FormState>();
  final name = TextEditingController();
  final email = TextEditingController();
  final phone = TextEditingController();
  final area = TextEditingController();
  final specialties = TextEditingController();

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: SafeArea(
            top: false,
            child: Form(
              key: form,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Add New Cleaner',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Close',
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _CleanerFormField(
                      controller: name,
                      label: 'Full Name',
                      hint: 'e.g. Jane Smith',
                      validator: (value) =>
                          Validators.required(value, 'Full name'),
                    ),
                    const SizedBox(height: 12),
                    _CleanerFormField(
                      controller: email,
                      label: 'Email Address',
                      hint: 'jane@example.com',
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.email,
                    ),
                    const SizedBox(height: 12),
                    _CleanerFormField(
                      controller: phone,
                      label: 'Phone Number',
                      hint: '+1 (555) 000-0000',
                      keyboardType: TextInputType.phone,
                      validator: Validators.phone,
                    ),
                    const SizedBox(height: 12),
                    _CleanerFormField(
                      controller: area,
                      label: 'Service Area',
                      hint: 'e.g. Manhattan, Brooklyn',
                      validator: (value) =>
                          Validators.required(value, 'Service area'),
                    ),
                    const SizedBox(height: 12),
                    _CleanerFormField(
                      controller: specialties,
                      label: 'Specialties (comma-separated)',
                      hint: 'Home Cleaning, Deep Cleaning',
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(sheetContext),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                if (!form.currentState!.validate()) return;
                                final model = UserModel(
                                  firebaseUid:
                                      'cleaner-${email.text.trim().toLowerCase()}-${DateTime.now().millisecondsSinceEpoch}',
                                  fullName: name.text.trim(),
                                  email: email.text.trim(),
                                  phone: phone.text.trim(),
                                  role: 'cleaner',
                                  address: area.text.trim(),
                                  hourlyRate: 12,
                                  isActive: true,
                                );
                                await context
                                    .read<AdminDataProvider>()
                                    .saveUser(model);
                                if (sheetContext.mounted) {
                                  Navigator.pop(sheetContext);
                                }
                              },
                              icon: const Icon(
                                Icons.person_add_alt_1,
                                size: 16,
                              ),
                              label: const Text('Add Cleaner'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                                backgroundColor: const Color(0xFF168BDB),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );

  name.dispose();
  email.dispose();
  phone.dispose();
  area.dispose();
  specialties.dispose();
}

Future<void> showEditCleanerSheet(
  BuildContext context, {
  required UserModel cleaner,
}) async {
  final adminData = context.read<AdminDataProvider>();
  final form = GlobalKey<FormState>();
  final name = TextEditingController(text: cleaner.fullName);
  final email = TextEditingController(text: cleaner.email);
  final phone = TextEditingController(text: cleaner.phone);
  final area = TextEditingController(text: cleaner.address);
  final rate = TextEditingController(
    text: cleaner.hourlyRate.toStringAsFixed(0),
  );
  final specialties = TextEditingController(
    text: 'Deep Cleaning, Move In/Out, Office',
  );
  var active = cleaner.isActive;

  final updatedCleaner = await showModalBottomSheet<UserModel>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: SafeArea(
            top: false,
            child: StatefulBuilder(
              builder: (context, setSheetState) => Form(
                key: form,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF168BDB), Color(0xFF4BA9E8)],
                          ),
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(22),
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.18,
                              ),
                              child: Text(
                                cleaner.fullName.isEmpty
                                    ? '?'
                                    : cleaner.fullName[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Edit Cleaner',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    'Update cleaner profile and availability',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton.filled(
                              tooltip: 'Close',
                              onPressed: () => Navigator.pop(sheetContext),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.18,
                                ),
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _CleanerFormField(
                              controller: name,
                              label: 'Full Name',
                              hint: 'e.g. Jane Smith',
                              validator: (value) =>
                                  Validators.required(value, 'Full name'),
                            ),
                            const SizedBox(height: 12),
                            _CleanerFormField(
                              controller: email,
                              label: 'Email Address',
                              hint: 'jane@example.com',
                              keyboardType: TextInputType.emailAddress,
                              validator: Validators.email,
                            ),
                            const SizedBox(height: 12),
                            _CleanerFormField(
                              controller: phone,
                              label: 'Phone Number',
                              hint: '+1 (555) 000-0000',
                              keyboardType: TextInputType.phone,
                              validator: Validators.phone,
                            ),
                            const SizedBox(height: 12),
                            _CleanerFormField(
                              controller: area,
                              label: 'Service Area',
                              hint: 'e.g. Manhattan, Brooklyn',
                              validator: (value) =>
                                  Validators.required(value, 'Service area'),
                            ),
                            const SizedBox(height: 12),
                            _CleanerFormField(
                              controller: specialties,
                              label: 'Specialties (comma-separated)',
                              hint: 'Home Cleaning, Deep Cleaning',
                            ),
                            const SizedBox(height: 12),
                            _CleanerFormField(
                              controller: rate,
                              label: 'Hourly Rate',
                              hint: '12',
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE6F0F8),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                value: active,
                                activeThumbColor: const Color(0xFF168BDB),
                                title: const Text(
                                  'Available for jobs',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13,
                                  ),
                                ),
                                subtitle: const Text(
                                  'Turn off to mark this cleaner as off duty.',
                                  style: TextStyle(fontSize: 11),
                                ),
                                onChanged: (value) =>
                                    setSheetState(() => active = value),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 48,
                                    child: OutlinedButton(
                                      onPressed: () =>
                                          Navigator.pop(sheetContext),
                                      style: OutlinedButton.styleFrom(
                                        minimumSize: const Size.fromHeight(48),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      child: const Text('Cancel'),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: SizedBox(
                                    height: 48,
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        if (!form.currentState!.validate()) {
                                          return;
                                        }
                                        final model = cleaner.copyWith(
                                          fullName: name.text.trim(),
                                          email: email.text.trim(),
                                          phone: phone.text.trim(),
                                          address: area.text.trim(),
                                          hourlyRate:
                                              double.tryParse(rate.text) ??
                                              cleaner.hourlyRate,
                                          isActive: active,
                                        );
                                        if (sheetContext.mounted) {
                                          Navigator.pop(sheetContext, model);
                                        }
                                      },
                                      icon: const Icon(
                                        Icons.save_outlined,
                                        size: 16,
                                      ),
                                      label: const Text('Save Changes'),
                                      style: ElevatedButton.styleFrom(
                                        minimumSize: const Size.fromHeight(48),
                                        backgroundColor: const Color(
                                          0xFF168BDB,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );

  await _waitForModalRouteToSettle();
  if (updatedCleaner != null && context.mounted) {
    await adminData.saveUser(updatedCleaner);
  }

  name.dispose();
  email.dispose();
  phone.dispose();
  area.dispose();
  rate.dispose();
  specialties.dispose();
}

class _CleanerFormField extends StatelessWidget {
  const _CleanerFormField({
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          color: Color(0xFF102A43),
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 6),
      TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF9AACBC), fontSize: 13),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFDDE6EE)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFDDE6EE)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF168BDB), width: 1.3),
          ),
        ),
      ),
    ],
  );
}

Future<void> showServiceEditor(
  BuildContext context, [
  ServiceModel? service,
]) async {
  final name = TextEditingController(text: service?.name ?? '');
  final category = TextEditingController(text: service?.category ?? '');
  final description = TextEditingController(text: service?.description ?? '');
  final price = TextEditingController(text: '${service?.basePrice ?? 25}');
  final duration = TextEditingController(
    text: '${service?.durationMinutes ?? 120}',
  );
  final cleaners = TextEditingController(
    text: '${service?.cleanersRequired ?? 1}',
  );
  final image = TextEditingController(
    text: service?.imageUrl ?? DemoImages.home,
  );
  var active = service?.isActive ?? true;
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(service == null ? 'Add service' : 'Edit service'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(controller: name, label: 'Service name'),
              const SizedBox(height: 10),
              CustomTextField(controller: category, label: 'Category'),
              const SizedBox(height: 10),
              CustomTextField(
                controller: description,
                label: 'Description',
                maxLines: 3,
              ),
              const SizedBox(height: 10),
              CustomTextField(
                controller: price,
                label: 'Base price',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              CustomTextField(
                controller: duration,
                label: 'Duration minutes',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              CustomTextField(
                controller: cleaners,
                label: 'Cleaners required',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              CustomTextField(controller: image, label: 'Image URL'),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: active,
                title: const Text('Active'),
                onChanged: (value) => setState(() => active = value),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () async {
              final model = ServiceModel(
                id: service?.id ?? 0,
                name: name.text.trim().isEmpty
                    ? 'New Service'
                    : name.text.trim(),
                category: category.text.trim().isEmpty
                    ? 'Cleaning'
                    : category.text.trim(),
                description: description.text.trim(),
                basePrice: double.tryParse(price.text) ?? 25,
                durationMinutes: int.tryParse(duration.text) ?? 120,
                imageUrl: image.text.trim().isEmpty
                    ? DemoImages.home
                    : image.text.trim(),
                rating: service?.rating ?? 4.5,
                cleanersRequired: int.tryParse(cleaners.text) ?? 1,
                isActive: active,
              );
              await context.read<ServiceProvider>().saveService(model);
              if (context.mounted) Navigator.pop(dialogContext);
            },
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save'),
          ),
        ],
      ),
    ),
  );
}

Future<void> showCleanerAssignment(
  BuildContext context,
  BookingModel booking,
) async {
  final admin = context.read<AuthProvider>().user!;
  final adminData = context.read<AdminDataProvider>();
  final bookingProvider = context.read<BookingProvider>();
  final availableCleaners = adminData.cleaners
      .where(
        (cleaner) => _cleanerIsAvailableForBooking(
          cleaner,
          booking,
          bookingProvider.bookings,
        ),
      )
      .toList();
  UserModel? assignedCleaner;
  String? assignmentError;
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Assign Cleaner',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        if (availableCleaners.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 28),
            child: EmptyStateWidget(
              title: 'No cleaner available',
              message: 'All active cleaners already have a job at this time.',
              icon: Icons.event_busy_outlined,
            ),
          ),
        for (final cleaner in availableCleaners)
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: AppColors.primary,
              child: Icon(Icons.cleaning_services, color: Colors.white),
            ),
            title: Text(cleaner.fullName),
            subtitle: Text(
              '${money(cleaner.hourlyRate)}/hour • estimated ${money(booking.estimatedDuration / 60 * cleaner.hourlyRate)}',
            ),
            trailing: booking.cleanerId == cleaner.id
                ? const Icon(Icons.check_circle, color: AppColors.primary)
                : null,
            onTap: () async {
              final navigator = Navigator.of(sheetContext);
              try {
                await bookingProvider.assignCleaner(booking, cleaner, admin);
                assignedCleaner = cleaner;
              } catch (error) {
                assignmentError = error.toString();
              }
              navigator.pop();
            },
          ),
      ],
    ),
  );
  if (assignmentError != null && context.mounted) {
    _showAdminToast(context, assignmentError!);
    return;
  }
  if (assignedCleaner != null && context.mounted) {
    _showAdminToast(
      context,
      '${assignedCleaner!.fullName} assigned to ${booking.serviceName}',
    );
  }
}

bool _cleanerIsAvailableForBooking(
  UserModel cleaner,
  BookingModel target,
  List<BookingModel> bookings,
) {
  if (!cleaner.isActive || cleaner.availabilityStatus != 'Available') {
    return false;
  }
  return !bookings.any(
    (existing) =>
        existing.id != target.id &&
        existing.cleanerId == cleaner.id &&
        !const ['Cancelled', 'Completed', 'Rejected'].contains(existing.status),
  );
}

void showExportSheet(BuildContext context, List<BookingModel> bookings) {
  var selectedType = _ReportExportType.daily;
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setSheetState) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Export Report',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Select a report type to export:',
                  style: TextStyle(color: Color(0xFF42566B), fontSize: 12),
                ),
                const SizedBox(height: 14),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.12,
                  children: [
                    for (final type in _ReportExportType.values)
                      _ExportReportTypeCard(
                        type: type,
                        selected: selectedType == type,
                        onTap: () => setSheetState(() => selectedType = type),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: OutlinedButton.icon(
                          onPressed: () => _exportAdminReport(
                            sheetContext,
                            bookings,
                            selectedType,
                            _ReportExportFormat.excel,
                          ),
                          icon: const Icon(
                            Icons.table_chart_outlined,
                            size: 17,
                          ),
                          label: const Text('Excel'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: ElevatedButton.icon(
                          onPressed: () => _exportAdminReport(
                            sheetContext,
                            bookings,
                            selectedType,
                            _ReportExportFormat.pdf,
                          ),
                          icon: const Icon(
                            Icons.picture_as_pdf_outlined,
                            size: 17,
                          ),
                          label: const Text('PDF'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1087DD),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

enum _ReportExportType { daily, monthly, income, performance }

enum _ReportExportFormat { pdf, excel }

extension _ReportExportTypeDetails on _ReportExportType {
  String get title => switch (this) {
    _ReportExportType.daily => 'Daily Report',
    _ReportExportType.monthly => 'Monthly Report',
    _ReportExportType.income => 'Income Report',
    _ReportExportType.performance => 'Performance Report',
  };

  String get description => switch (this) {
    _ReportExportType.daily => "Today's operations summary",
    _ReportExportType.monthly => 'June 2026 performance overview',
    _ReportExportType.income => 'Detailed financial breakdown',
    _ReportExportType.performance => 'Team & operational metrics',
  };

  String get fileSlug => switch (this) {
    _ReportExportType.daily => 'daily-report',
    _ReportExportType.monthly => 'monthly-report',
    _ReportExportType.income => 'income-report',
    _ReportExportType.performance => 'performance-report',
  };
}

class _ExportReportTypeCard extends StatelessWidget {
  const _ExportReportTypeCard({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final _ReportExportType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InteractiveSurface(
    borderRadius: 12,
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFEAF6FF) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? const Color(0xFF1087DD) : const Color(0xFFDDE6EE),
          width: selected ? 1.4 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.description_outlined,
            color: const Color(0xFF1087DD),
            size: 24,
          ),
          const Spacer(),
          Text(
            type.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            type.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF42566B), fontSize: 10),
          ),
        ],
      ),
    ),
  );
}

Future<void> _exportAdminReport(
  BuildContext context,
  List<BookingModel> bookings,
  _ReportExportType type,
  _ReportExportFormat format,
) async {
  try {
    final report = _buildExportReport(type, bookings);
    final date = DateFormat('yyyyMMdd').format(DateTime.now());
    switch (format) {
      case _ReportExportFormat.pdf:
        final bytes = await _buildReportPdf(report);
        downloadBytes(
          fileName: '${type.fileSlug}-$date.pdf',
          mimeType: 'application/pdf',
          bytes: bytes,
        );
      case _ReportExportFormat.excel:
        final bytes = Uint8List.fromList(
          utf8.encode(_buildReportExcel(report)),
        );
        downloadBytes(
          fileName: '${type.fileSlug}-$date.xls',
          mimeType: 'application/vnd.ms-excel',
          bytes: bytes,
        );
    }
    if (!context.mounted) return;
    Navigator.pop(context);
    _showAdminToast(context, '${type.title} exported');
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Export failed: $error')));
  }
}

class _ExportReportData {
  const _ExportReportData({
    required this.title,
    required this.subtitle,
    required this.summary,
    required this.headers,
    required this.rows,
  });

  final String title;
  final String subtitle;
  final Map<String, String> summary;
  final List<String> headers;
  final List<List<String>> rows;
}

_ExportReportData _buildExportReport(
  _ReportExportType type,
  List<BookingModel> bookings,
) {
  final data = bookings.isEmpty ? _demoAdminManagementBookings : bookings;
  final completed = data.where((item) => item.status == 'Completed').toList();
  final revenue = data
      .where((item) => item.status != 'Cancelled')
      .fold<double>(0, (sum, item) => sum + item.totalPrice);
  final cleanerPay = data.fold<double>(0, (sum, item) => sum + item.cleanerPay);
  final completionRate = data.isEmpty
      ? '0%'
      : '${(completed.length / data.length * 100).round()}%';
  final subtitle = DateFormat('MMM d, yyyy h:mm a').format(DateTime.now());
  final summary = <String, String>{
    'Bookings': '${data.length}',
    'Revenue': _adminMoney(revenue),
    'Cleaner Pay': _adminMoney(cleanerPay),
    'Complete': completionRate,
  };
  final headers = switch (type) {
    _ReportExportType.daily => const [
      'ID',
      'Service',
      'Customer',
      'Date',
      'Time',
      'Status',
      'Total',
    ],
    _ReportExportType.monthly => const [
      'Month',
      'Revenue',
      'Bookings',
      'Completion',
    ],
    _ReportExportType.income => const [
      'ID',
      'Service',
      'Total',
      'Cleaner Pay',
      'Net Income',
      'Status',
    ],
    _ReportExportType.performance => const [
      'Cleaner',
      'Jobs',
      'Completed',
      'Cleaner Pay',
      'Status',
    ],
  };
  final rows = switch (type) {
    _ReportExportType.daily => [
      for (final item in data)
        [
          '${item.id ?? '-'}',
          item.serviceName,
          item.customerName,
          item.bookingDate.split('T').first,
          item.bookingTime,
          item.status,
          _adminMoney(item.totalPrice),
        ],
    ],
    _ReportExportType.monthly => _monthlyExportRows(data),
    _ReportExportType.income => [
      for (final item in data)
        [
          '${item.id ?? '-'}',
          item.serviceName,
          _adminMoney(item.totalPrice),
          _adminMoney(item.cleanerPay),
          _adminMoney(item.totalPrice - item.cleanerPay),
          item.status,
        ],
    ],
    _ReportExportType.performance => _performanceExportRows(data),
  };
  return _ExportReportData(
    title: type.title,
    subtitle: 'Generated $subtitle',
    summary: summary,
    headers: headers,
    rows: rows,
  );
}

List<List<String>> _monthlyExportRows(List<BookingModel> bookings) {
  const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
  return [
    for (var month = 1; month <= 6; month++)
      [
        monthNames[month - 1],
        _adminMoney(
          bookings
              .where(
                (item) => DateTime.tryParse(item.bookingDate)?.month == month,
              )
              .fold<double>(0, (sum, item) => sum + item.totalPrice),
        ),
        '${bookings.where((item) => DateTime.tryParse(item.bookingDate)?.month == month).length}',
        '${_monthlyCompletionRate(bookings, month)}%',
      ],
  ];
}

int _monthlyCompletionRate(List<BookingModel> bookings, int month) {
  final monthly = bookings
      .where((item) => DateTime.tryParse(item.bookingDate)?.month == month)
      .toList();
  if (monthly.isEmpty) return 0;
  return (monthly.where((item) => item.status == 'Completed').length /
          monthly.length *
          100)
      .round();
}

List<List<String>> _performanceExportRows(List<BookingModel> bookings) {
  final cleanerNames = {
    for (final item in bookings)
      if (item.cleanerName.isNotEmpty) item.cleanerName,
  };
  if (cleanerNames.isEmpty) {
    return const [
      ['Unassigned', '0', '0', r'$0', 'No assigned jobs'],
    ];
  }
  return [
    for (final cleaner in cleanerNames)
      [
        cleaner,
        '${bookings.where((item) => item.cleanerName == cleaner).length}',
        '${bookings.where((item) => item.cleanerName == cleaner && item.status == 'Completed').length}',
        _adminMoney(
          bookings
              .where((item) => item.cleanerName == cleaner)
              .fold<double>(0, (sum, item) => sum + item.cleanerPay),
        ),
        'Active',
      ],
  ];
}

Future<Uint8List> _buildReportPdf(_ExportReportData report) async {
  final document = pw.Document();
  document.addPage(
    pw.MultiPage(
      build: (context) => [
        pw.Text(
          report.title,
          style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        pw.Text(report.subtitle),
        pw.SizedBox(height: 16),
        pw.Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final entry in report.summary.entries)
              pw.Container(
                width: 120,
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(entry.key, style: const pw.TextStyle(fontSize: 9)),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      entry.value,
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ),
          ],
        ),
        pw.SizedBox(height: 18),
        pw.TableHelper.fromTextArray(
          headers: report.headers,
          data: report.rows,
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          cellStyle: const pw.TextStyle(fontSize: 9),
          cellAlignment: pw.Alignment.centerLeft,
          headerDecoration: const pw.BoxDecoration(),
        ),
      ],
    ),
  );
  return document.save();
}

String _buildReportExcel(_ExportReportData report) {
  final buffer = StringBuffer()
    ..writeln('<html><head><meta charset="utf-8"></head><body>')
    ..writeln('<h2>${_escapeHtml(report.title)}</h2>')
    ..writeln('<p>${_escapeHtml(report.subtitle)}</p>')
    ..writeln('<table border="1">');
  for (final entry in report.summary.entries) {
    buffer.writeln(
      '<tr><th>${_escapeHtml(entry.key)}</th><td>${_escapeHtml(entry.value)}</td></tr>',
    );
  }
  buffer
    ..writeln('</table><br>')
    ..writeln('<table border="1"><tr>');
  for (final header in report.headers) {
    buffer.write('<th>${_escapeHtml(header)}</th>');
  }
  buffer.writeln('</tr>');
  for (final row in report.rows) {
    buffer.writeln('<tr>');
    for (final cell in row) {
      buffer.write('<td>${_escapeHtml(cell)}</td>');
    }
    buffer.writeln('</tr>');
  }
  buffer.writeln('</table></body></html>');
  return buffer.toString();
}

String _escapeHtml(String value) => value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;');

void requireLogin(BuildContext context, VoidCallback action) {
  if (context.read<AuthProvider>().loggedIn) {
    action();
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please log in before continuing.')),
    );
    Navigator.pushNamed(context, LoginScreen.route);
  }
}
