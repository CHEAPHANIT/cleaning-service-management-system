import 'dart:async';

import '../../core/errors.dart';
import '../local/database_helper.dart';
import '../models/models.dart';
import '../remote/clean_now_api.dart';

class AuthRepository {
  AuthRepository(this.apiEnabled);
  final bool apiEnabled;
  final CleanNowApi _api = CleanNowApi();
  String? get authToken => CleanNowApi.authToken;

  Future<UserModel> register(
    String email,
    String password,
    String name,
    String phone,
  ) async {
    if (!apiEnabled) throw AppException('The CleanNow API is not enabled.');
    final user = await _api.register(
      name: name,
      email: email,
      phone: phone,
      password: password,
    );
    if (user == null)
      throw AppException(
        'Registration failed. Check that the API is running and the email is available.',
      );
    return user;
  }

  Future<UserModel> login(String email, String password) async {
    if (!apiEnabled) throw AppException('The CleanNow API is not enabled.');
    final user = await _api.login(email, password);
    if (user == null)
      throw AppException(
        'Invalid email or password, or the API is unavailable.',
      );
    return user;
  }

  Future<UserModel> socialLogin({
    required String firebaseUid,
    required String fullName,
    required String email,
    required String phone,
    required String provider,
  }) async {
    if (!apiEnabled) throw AppException('The CleanNow API is not enabled.');
    final user = await _api.socialLogin(
      firebaseUid: firebaseUid,
      fullName: fullName,
      email: email,
      phone: phone,
      provider: provider,
    );
    if (user == null) throw AppException('Social sign-in failed.');
    return user;
  }

  Future<UserModel?> me(String? token) async {
    if (!apiEnabled || token == null) return null;
    CleanNowApi.setAuthToken(token);
    return _api.me();
  }

  Future<UserModel?> profile(String uid) async {
    if (!apiEnabled) return null;
    final users = await _api.users();
    return users?.where((item) => item.firebaseUid == uid).firstOrNull;
  }

  Future<void> updateProfile(UserModel user) async {
    if (!apiEnabled) return;
    if (await _api.upsertUser(user) == null) {
      throw AppException('Could not update the profile through the API.');
    }
  }

  Future<void> resetPassword(String email) async {
    if (!apiEnabled || !await _api.resetPassword(email)) {
      throw AppException('Could not submit the password reset request.');
    }
  }

  Future<void> logout() async {
    if (apiEnabled) await _api.logout();
  }
}

class ServiceRepository {
  ServiceRepository(this.database);
  final DatabaseHelper database;
  Future<List<ServiceModel>> getServices() => database.services();
  Future<ServiceModel?> getService(int id) => database.service(id);
}

class BookingRepository {
  BookingRepository(this.database);
  final DatabaseHelper database;
  Future<int> create(BookingModel booking) => database.saveBooking(booking);
  Future<List<BookingModel>> byUser(int userId) => database.bookings(userId);
  Future<void> cancel(BookingModel booking) async {
    if (!['Pending', 'Accepted'].contains(booking.status))
      throw ValidationException('This booking can no longer be cancelled.');
    await database.updateBookingStatus(booking.id!, 'Cancelled');
  }
}

class ProductRepository {
  ProductRepository(this.database);
  final DatabaseHelper database;

  Future<List<ProductModel>> products() async {
    final products = await database.cachedProducts();
    if (products.isEmpty)
      throw ServerException('No products are available from the API.');
    return products;
  }
}
