part of '../screens.dart';

class AdminServiceManagementScreen extends StatelessWidget {
  const AdminServiceManagementScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final services = context.watch<ServiceProvider>().services;
    return Scaffold(
      backgroundColor: Colors.white,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
        children: [
          _AdminPageTop(
            user: context.watch<AuthProvider>().user,
            title: 'Manage Services',
            subtitle: 'Review and update cleaning service packages.',
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () => showServiceEditor(context),
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: const Text('Add service'),
            ),
          ),
          const SizedBox(height: 14),
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
      final sourceBookings = visibleBookings;
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
        backgroundColor: Colors.white,
        body: provider.loading
            ? const LoadingWidget()
            : RefreshIndicator(
                onRefresh: () => provider.loadForRole(auth.user),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
                  children: [
                    _AdminPageTop(
                      user: auth.user,
                      title: 'Booking Management',
                      subtitle:
                          'Manage assignments, statuses, and service flow.',
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
                      EmptyStateWidget(
                        title: sourceBookings.isEmpty
                            ? 'No bookings yet'
                            : 'No matching bookings',
                        message: sourceBookings.isEmpty
                            ? 'New customer bookings will appear here for review and cleaner assignment.'
                            : 'Try another search term or choose a different status.',
                        icon: sourceBookings.isEmpty
                            ? Icons.event_note_outlined
                            : Icons.manage_search_outlined,
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
    final bookings = liveBookings;
    final completed = bookings.where((item) => item.status == 'Completed');
    final liveRevenue = completed.fold<double>(
      0,
      (sum, item) => sum + item.totalPrice,
    );
    final totalRevenue = liveRevenue;
    final customers = adminData.users
        .where((item) => item.role == 'customer')
        .length;
    final activeCleaners = adminData.cleaners
        .where((item) => item.isActive)
        .length;
    final performers = _adminPerformers(
      adminData.cleaners,
      liveBookings,
      adminData.cleanerReviews,
    );
    return Scaffold(
      backgroundColor: Colors.white,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
        children: [
          _AdminPageTop(
            user: context.watch<AuthProvider>().user,
            title: 'Reports & Analytics',
            subtitle: 'Business insights, revenue, and cleaner performance.',
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              height: 38,
              child: ElevatedButton.icon(
                onPressed: () => _showExportSheet(context, bookings),
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
                  trend: 'Completed jobs',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ReportMetricCard(
                  icon: Icons.calendar_today_outlined,
                  iconColor: const Color(0xFF2F80ED),
                  label: 'Total Bookings',
                  value: '${bookings.length}',
                  trend: 'Live data',
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
                  value: NumberFormat.decimalPattern().format(customers),
                  trend: 'Live data',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ReportMetricCard(
                  icon: Icons.person_search_outlined,
                  iconColor: const Color(0xFFFF6A00),
                  label: 'Active Cleaners',
                  value: '$activeCleaners',
                  trend: 'Live data',
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
          if (performers.isEmpty)
            const _AdminDashboardEmpty(
              message: 'No cleaner has completed a job yet.',
            )
          else
            _AdminPerformerList(performers: performers),
          const SizedBox(height: 18),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.7,
            children: [
              _ReportShortcutCard(
                label: 'Daily Report',
                onTap: () => _showExportSheet(
                  context,
                  bookings,
                  initialType: _ReportExportType.daily,
                ),
              ),
              _ReportShortcutCard(
                label: 'Monthly Report',
                onTap: () => _showExportSheet(
                  context,
                  bookings,
                  initialType: _ReportExportType.monthly,
                ),
              ),
              _ReportShortcutCard(
                label: 'Income Report',
                onTap: () => _showExportSheet(
                  context,
                  bookings,
                  initialType: _ReportExportType.income,
                ),
              ),
              _ReportShortcutCard(
                label: 'Performance',
                onTap: () => _showExportSheet(
                  context,
                  bookings,
                  initialType: _ReportExportType.performance,
                ),
              ),
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
  const _ReportShortcutCard({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InteractiveSurface(
    borderRadius: 10,
    lift: 2,
    onTap: onTap,
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
