import 'package:flutter/material.dart';

class AppConstants {
  // App metadata
  static const String appName = 'Task Manager';
  static const String appVersion = '1.0.0';

  // Colors
  static const Color primaryColor = Colors.teal;
  static const Color secondaryColor = Colors.cyan;
  static const Color accentColor = Colors.amber;
  static const Color backgroundColor = Colors.white;
  static const Color errorColor = Colors.red;
  static const Color successColor = Colors.green;
  static const Color textPrimaryColor = Colors.black87;
  static const Color textSecondaryColor = Colors.grey;

  // Text styles
  static const TextStyle headlineStyle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: textPrimaryColor,
  );
  static const TextStyle subtitleStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: textSecondaryColor,
  );
  static const TextStyle bodyStyle = TextStyle(
    fontSize: 16,
    color: textPrimaryColor,
  );
  static const TextStyle buttonTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  // UI dimensions
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 8.0;
  static const double buttonHeight = 48.0;
  static const double iconSize = 24.0;

  // Strings
  static const String loginTitle = 'Welcome Back';
  static const String signupTitle = 'Create Account';
  static const String taskListTitle = 'Your Tasks';
  static const String createTaskTitle = 'New Task';
  static const String editTaskTitle = 'Edit Task';
  static const String profileTitle = 'Profile';
  static const String noTasksMessage = 'No tasks yet';
  static const String addTaskPrompt =
      'Tap the + button to create your first task';
  static const String errorGeneric = 'Something went wrong';
  static const String successMessage = 'Operation successful';

  // Validation messages
  static const String requiredField = 'This field is required';
  static const String invalidEmail = 'Please enter a valid email';
  static const String passwordTooShort =
      'Password must be at least 6 characters';
  static const String passwordsDontMatch = 'Passwords do not match';
  static const String invalidName = 'Name must be at least 2 characters';
}
