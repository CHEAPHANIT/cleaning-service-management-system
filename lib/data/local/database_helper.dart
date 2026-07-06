import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/constants.dart';
import '../../core/errors.dart';
import '../models/models.dart';
import '../remote/clean_now_api.dart';

class DatabaseHelper {
  static const _webUsersKey = 'cleannow_web_users';
  static const _webBookingsKey = 'cleannow_web_bookings';
  static const _webNotificationsKey = 'cleannow_web_notifications';
  static const _webCleanerApplicationsKey = 'cleannow_web_cleaner_applications';
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper({bool enableApi = false}) {
    if (enableApi) _instance._apiEnabled = true;
    return _instance;
  }
  DatabaseHelper._internal();

  Database? _database;
  final CleanNowApi _api = CleanNowApi();
  bool _apiEnabled = false;
  final List<UserModel> _webUsers = [];
  final List<BookingModel> _webBookings = [];
  final List<FavoriteModel> _webFavorites = [];
  final List<ReviewModel> _webReviews = [];
  final List<NotificationModel> _webNotifications = [];
  final List<CleanerApplicationModel> _webCleanerApplications = [];
  final List<ProductModel> _webProducts = [];
  final List<ServiceModel> _webServices = List.of(seedServices);
  int _webUserId = 1;
  int _webBookingId = 1;
  int _webServiceId = 7;
  int _webFavoriteId = 1;
  int _webReviewId = 1;
  int _webNotificationId = 1;
  int _webCleanerApplicationId = 1;
  bool _webSyncInProgress = false;

  Future<void> initialize() async {
    if (kIsWeb) {
      await _loadWebUsers();
      await _loadWebBookings();
      await _loadWebNotifications();
      await _loadWebCleanerApplications();
      await _seedWebUsers();
      return;
    }
    await database;
  }

  Future<Database> get database async => _database ??= await _open();

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'cleannow.db');
    return openDatabase(
      path,
      version: 6,
      onCreate: _create,
      onUpgrade: _upgrade,
      onOpen: (db) async {
        await _seedServices(db);
        await _seedUsers(db);
      },
    );
  }

  Future<void> _create(Database db, int version) async {
    await db.execute(
      'CREATE TABLE users(id INTEGER PRIMARY KEY AUTOINCREMENT, firebase_uid TEXT UNIQUE, full_name TEXT, email TEXT, phone TEXT, role TEXT DEFAULT "customer", address TEXT, hourly_rate REAL DEFAULT 8, is_active INTEGER DEFAULT 1, status TEXT DEFAULT "active", availability_status TEXT DEFAULT "Available", created_at TEXT, updated_at TEXT)',
    );
    await db.execute(
      'CREATE TABLE cleaner_applications(id INTEGER PRIMARY KEY AUTOINCREMENT, full_name TEXT, email TEXT, phone TEXT, gender TEXT, address TEXT, work_experience TEXT, skills TEXT, available_days TEXT, available_time TEXT, profile_photo TEXT, id_document TEXT, status TEXT DEFAULT "pending", admin_note TEXT, user_id INTEGER, created_at TEXT, updated_at TEXT)',
    );
    await db.execute(
      'CREATE TABLE services(id INTEGER PRIMARY KEY, name TEXT, category TEXT, description TEXT, base_price REAL, duration_minutes INTEGER, image_url TEXT, rating REAL, cleaners_required INTEGER, is_active INTEGER)',
    );
    await db.execute(
      'CREATE TABLE bookings(id INTEGER PRIMARY KEY AUTOINCREMENT, user_id INTEGER, service_id INTEGER, service_name TEXT, customer_name TEXT, phone TEXT, address TEXT, property_type TEXT, rooms INTEGER, bathrooms INTEGER, booking_date TEXT, booking_time TEXT, extra_services TEXT, special_instruction TEXT, payment_method TEXT, base_price REAL, extra_price REAL, total_price REAL, estimated_duration INTEGER, cleaner_id INTEGER, cleaner_name TEXT, cleaner_pay REAL DEFAULT 0, status TEXT, service_image TEXT, before_photos TEXT DEFAULT "[]", after_photos TEXT DEFAULT "[]", completion_notes TEXT DEFAULT "", created_at TEXT, updated_at TEXT)',
    );
    await db.execute(
      'CREATE TABLE favorites(id INTEGER PRIMARY KEY AUTOINCREMENT, user_id INTEGER, service_id INTEGER, service_name TEXT, service_image TEXT, service_price REAL, created_at TEXT, UNIQUE(user_id, service_id))',
    );
    await db.execute(
      'CREATE TABLE reviews(id INTEGER PRIMARY KEY AUTOINCREMENT, booking_id INTEGER UNIQUE, service_id INTEGER, user_id INTEGER, rating INTEGER, comment TEXT, created_at TEXT)',
    );
    await db.execute(
      'CREATE TABLE notifications(id INTEGER PRIMARY KEY AUTOINCREMENT, user_id INTEGER, title TEXT, message TEXT, is_read INTEGER, created_at TEXT)',
    );
    await db.execute(
      'CREATE TABLE cached_products(id INTEGER PRIMARY KEY AUTOINCREMENT, api_id INTEGER UNIQUE, title TEXT, description TEXT, price REAL, image_url TEXT, category TEXT, created_at TEXT)',
    );
  }

  Future<void> _upgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE users ADD COLUMN role TEXT DEFAULT "customer"',
      );
    }
    if (oldVersion < 3) {
      await _addColumnIfMissing(db, 'users', 'hourly_rate', 'REAL DEFAULT 8');
      await _addColumnIfMissing(db, 'users', 'is_active', 'INTEGER DEFAULT 1');
      await _addColumnIfMissing(db, 'bookings', 'cleaner_id', 'INTEGER');
      await _addColumnIfMissing(db, 'bookings', 'cleaner_name', 'TEXT');
      await _addColumnIfMissing(
        db,
        'bookings',
        'cleaner_pay',
        'REAL DEFAULT 0',
      );
    }
    if (oldVersion < 4) {
      await _addColumnIfMissing(
        db,
        'bookings',
        'before_photos',
        'TEXT DEFAULT "[]"',
      );
      await _addColumnIfMissing(
        db,
        'bookings',
        'after_photos',
        'TEXT DEFAULT "[]"',
      );
      await _addColumnIfMissing(
        db,
        'bookings',
        'completion_notes',
        'TEXT DEFAULT ""',
      );
    }
    if (oldVersion < 5) {
      await _addColumnIfMissing(
        db,
        'users',
        'availability_status',
        'TEXT DEFAULT "Available"',
      );
      await db.execute(
        'UPDATE users SET availability_status = "Off Duty" WHERE is_active = 0',
      );
    }
    if (oldVersion < 6) {
      await _addColumnIfMissing(db, 'users', 'status', 'TEXT DEFAULT "active"');
      await db.execute(
        'UPDATE users SET status = CASE WHEN is_active = 1 THEN "active" ELSE "inactive" END WHERE status IS NULL OR status = ""',
      );
      await db.execute(
        'CREATE TABLE IF NOT EXISTS cleaner_applications(id INTEGER PRIMARY KEY AUTOINCREMENT, full_name TEXT, email TEXT, phone TEXT, gender TEXT, address TEXT, work_experience TEXT, skills TEXT, available_days TEXT, available_time TEXT, profile_photo TEXT, id_document TEXT, status TEXT DEFAULT "pending", admin_note TEXT, user_id INTEGER, created_at TEXT, updated_at TEXT)',
      );
    }
  }

  Future<void> _addColumnIfMissing(
    Database db,
    String table,
    String column,
    String type,
  ) async {
    final columns = await db.rawQuery('PRAGMA table_info($table)');
    final exists = columns.any((item) => item['name'] == column);
    if (!exists)
      await db.execute('ALTER TABLE $table ADD COLUMN $column $type');
  }

  Future<void> _seedServices(Database db) async {
    final count =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM services'),
        ) ??
        0;
    if (count > 0) return;
    for (final service in seedServices) {
      await db.insert(
        'services',
        service.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> _seedUsers(Database db) async {
    final count =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM users'),
        ) ??
        0;
    if (count > 0) return;
    for (final user in seedUsers) {
      await db.insert(
        'users',
        user.toJson()..remove('id'),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> _seedWebUsers() async {
    if (_webUsers.isNotEmpty) return;
    for (final user in seedUsers) {
      _webUsers.add(user.copyWith(id: _webUserId++));
    }
    await _saveWebUsers();
  }

  bool get supportsRealtimeSync => _apiEnabled || kIsWeb;

  Future<void> _loadWebUsers({bool reload = false}) async {
    final prefs = await SharedPreferences.getInstance();
    if (reload) await prefs.reload();
    final storedUsers = prefs.getString(_webUsersKey);
    if (storedUsers == null || storedUsers.isEmpty) return;

    try {
      final decoded = jsonDecode(storedUsers) as List<dynamic>;
      _webUsers
        ..clear()
        ..addAll(
          decoded.map(
            (item) => UserModel.fromJson(
              Map<String, dynamic>.from(item as Map<dynamic, dynamic>),
            ),
          ),
        );
      final largestId = _webUsers.fold<int>(
        0,
        (largest, user) => (user.id ?? 0) > largest ? user.id! : largest,
      );
      _webUserId = largestId + 1;
    } catch (_) {
      // Ignore invalid legacy data and recreate the seed users below.
      _webUsers.clear();
    }
  }

  Future<void> _saveWebUsers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _webUsersKey,
      jsonEncode(_webUsers.map((user) => user.toJson()).toList()),
    );
  }

  Future<void> _loadWebBookings() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_webBookingsKey);
    if (stored == null || stored.isEmpty) {
      _webBookings.clear();
      _webBookingId = 1;
      return;
    }
    try {
      final decoded = jsonDecode(stored) as List<dynamic>;
      _webBookings
        ..clear()
        ..addAll(
          decoded.map(
            (item) => BookingModel.fromJson(
              Map<String, dynamic>.from(item as Map<dynamic, dynamic>),
            ),
          ),
        );
      _webBookingId =
          _webBookings.fold<int>(
            0,
            (largest, booking) =>
                (booking.id ?? 0) > largest ? booking.id! : largest,
          ) +
          1;
    } catch (_) {
      _webBookings.clear();
      _webBookingId = 1;
    }
  }

  Future<void> _saveWebBookings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _webBookingsKey,
      jsonEncode(_webBookings.map((booking) => booking.toJson()).toList()),
    );
  }

  Future<void> _loadWebNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_webNotificationsKey);
    if (stored == null || stored.isEmpty) {
      _webNotifications.clear();
      _webNotificationId = 1;
      return;
    }
    try {
      final decoded = jsonDecode(stored) as List<dynamic>;
      _webNotifications
        ..clear()
        ..addAll(
          decoded.map(
            (item) => NotificationModel.fromJson(
              Map<String, dynamic>.from(item as Map<dynamic, dynamic>),
            ),
          ),
        );
      _webNotificationId =
          _webNotifications.fold<int>(
            0,
            (largest, item) => (item.id ?? 0) > largest ? item.id! : largest,
          ) +
          1;
    } catch (_) {
      _webNotifications.clear();
      _webNotificationId = 1;
    }
  }

  Future<void> _saveWebNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _webNotificationsKey,
      jsonEncode(_webNotifications.map((item) => item.toJson()).toList()),
    );
  }

  Future<void> _loadWebCleanerApplications() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_webCleanerApplicationsKey);
    if (stored == null || stored.isEmpty) {
      _webCleanerApplications.clear();
      _webCleanerApplicationId = 1;
      return;
    }
    try {
      final decoded = jsonDecode(stored) as List<dynamic>;
      _webCleanerApplications
        ..clear()
        ..addAll(
          decoded.map(
            (item) => CleanerApplicationModel.fromJson(
              Map<String, dynamic>.from(item as Map<dynamic, dynamic>),
            ),
          ),
        );
      _webCleanerApplicationId =
          _webCleanerApplications.fold<int>(
            0,
            (largest, item) => (item.id ?? 0) > largest ? item.id! : largest,
          ) +
          1;
    } catch (_) {
      _webCleanerApplications.clear();
      _webCleanerApplicationId = 1;
    }
  }

  Future<void> _saveWebCleanerApplications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _webCleanerApplicationsKey,
      jsonEncode(_webCleanerApplications.map((item) => item.toJson()).toList()),
    );
  }

  Future<bool> syncWebData() async {
    if (!kIsWeb) return false;
    if (_webSyncInProgress) return false;
    _webSyncInProgress = true;
    try {
      final before = jsonEncode({
        'users': _webUsers.map((item) => item.toJson()).toList(),
        'bookings': _webBookings.map((item) => item.toJson()).toList(),
        'notifications': _webNotifications
            .map((item) => item.toJson())
            .toList(),
      });
      await _loadWebUsers(reload: true);
      await _loadWebBookings();
      await _loadWebNotifications();
      final after = jsonEncode({
        'users': _webUsers.map((item) => item.toJson()).toList(),
        'bookings': _webBookings.map((item) => item.toJson()).toList(),
        'notifications': _webNotifications
            .map((item) => item.toJson())
            .toList(),
      });
      return before != after;
    } finally {
      _webSyncInProgress = false;
    }
  }

  static final seedUsers = [
    const UserModel(
      firebaseUid: 'seed-admin',
      fullName: 'Default Admin',
      email: 'admin@example.com',
      phone: '+855 000 000 001',
      role: 'admin',
    ),
    const UserModel(
      firebaseUid: 'seed-customer',
      fullName: 'Sample Customer',
      email: 'customer@example.com',
      phone: '+855 000 000 002',
      role: 'customer',
    ),
    const UserModel(
      firebaseUid: 'seed-cleaner',
      fullName: 'Sample Cleaner',
      email: 'cleaner@example.com',
      phone: '+855 000 000 003',
      role: 'cleaner',
      hourlyRate: 10,
    ),
    const UserModel(
      firebaseUid: 'demo-admin',
      fullName: 'Admin Demo',
      email: 'admin@cleannow.demo',
      phone: '+855 123 456 789',
      role: 'admin',
    ),
    const UserModel(
      firebaseUid: 'demo-cleaner',
      fullName: 'Cleaner Demo',
      email: 'cleaner@cleannow.demo',
      phone: '+855 987 654 321',
      role: 'cleaner',
      hourlyRate: 9,
    ),
    const UserModel(
      firebaseUid: 'demo-cleaner-sokha',
      fullName: 'Sokha Chan',
      email: 'sokha@cleannow.demo',
      phone: '+855 111 222 333',
      role: 'cleaner',
      hourlyRate: 10,
    ),
  ];

  static final seedServices = [
    const ServiceModel(
      id: 1,
      name: 'Basic Home Cleaning',
      category: 'Home Cleaning',
      description:
          'Trusted cleaners refresh your living areas, kitchen, bathroom, floors, and surfaces.',
      basePrice: 25,
      durationMinutes: 120,
      imageUrl: DemoImages.home,
      rating: 4.5,
      cleanersRequired: 1,
    ),
    const ServiceModel(
      id: 2,
      name: 'Deep Cleaning',
      category: 'Deep Cleaning',
      description:
          'Detailed top-to-bottom cleaning for high-touch surfaces, stains, and hard-to-reach spaces.',
      basePrice: 50,
      durationMinutes: 240,
      imageUrl: DemoImages.deep,
      rating: 4.8,
      cleanersRequired: 2,
    ),
    const ServiceModel(
      id: 3,
      name: 'Office Cleaning',
      category: 'Office Cleaning',
      description:
          'Workplace cleaning for desks, meeting rooms, shared areas, floors, and restrooms.',
      basePrice: 40,
      durationMinutes: 180,
      imageUrl: DemoImages.office,
      rating: 4.6,
      cleanersRequired: 2,
    ),
    const ServiceModel(
      id: 4,
      name: 'Move-in Cleaning',
      category: 'Move-in Cleaning',
      description:
          'Prepare a new home with cabinet wipe-downs, floor care, bathroom cleaning, and kitchen reset.',
      basePrice: 60,
      durationMinutes: 300,
      imageUrl: DemoImages.deep,
      rating: 4.7,
      cleanersRequired: 2,
    ),
    const ServiceModel(
      id: 5,
      name: 'Sofa Cleaning',
      category: 'Sofa Cleaning',
      description:
          'Fabric-safe sofa cleaning, surface treatment, vacuuming, and deodorizing.',
      basePrice: 20,
      durationMinutes: 90,
      imageUrl: DemoImages.sofa,
      rating: 4.4,
      cleanersRequired: 1,
    ),
    const ServiceModel(
      id: 6,
      name: 'Carpet Cleaning',
      category: 'Carpet Cleaning',
      description:
          'Carpet refresh with vacuuming, stain focus, shampoo, and drying guidance.',
      basePrice: 30,
      durationMinutes: 120,
      imageUrl: DemoImages.carpet,
      rating: 4.5,
      cleanersRequired: 1,
    ),
  ];

  Future<int> upsertUser(UserModel user) async {
    if (_apiEnabled) {
      final remoteUser = await _api.upsertUser(user);
      if (remoteUser != null) return remoteUser.id!;
    }
    if (kIsWeb) {
      await syncWebData();
      final now = DateTime.now().toIso8601String();
      final index = _webUsers.indexWhere(
        (item) => item.firebaseUid == user.firebaseUid,
      );
      if (index >= 0) {
        final id = _webUsers[index].id!;
        _webUsers[index] = user.copyWith(
          id: id,
          createdAt: _webUsers[index].createdAt,
          updatedAt: now,
        );
        await _saveWebUsers();
        return id;
      }
      final id = _webUserId++;
      _webUsers.add(user.copyWith(id: id, createdAt: now, updatedAt: now));
      await _saveWebUsers();
      return id;
    }

    final db = await database;
    final now = DateTime.now().toIso8601String();
    final data =
        user.copyWith(createdAt: user.createdAt ?? now, updatedAt: now).toJson()
          ..remove('id');
    await db.insert(
      'users',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    final rows = await db.query(
      'users',
      where: 'firebase_uid = ?',
      whereArgs: [user.firebaseUid],
      limit: 1,
    );
    return rows.first['id'] as int;
  }

  Future<UserModel?> getUserByUid(String uid) async {
    if (_apiEnabled) {
      final remoteUsers = await _api.users();
      if (remoteUsers != null) {
        return remoteUsers.where((item) => item.firebaseUid == uid).firstOrNull;
      }
    }
    if (kIsWeb) {
      return _webUsers.where((item) => item.firebaseUid == uid).firstOrNull;
    }
    final db = await database;
    final rows = await db.query(
      'users',
      where: 'firebase_uid = ?',
      whereArgs: [uid],
      limit: 1,
    );
    return rows.isEmpty ? null : UserModel.fromJson(rows.first);
  }

  Future<void> updateUser(UserModel user) async {
    if (_apiEnabled && await _api.upsertUser(user) != null) return;
    if (kIsWeb) {
      final index = _webUsers.indexWhere((item) => item.id == user.id);
      if (index >= 0) {
        _webUsers[index] = user.copyWith(
          updatedAt: DateTime.now().toIso8601String(),
        );
        await _saveWebUsers();
      }
      return;
    }
    final db = await database;
    await db.update(
      'users',
      user.copyWith(updatedAt: DateTime.now().toIso8601String()).toJson()
        ..remove('id'),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<List<ServiceModel>> services() async {
    if (_apiEnabled) {
      final remote = await _api.services();
      if (remote != null) return remote;
    }
    if (kIsWeb) return List.of(_webServices);
    return (await (await database).query(
      'services',
    )).map(ServiceModel.fromJson).toList();
  }

  Future<ServiceModel?> service(int id) async {
    if (_apiEnabled) {
      final remote = await _api.services();
      if (remote != null) {
        return remote.where((item) => item.id == id).firstOrNull;
      }
    }
    if (kIsWeb) {
      return _webServices.where((item) => item.id == id).firstOrNull;
    }
    final rows = await (await database).query(
      'services',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : ServiceModel.fromJson(rows.first);
  }

  Future<int> saveBooking(BookingModel booking) async {
    if (_apiEnabled) {
      final remoteBooking = await _api.createBooking(booking);
      if (remoteBooking != null) return remoteBooking.id!;
    }
    if (kIsWeb) {
      await syncWebData();
      final now = DateTime.now().toIso8601String();
      final id = _webBookingId++;
      _webBookings.insert(0, booking.copyWith(id: id));
      await _saveWebBookings();
      await addNotification(
        NotificationModel(
          userId: booking.userId,
          title: 'Booking created',
          message: '${booking.serviceName} is pending confirmation.',
          createdAt: now,
        ),
      );
      await _notifyAdmins(
        title: 'New booking request',
        message:
            '${booking.customerName} booked ${booking.serviceName} for ${booking.bookingDate} at ${booking.bookingTime}.',
      );
      return id;
    }

    final db = await database;
    final now = DateTime.now().toIso8601String();
    final id = await db.insert(
      'bookings',
      booking.copyWith().toJson()
        ..remove('id')
        ..['created_at'] = now
        ..['updated_at'] = now,
    );
    await addNotification(
      NotificationModel(
        userId: booking.userId,
        title: 'Booking created',
        message: '${booking.serviceName} is pending confirmation.',
        createdAt: now,
      ),
    );
    await _notifyAdmins(
      title: 'New booking request',
      message:
          '${booking.customerName} booked ${booking.serviceName} for ${booking.bookingDate} at ${booking.bookingTime}.',
    );
    return id;
  }

  Future<List<BookingModel>> bookings(int userId) async {
    if (_apiEnabled) {
      final remote = await _api.bookings(userId: userId);
      if (remote != null) return remote;
    }
    if (kIsWeb) {
      return _webBookings.where((item) => item.userId == userId).toList();
    }
    final rows = await (await database).query(
      'bookings',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return rows.map(BookingModel.fromJson).toList();
  }

  Future<List<BookingModel>> allBookings() async {
    if (_apiEnabled) {
      final remote = await _api.bookings();
      if (remote != null) return remote;
    }
    if (kIsWeb) {
      return List.of(_webBookings);
    }
    final rows = await (await database).query(
      'bookings',
      orderBy: 'created_at DESC',
    );
    return rows.map(BookingModel.fromJson).toList();
  }

  Future<List<BookingModel>> bookingsForCleaner(int cleanerId) async {
    if (_apiEnabled) {
      final remote = await _api.bookings(cleanerId: cleanerId);
      if (remote != null) return remote;
    }
    if (kIsWeb) {
      return _webBookings.where((item) => item.cleanerId == cleanerId).toList();
    }
    final rows = await (await database).query(
      'bookings',
      where: 'cleaner_id = ?',
      whereArgs: [cleanerId],
      orderBy: 'booking_date ASC',
    );
    return rows.map(BookingModel.fromJson).toList();
  }

  Future<void> updateBookingStatus(int id, String status) async {
    if (_apiEnabled && await _api.updateStatus(id, status)) return;
    if (kIsWeb) await syncWebData();
    final booking = await _bookingById(id);
    if (kIsWeb) {
      final index = _webBookings.indexWhere((item) => item.id == id);
      if (index >= 0) {
        _webBookings[index] = _webBookings[index].copyWith(status: status);
        final cleanerId = _webBookings[index].cleanerId;
        if (cleanerId != null && _isTerminalBookingStatus(status)) {
          _setWebCleanerAvailability(cleanerId, 'Available');
        }
        await _saveWebBookings();
        await _saveWebUsers();
      }
    } else {
      await (await database).update(
        'bookings',
        {'status': status, 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [id],
      );
      if (booking?.cleanerId != null && _isTerminalBookingStatus(status)) {
        await (await database).update(
          'users',
          {'is_active': 1, 'availability_status': 'Available'},
          where: 'id = ?',
          whereArgs: [booking!.cleanerId],
        );
      }
    }
    if (booking != null) {
      await addNotification(
        NotificationModel(
          userId: booking.userId,
          title: 'Booking status updated',
          message: '${booking.serviceName} is now $status.',
        ),
      );
      await _notifyAdmins(
        title: 'Booking status updated',
        message: '${booking.serviceName} #$id is now $status.',
      );
    }
  }

  Future<void> updateBookingDocumentation(BookingModel booking) async {
    if (booking.id == null) return;
    if (_apiEnabled && await _api.updateDocumentation(booking)) return;
    if (kIsWeb) {
      await syncWebData();
      final index = _webBookings.indexWhere((item) => item.id == booking.id);
      if (index >= 0) {
        _webBookings[index] = booking;
        await _saveWebBookings();
      }
      return;
    }
    await (await database).update(
      'bookings',
      {
        'before_photos': jsonEncode(booking.beforePhotos),
        'after_photos': jsonEncode(booking.afterPhotos),
        'completion_notes': booking.completionNotes,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [booking.id],
    );
  }

  Future<void> assignBookingCleaner(
    BookingModel booking,
    UserModel cleaner,
  ) async {
    if (booking.status != 'Accepted' || booking.cleanerId != null) {
      throw ValidationException(
        'Only an unassigned accepted booking can be assigned.',
      );
    }
    if (!cleaner.isActive || cleaner.availabilityStatus != 'Available') {
      throw ValidationException('Cleaner is not available.');
    }
    final pay = booking.estimatedDuration / 60 * cleaner.hourlyRate;
    if (_apiEnabled) {
      final result = await _api.assignCleaner(booking.id!, cleaner, pay);
      if (result == true) return;
      if (result == false) {
        throw ValidationException(
          'Cleaner already has an active task. Complete or cancel it first.',
        );
      }
    }
    if (kIsWeb) {
      await syncWebData();
      final hasActiveJob = _webBookings.any(
        (item) =>
            item.id != booking.id &&
            item.cleanerId == cleaner.id &&
            !_isTerminalBookingStatus(item.status),
      );
      if (hasActiveJob) {
        throw ValidationException('Cleaner already has an active task.');
      }
      final index = _webBookings.indexWhere((item) => item.id == booking.id);
      if (index >= 0) {
        _webBookings[index] = _webBookings[index].copyWith(
          cleanerId: cleaner.id,
          cleanerName: cleaner.fullName,
          cleanerPay: pay,
          status: 'Cleaner Assigned',
        );
        _setWebCleanerAvailability(cleaner.id!, 'Busy');
        await _saveWebBookings();
        await _saveWebUsers();
      }
    } else {
      final activeJobs = await (await database).query(
        'bookings',
        columns: ['id'],
        where: 'cleaner_id = ? AND id <> ? AND status NOT IN (?, ?, ?)',
        whereArgs: [
          cleaner.id,
          booking.id,
          'Completed',
          'Cancelled',
          'Rejected',
        ],
        limit: 1,
      );
      if (activeJobs.isNotEmpty) {
        throw ValidationException('Cleaner already has an active task.');
      }
      await (await database).update(
        'bookings',
        {
          'cleaner_id': cleaner.id,
          'cleaner_name': cleaner.fullName,
          'cleaner_pay': pay,
          'status': 'Cleaner Assigned',
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [booking.id],
      );
      await (await database).update(
        'users',
        {'is_active': 1, 'availability_status': 'Busy'},
        where: 'id = ?',
        whereArgs: [cleaner.id],
      );
    }
    await addNotification(
      NotificationModel(
        userId: cleaner.id!,
        title: 'New job assigned',
        message:
            '${booking.serviceName} for ${booking.customerName} on ${booking.bookingDate.split('T').first} at ${booking.bookingTime}.',
      ),
    );
    await addNotification(
      NotificationModel(
        userId: booking.userId,
        title: 'Cleaner assigned',
        message: '${cleaner.fullName} has been assigned to your booking.',
      ),
    );
  }

  bool _isTerminalBookingStatus(String status) =>
      const {'Completed', 'Cancelled', 'Rejected'}.contains(status);

  void _setWebCleanerAvailability(int cleanerId, String status) {
    final index = _webUsers.indexWhere((user) => user.id == cleanerId);
    if (index < 0) return;
    _webUsers[index] = _webUsers[index].copyWith(
      isActive: status != 'Off Duty',
      availabilityStatus: status,
      updatedAt: DateTime.now().toIso8601String(),
    );
  }

  Future<BookingModel?> _bookingById(int id) async {
    if (kIsWeb) {
      return _webBookings.where((item) => item.id == id).firstOrNull;
    }
    final rows = await (await database).query(
      'bookings',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : BookingModel.fromJson(rows.first);
  }

  Future<void> _notifyAdmins({
    required String title,
    required String message,
  }) async {
    final adminIds = kIsWeb
        ? _webUsers
              .where((user) => user.role == 'admin' && user.id != null)
              .map((user) => user.id!)
              .toList()
        : (await (await database).query(
            'users',
            columns: ['id'],
            where: 'role = ? AND is_active = 1',
            whereArgs: ['admin'],
          )).map((row) => row['id'] as int).toList();
    for (final adminId in adminIds) {
      await addNotification(
        NotificationModel(userId: adminId, title: title, message: message),
      );
    }
  }

  Future<List<UserModel>> users() async {
    if (_apiEnabled) {
      final remote = await _api.users();
      if (remote != null) return remote;
    }
    if (kIsWeb) {
      await _seedWebUsers();
      return List.of(_webUsers);
    }
    final rows = await (await database).query(
      'users',
      orderBy: 'role ASC, full_name ASC',
    );
    return rows.map(UserModel.fromJson).toList();
  }

  Future<List<UserModel>> cleaners() async {
    final list = await users();
    return list
        .where((item) => item.role == 'cleaner' && item.status == 'active')
        .toList();
  }

  Future<int> saveCleanerApplication(
    CleanerApplicationModel application,
  ) async {
    if (_apiEnabled) {
      final remote = await _api.createCleanerApplication(application);
      if (remote != null) return remote.id!;
    }
    final stamp = DateTime.now().toIso8601String();
    if (kIsWeb) {
      await _loadWebCleanerApplications();
      final id = _webCleanerApplicationId++;
      _webCleanerApplications.insert(
        0,
        CleanerApplicationModel.fromJson({
          ...application.toJson(),
          'id': id,
          'status': 'pending',
          'created_at': stamp,
          'updated_at': stamp,
        }),
      );
      await _saveWebCleanerApplications();
      return id;
    }
    return (await database).insert(
      'cleaner_applications',
      application.toJson()
        ..remove('id')
        ..['status'] = 'pending'
        ..['created_at'] = stamp
        ..['updated_at'] = stamp,
    );
  }

  Future<List<CleanerApplicationModel>> cleanerApplications() async {
    if (_apiEnabled) {
      final remote = await _api.cleanerApplications();
      if (remote != null) return remote;
    }
    if (kIsWeb) {
      await _loadWebCleanerApplications();
      return List.of(_webCleanerApplications);
    }
    final rows = await (await database).query(
      'cleaner_applications',
      orderBy: 'created_at DESC',
    );
    return rows.map(CleanerApplicationModel.fromJson).toList();
  }

  Future<void> approveCleanerApplication(
    CleanerApplicationModel application,
  ) async {
    if (application.id == null) return;
    if (_apiEnabled && await _api.approveCleanerApplication(application.id!)) {
      return;
    }
    final stamp = DateTime.now().toIso8601String();
    final user = UserModel(
      firebaseUid: 'cleaner-${application.email.toLowerCase()}',
      fullName: application.fullName,
      email: application.email,
      phone: application.phone,
      role: 'cleaner',
      address: application.address,
      hourlyRate: 10,
      status: 'active',
    );
    final userId = await upsertUser(user);
    if (kIsWeb) {
      final index = _webCleanerApplications.indexWhere(
        (item) => item.id == application.id,
      );
      if (index >= 0) {
        _webCleanerApplications[index] = CleanerApplicationModel.fromJson({
          ...application.toJson(),
          'status': 'approved',
          'user_id': userId,
          'updated_at': stamp,
        });
        await _saveWebCleanerApplications();
      }
      return;
    }
    await (await database).update(
      'cleaner_applications',
      {'status': 'approved', 'user_id': userId, 'updated_at': stamp},
      where: 'id = ?',
      whereArgs: [application.id],
    );
  }

  Future<void> rejectCleanerApplication(
    CleanerApplicationModel application, {
    String note = '',
  }) async {
    if (application.id == null) return;
    if (_apiEnabled &&
        await _api.rejectCleanerApplication(application.id!, note: note)) {
      return;
    }
    final stamp = DateTime.now().toIso8601String();
    if (kIsWeb) {
      final index = _webCleanerApplications.indexWhere(
        (item) => item.id == application.id,
      );
      if (index >= 0) {
        _webCleanerApplications[index] = CleanerApplicationModel.fromJson({
          ...application.toJson(),
          'status': 'rejected',
          'admin_note': note,
          'updated_at': stamp,
        });
        await _saveWebCleanerApplications();
      }
      return;
    }
    await (await database).update(
      'cleaner_applications',
      {'status': 'rejected', 'admin_note': note, 'updated_at': stamp},
      where: 'id = ?',
      whereArgs: [application.id],
    );
  }

  Future<void> deleteUser(int id) async {
    if (_apiEnabled && await _api.deleteUser(id)) return;
    if (kIsWeb) {
      _webUsers.removeWhere((item) => item.id == id);
      await _saveWebUsers();
      return;
    }
    await (await database).delete('users', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> saveService(ServiceModel service) async {
    if (_apiEnabled) {
      final remote = await _api.saveService(service);
      if (remote != null) return remote.id;
    }
    if (kIsWeb) {
      final index = _webServices.indexWhere((item) => item.id == service.id);
      if (index >= 0) {
        _webServices[index] = service;
        return service.id;
      }
      final id = _webServiceId++;
      _webServices.add(service.copyWith(id: id));
      return id;
    }
    final db = await database;
    final nextId = service.id == 0
        ? (Sqflite.firstIntValue(
                    await db.rawQuery('SELECT MAX(id) FROM services'),
                  ) ??
                  0) +
              1
        : service.id;
    await db.insert(
      'services',
      service.copyWith(id: nextId).toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return nextId;
  }

  Future<void> deleteService(int id) async {
    if (_apiEnabled && await _api.deleteService(id)) return;
    if (kIsWeb) {
      final index = _webServices.indexWhere((item) => item.id == id);
      if (index >= 0) {
        _webServices[index] = _webServices[index].copyWith(isActive: false);
      }
      return;
    }
    await (await database).update(
      'services',
      {'is_active': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<FavoriteModel>> favorites(int userId) async {
    if (_apiEnabled) {
      final remote = await _api.favorites(userId);
      if (remote != null) return remote;
    }
    if (kIsWeb) {
      return _webFavorites.where((item) => item.userId == userId).toList();
    }
    final rows = await (await database).query(
      'favorites',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return rows.map(FavoriteModel.fromJson).toList();
  }

  Future<List<Map<String, dynamic>>> customerAddresses(int userId) async {
    if (_apiEnabled) return await _api.addresses(userId) ?? [];
    return [];
  }

  Future<void> saveCustomerAddresses(
    int userId,
    List<Map<String, dynamic>> addresses,
  ) async {
    if (_apiEnabled) await _api.saveAddresses(userId, addresses);
  }

  Future<void> toggleFavorite(FavoriteModel favorite) async {
    if (_apiEnabled && await _api.toggleFavorite(favorite)) return;
    if (kIsWeb) {
      final index = _webFavorites.indexWhere(
        (item) =>
            item.userId == favorite.userId &&
            item.serviceId == favorite.serviceId,
      );
      if (index >= 0) {
        _webFavorites.removeAt(index);
      } else {
        _webFavorites.insert(0, favorite.copyWith(id: _webFavoriteId++));
      }
      return;
    }

    final db = await database;
    final exists = await db.query(
      'favorites',
      where: 'user_id = ? AND service_id = ?',
      whereArgs: [favorite.userId, favorite.serviceId],
    );
    if (exists.isNotEmpty) {
      await db.delete(
        'favorites',
        where: 'user_id = ? AND service_id = ?',
        whereArgs: [favorite.userId, favorite.serviceId],
      );
    } else {
      await db.insert(
        'favorites',
        favorite.toJson()
          ..remove('id')
          ..['created_at'] = DateTime.now().toIso8601String(),
      );
    }
  }

  Future<int> addReview(ReviewModel review) async {
    if (_apiEnabled) {
      final remoteId = await _api.addReview(review);
      if (remoteId != null) return remoteId;
    }
    if (kIsWeb) {
      if (_webReviews.any((item) => item.bookingId == review.bookingId)) {
        return 0;
      }
      final id = _webReviewId++;
      _webReviews.add(review.copyWith(id: id));
      return id;
    }
    return (await database).insert(
      'reviews',
      review.toJson()
        ..remove('id')
        ..['created_at'] = DateTime.now().toIso8601String(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<ReviewModel?> reviewForBooking(int bookingId) async {
    if (_apiEnabled) {
      final remote = await _api.reviewForBooking(bookingId);
      if (remote != null) return remote;
    }
    if (kIsWeb) {
      return _webReviews
          .where((item) => item.bookingId == bookingId)
          .firstOrNull;
    }
    final rows = await (await database).query(
      'reviews',
      where: 'booking_id = ?',
      whereArgs: [bookingId],
      limit: 1,
    );
    return rows.isEmpty ? null : ReviewModel.fromJson(rows.first);
  }

  Future<void> addNotification(NotificationModel item) async {
    if (kIsWeb) {
      await syncWebData();
      _webNotifications.insert(
        0,
        NotificationModel(
          id: _webNotificationId++,
          userId: item.userId,
          title: item.title,
          message: item.message,
          isRead: item.isRead,
          createdAt: item.createdAt ?? DateTime.now().toIso8601String(),
        ),
      );
      await _saveWebNotifications();
      return;
    }
    await (await database).insert(
      'notifications',
      item.toJson()
        ..remove('id')
        ..['created_at'] = item.createdAt ?? DateTime.now().toIso8601String(),
    );
  }

  Future<List<NotificationModel>> notifications(int userId) async {
    if (_apiEnabled) {
      final remote = await _api.notifications(userId);
      if (remote != null) return remote;
    }
    if (kIsWeb) {
      return _webNotifications.where((item) => item.userId == userId).toList();
    }
    final rows = await (await database).query(
      'notifications',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return rows.map(NotificationModel.fromJson).toList();
  }

  Future<void> markNotificationsRead(int userId) async {
    if (_apiEnabled && await _api.markNotificationsRead(userId)) return;
    if (kIsWeb) {
      for (var index = 0; index < _webNotifications.length; index++) {
        final item = _webNotifications[index];
        if (item.userId != userId || item.isRead) continue;
        _webNotifications[index] = NotificationModel(
          id: item.id,
          userId: item.userId,
          title: item.title,
          message: item.message,
          isRead: true,
          createdAt: item.createdAt,
        );
      }
      await _saveWebNotifications();
      return;
    }
    await (await database).update(
      'notifications',
      {'is_read': 1},
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> cacheProducts(List<ProductModel> products) async {
    if (kIsWeb) {
      _webProducts
        ..clear()
        ..addAll(products);
      return;
    }
    final db = await database;
    final batch = db.batch();
    for (final product in products) {
      batch.insert(
        'cached_products',
        product.toJson()
          ..remove('id')
          ..['created_at'] = DateTime.now().toIso8601String(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<ProductModel>> cachedProducts() async {
    if (_apiEnabled) {
      final remote = await _api.products();
      if (remote != null) return remote;
    }
    if (kIsWeb) return List.of(_webProducts);
    final rows = await (await database).query(
      'cached_products',
      orderBy: 'created_at DESC',
    );
    return rows.map(ProductModel.fromJson).toList();
  }
}
