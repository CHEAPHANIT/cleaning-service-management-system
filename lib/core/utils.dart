import 'package:intl/intl.dart';

class Validators {
  static String? required(String? value, [String label = 'This field']) {
    if (value == null || value.trim().isEmpty) return '$label is required';
    return null;
  }

  static String? email(String? value) {
    final requiredError = required(value, 'Email');
    if (requiredError != null) return requiredError;
    final pattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return pattern.hasMatch(value!.trim()) ? null : 'Enter a valid email';
  }

  static String? password(String? value) {
    final requiredError = required(value, 'Password');
    if (requiredError != null) return requiredError;
    return value!.length >= 6 ? null : 'Password must be at least 6 characters';
  }

  static String? confirmPassword(String? value, String originalPassword) {
    if (value != originalPassword) return 'Passwords do not match';
    return password(value);
  }

  static String? phone(String? value) {
    final requiredError = required(value, 'Phone number');
    if (requiredError != null) return requiredError;
    final pattern = RegExp(r'^[0-9+\-\s()]{7,20}$');
    return pattern.hasMatch(value!.trim())
        ? null
        : 'Enter a valid phone number';
  }

  static String? positiveNumber(String? value, String label) {
    final parsed = int.tryParse(value ?? '');
    if (parsed == null || parsed <= 0) return '$label must be greater than 0';
    return null;
  }

  static String? bookingDate(DateTime? value) {
    if (value == null) return 'Date is required';
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    return value.isBefore(todayOnly)
        ? 'Booking date cannot be in the past'
        : null;
  }
}

class PriceCalculator {
  static const extraPrices = {
    'Inside fridge cleaning': 5.0,
    'Inside oven cleaning': 7.0,
    'Carpet shampoo': 10.0,
    'Sofa cleaning': 12.0,
    'Window cleaning': 8.0,
    'Balcony cleaning': 6.0,
  };

  static double total(
    double basePrice,
    int rooms,
    int bathrooms,
    List<String> extras,
  ) {
    final roomCharge = rooms > 2 ? (rooms - 2) * 5 : 0;
    final bathCharge = bathrooms > 1 ? (bathrooms - 1) * 3 : 0;
    final extraCharge = extras.fold<double>(
      0,
      (sum, item) => sum + (extraPrices[item] ?? 0),
    );
    return basePrice + roomCharge + bathCharge + extraCharge;
  }

  static int duration(
    int baseMinutes,
    int rooms,
    int bathrooms,
    List<String> extras,
  ) {
    return baseMinutes +
        (rooms > 2 ? (rooms - 2) * 20 : 0) +
        (bathrooms > 1 ? (bathrooms - 1) * 15 : 0) +
        extras.length * 15;
  }
}

String money(num value) => '\$${value.toStringAsFixed(2)}';
String prettyDate(DateTime value) => DateFormat('MMM d, yyyy').format(value);
