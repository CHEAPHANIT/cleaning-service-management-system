part of '../screens.dart';

class FavoriteScreen extends StatelessWidget {
  const FavoriteScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoriteProvider>().favorites;
    final services = context.watch<ServiceProvider>().services;
    final userId = context.watch<AuthProvider>().user?.id;
    return Scaffold(
      backgroundColor: Colors.white,
      body: favorites.isEmpty
          ? const Column(
              children: [
                _MobilePageTopBar(
                  title: 'Favorites',
                  subtitle: 'Your saved services in one place.',
                  showBack: true,
                  showBrand: false,
                ),
                Expanded(
                  child: EmptyStateWidget(
                    title: 'No favorites',
                    message: 'Tap the heart on any service to save it.',
                    icon: Icons.favorite_border,
                  ),
                ),
              ],
            )
          : ListView(
              padding: EdgeInsets.zero,
              children: [
                const _MobilePageTopBar(
                  title: 'Favorites',
                  subtitle: 'Your saved services in one place.',
                  showBack: true,
                  showBrand: false,
                ),
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
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const _MobilePageTopBar(
            title: 'Cleaning Add-ons',
            subtitle: 'Supplies and extras for a better service.',
            showBack: true,
            showBrand: false,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
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
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
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
      backgroundColor: Colors.white,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _MobilePageTopBar(
            title: product.title,
            subtitle: product.category,
            showBack: true,
            showBrand: false,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 260,
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F7FB),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Image.network(product.imageUrl, fit: BoxFit.contain),
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
      backgroundColor: Colors.white,
      body: items.isEmpty
          ? const Column(
              children: [
                _MobilePageTopBar(
                  title: 'Notifications',
                  subtitle: 'Booking updates and service alerts.',
                  showBack: true,
                  showBrand: false,
                ),
                Expanded(
                  child: EmptyStateWidget(
                    title: 'No notifications',
                    message: 'Booking updates will appear here.',
                    icon: Icons.notifications_none,
                  ),
                ),
              ],
            )
          : ListView(
              padding: EdgeInsets.zero,
              children: [
                const _MobilePageTopBar(
                  title: 'Notifications',
                  subtitle: 'Booking updates and service alerts.',
                  showBack: true,
                  showBrand: false,
                ),
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
                    trailing: _isCleanerApplicationNotification(context, item)
                        ? const Icon(Icons.chevron_right_rounded)
                        : null,
                    onTap: _isCleanerApplicationNotification(context, item)
                        ? () => _openCleanerApplication(context, item)
                        : null,
                  ),
              ],
            ),
    );
  }

  bool _isCleanerApplicationNotification(
    BuildContext context,
    NotificationModel item,
  ) =>
      context.read<AuthProvider>().user?.role == 'admin' &&
      item.title.toLowerCase() == 'cleaner application';

  Future<void> _openCleanerApplication(
    BuildContext context,
    NotificationModel notification,
  ) async {
    final provider = context.read<AdminDataProvider>();
    await provider.load();
    if (!context.mounted) return;

    CleanerApplicationModel? matchingApplication;
    for (final application in provider.cleanerApplications) {
      if (notification.message ==
          '${application.fullName} applied to join CleanNow.') {
        matchingApplication = application;
        break;
      }
    }
    if (matchingApplication != null) {
      await Navigator.pushNamed(
        context,
        AdminCleanerApplicationDetailScreen.route,
        arguments: matchingApplication,
      );
    } else {
      await Navigator.pushNamed(context, AdminCleanerApplicationsScreen.route);
    }
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
