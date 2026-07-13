import 'dart:convert';

class UserModel {
  const UserModel({
    this.id,
    required this.firebaseUid,
    required this.fullName,
    required this.email,
    required this.phone,
    this.role = 'customer',
    this.address = '',
    this.hourlyRate = 8,
    this.isActive = true,
    this.status = 'active',
    this.availabilityStatus = 'Available',
    this.createdAt,
    this.updatedAt,
  });
  final int? id;
  final String firebaseUid;
  final String fullName;
  final String email;
  final String phone;
  final String role;
  final String address;
  final double hourlyRate;
  final bool isActive;
  final String status;
  final String availabilityStatus;
  final String? createdAt;
  final String? updatedAt;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final status = json['status']?.toString();
    final isActive = status == null
        ? (json['is_active'] ?? 1) == 1 || json['is_active'] == true
        : status == 'active';
    return UserModel(
      id: json['id'] as int?,
      firebaseUid:
          json['firebase_uid']?.toString() ??
          json['firebaseUid']?.toString() ??
          '',
      fullName:
          json['full_name']?.toString() ?? json['fullName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      role: json['role']?.toString() ?? 'customer',
      address: json['address']?.toString() ?? '',
      hourlyRate: (json['hourly_rate'] as num?)?.toDouble() ?? 8,
      isActive: isActive,
      status: status ?? (isActive ? 'active' : 'inactive'),
      availabilityStatus:
          json['availability_status']?.toString() ??
          (isActive ? 'Available' : 'Off Duty'),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'firebase_uid': firebaseUid,
    'full_name': fullName,
    'email': email,
    'phone': phone,
    'role': role,
    'address': address,
    'hourly_rate': hourlyRate,
    'is_active': isActive ? 1 : 0,
    'status': status,
    'availability_status': isActive ? availabilityStatus : 'Off Duty',
    'created_at': createdAt,
    'updated_at': updatedAt,
  };

  UserModel copyWith({
    int? id,
    String? firebaseUid,
    String? fullName,
    String? email,
    String? phone,
    String? role,
    String? address,
    double? hourlyRate,
    bool? isActive,
    String? status,
    String? availabilityStatus,
    String? createdAt,
    String? updatedAt,
  }) => UserModel(
    id: id ?? this.id,
    firebaseUid: firebaseUid ?? this.firebaseUid,
    fullName: fullName ?? this.fullName,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    role: role ?? this.role,
    address: address ?? this.address,
    hourlyRate: hourlyRate ?? this.hourlyRate,
    isActive: isActive ?? this.isActive,
    status: status ?? (isActive == false ? 'inactive' : this.status),
    availabilityStatus:
        availabilityStatus ??
        (isActive == false
            ? 'Off Duty'
            : isActive == true && this.availabilityStatus == 'Off Duty'
            ? 'Available'
            : this.availabilityStatus),
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

class CleanerApplicationModel {
  const CleanerApplicationModel({
    this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.gender,
    required this.address,
    required this.workExperience,
    required this.skills,
    required this.availableDays,
    required this.availableTime,
    this.password = '',
    this.profilePhoto = '',
    this.idDocument = '',
    this.status = 'pending',
    this.adminNote = '',
    this.userId,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final String fullName;
  final String email;
  final String phone;
  final String gender;
  final String address;
  final String workExperience;
  final String skills;
  final String availableDays;
  final String availableTime;

  /// Write-only credential used when submitting or directly creating a cleaner.
  /// The API never returns this value.
  final String password;
  final String profilePhoto;
  final String idDocument;
  final String status;
  final String adminNote;
  final int? userId;
  final String? createdAt;
  final String? updatedAt;

  factory CleanerApplicationModel.fromJson(Map<String, dynamic> json) =>
      CleanerApplicationModel(
        id: json['id'] as int?,
        fullName: json['full_name']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        phone: json['phone']?.toString() ?? '',
        gender: json['gender']?.toString() ?? '',
        address: json['address']?.toString() ?? '',
        workExperience: json['work_experience']?.toString() ?? '',
        skills: json['skills']?.toString() ?? '',
        availableDays: json['available_days']?.toString() ?? '',
        availableTime: json['available_time']?.toString() ?? '',
        password: '',
        profilePhoto: json['profile_photo']?.toString() ?? '',
        idDocument: json['id_document']?.toString() ?? '',
        status: json['status']?.toString() ?? 'pending',
        adminNote: json['admin_note']?.toString() ?? '',
        userId: (json['user_id'] as num?)?.toInt(),
        createdAt: json['created_at']?.toString(),
        updatedAt: json['updated_at']?.toString(),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'full_name': fullName,
    'email': email,
    'phone': phone,
    'gender': gender,
    'address': address,
    'work_experience': workExperience,
    'skills': skills,
    'available_days': availableDays,
    'available_time': availableTime,
    if (password.isNotEmpty) 'password': password,
    'profile_photo': profilePhoto,
    'id_document': idDocument,
    'status': status,
    'admin_note': adminNote,
    'user_id': userId,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };
}

class ServiceModel {
  const ServiceModel({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.basePrice,
    required this.durationMinutes,
    required this.imageUrl,
    required this.rating,
    required this.cleanersRequired,
    this.isActive = true,
  });
  final int id;
  final String name;
  final String category;
  final String description;
  final double basePrice;
  final int durationMinutes;
  final String imageUrl;
  final double rating;
  final int cleanersRequired;
  final bool isActive;

  factory ServiceModel.fromJson(Map<String, dynamic> json) => ServiceModel(
    id: (json['id'] as num).toInt(),
    name: json['name'].toString(),
    category: json['category'].toString(),
    description: json['description'].toString(),
    basePrice: (json['base_price'] as num).toDouble(),
    durationMinutes: (json['duration_minutes'] as num).toInt(),
    imageUrl: json['image_url'].toString(),
    rating: (json['rating'] as num).toDouble(),
    cleanersRequired: (json['cleaners_required'] as num).toInt(),
    isActive: (json['is_active'] ?? 1) == 1 || json['is_active'] == true,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'description': description,
    'base_price': basePrice,
    'duration_minutes': durationMinutes,
    'image_url': imageUrl,
    'rating': rating,
    'cleaners_required': cleanersRequired,
    'is_active': isActive ? 1 : 0,
  };

  ServiceModel copyWith({
    int? id,
    String? name,
    String? category,
    String? description,
    double? basePrice,
    int? durationMinutes,
    String? imageUrl,
    double? rating,
    int? cleanersRequired,
    bool? isActive,
  }) => ServiceModel(
    id: id ?? this.id,
    name: name ?? this.name,
    category: category ?? this.category,
    description: description ?? this.description,
    basePrice: basePrice ?? this.basePrice,
    durationMinutes: durationMinutes ?? this.durationMinutes,
    imageUrl: imageUrl ?? this.imageUrl,
    rating: rating ?? this.rating,
    cleanersRequired: cleanersRequired ?? this.cleanersRequired,
    isActive: isActive ?? this.isActive,
  );
}

class BookingModel {
  const BookingModel({
    this.id,
    required this.userId,
    required this.serviceId,
    required this.serviceName,
    required this.customerName,
    required this.phone,
    required this.address,
    required this.propertyType,
    required this.rooms,
    required this.bathrooms,
    required this.bookingDate,
    required this.bookingTime,
    required this.extraServices,
    this.specialInstruction = '',
    required this.paymentMethod,
    required this.basePrice,
    required this.extraPrice,
    required this.totalPrice,
    required this.estimatedDuration,
    this.cleanerId,
    this.cleanerName = '',
    this.cleanerPay = 0,
    this.status = 'Pending',
    this.serviceImage = '',
    this.beforePhotos = const [],
    this.afterPhotos = const [],
    this.completionNotes = '',
    this.createdAt,
    this.updatedAt,
  });
  final int? id;
  final int userId;
  final int serviceId;
  final String serviceName;
  final String customerName;
  final String phone;
  final String address;
  final String propertyType;
  final int rooms;
  final int bathrooms;
  final String bookingDate;
  final String bookingTime;
  final List<String> extraServices;
  final String specialInstruction;
  final String paymentMethod;
  final double basePrice;
  final double extraPrice;
  final double totalPrice;
  final int estimatedDuration;
  final int? cleanerId;
  final String cleanerName;
  final double cleanerPay;
  final String status;
  final String serviceImage;
  final List<String> beforePhotos;
  final List<String> afterPhotos;
  final String completionNotes;
  final String? createdAt;
  final String? updatedAt;

  factory BookingModel.fromJson(Map<String, dynamic> json) => BookingModel(
    id: json['id'] as int?,
    userId: (json['user_id'] as num).toInt(),
    serviceId: (json['service_id'] as num).toInt(),
    serviceName: json['service_name'].toString(),
    customerName: json['customer_name'].toString(),
    phone: json['phone'].toString(),
    address: json['address'].toString(),
    propertyType: json['property_type'].toString(),
    rooms: (json['rooms'] as num).toInt(),
    bathrooms: (json['bathrooms'] as num).toInt(),
    bookingDate: json['booking_date'].toString(),
    bookingTime: json['booking_time'].toString(),
    extraServices: List<String>.from(
      jsonDecode((json['extra_services'] ?? '[]').toString()),
    ),
    specialInstruction: json['special_instruction']?.toString() ?? '',
    paymentMethod: json['payment_method'].toString(),
    basePrice: (json['base_price'] as num).toDouble(),
    extraPrice: (json['extra_price'] as num).toDouble(),
    totalPrice: (json['total_price'] as num).toDouble(),
    estimatedDuration: (json['estimated_duration'] as num).toInt(),
    cleanerId: (json['cleaner_id'] as num?)?.toInt(),
    cleanerName: json['cleaner_name']?.toString() ?? '',
    cleanerPay: (json['cleaner_pay'] as num?)?.toDouble() ?? 0,
    status: json['status'].toString(),
    serviceImage: json['service_image']?.toString() ?? '',
    beforePhotos: List<String>.from(
      jsonDecode((json['before_photos'] ?? '[]').toString()),
    ),
    afterPhotos: List<String>.from(
      jsonDecode((json['after_photos'] ?? '[]').toString()),
    ),
    completionNotes: json['completion_notes']?.toString() ?? '',
    createdAt: json['created_at']?.toString(),
    updatedAt: json['updated_at']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'service_id': serviceId,
    'service_name': serviceName,
    'customer_name': customerName,
    'phone': phone,
    'address': address,
    'property_type': propertyType,
    'rooms': rooms,
    'bathrooms': bathrooms,
    'booking_date': bookingDate,
    'booking_time': bookingTime,
    'extra_services': jsonEncode(extraServices),
    'special_instruction': specialInstruction,
    'payment_method': paymentMethod,
    'base_price': basePrice,
    'extra_price': extraPrice,
    'total_price': totalPrice,
    'estimated_duration': estimatedDuration,
    'cleaner_id': cleanerId,
    'cleaner_name': cleanerName,
    'cleaner_pay': cleanerPay,
    'status': status,
    'service_image': serviceImage,
    'before_photos': jsonEncode(beforePhotos),
    'after_photos': jsonEncode(afterPhotos),
    'completion_notes': completionNotes,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };

  BookingModel copyWith({
    int? id,
    String? status,
    int? cleanerId,
    String? cleanerName,
    double? cleanerPay,
    List<String>? beforePhotos,
    List<String>? afterPhotos,
    String? completionNotes,
  }) => BookingModel(
    id: id ?? this.id,
    userId: userId,
    serviceId: serviceId,
    serviceName: serviceName,
    customerName: customerName,
    phone: phone,
    address: address,
    propertyType: propertyType,
    rooms: rooms,
    bathrooms: bathrooms,
    bookingDate: bookingDate,
    bookingTime: bookingTime,
    extraServices: extraServices,
    specialInstruction: specialInstruction,
    paymentMethod: paymentMethod,
    basePrice: basePrice,
    extraPrice: extraPrice,
    totalPrice: totalPrice,
    estimatedDuration: estimatedDuration,
    cleanerId: cleanerId ?? this.cleanerId,
    cleanerName: cleanerName ?? this.cleanerName,
    cleanerPay: cleanerPay ?? this.cleanerPay,
    status: status ?? this.status,
    serviceImage: serviceImage,
    beforePhotos: beforePhotos ?? this.beforePhotos,
    afterPhotos: afterPhotos ?? this.afterPhotos,
    completionNotes: completionNotes ?? this.completionNotes,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

class FavoriteModel {
  const FavoriteModel({
    this.id,
    required this.userId,
    required this.serviceId,
    required this.serviceName,
    required this.serviceImage,
    required this.servicePrice,
    this.createdAt,
  });
  final int? id;
  final int userId;
  final int serviceId;
  final String serviceName;
  final String serviceImage;
  final double servicePrice;
  final String? createdAt;

  factory FavoriteModel.fromJson(Map<String, dynamic> json) => FavoriteModel(
    id: json['id'] as int?,
    userId: (json['user_id'] as num).toInt(),
    serviceId: (json['service_id'] as num).toInt(),
    serviceName: json['service_name'].toString(),
    serviceImage: json['service_image'].toString(),
    servicePrice: (json['service_price'] as num).toDouble(),
    createdAt: json['created_at']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'service_id': serviceId,
    'service_name': serviceName,
    'service_image': serviceImage,
    'service_price': servicePrice,
    'created_at': createdAt,
  };

  FavoriteModel copyWith({int? id}) => FavoriteModel(
    id: id ?? this.id,
    userId: userId,
    serviceId: serviceId,
    serviceName: serviceName,
    serviceImage: serviceImage,
    servicePrice: servicePrice,
    createdAt: createdAt,
  );
}

class ReviewModel {
  const ReviewModel({
    this.id,
    required this.bookingId,
    required this.serviceId,
    required this.userId,
    required this.rating,
    this.comment = '',
    this.createdAt,
  });
  final int? id;
  final int bookingId;
  final int serviceId;
  final int userId;
  final int rating;
  final String comment;
  final String? createdAt;

  factory ReviewModel.fromJson(Map<String, dynamic> json) => ReviewModel(
    id: json['id'] as int?,
    bookingId: (json['booking_id'] as num).toInt(),
    serviceId: (json['service_id'] as num).toInt(),
    userId: (json['user_id'] as num).toInt(),
    rating: (json['rating'] as num).toInt(),
    comment: json['comment']?.toString() ?? '',
    createdAt: json['created_at']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'booking_id': bookingId,
    'service_id': serviceId,
    'user_id': userId,
    'rating': rating,
    'comment': comment,
    'created_at': createdAt,
  };
  ReviewModel copyWith({int? id}) => ReviewModel(
    id: id ?? this.id,
    bookingId: bookingId,
    serviceId: serviceId,
    userId: userId,
    rating: rating,
    comment: comment,
    createdAt: createdAt,
  );
}

class NotificationModel {
  const NotificationModel({
    this.id,
    required this.userId,
    required this.title,
    required this.message,
    this.isRead = false,
    this.createdAt,
  });
  final int? id;
  final int userId;
  final String title;
  final String message;
  final bool isRead;
  final String? createdAt;
  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      NotificationModel(
        id: json['id'] as int?,
        userId: (json['user_id'] as num).toInt(),
        title: json['title'].toString(),
        message: json['message'].toString(),
        isRead: (json['is_read'] ?? 0) == 1 || json['is_read'] == true,
        createdAt: json['created_at']?.toString(),
      );
  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'title': title,
    'message': message,
    'is_read': isRead ? 1 : 0,
    'created_at': createdAt,
  };
}

class ProductModel {
  const ProductModel({
    this.id,
    required this.apiId,
    required this.title,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    this.createdAt,
  });
  final int? id;
  final int apiId;
  final String title;
  final String description;
  final double price;
  final String imageUrl;
  final String category;
  final String? createdAt;

  factory ProductModel.fromJson(Map<String, dynamic> json) => ProductModel(
    id: json['id'] is int && json.containsKey('api_id')
        ? json['id'] as int
        : null,
    apiId: (json['api_id'] ?? json['id'] as num).toInt(),
    title: json['title'].toString(),
    description: json['description']?.toString() ?? '',
    price: (json['price'] as num).toDouble(),
    imageUrl: (json['image_url'] ?? json['thumbnail'] ?? json['image'])
        .toString(),
    category: json['category']?.toString() ?? 'Cleaning supplies',
    createdAt: json['created_at']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'api_id': apiId,
    'title': title,
    'description': description,
    'price': price,
    'image_url': imageUrl,
    'category': category,
    'created_at': createdAt,
  };
}

class ApiResponseModel<T> {
  const ApiResponseModel({required this.data, this.message = ''});
  final T data;
  final String message;
}
