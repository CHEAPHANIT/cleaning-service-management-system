part of '../screens.dart';

class CleanerDashboardScreen extends StatefulWidget {
  const CleanerDashboardScreen({super.key});

  @override
  State<CleanerDashboardScreen> createState() => _CleanerDashboardScreenState();
}

class _CleanerDashboardScreenState extends State<CleanerDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<BookingProvider>();
    final sourceJobs = provider.bookings;
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
                  if (jobs.isEmpty)
                    const EmptyStateWidget(
                      title: 'No assigned jobs',
                      message: 'Your assigned jobs will appear here.',
                      icon: Icons.work_outline_rounded,
                    )
                  else
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
            _AppLogoMark(size: 30),
            SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.appName,
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
    return context.watch<BookingProvider>().bookings;
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

class CleanerProfileScreen extends StatefulWidget {
  const CleanerProfileScreen({super.key});

  @override
  State<CleanerProfileScreen> createState() => _CleanerProfileScreenState();
}

class _CleanerProfileScreenState extends State<CleanerProfileScreen> {
  int? loadedCleanerId;
  List<ReviewModel> reviews = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final cleanerId = context.read<AuthProvider>().user?.id;
    if (cleanerId == null || cleanerId == loadedCleanerId) return;
    loadedCleanerId = cleanerId;
    unawaited(_loadReviews(cleanerId));
  }

  Future<void> _loadReviews(int cleanerId) async {
    try {
      final items = await context
          .read<BookingProvider>()
          .database
          .reviewsForCleaner(cleanerId);
      if (mounted && loadedCleanerId == cleanerId) {
        setState(() => reviews = items);
      }
    } catch (_) {
      if (mounted && loadedCleanerId == cleanerId) {
        setState(() => reviews = []);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user!;
    final jobs = context.watch<BookingProvider>().bookings;
    final completed = jobs
        .where((booking) => booking.status == 'Completed')
        .toList();
    final completedCount = completed.length;
    final earned = completed.fold<double>(
      0,
      (sum, booking) => sum + booking.cleanerPay,
    );
    final finishedCount = jobs
        .where(
          (booking) => const [
            'Completed',
            'Cancelled',
            'Rejected',
          ].contains(booking.status),
        )
        .length;
    final successRate = finishedCount == 0
        ? 0
        : (completedCount / finishedCount * 100).round();
    final averageRating = reviews.isEmpty
        ? null
        : reviews.fold<int>(0, (sum, review) => sum + review.rating) /
              reviews.length;

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
                          Row(
                            children: [
                              Icon(
                                Icons.star,
                                color: averageRating == null
                                    ? Colors.white54
                                    : Colors.white,
                                size: 15,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                averageRating?.toStringAsFixed(1) ?? '—',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  '(${reviews.length} ${reviews.length == 1 ? 'review' : 'reviews'})',
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
                        value: '$completedCount',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _CleanerHeroMetric(
                        icon: Icons.star_outline,
                        label: 'Average Rating',
                        value: averageRating?.toStringAsFixed(1) ?? '—',
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
                        value: money(earned),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _CleanerPerformanceCard(
                        icon: Icons.workspace_premium_outlined,
                        iconColor: Color(0xFF8B5CF6),
                        label: 'Success Rate',
                        value: '$successRate%',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const _CleanerProfileTitle('Achievements'),
                if (completedCount == 0)
                  const Text(
                    'Complete your first assigned job to earn achievements.',
                    style: TextStyle(color: AppColors.muted, fontSize: 11),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: _CleanerAchievementCard(
                          icon: Icons.emoji_events_outlined,
                          color: const Color(0xFFFFB020),
                          title: 'First Job',
                          description: 'Completed the first job',
                        ),
                      ),
                      if (completedCount >= 10) ...[
                        const SizedBox(width: 8),
                        const Expanded(
                          child: _CleanerAchievementCard(
                            icon: Icons.calendar_today_outlined,
                            color: Color(0xFF3B82F6),
                            title: '10 Jobs',
                            description: 'Completed 10+ jobs',
                          ),
                        ),
                      ],
                      if (averageRating != null &&
                          averageRating >= 4.8 &&
                          reviews.length >= 5) ...[
                        const SizedBox(width: 8),
                        const Expanded(
                          child: _CleanerAchievementCard(
                            icon: Icons.star_outline,
                            color: Color(0xFF8B5CF6),
                            title: 'Top Rated',
                            description: '4.8+ from 5 reviews',
                          ),
                        ),
                      ],
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
                            ? 'No service area set'
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
                if (reviews.isEmpty)
                  const Text(
                    'No customer reviews yet.',
                    style: TextStyle(color: AppColors.muted, fontSize: 11),
                  )
                else
                  for (final review in reviews.take(3))
                    _CleanerPortalReviewCard(
                      customer: _cleanerReviewCustomer(review, jobs),
                      date: _cleanerReviewDate(review),
                      rating: review.rating,
                      comment: review.comment.isEmpty
                          ? 'No written comment.'
                          : review.comment,
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

String _cleanerReviewCustomer(ReviewModel review, List<BookingModel> jobs) =>
    jobs
        .where((booking) => booking.id == review.bookingId)
        .map((booking) => booking.customerName)
        .firstOrNull ??
    'Customer';

String _cleanerReviewDate(ReviewModel review) {
  final date = DateTime.tryParse(review.createdAt ?? '');
  return date == null
      ? 'Date unavailable'
      : DateFormat('MMM d, y').format(date);
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
