import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

class Validators {
  // Validate email address
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return AppConstants.requiredField;
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return AppConstants.invalidEmail;
    }
    return null;
  }

  // Validate password
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return AppConstants.requiredField;
    }
    if (value.length < 6) {
      return AppConstants.passwordTooShort;
    }
    return null;
  }

  // Validate confirm password
  static String? validateConfirmPassword(
    String? password,
    String? confirmPassword,
  ) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return AppConstants.requiredField;
    }
    if (confirmPassword != password) {
      return AppConstants.passwordsDontMatch;
    }
    return null;
  }

  // Validate display name
  static String? validateDisplayName(String? value) {
    if (value == null || value.isEmpty) {
      return AppConstants.requiredField;
    }
    if (value.length < 2) {
      return AppConstants.invalidName;
    }
    return null;
  }

  // Validate task title
  static String? validateTaskTitle(String? value) {
    if (value == null || value.isEmpty) {
      return AppConstants.requiredField;
    }
    if (value.length < 3) {
      return 'Title must be at least 3 characters';
    }
    if (value.length > 100) {
      return 'Title must not exceed 100 characters';
    }
    return null;
  }

  // Validate task description
  static String? validateTaskDescription(String? value) {
    if (value != null && value.length > 500) {
      return 'Description must not exceed 500 characters';
    }
    return null;
  }

  // Validate start date (must be today or future)
  static String? validateStartDate(String? value) {
    if (value == null || value.isEmpty) {
      return AppConstants.requiredField;
    }
    try {
      final date = DateFormat('yyyy-MM-dd').parse(value);
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);

      if (date.isBefore(todayStart)) {
        return 'Start date cannot be in the past';
      }
      return null;
    } catch (e) {
      return 'Invalid date format';
    }
  }

  // Validate due date (must be today or future, and after start date)
  static String? validateDueDate(String? value, String? startDateValue) {
    if (value == null || value.isEmpty) {
      return AppConstants.requiredField;
    }
    try {
      final dueDate = DateFormat('yyyy-MM-dd').parse(value);
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);

      if (dueDate.isBefore(todayStart)) {
        return 'Due date cannot be in the past';
      }

      if (startDateValue != null && startDateValue.isNotEmpty) {
        final startDate = DateFormat('yyyy-MM-dd').parse(startDateValue);
        if (dueDate.isBefore(startDate)) {
          return 'Due date must be same or after start date';
        }
      }

      return null;
    } catch (e) {
      return 'Invalid date format';
    }
  }

  // Validate date (ensure it's not in the past)
  static String? validateDate(String? value, {bool allowPast = false}) {
    if (value == null || value.isEmpty) {
      return AppConstants.requiredField;
    }
    try {
      final date = DateFormat('yyyy-MM-dd').parse(value);
      if (!allowPast && date.isBefore(DateTime.now())) {
        return 'Date cannot be in the past';
      }
      return null;
    } catch (e) {
      return 'Invalid date format';
    }
  }

  // Validate label name
  static String? validateLabelName(String? value) {
    if (value == null || value.isEmpty) {
      return AppConstants.requiredField;
    }
    if (value.length < 2) {
      return 'Label name must be at least 2 characters';
    }
    if (value.length > 50) {
      return 'Label name must not exceed 50 characters';
    }
    return null;
  }

  // Validate color (hex code)
  static String? validateColor(String? value) {
    if (value == null || value.isEmpty) {
      return AppConstants.requiredField;
    }
    final colorRegex = RegExp(r'^#[0-9A-Fa-f]{6}$');
    if (!colorRegex.hasMatch(value)) {
      return 'Invalid hex color code (e.g., #FF0000)';
    }
    return null;
  }
}
