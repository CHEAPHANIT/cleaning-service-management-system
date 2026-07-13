import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_core/firebase_core.dart' as firebase_core;
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/errors.dart';
import '../../core/utils.dart';
import '../local/database_helper.dart';
import '../models/models.dart';
import '../repositories/repositories.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this.repository, this.database);
  final AuthRepository repository;
  final DatabaseHelper database;
  bool loading = false;
  bool initialized = false;
  String? error;
  UserModel? user;
  bool onboarded = false;
  bool get loggedIn => user != null;

  Future<void> bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    onboarded = prefs.getBool('onboarded') ?? false;
    final savedUid = prefs.getString('current_user_uid');
    final savedToken = prefs.getString('auth_token');
    if (savedToken != null) {
      user = await repository.me(savedToken);
    }
    if (user == null && savedUid != null) {
      user =
          await repository.profile(savedUid) ??
          await database.getUserByUid(savedUid);
    }
    initialized = true;
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    onboarded = true;
    await (await SharedPreferences.getInstance()).setBool('onboarded', true);
    notifyListeners();
  }

  Future<bool> register(
    String name,
    String email,
    String phone,
    String password,
  ) async {
    return _run(() async {
      if (!repository.apiEnabled) {
        final model = UserModel(
          firebaseUid: 'demo-${email.toLowerCase()}',
          fullName: name,
          email: email,
          phone: phone,
        );
        user = model.copyWith(id: await database.upsertUser(model));
        await _saveSession();
        return;
      }
      user = await repository.register(email, password, name, phone);
      await _saveSession();
    });
  }

  Future<bool> login(String email, String password) async {
    return _run(() async {
      if (!repository.apiEnabled) {
        final uid = 'demo-${email.toLowerCase()}';
        user =
            await database.getUserByUid(uid) ??
            UserModel(
              firebaseUid: uid,
              fullName: 'Demo Customer',
              email: email,
              phone: '+855 123 456 789',
            );
        if (user!.id == null) {
          user = user!.copyWith(id: await database.upsertUser(user!));
        }
        await _saveSession();
        return;
      }
      user = await repository.login(email, password);
      await _saveSession();
    });
  }

  Future<bool> loginWithGoogle() async {
    return _run(() async {
      _ensureFirebaseReady();
      final account = await GoogleSignIn.instance.authenticate();
      final googleAuth = account.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw AppException('Google sign-in did not return an ID token.');
      }
      final credential = firebase_auth.GoogleAuthProvider.credential(
        idToken: idToken,
      );
      final result = await firebase_auth.FirebaseAuth.instance
          .signInWithCredential(credential);
      final firebaseUser = result.user;
      if (firebaseUser == null) {
        throw AppException('Google sign-in failed.');
      }
      await _signInWithSocialUser(
        firebaseUser: firebaseUser,
        provider: 'google',
      );
    });
  }

  Future<bool> loginWithFacebook() async {
    return _run(() async {
      _ensureFirebaseReady();
      final result = await FacebookAuth.instance.login(
        permissions: const ['email', 'public_profile'],
        loginTracking: LoginTracking.enabled,
      );
      if (result.status != LoginStatus.success || result.accessToken == null) {
        throw AppException('Facebook sign-in was cancelled.');
      }
      final credential = firebase_auth.FacebookAuthProvider.credential(
        result.accessToken!.tokenString,
      );
      final authResult = await firebase_auth.FirebaseAuth.instance
          .signInWithCredential(credential);
      final firebaseUser = authResult.user;
      if (firebaseUser == null) {
        throw AppException('Facebook sign-in failed.');
      }
      await _signInWithSocialUser(
        firebaseUser: firebaseUser,
        provider: 'facebook',
      );
    });
  }

  Future<bool> loginDemoRole(String role) async {
    return _run(() async {
      final normalizedRole = role.toLowerCase();
      if (repository.apiEnabled) {
        final email = switch (normalizedRole) {
          'admin' => 'admin@example.com',
          'cleaner' => 'cleaner@example.com',
          _ => 'customer@example.com',
        };
        final password = switch (normalizedRole) {
          'admin' => 'Admin@123',
          'cleaner' => 'Cleaner@123',
          _ => 'Customer@123',
        };
        user = await repository.login(email, password);
        await _saveSession();
        return;
      }
      final uid = 'demo-$normalizedRole';
      final savedUser = await database.getUserByUid(uid);
      if (savedUser != null) {
        user = savedUser;
        return;
      }
      final model = UserModel(
        firebaseUid: uid,
        fullName: switch (normalizedRole) {
          'admin' => 'Admin Demo',
          'cleaner' => 'Cleaner Demo',
          _ => 'Demo Customer',
        },
        email: '$normalizedRole@cleannow.demo',
        phone: '+855 123 456 789',
        role: normalizedRole,
      );
      user = model.copyWith(id: await database.upsertUser(model));
      await _saveSession();
    });
  }

  Future<bool> resetPassword(String email) =>
      _run(() async => repository.resetPassword(email));

  Future<void> updateProfile(
    String name,
    String phone,
    String address, {
    String? email,
  }) async {
    if (user == null) return;
    final updatedUser = user!.copyWith(
      fullName: name,
      email: email ?? user!.email,
      phone: phone,
      address: address,
    );
    await repository.updateProfile(updatedUser);
    await database.updateUser(updatedUser);
    user = updatedUser;
    notifyListeners();
  }

  Future<void> logout() async {
    // Clear the app session first. A user must still be logged out even when an
    // optional social provider is unavailable or its SDK throws during sign-out.
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user_uid');
    await prefs.remove('auth_token');
    user = null;
    error = null;
    notifyListeners();

    try {
      await repository.logout();
    } catch (_) {}
    try {
      if (firebase_core.Firebase.apps.isNotEmpty) {
        await firebase_auth.FirebaseAuth.instance.signOut();
      }
    } catch (_) {}
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    try {
      await FacebookAuth.instance.logOut();
    } catch (_) {}
  }

  Future<void> _signInWithSocialUser({
    required firebase_auth.User firebaseUser,
    required String provider,
  }) async {
    final email = firebaseUser.email ?? '';
    if (email.isEmpty) {
      throw AppException('This $provider account does not expose an email.');
    }
    final name = firebaseUser.displayName?.trim().isNotEmpty == true
        ? firebaseUser.displayName!.trim()
        : email.split('@').first;
    final phone = firebaseUser.phoneNumber?.trim().isNotEmpty == true
        ? firebaseUser.phoneNumber!.trim()
        : '+855 000 000 000';
    if (!repository.apiEnabled) {
      final model = UserModel(
        firebaseUid: firebaseUser.uid,
        fullName: name,
        email: email,
        phone: phone,
      );
      user = model.copyWith(id: await database.upsertUser(model));
      await _saveSession();
      return;
    }
    user = await repository.socialLogin(
      firebaseUid: firebaseUser.uid,
      fullName: name,
      email: email,
      phone: phone,
      provider: provider,
    );
    await _saveSession();
  }

  void _ensureFirebaseReady() {
    if (firebase_core.Firebase.apps.isEmpty) {
      throw AppException(
        'Firebase is not configured yet. Add firebase_options.dart or platform Firebase config before using social sign-in.',
      );
    }
    if (firebase_auth.FirebaseAuth.instance.app.options.apiKey.isEmpty) {
      throw AppException(
        'Firebase is not configured yet. Add Firebase options before using social sign-in.',
      );
    }
  }

  Future<void> _saveSession() async {
    if (user == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_user_uid', user!.firebaseUid);
    final token = repository.authToken;
    if (token != null) await prefs.setString('auth_token', token);
  }

  Future<bool> _run(Future<void> Function() action) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await action();
      loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      loading = false;
      error = e.toString();
      notifyListeners();
      return false;
    }
  }
}

class ServiceProvider extends ChangeNotifier {
  ServiceProvider(this.repository);
  final ServiceRepository repository;
  bool loading = false;
  String? error;
  List<ServiceModel> services = [];
  String search = '';
  String category = 'All';
  String sort = 'Popular';

  List<String> get categories => [
    'All',
    ...{for (final item in services) item.category},
  ];

  List<ServiceModel> get filtered {
    var result = services
        .where(
          (item) =>
              item.isActive &&
              item.name.toLowerCase().contains(search.toLowerCase()) &&
              (category == 'All' || item.category == category),
        )
        .toList();
    if (sort == 'Price')
      result.sort((a, b) => a.basePrice.compareTo(b.basePrice));
    if (sort == 'Rating') result.sort((a, b) => b.rating.compareTo(a.rating));
    return result;
  }

  Future<void> loadServices() async {
    loading = true;
    notifyListeners();
    try {
      services = await repository.getServices();
      error = null;
    } catch (_) {
      error = 'No services found.';
    }
    loading = false;
    notifyListeners();
  }

  Future<void> saveService(ServiceModel service) async {
    await repository.database.saveService(service);
    await loadServices();
  }

  Future<void> deleteService(ServiceModel service) async {
    await repository.database.deleteService(service.id);
    await loadServices();
  }

  void updateSearch(String value) {
    search = value;
    notifyListeners();
  }

  void updateCategory(String value) {
    category = value;
    notifyListeners();
  }

  void updateSort(String value) {
    sort = value;
    notifyListeners();
  }
}

class BookingProvider extends ChangeNotifier {
  BookingProvider(this.database) : repository = BookingRepository(database);
  final DatabaseHelper database;
  final BookingRepository repository;
  bool loading = false;
  String? error;
  List<BookingModel> bookings = [];
  BookingModel? lastCreatedBooking;
  Timer? _realtimeTimer;
  bool _realtimeSyncing = false;

  void startRealtime(UserModel? user) {
    _realtimeTimer?.cancel();
    if (user == null || !database.supportsRealtimeSync) return;
    unawaited(_syncRealtime(user));
    _realtimeTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => unawaited(_syncRealtime(user)),
    );
  }

  Future<void> _syncRealtime(UserModel user) async {
    if (_realtimeSyncing) return;
    _realtimeSyncing = true;
    try {
      await database.syncWebData();
      final latest = switch (user.role) {
        'admin' => await database.allBookings(),
        'cleaner' => await database.bookingsForCleaner(user.id!),
        _ => await repository.byUser(user.id!),
      };
      if (jsonEncode(latest.map((item) => item.toJson()).toList()) !=
          jsonEncode(bookings.map((item) => item.toJson()).toList())) {
        bookings = latest;
        notifyListeners();
      }
    } finally {
      _realtimeSyncing = false;
    }
  }

  @override
  void dispose() {
    _realtimeTimer?.cancel();
    super.dispose();
  }

  Future<void> load(int? userId) async {
    if (userId == null) return;
    loading = true;
    notifyListeners();
    bookings = await repository.byUser(userId);
    loading = false;
    notifyListeners();
  }

  Future<void> loadForRole(UserModel? user) async {
    if (user == null) return;
    loading = true;
    notifyListeners();
    if (user.role == 'admin') {
      bookings = await database.allBookings();
    } else if (user.role == 'cleaner') {
      bookings = await database.bookingsForCleaner(user.id!);
    } else {
      bookings = await repository.byUser(user.id!);
    }
    loading = false;
    notifyListeners();
  }

  Future<bool> create(BookingModel booking) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final id = await repository.create(booking);
      lastCreatedBooking = booking.copyWith(id: id);
      bookings = [lastCreatedBooking!, ...bookings];
      loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> cancel(BookingModel booking, UserModel user) async {
    if (user.role != 'customer' || booking.userId != user.id) {
      throw ValidationException(
        'You cannot cancel another customer\'s booking.',
      );
    }
    await repository.cancel(booking);
    await load(booking.userId);
  }

  Future<void> updateStatus(
    BookingModel booking,
    String status,
    UserModel user,
  ) async {
    final allowed = switch (user.role) {
      'admin' => _adminBookingTransitions[booking.status] ?? const <String>{},
      'cleaner' when booking.cleanerId == user.id =>
        _cleanerBookingTransitions[booking.status] ?? const <String>{},
      _ => const <String>{},
    };
    if (!allowed.contains(status)) {
      throw ValidationException(
        'The ${user.role} role cannot change ${booking.status} to $status.',
      );
    }
    await database.updateBookingStatus(booking.id!, status);
    await loadForRole(user);
  }

  Future<void> updateDocumentation(BookingModel booking) async {
    await database.updateBookingDocumentation(booking);
    final index = bookings.indexWhere((item) => item.id == booking.id);
    if (index >= 0) bookings[index] = booking;
    notifyListeners();
  }

  Future<void> assignCleaner(
    BookingModel booking,
    UserModel cleaner,
    UserModel admin,
  ) async {
    if (admin.role != 'admin') return;
    await database.assignBookingCleaner(booking, cleaner);
    await loadForRole(admin);
  }

  double cleanerIncome(int cleanerId) => bookings
      .where(
        (item) => item.cleanerId == cleanerId && item.status == 'Completed',
      )
      .fold(0, (sum, item) => sum + item.cleanerPay);

  double cleanerPendingPay(int cleanerId) => bookings
      .where(
        (item) => item.cleanerId == cleanerId && item.status != 'Completed',
      )
      .fold(0, (sum, item) => sum + item.cleanerPay);
}

const Map<String, Set<String>> _adminBookingTransitions = {
  'Pending': {'Accepted', 'Cancelled', 'Rejected'},
  'Accepted': {'Cancelled', 'Rejected'},
  'Cleaner Assigned': {'Cancelled', 'Rejected'},
  'On the Way': {'Cancelled', 'Rejected'},
  'Arrived': {'Cancelled', 'Rejected'},
  'In Progress': {'Cancelled', 'Rejected'},
};

const Map<String, Set<String>> _cleanerBookingTransitions = {
  'Cleaner Assigned': {'On the Way'},
  'On the Way': {'Arrived'},
  'Arrived': {'In Progress'},
  'In Progress': {'Completed'},
};

class AdminDataProvider extends ChangeNotifier {
  AdminDataProvider(this.database);
  final DatabaseHelper database;
  bool loading = false;
  List<UserModel> users = [];
  List<UserModel> cleaners = [];
  List<CleanerApplicationModel> cleanerApplications = [];
  Timer? _realtimeTimer;
  bool _realtimeSyncing = false;

  void startRealtime() {
    _realtimeTimer?.cancel();
    if (!database.supportsRealtimeSync) return;
    _realtimeTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => unawaited(_syncRealtime()),
    );
  }

  void stopRealtime() => _realtimeTimer?.cancel();

  Future<void> _syncRealtime() async {
    if (_realtimeSyncing) return;
    _realtimeSyncing = true;
    try {
      await database.syncWebData();
      final latestUsers = await database.users();
      final latestApplications = await database.cleanerApplications();
      final latestCleaners = latestUsers
          .where((item) => item.role == 'cleaner' && item.isActive)
          .toList();
      final usersChanged =
          jsonEncode(latestUsers.map((item) => item.toJson()).toList()) !=
          jsonEncode(users.map((item) => item.toJson()).toList());
      final applicationsChanged =
          jsonEncode(
            latestApplications.map((item) => item.toJson()).toList(),
          ) !=
          jsonEncode(cleanerApplications.map((item) => item.toJson()).toList());
      if (usersChanged || applicationsChanged) {
        users = latestUsers;
        cleaners = latestCleaners;
        cleanerApplications = latestApplications;
        notifyListeners();
      }
    } finally {
      _realtimeSyncing = false;
    }
  }

  @override
  void dispose() {
    _realtimeTimer?.cancel();
    super.dispose();
  }

  Future<void> load() async {
    loading = true;
    notifyListeners();
    users = await database.users();
    cleaners = await database.cleaners();
    cleanerApplications = await database.cleanerApplications();
    loading = false;
    notifyListeners();
  }

  Future<void> saveUser(UserModel user) async {
    await database.upsertUser(user);
    await load();
  }

  Future<void> deleteUser(UserModel user) async {
    if (user.id == null) return;
    await database.deleteUser(user.id!);
    await load();
  }

  Future<void> submitCleanerApplication(
    CleanerApplicationModel application,
  ) async {
    await database.saveCleanerApplication(application);
    await load();
  }

  Future<void> addCleanerFromApplication(
    CleanerApplicationModel application,
  ) async {
    await database.addCleanerFromApplication(application);
    await load();
  }

  Future<void> approveCleanerApplication(
    CleanerApplicationModel application,
  ) async {
    await database.approveCleanerApplication(application);
    await load();
  }

  Future<void> rejectCleanerApplication(
    CleanerApplicationModel application, {
    String note = '',
  }) async {
    await database.rejectCleanerApplication(application, note: note);
    await load();
  }
}

class FavoriteProvider extends ChangeNotifier {
  FavoriteProvider(this.database);
  final DatabaseHelper database;
  List<FavoriteModel> favorites = [];

  bool isFavorite(int serviceId) =>
      favorites.any((item) => item.serviceId == serviceId);

  Future<void> load(int? userId) async {
    if (userId == null) return;
    favorites = await database.favorites(userId);
    notifyListeners();
  }

  Future<void> toggle(int userId, ServiceModel service) async {
    await database.toggleFavorite(
      FavoriteModel(
        userId: userId,
        serviceId: service.id,
        serviceName: service.name,
        serviceImage: service.imageUrl,
        servicePrice: service.basePrice,
      ),
    );
    await load(userId);
  }
}

class ProductProvider extends ChangeNotifier {
  ProductProvider(this.repository);
  final ProductRepository repository;
  bool loading = false;
  String? error;
  List<ProductModel> products = [];
  String search = '';

  List<ProductModel> get filtered => products
      .where((item) => item.title.toLowerCase().contains(search.toLowerCase()))
      .toList();

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      products = await repository.products();
    } catch (e) {
      error = e.toString();
    }
    loading = false;
    notifyListeners();
  }

  void updateSearch(String value) {
    search = value;
    notifyListeners();
  }
}

class NotificationProvider extends ChangeNotifier {
  NotificationProvider(this.database);
  final DatabaseHelper database;
  List<NotificationModel> notifications = [];
  Timer? _realtimeTimer;
  bool _realtimeSyncing = false;
  int get unreadCount =>
      notifications.where((notification) => !notification.isRead).length;

  void startRealtime(int? userId) {
    _realtimeTimer?.cancel();
    if (userId == null || !database.supportsRealtimeSync) return;
    unawaited(_syncRealtime(userId));
    _realtimeTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => unawaited(_syncRealtime(userId)),
    );
  }

  Future<void> _syncRealtime(int userId) async {
    if (_realtimeSyncing) return;
    _realtimeSyncing = true;
    try {
      await database.syncWebData();
      final latest = await database.notifications(userId);
      if (jsonEncode(latest.map((item) => item.toJson()).toList()) !=
          jsonEncode(notifications.map((item) => item.toJson()).toList())) {
        notifications = latest;
        notifyListeners();
      }
    } finally {
      _realtimeSyncing = false;
    }
  }

  @override
  void dispose() {
    _realtimeTimer?.cancel();
    super.dispose();
  }

  Future<void> load(int? userId) async {
    if (userId == null) return;
    notifications = await database.notifications(userId);
    notifyListeners();
  }

  Future<void> markAllRead(int? userId) async {
    if (userId == null || unreadCount == 0) return;
    await database.markNotificationsRead(userId);
    notifications = notifications
        .map(
          (item) => NotificationModel(
            id: item.id,
            userId: item.userId,
            title: item.title,
            message: item.message,
            isRead: true,
            createdAt: item.createdAt,
          ),
        )
        .toList();
    notifyListeners();
  }
}

class BookingDraft {
  BookingDraft({required this.service, required this.user});
  final ServiceModel service;
  final UserModel user;
  final extras = <String>[];
  String propertyType = 'House';
  String paymentMethod = 'Cash';
  int rooms = 2;
  int bathrooms = 1;
  DateTime? date;
  TimeOfDay? time;

  double get total =>
      PriceCalculator.total(service.basePrice, rooms, bathrooms, extras);
  double get extraPrice => total - service.basePrice;
  int get duration => PriceCalculator.duration(
    service.durationMinutes,
    rooms,
    bathrooms,
    extras,
  );
}
