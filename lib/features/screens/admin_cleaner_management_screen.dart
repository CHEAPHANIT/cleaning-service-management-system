part of '../screens.dart';

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
    final cleaners = sourceCleaners;
    final query = searchController.text.trim().toLowerCase();
    final pendingApplications = provider.cleanerApplications.where((item) {
      if (item.status != 'pending') return false;
      return query.isEmpty ||
          item.fullName.toLowerCase().contains(query) ||
          item.email.toLowerCase().contains(query) ||
          item.phone.toLowerCase().contains(query) ||
          item.address.toLowerCase().contains(query);
    }).toList();
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
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: provider.load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
          children: [
            _AdminPageTop(
              user: context.watch<AuthProvider>().user,
              title: 'Cleaner Management',
              subtitle: 'Manage cleaning staff, availability, and assignments.',
            ),
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 132,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: () => showAddCleanerSheet(context),
                  icon: const Icon(Icons.person_add_alt_1, size: 16),
                  label: const Text(
                    'Add Cleaner',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(132, 46),
                    backgroundColor: const Color(0xFF168BDB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
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
            if (pendingApplications.isNotEmpty) ...[
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Pending applications',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  StatusBadge('${pendingApplications.length} pending'),
                ],
              ),
              const SizedBox(height: 10),
              for (final application in pendingApplications) ...[
                _PendingCleanerApplicationCard(application: application),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 6),
              const Text(
                'Cleaning staff',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
            ],
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
                  reviews: provider.cleanerReviews[cleaner.id] ?? const [],
                  onEdit: () => showCleanerDetailSheet(
                    context,
                    cleaner: cleaner,
                    jobs: bookings
                        .where((item) => item.cleanerId == cleaner.id)
                        .toList(),
                    reviews: provider.cleanerReviews[cleaner.id] ?? const [],
                  ),
                  onAssign: () => _showAssignableBookings(context, cleaner),
                ),
          ],
        ),
      ),
    );
  }
}

class _PendingCleanerApplicationCard extends StatelessWidget {
  const _PendingCleanerApplicationCard({required this.application});

  final CleanerApplicationModel application;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFF8FBFE),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => Navigator.pushNamed(
            context,
            AdminCleanerApplicationDetailScreen.route,
            arguments: application,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: Icon(
                    Icons.cleaning_services_outlined,
                    color: Colors.white,
                  ),
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
                        '${application.email} • ${application.phone}',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  try {
                    await context
                        .read<AdminDataProvider>()
                        .approveCleanerApplication(application);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${application.fullName} has been approved as a cleaner.',
                        ),
                        backgroundColor: const Color(0xFF15966A),
                      ),
                    );
                  } catch (error) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(_cleanerApplicationError(error)),
                        backgroundColor: const Color(0xFFC43D3D),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.check_rounded, size: 18),
                label: const Text('Approve'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  try {
                    await context
                        .read<AdminDataProvider>()
                        .rejectCleanerApplication(application);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${application.fullName} has been rejected.',
                        ),
                      ),
                    );
                  } catch (error) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(_cleanerApplicationError(error)),
                        backgroundColor: const Color(0xFFC43D3D),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.close_rounded, size: 18),
                label: const Text('Reject'),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

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
    required this.reviews,
    required this.onEdit,
    required this.onAssign,
  });

  final UserModel cleaner;
  final List<BookingModel> jobs;
  final List<ReviewModel> reviews;
  final VoidCallback onEdit;
  final VoidCallback onAssign;

  @override
  Widget build(BuildContext context) {
    final stats = _cleanerDisplayStats(jobs, reviews);
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
                Icon(
                  Icons.star_rounded,
                  color: stats.rating == null
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFFFFB000),
                  size: 16,
                ),
                const SizedBox(width: 2),
                Text(
                  stats.rating?.toStringAsFixed(1) ?? '—',
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
            _CleanerInfoRow(icon: Icons.phone_outlined, text: cleaner.phone),
            const SizedBox(height: 8),
            _CleanerInfoRow(
              icon: Icons.location_on_outlined,
              text: cleaner.address.isEmpty
                  ? 'No service area set'
                  : cleaner.address,
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFE1E9F0)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _CleanerMetric(
                    icon: Icons.calendar_today_outlined,
                    value: '${stats.completed}',
                    label: 'Completed',
                  ),
                ),
                Expanded(
                  child: _CleanerMetric(
                    icon: Icons.check_circle_outline,
                    value: '${stats.successRate}%',
                    label: 'Success',
                  ),
                ),
                Expanded(
                  child: _CleanerMetric(
                    icon: Icons.attach_money,
                    value: _adminMoney(stats.earnings),
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
  final bookings = liveBookings;

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
  required List<ReviewModel> reviews,
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
          final stats = _cleanerDisplayStats(jobs, reviews);
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
                                ? 'No service area set'
                                : cleaner.address,
                          ),
                          (
                            Icons.calendar_today_outlined,
                            cleaner.createdAt == null
                                ? 'Join date unavailable'
                                : 'Joined ${prettyDate(DateTime.parse(cleaner.createdAt!))}',
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const _AdminDashboardTitle('Recent Reviews'),
                      const SizedBox(height: 10),
                      if (reviews.isEmpty)
                        const Text(
                          'No customer reviews yet.',
                          style: TextStyle(color: AppColors.muted),
                        )
                      else
                        for (final review in reviews.take(3)) ...[
                          _CleanerReviewCard(
                            name: _reviewCustomerName(review, jobs),
                            text: review.comment.isEmpty
                                ? '${review.rating}-star rating'
                                : review.comment,
                          ),
                          const SizedBox(height: 8),
                        ],
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pop(
                            sheetContext,
                            _CleanerDetailAction.deactivate,
                          ),
                          icon: const Icon(Icons.delete_outline, size: 16),
                          label: const Text('Deactivate'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.danger,
                            side: const BorderSide(color: Color(0xFFFFB8B8)),
                            minimumSize: const Size.fromHeight(44),
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
          );
        },
      ),
    ),
  );

  if (!parentContext.mounted) return;
  switch (action) {
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

enum _CleanerDetailAction { deactivate }

Future<void> _waitForModalRouteToSettle() async {
  await WidgetsBinding.instance.endOfFrame;
  await Future<void>.delayed(const Duration(milliseconds: 350));
}

({int completed, double earnings, double? rating, int successRate})
_cleanerDisplayStats(List<BookingModel> jobs, List<ReviewModel> reviews) {
  final completed = jobs.where((item) => item.status == 'Completed').length;
  final finished = jobs
      .where(
        (item) =>
            const ['Completed', 'Cancelled', 'Rejected'].contains(item.status),
      )
      .length;
  final earnings = jobs
      .where((item) => item.status == 'Completed')
      .fold<double>(0, (sum, item) => sum + item.cleanerPay);
  final rating = reviews.isEmpty
      ? null
      : reviews.fold<int>(0, (sum, review) => sum + review.rating) /
            reviews.length;
  return (
    completed: completed,
    earnings: earnings,
    rating: rating,
    successRate: finished == 0 ? 0 : (completed / finished * 100).round(),
  );
}

String _reviewCustomerName(ReviewModel review, List<BookingModel> jobs) =>
    jobs
        .where((booking) => booking.id == review.bookingId)
        .map((booking) => booking.customerName)
        .firstOrNull ??
    'Customer';

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
  final ({int completed, double earnings, double? rating, int successRate})
  stats;
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
                      Icon(
                        Icons.star_rounded,
                        color: stats.rating == null
                            ? Colors.white54
                            : const Color(0xFFFFD43B),
                        size: 16,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        stats.rating == null
                            ? 'No rating yet'
                            : '${stats.rating!.toStringAsFixed(1)} rating',
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
            Expanded(
              child: _CleanerDetailStat(
                value: '${stats.successRate}%',
                label: 'Success',
              ),
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
