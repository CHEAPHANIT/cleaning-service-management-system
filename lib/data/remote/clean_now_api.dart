import 'package:dio/dio.dart';

import '../../core/errors.dart';
import '../models/models.dart';

/// REST client for the shared CleanNow SQLite server.
///
/// Override the URL when needed with:
/// `--dart-define=CLEAN_NOW_API_URL=http://host:8080/api`
class CleanNowApi {
  CleanNowApi()
    : _dio = Dio(
        BaseOptions(
          baseUrl: const String.fromEnvironment(
            'CLEAN_NOW_API_URL',
            defaultValue: 'http://localhost:8080/api',
          ),
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 20),
          headers: const {'Content-Type': 'application/json'},
        ),
      );

  final Dio _dio;
  static String? _authToken;

  static void setAuthToken(String? token) {
    _authToken = token;
  }

  static String? get authToken => _authToken;

  Options get _authOptions => Options(
    headers: _authToken == null
        ? null
        : {'Authorization': 'Bearer $_authToken'},
  );

  Future<UserModel?> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) => _userPost('/auth/register-customer', {
    'full_name': name,
    'email': email,
    'phone': phone,
    'password': password,
  });

  Future<UserModel?> login(String email, String password) =>
      _userPost('/auth/login', {'email': email, 'password': password});

  Future<UserModel?> socialLogin({
    required String firebaseUid,
    required String fullName,
    required String email,
    required String phone,
    required String provider,
  }) => _userPost('/auth/social-login', {
    'firebase_uid': firebaseUid,
    'full_name': fullName,
    'email': email,
    'phone': phone,
    'provider': provider,
  });

  Future<UserModel?> me() => _userGet('/auth/me');

  Future<bool> logout() async {
    setAuthToken(null);
    return _postOk('/auth/logout', {});
  }

  Future<CleanerApplicationModel?> createCleanerApplication(
    CleanerApplicationModel application,
  ) async {
    try {
      final response = await _dio.post(
        '/cleaner-applications',
        data: application.toJson(),
      );
      final body = _mapOrNull(response.data);
      if (body == null) {
        throw ServerException(
          'The application may have been saved, but the server returned an invalid response. Check the admin queue before trying again.',
        );
      }
      return CleanerApplicationModel.fromJson(body);
    } on DioException catch (error) {
      final message = _apiError(error);
      if (message != null) throw ValidationException(message);
      throw NetworkException(
        'The application server did not respond. Please try again.',
      );
    }
  }

  Future<CleanerApplicationModel?> adminCreateCleaner(
    CleanerApplicationModel application,
  ) async {
    try {
      final response = await _dio.post(
        '/admin/cleaners',
        data: application.toJson(),
        options: _authOptions,
      );
      return CleanerApplicationModel.fromJson(_map(response.data));
    } on DioException {
      return null;
    }
  }

  Future<List<CleanerApplicationModel>?> cleanerApplications() async {
    try {
      final response = await _dio.get(
        '/admin/cleaner-applications',
        options: _authOptions,
      );
      return _list(
        response.data,
      ).map(CleanerApplicationModel.fromJson).toList();
    } on DioException {
      return null;
    }
  }

  Future<CleanerApplicationModel?> cleanerApplication(int id) async {
    try {
      final response = await _dio.get(
        '/admin/cleaner-applications/$id',
        options: _authOptions,
      );
      return CleanerApplicationModel.fromJson(_map(response.data));
    } on DioException {
      return null;
    }
  }

  Future<bool> approveCleanerApplication(int id) =>
      _postOk('/admin/cleaner-applications/$id/approve', {}, auth: true);

  Future<bool> rejectCleanerApplication(int id, {String note = ''}) => _postOk(
    '/admin/cleaner-applications/$id/reject',
    {'admin_note': note},
    auth: true,
  );

  Future<bool> resetPassword(String email) =>
      _postOk('/auth/reset-password', {'email': email});

  Future<UserModel?> upsertUser(UserModel user) async {
    try {
      final response = await _dio.post(
        '/users/upsert',
        data: user.toJson(),
        options: _authOptions,
      );
      return UserModel.fromJson(_map(response.data));
    } on DioException {
      return null;
    }
  }

  Future<List<UserModel>?> users() async {
    try {
      final response = await _dio.get('/users', options: _authOptions);
      return _list(response.data).map(UserModel.fromJson).toList();
    } on DioException {
      return null;
    }
  }

  Future<bool> deleteUser(int id) => _delete('/users/$id');

  Future<bool> updateUserStatus(int id, String status) =>
      _patch('/admin/users/$id/status', {'status': status}, auth: true);

  Future<List<ServiceModel>?> services() async {
    try {
      final response = await _dio.get('/services');
      return _list(response.data).map(ServiceModel.fromJson).toList();
    } on DioException {
      return null;
    }
  }

  Future<ServiceModel?> saveService(ServiceModel service) async {
    try {
      final response = await _dio.post(
        '/services',
        data: service.toJson(),
        options: _authOptions,
      );
      return ServiceModel.fromJson(_map(response.data));
    } on DioException {
      return null;
    }
  }

  Future<bool> deleteService(int id) => _delete('/services/$id');

  Future<BookingModel?> createBooking(BookingModel booking) async {
    try {
      final response = await _dio.post(
        '/bookings',
        data: booking.toJson(),
        options: _authOptions,
      );
      return BookingModel.fromJson(_map(response.data));
    } on DioException {
      return null;
    }
  }

  Future<List<BookingModel>?> bookings({int? userId, int? cleanerId}) async {
    try {
      final query = <String, dynamic>{};
      if (userId != null) query['user_id'] = userId;
      if (cleanerId != null) query['cleaner_id'] = cleanerId;
      final response = await _dio.get(
        '/bookings',
        queryParameters: query,
        options: _authOptions,
      );
      return _list(response.data).map(BookingModel.fromJson).toList();
    } on DioException {
      return null;
    }
  }

  Future<bool> updateStatus(int id, String status) =>
      _patch('/bookings/$id/status', {'status': status}, auth: true);

  Future<bool> updateDocumentation(BookingModel booking) =>
      _patch('/bookings/${booking.id}/documentation', {
        'before_photos': booking.beforePhotos,
        'after_photos': booking.afterPhotos,
        'completion_notes': booking.completionNotes,
      }, auth: true);

  Future<bool?> assignCleaner(
    int bookingId,
    UserModel cleaner,
    double cleanerPay,
  ) async {
    try {
      await _dio.patch(
        '/bookings/$bookingId/assign',
        options: _authOptions,
        data: {
          'cleaner_id': cleaner.id,
          'cleaner_name': cleaner.fullName,
          'cleaner_pay': cleanerPay,
        },
      );
      return true;
    } on DioException catch (error) {
      if (error.response?.statusCode == 409) return false;
      return null;
    }
  }

  Future<List<NotificationModel>?> notifications(int userId) async {
    try {
      final response = await _dio.get(
        '/notifications',
        queryParameters: {'user_id': userId},
        options: _authOptions,
      );
      return _list(response.data).map(NotificationModel.fromJson).toList();
    } on DioException {
      return null;
    }
  }

  Future<bool> markNotificationsRead(int userId) =>
      _patch('/notifications/read-all', {'user_id': userId}, auth: true);

  Future<List<FavoriteModel>?> favorites(int userId) async {
    try {
      final response = await _dio.get(
        '/favorites',
        queryParameters: {'user_id': userId},
        options: _authOptions,
      );
      return _list(response.data).map(FavoriteModel.fromJson).toList();
    } on DioException {
      return null;
    }
  }

  Future<bool> toggleFavorite(FavoriteModel favorite) =>
      _postOk('/favorites/toggle', favorite.toJson(), auth: true);

  Future<List<Map<String, dynamic>>?> addresses(int userId) async {
    try {
      final response = await _dio.get(
        '/addresses',
        queryParameters: {'user_id': userId},
        options: _authOptions,
      );
      return _list(response.data);
    } on DioException {
      return null;
    }
  }

  Future<bool> saveAddresses(
    int userId,
    List<Map<String, dynamic>> addresses,
  ) => _postOk('/addresses/replace', {
    'user_id': userId,
    'addresses': addresses,
  }, auth: true);

  Future<int?> addReview(ReviewModel review) async {
    try {
      final response = await _dio.post(
        '/reviews',
        data: review.toJson(),
        options: _authOptions,
      );
      return (_map(response.data)['id'] as num).toInt();
    } on DioException {
      return null;
    }
  }

  Future<ReviewModel?> reviewForBooking(int bookingId) async {
    try {
      final response = await _dio.get(
        '/reviews/booking/$bookingId',
        options: _authOptions,
      );
      return ReviewModel.fromJson(_map(response.data));
    } on DioException {
      return null;
    }
  }

  Future<List<ReviewModel>?> reviewsForCleaner(int cleanerId) async {
    try {
      final response = await _dio.get(
        '/reviews',
        queryParameters: {'cleaner_id': cleanerId},
        options: _authOptions,
      );
      return _list(response.data).map(ReviewModel.fromJson).toList();
    } on DioException {
      return null;
    }
  }

  Future<List<ProductModel>?> products() async {
    try {
      final response = await _dio.get('/products');
      return _list(response.data).map(ProductModel.fromJson).toList();
    } on DioException {
      return null;
    }
  }

  Future<Map<String, dynamic>?> createDemoPayment(double amount) async {
    try {
      final response = await _dio.post(
        '/demo-payments',
        options: _authOptions,
        data: {
          'amount': amount,
          'public_base_url': const String.fromEnvironment(
            'CLEAN_NOW_PUBLIC_URL',
          ),
        },
      );
      return _map(response.data);
    } on DioException {
      return null;
    }
  }

  Future<Map<String, dynamic>?> demoPayment(String id) async {
    try {
      final response = await _dio.get(
        '/demo-payments/$id',
        options: _authOptions,
      );
      return _map(response.data);
    } on DioException {
      return null;
    }
  }

  Future<UserModel?> _userPost(String path, Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(path, data: data);
      final body = _map(response.data);
      final token = body['token']?.toString();
      if (token != null && token.isNotEmpty) setAuthToken(token);
      return UserModel.fromJson(
        body['user'] is Map
            ? Map<String, dynamic>.from(body['user'] as Map)
            : body,
      );
    } on DioException catch (error) {
      throw Exception(
        _mapOrNull(error.response?.data)?['error']?.toString() ??
            'Invalid email or password.',
      );
    }
  }

  Future<UserModel?> _userGet(String path) async {
    try {
      final response = await _dio.get(path, options: _authOptions);
      final body = _map(response.data);
      return UserModel.fromJson(
        body['user'] is Map
            ? Map<String, dynamic>.from(body['user'] as Map)
            : body,
      );
    } on DioException {
      return null;
    }
  }

  Future<bool> _postOk(
    String path,
    Map<String, dynamic> data, {
    bool auth = false,
  }) async {
    try {
      await _dio.post(path, data: data, options: auth ? _authOptions : null);
      return true;
    } on DioException {
      return false;
    }
  }

  Future<bool> _delete(String path) async {
    try {
      await _dio.delete(path, options: _authOptions);
      return true;
    } on DioException {
      return false;
    }
  }

  Future<bool> _patch(
    String path,
    Map<String, dynamic> data, {
    bool auth = false,
  }) async {
    try {
      await _dio.patch(path, data: data, options: auth ? _authOptions : null);
      return true;
    } on DioException {
      return false;
    }
  }

  Map<String, dynamic> _map(dynamic value) =>
      Map<String, dynamic>.from(value as Map);

  Map<String, dynamic>? _mapOrNull(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  String? _apiError(DioException error) {
    final message = _mapOrNull(error.response?.data)?['error']?.toString();
    if (message != null && message.trim().isNotEmpty) return message;
    if (error.response?.statusCode == 413) {
      return 'The selected images are too large. Choose smaller images and try again.';
    }
    return null;
  }

  List<Map<String, dynamic>> _list(dynamic value) => (value as List)
      .map((item) => Map<String, dynamic>.from(item as Map))
      .toList();
}
