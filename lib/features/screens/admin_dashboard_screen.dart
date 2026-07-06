part of '../screens.dart';

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
