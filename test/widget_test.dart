import 'package:clean_now/core/utils.dart';
import 'package:clean_now/data/local/database_helper.dart';
import 'package:clean_now/data/models/models.dart';
import 'package:clean_now/data/providers/app_providers.dart';
import 'package:clean_now/data/repositories/repositories.dart';
import 'package:clean_now/features/screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('booking price calculation includes extras and size charges', () {
    final total = PriceCalculator.total(25, 4, 2, [
      'Inside fridge cleaning',
      'Window cleaning',
    ]);

    expect(total, 51);
  });

  testWidgets('customer can select optional services while booking', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final database = DatabaseHelper();
    final auth = AuthProvider(AuthRepository(false), database)
      ..initialized = true
      ..user = const UserModel(
        id: 10,
        firebaseUid: 'extras-customer',
        fullName: 'Extras Customer',
        email: 'extras@example.com',
        phone: '+855 12 345 678',
      );
    final services = ServiceProvider(ServiceRepository(database))
      ..services = const [
        ServiceModel(
          id: 1,
          name: 'Basic Home Cleaning',
          category: 'Home Cleaning',
          description: 'Home cleaning test service',
          basePrice: 25,
          durationMinutes: 120,
          imageUrl: '',
          rating: 4.5,
          cleanersRequired: 1,
        ),
      ];

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
          ChangeNotifierProvider<ServiceProvider>.value(value: services),
          ChangeNotifierProvider(create: (_) => BookingProvider(database)),
        ],
        child: const MaterialApp(home: BookingFormScreen()),
      ),
    );

    await tester.tap(find.text('Basic Home Cleaning'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    final extra = find.byKey(
      const ValueKey('booking-extra-Inside fridge cleaning'),
    );
    await tester.ensureVisible(extra);
    expect(tester.widget<CheckboxListTile>(extra).value, isFalse);

    await tester.tap(extra);
    await tester.pumpAndSettle();

    expect(tester.widget<CheckboxListTile>(extra).value, isTrue);
    expect(find.text(r'+$5'), findsOneWidget);
  });

  testWidgets('protected booking route redirects signed-out users', (
    tester,
  ) async {
    final database = DatabaseHelper();
    final auth = AuthProvider(AuthRepository(false), database)
      ..initialized = true;

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: auth,
        child: MaterialApp(
          routes: {
            BookingFormScreen.route: appRoutes[BookingFormScreen.route]!,
            LoginScreen.route: (_) => const Scaffold(
              body: Center(child: Text('Sign in destination')),
            ),
          },
          initialRoute: BookingFormScreen.route,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sign in destination'), findsOneWidget);
    expect(find.text('New Booking'), findsNothing);
  });

  test('email validator rejects invalid email', () {
    expect(Validators.email('not-an-email'), isNotNull);
    expect(Validators.email('customer@example.com'), isNull);
  });

  test('booking documentation survives model serialization', () {
    const booking = BookingModel(
      id: 7,
      userId: 1,
      serviceId: 2,
      serviceName: 'Deep Cleaning',
      customerName: 'Customer',
      phone: '012345678',
      address: 'Main Street',
      propertyType: 'Apartment',
      rooms: 2,
      bathrooms: 1,
      bookingDate: '2026-06-20',
      bookingTime: '10:00 AM',
      extraServices: [],
      paymentMethod: 'Cash',
      basePrice: 50,
      extraPrice: 0,
      totalPrice: 50,
      estimatedDuration: 120,
      beforePhotos: ['data:image/jpeg;base64,YmVmb3Jl'],
      afterPhotos: ['data:image/jpeg;base64,YWZ0ZXI='],
      completionNotes: 'Kitchen and bathroom completed.',
    );

    final restored = BookingModel.fromJson(booking.toJson());

    expect(restored.beforePhotos, booking.beforePhotos);
    expect(restored.afterPhotos, booking.afterPhotos);
    expect(restored.completionNotes, booking.completionNotes);
  });

  test('cleaner availability survives persistence and activation changes', () {
    const busyCleaner = UserModel(
      id: 3,
      firebaseUid: 'cleaner-3',
      fullName: 'Sokha Chan',
      email: 'sokha@cleannow.demo',
      phone: '+855 111 222 333',
      role: 'cleaner',
      availabilityStatus: 'Busy',
    );

    final restored = UserModel.fromJson(busyCleaner.toJson());
    final offDuty = restored.copyWith(isActive: false);

    expect(restored.availabilityStatus, 'Busy');
    expect(offDuty.availabilityStatus, 'Off Duty');
    expect(offDuty.copyWith(isActive: true).availabilityStatus, 'Available');
  });

  testWidgets('customer can open and close promotions sheet', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(661, 905));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final database = DatabaseHelper();
    final auth = AuthProvider(AuthRepository(false), database)
      ..user = const UserModel(
        id: 99,
        firebaseUid: 'test-customer',
        fullName: 'Test Customer',
        email: 'customer@example.com',
        phone: '+855 123 456 789',
      );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
          ChangeNotifierProvider(create: (_) => BookingProvider(database)),
        ],
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );

    final promotions = find.text('Promotions & Discounts');
    await tester.drag(find.byType(ListView).first, const Offset(0, -1000));
    await tester.pumpAndSettle();
    await tester.ensureVisible(promotions);
    await tester.tap(promotions);
    await tester.pumpAndSettle();

    expect(find.text('WELCOME15'), findsOneWidget);
    expect(find.byTooltip('Close'), findsOneWidget);

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();

    expect(find.text('WELCOME15'), findsNothing);
    expect(find.byTooltip('Close'), findsNothing);
  });

  testWidgets('new customer profile starts without sample addresses', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final database = DatabaseHelper();
    final auth = AuthProvider(AuthRepository(false), database)
      ..user = const UserModel(
        id: 501,
        firebaseUid: 'new-customer-address-test',
        fullName: 'New Customer',
        email: 'new@example.com',
        phone: '+855 123 456 789',
      );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
          ChangeNotifierProvider(create: (_) => BookingProvider(database)),
        ],
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('No saved addresses yet. Add an address when you are ready.'),
      findsOneWidget,
    );
    expect(find.text('Office'), findsNothing);
    expect(find.textContaining('123 Main St'), findsNothing);
  });

  testWidgets('customer history excludes bookings owned by another customer', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final database = DatabaseHelper();
    final auth = AuthProvider(AuthRepository(false), database)
      ..user = const UserModel(
        id: 601,
        firebaseUid: 'history-owner',
        fullName: 'History Owner',
        email: 'owner@example.com',
        phone: '+855 123 456 789',
      );
    final bookingProvider = BookingProvider(database)
      ..bookings = const [
        BookingModel(
          id: 602,
          userId: 999,
          serviceId: 1,
          serviceName: 'Foreign Booking',
          customerName: 'Another Customer',
          phone: '+855 111 111 111',
          address: 'Another address',
          propertyType: 'House',
          rooms: 2,
          bathrooms: 1,
          bookingDate: '2026-06-25',
          bookingTime: '10:00 AM',
          extraServices: [],
          paymentMethod: 'Cash',
          basePrice: 25,
          extraPrice: 0,
          totalPrice: 25,
          estimatedDuration: 120,
        ),
      ];

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
          ChangeNotifierProvider<BookingProvider>.value(value: bookingProvider),
        ],
        child: const MaterialApp(home: BookingHistoryScreen()),
      ),
    );

    expect(find.text('No booking history yet.'), findsOneWidget);
    expect(find.text('Foreign Booking'), findsNothing);
  });

  testWidgets('booking success opens the newly created booking detail', (
    tester,
  ) async {
    final database = DatabaseHelper();
    final auth = AuthProvider(AuthRepository(false), database)
      ..user = const UserModel(
        id: 701,
        firebaseUid: 'booking-success-owner',
        fullName: 'Booking Owner',
        email: 'booking@example.com',
        phone: '+855 123 456 789',
      );
    const booking = BookingModel(
      id: 702,
      userId: 701,
      serviceId: 2,
      serviceName: 'New Deep Cleaning',
      customerName: 'Booking Owner',
      phone: '+855 123 456 789',
      address: 'Customer address',
      propertyType: 'Apartment',
      rooms: 2,
      bathrooms: 1,
      bookingDate: '2026-06-25',
      bookingTime: '10:00 AM',
      extraServices: [],
      specialInstruction: 'Use the side entrance.',
      paymentMethod: 'Cash',
      basePrice: 50,
      extraPrice: 0,
      totalPrice: 50,
      estimatedDuration: 180,
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
          ChangeNotifierProvider(create: (_) => BookingProvider(database)),
        ],
        child: MaterialApp(
          onGenerateRoute: (settings) {
            if (settings.name == BookingDetailScreen.route) {
              return MaterialPageRoute<void>(
                settings: settings,
                builder: (_) => const BookingDetailScreen(),
              );
            }
            return MaterialPageRoute<void>(
              settings: const RouteSettings(arguments: booking),
              builder: (_) => const BookingSuccessScreen(),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('View Booking Detail'));
    await tester.pumpAndSettle();

    expect(find.text('Booking #702'), findsOneWidget);
    expect(find.text('New Deep Cleaning'), findsOneWidget);
    expect(find.text('Customer address'), findsOneWidget);
    expect(find.text('Cash • Unpaid'), findsOneWidget);
  });

  testWidgets('customer cannot open another customer booking detail', (
    tester,
  ) async {
    final database = DatabaseHelper();
    final auth = AuthProvider(AuthRepository(false), database)
      ..user = const UserModel(
        id: 801,
        firebaseUid: 'detail-owner',
        fullName: 'Detail Owner',
        email: 'detail@example.com',
        phone: '+855 123 456 789',
      );
    const foreignBooking = BookingModel(
      id: 802,
      userId: 999,
      serviceId: 1,
      serviceName: 'Private Booking',
      customerName: 'Other Customer',
      phone: '+855 111 111 111',
      address: 'Private address',
      propertyType: 'House',
      rooms: 1,
      bathrooms: 1,
      bookingDate: '2026-06-25',
      bookingTime: '11:00 AM',
      extraServices: [],
      paymentMethod: 'Cash',
      basePrice: 25,
      extraPrice: 0,
      totalPrice: 25,
      estimatedDuration: 120,
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: auth,
        child: MaterialApp(
          onGenerateRoute: (_) => MaterialPageRoute<void>(
            settings: const RouteSettings(arguments: foreignBooking),
            builder: (_) => const BookingDetailScreen(),
          ),
        ),
      ),
    );

    expect(
      find.text('You do not have permission to view this booking.'),
      findsOneWidget,
    );
    expect(find.text('Private address'), findsNothing);
  });

  testWidgets('cleaner jobs screen fits a narrow mobile viewport', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(306, 674));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final database = DatabaseHelper();
    final auth = AuthProvider(AuthRepository(false), database)
      ..user = const UserModel(
        id: 2,
        firebaseUid: 'demo-cleaner',
        fullName: 'Cleaner Demo',
        email: 'cleaner@cleannow.demo',
        phone: '+855 987 654 321',
        role: 'cleaner',
      );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
          ChangeNotifierProvider(create: (_) => BookingProvider(database)),
        ],
        child: const MaterialApp(home: CleanerDashboardScreen()),
      ),
    );

    expect(find.text('CleanNow'), findsOneWidget);
    expect(find.text("Today's Jobs"), findsOneWidget);
    expect(find.text('No assigned jobs'), findsOneWidget);
    expect(find.text('Deep Cleaning'), findsNothing);
    expect(find.text('View Details →'), findsNothing);
    expect(find.text('\$0.00'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cleaner advances a job through every tracking status', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(306, 674));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final database = DatabaseHelper();
    final auth = AuthProvider(AuthRepository(false), database)
      ..user = const UserModel(
        id: 2,
        firebaseUid: 'demo-cleaner',
        fullName: 'Cleaner Demo',
        email: 'cleaner@cleannow.demo',
        phone: '+855 987 654 321',
        role: 'cleaner',
      );
    const booking = BookingModel(
      id: 101,
      userId: 11,
      serviceId: 2,
      serviceName: 'Deep Cleaning',
      customerName: 'John Doe',
      phone: '+1 555 0101',
      address: '123 Main St, New York, NY',
      propertyType: 'Apartment',
      rooms: 2,
      bathrooms: 1,
      bookingDate: '2026-06-20',
      bookingTime: '10:00 AM',
      extraServices: [],
      paymentMethod: 'Cash',
      basePrice: 129,
      extraPrice: 0,
      totalPrice: 129,
      estimatedDuration: 240,
      cleanerId: 2,
      cleanerName: 'Cleaner Demo',
      cleanerPay: 48,
      status: 'Cleaner Assigned',
      afterPhotos: [
        'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
      ],
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
          ChangeNotifierProvider(create: (_) => BookingProvider(database)),
        ],
        child: MaterialApp(
          onGenerateRoute: (_) => MaterialPageRoute<void>(
            settings: const RouteSettings(arguments: booking),
            builder: (_) => const BookingDetailScreen(),
          ),
        ),
      ),
    );

    expect(find.text('Job Status'), findsOneWidget);
    expect(find.text('Task Documentation'), findsOneWidget);
    expect(find.text('Upload Before Photos'), findsOneWidget);
    expect(find.text('Add After Photos'), findsOneWidget);
    expect(find.text('Save Documentation'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline_rounded), findsOneWidget);
    expect(find.text('← Back'), findsNothing);
    expect(find.text('Update'), findsOneWidget);

    for (final status in [
      'On the Way',
      'Arrived',
      'In Progress',
      'Completed',
    ]) {
      await tester.tap(find.text(status));
      await tester.pump(const Duration(milliseconds: 250));
    }

    expect(find.byIcon(Icons.check_circle_outline_rounded), findsNWidgets(5));
    expect(tester.takeException(), isNull);
  });

  testWidgets('cleaner schedule renders its calendar on a narrow screen', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(306, 674));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final database = DatabaseHelper();
    final auth = AuthProvider(AuthRepository(false), database)
      ..user = const UserModel(
        id: 2,
        firebaseUid: 'demo-cleaner',
        fullName: 'Cleaner Demo',
        email: 'cleaner@cleannow.demo',
        phone: '+855 987 654 321',
        role: 'cleaner',
      );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
          ChangeNotifierProvider(create: (_) => BookingProvider(database)),
        ],
        child: const MaterialApp(home: CleanerScheduleScreen()),
      ),
    );

    expect(find.text('Work Schedule'), findsOneWidget);
    expect(
      find.text(DateFormat('MMMM y').format(DateTime.now())),
      findsOneWidget,
    );
    expect(
      find.textContaining(
        'Jobs on ${DateFormat('MMMM').format(DateTime.now())}',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('cleaner profile matches the published portal sections', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(306, 674));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final database = DatabaseHelper();
    final auth = AuthProvider(AuthRepository(false), database)
      ..user = const UserModel(
        id: 2,
        firebaseUid: 'demo-cleaner',
        fullName: 'Cleaner Demo',
        email: 'cleaner@cleannow.demo',
        phone: '+855 987 654 321',
        role: 'cleaner',
      );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
          ChangeNotifierProvider(create: (_) => BookingProvider(database)),
        ],
        child: const MaterialApp(home: CleanerProfileScreen()),
      ),
    );

    expect(find.text('Professional Cleaner'), findsOneWidget);
    expect(find.text('Performance Stats'), findsOneWidget);
    expect(find.text('Achievements'), findsOneWidget);
    expect(find.text('Recent Reviews'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
