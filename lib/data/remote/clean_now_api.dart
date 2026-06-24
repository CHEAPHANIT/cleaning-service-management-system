import 'package:dio/dio.dart';

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
          connectTimeout: const Duration(seconds: 2),
          receiveTimeout: const Duration(seconds: 3),
          headers: const {'Content-Type': 'application/json'},
        ),
      );

  final Dio _dio;

  Future<UserModel?> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) => _userPost('/auth/register', {
    'full_name': name,
    'email': email,
    'phone': phone,
    'password': password,
  });

  Future<UserModel?> login(String email, String password) =>
      _userPost('/auth/login', {'email': email, 'password': password});

  Future<bool> resetPassword(String email) =>
      _postOk('/auth/reset-password', {'email': email});

  Future<UserModel?> upsertUser(UserModel user) async {
    try {
      final response = await _dio.post('/users/upsert', data: user.toJson());
      return UserModel.fromJson(_map(response.data));
    } on DioException {
      return null;
    }
  }

  Future<List<UserModel>?> users() async {
    try {
      final response = await _dio.get('/users');
      return _list(response.data).map(UserModel.fromJson).toList();
    } on DioException {
      return null;
    }
  }

  Future<bool> deleteUser(int id) => _delete('/users/$id');

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
      final response = await _dio.post('/services', data: service.toJson());
      return ServiceModel.fromJson(_map(response.data));
    } on DioException {
      return null;
    }
  }

  Future<bool> deleteService(int id) => _delete('/services/$id');

  Future<BookingModel?> createBooking(BookingModel booking) async {
    try {
      final response = await _dio.post('/bookings', data: booking.toJson());
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
      final response = await _dio.get('/bookings', queryParameters: query);
      return _list(response.data).map(BookingModel.fromJson).toList();
    } on DioException {
      return null;
    }
  }

  Future<bool> updateStatus(int id, String status) =>
      _patch('/bookings/$id/status', {'status': status});

  Future<bool> updateDocumentation(BookingModel booking) =>
      _patch('/bookings/${booking.id}/documentation', {
        'before_photos': booking.beforePhotos,
        'after_photos': booking.afterPhotos,
        'completion_notes': booking.completionNotes,
      });

  Future<bool?> assignCleaner(
    int bookingId,
    UserModel cleaner,
    double cleanerPay,
  ) async {
    try {
      await _dio.patch(
        '/bookings/$bookingId/assign',
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
      );
      return _list(response.data).map(NotificationModel.fromJson).toList();
    } on DioException {
      return null;
    }
  }

  Future<bool> markNotificationsRead(int userId) =>
      _patch('/notifications/read-all', {'user_id': userId});

  Future<List<FavoriteModel>?> favorites(int userId) async {
    try {
      final response = await _dio.get(
        '/favorites',
        queryParameters: {'user_id': userId},
      );
      return _list(response.data).map(FavoriteModel.fromJson).toList();
    } on DioException {
      return null;
    }
  }

  Future<bool> toggleFavorite(FavoriteModel favorite) =>
      _postOk('/favorites/toggle', favorite.toJson());

  Future<List<Map<String, dynamic>>?> addresses(int userId) async {
    try {
      final response = await _dio.get(
        '/addresses',
        queryParameters: {'user_id': userId},
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
  });

  Future<int?> addReview(ReviewModel review) async {
    try {
      final response = await _dio.post('/reviews', data: review.toJson());
      return (_map(response.data)['id'] as num).toInt();
    } on DioException {
      return null;
    }
  }

  Future<ReviewModel?> reviewForBooking(int bookingId) async {
    try {
      final response = await _dio.get('/reviews/booking/$bookingId');
      return ReviewModel.fromJson(_map(response.data));
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

  Future<UserModel?> _userPost(String path, Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(path, data: data);
      return UserModel.fromJson(_map(response.data));
    } on DioException {
      return null;
    }
  }

  Future<bool> _postOk(String path, Map<String, dynamic> data) async {
    try {
      await _dio.post(path, data: data);
      return true;
    } on DioException {
      return false;
    }
  }

  Future<bool> _delete(String path) async {
    try {
      await _dio.delete(path);
      return true;
    } on DioException {
      return false;
    }
  }

  Future<bool> _patch(String path, Map<String, dynamic> data) async {
    try {
      await _dio.patch(path, data: data);
      return true;
    } on DioException {
      return false;
    }
  }

  Map<String, dynamic> _map(dynamic value) =>
      Map<String, dynamic>.from(value as Map);

  List<Map<String, dynamic>> _list(dynamic value) => (value as List)
      .map((item) => Map<String, dynamic>.from(item as Map))
      .toList();
}
