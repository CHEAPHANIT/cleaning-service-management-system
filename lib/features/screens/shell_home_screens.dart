part of '../screens.dart';

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
