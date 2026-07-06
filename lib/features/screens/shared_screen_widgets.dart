part of '../screens.dart';

class _AppLogoMark extends StatelessWidget {
  const _AppLogoMark({
    this.size = 42,
    this.primary = AppColors.primary,
    this.secondary = const Color(0xFF32D29B),
    this.foreground = Colors.white,
    this.showShadow = false,
  });

  final double size;
  final Color primary;
  final Color secondary;
  final Color foreground;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    final iconSize = size * 0.48;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        gradient: LinearGradient(
          colors: [primary, secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: primary.withValues(alpha: 0.28),
                  blurRadius: size * 0.28,
                  offset: Offset(0, size * 0.12),
                ),
              ]
            : null,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: size * 0.15,
            right: size * 0.16,
            child: Container(
              width: size * 0.18,
              height: size * 0.18,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.34),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: size * 0.15,
            bottom: size * 0.15,
            child: Container(
              width: size * 0.28,
              height: size * 0.09,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Center(
            child: Icon(
              Icons.cleaning_services_rounded,
              color: foreground,
              size: iconSize,
            ),
          ),
          Positioned(
            right: -size * 0.03,
            top: -size * 0.04,
            child: Container(
              width: size * 0.34,
              height: size * 0.34,
              decoration: BoxDecoration(
                color: foreground,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.65),
                  width: size * 0.03,
                ),
              ),
              child: Icon(
                Icons.auto_awesome_rounded,
                color: secondary,
                size: size * 0.18,
              ),
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
