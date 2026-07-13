part of '../screens.dart';

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
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: provider.load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
          children: [
            _AdminPageTop(
              user: context.watch<AuthProvider>().user,
              title: 'Customer Management',
              subtitle: 'Manage customer accounts and booking history.',
            ),
            const SizedBox(height: 18),
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

class AdminCleanerApplicationsScreen extends StatelessWidget {
  const AdminCleanerApplicationsScreen({super.key});
  static const route = '/admin/cleaner-applications';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminDataProvider>();
    final applications = provider.cleanerApplications;
    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: provider.load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          children: [
            _AdminPageTop(
              user: context.watch<AuthProvider>().user,
              title: 'Cleaner Applications',
              subtitle: 'Review cleaner requests and approval status.',
            ),
            const SizedBox(height: 18),
            if (applications.isEmpty)
              const EmptyStateWidget(
                title: 'No applications',
                message: 'New cleaner applications will appear here.',
                icon: Icons.assignment_ind_outlined,
              )
            else
              for (final application in applications) ...[
                _CleanerApplicationCard(application: application),
                const SizedBox(height: 12),
              ],
          ],
        ),
      ),
    );
  }
}

class _CleanerApplicationCard extends StatelessWidget {
  const _CleanerApplicationCard({required this.application});

  final CleanerApplicationModel application;

  @override
  Widget build(BuildContext context) => InteractiveSurface(
    borderRadius: 12,
    onTap: () => Navigator.pushNamed(
      context,
      AdminCleanerApplicationDetailScreen.route,
      arguments: application,
    ),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: AppColors.primary,
            child: Icon(Icons.cleaning_services_outlined, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  application.fullName,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  application.email,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          StatusBadge(application.status),
        ],
      ),
    ),
  );
}

class AdminCleanerApplicationDetailScreen extends StatelessWidget {
  const AdminCleanerApplicationDetailScreen({super.key});
  static const route = '/admin/cleaner-applications/detail';

  @override
  Widget build(BuildContext context) {
    final argument = ModalRoute.of(context)?.settings.arguments;
    final application = argument is CleanerApplicationModel ? argument : null;
    if (application == null) {
      return const Scaffold(
        body: EmptyStateWidget(
          title: 'Application not found',
          message: 'Open an application from the admin list.',
          icon: Icons.assignment_late_outlined,
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Application Detail')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        children: [
          _ApplicationDetailRow('Full name', application.fullName),
          _ApplicationDetailRow('Email', application.email),
          _ApplicationDetailRow('Phone', application.phone),
          _ApplicationDetailRow('Gender', application.gender),
          _ApplicationDetailRow('Address', application.address),
          _ApplicationDetailRow('Experience', application.workExperience),
          _ApplicationDetailRow('Skills', application.skills),
          _ApplicationDetailRow('Available days', application.availableDays),
          _ApplicationDetailRow('Available time', application.availableTime),
          _ApplicationDocumentRow(
            label: 'Profile photo',
            value: application.profilePhoto,
            fallbackIcon: Icons.person_outline_rounded,
          ),
          _ApplicationDocumentRow(
            label: 'ID document',
            value: application.idDocument,
            fallbackIcon: Icons.badge_outlined,
          ),
          const SizedBox(height: 12),
          if (application.status == 'pending')
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await context
                          .read<AdminDataProvider>()
                          .approveCleanerApplication(application);
                      if (context.mounted) Navigator.pop(context);
                    },
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Approve'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await context
                          .read<AdminDataProvider>()
                          .rejectCleanerApplication(application);
                      if (context.mounted) Navigator.pop(context);
                    },
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Reject'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ApplicationDetailRow extends StatelessWidget {
  const _ApplicationDetailRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.muted, fontSize: 11),
        ),
        const SizedBox(height: 4),
        Text(
          value.isEmpty ? '-' : value,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}

class _ApplicationDocumentRow extends StatelessWidget {
  const _ApplicationDocumentRow({
    required this.label,
    required this.value,
    required this.fallbackIcon,
  });

  final String label;
  final String value;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    Uint8List? bytes;
    if (value.startsWith('data:')) {
      try {
        bytes = base64Decode(value.split(',').last);
      } catch (_) {}
    }
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 72,
              height: 72,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF6FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: bytes == null
                  ? Icon(fallbackIcon, color: AppColors.primary, size: 30)
                  : Image.memory(bytes, fit: BoxFit.cover),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value.isEmpty
                        ? 'Not provided'
                        : bytes == null
                        ? value
                        : 'Image uploaded',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            if (bytes != null)
              const Icon(Icons.verified_rounded, color: Colors.green),
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
