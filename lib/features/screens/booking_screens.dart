part of '../screens.dart';

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
    final liveBookings = context.watch<BookingProvider>().bookings;
    final currentBooking = liveBookings
        .where((item) => item.id == this.booking.id)
        .firstOrNull;
    final booking = currentBooking ?? this.booking;
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'No cleaner assigned',
              style: TextStyle(
                color: Color(0xFF5E7388),
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
            if (booking.status == 'Pending' ||
                booking.status == 'Accepted') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => showCleanerAssignment(context, booking),
                  icon: const Icon(Icons.person_add_alt_1, size: 18),
                  label: const Text('Choose Available Cleaner'),
                ),
              ),
              if (booking.status == 'Pending') ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _rejectBookingFromDetails(context, booking),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text('Reject Booking'),
                  ),
                ),
              ],
            ],
          ],
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

Future<void> _rejectBookingFromDetails(
  BuildContext context,
  BookingModel booking,
) async {
  final admin = context.read<AuthProvider>().user;
  if (admin == null) return;
  try {
    await context.read<BookingProvider>().updateStatus(
      booking,
      'Rejected',
      admin,
    );
    if (context.mounted) _showAdminToast(context, 'Booking rejected');
  } catch (error) {
    if (context.mounted) _showAdminToast(context, error.toString());
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
