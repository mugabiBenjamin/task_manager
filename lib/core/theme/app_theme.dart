import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppConstants.primaryColor,
        primary: AppConstants.primaryColor,
        secondary: AppConstants.secondaryColor,
        surface: AppConstants.backgroundColor,
        error: AppConstants.errorColor,
      ),
      scaffoldBackgroundColor: AppConstants.backgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            vertical: AppConstants.defaultPadding,
            horizontal: AppConstants.largePadding,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
          textStyle: AppConstants.buttonTextStyle,
          minimumSize: const Size(double.infinity, AppConstants.buttonHeight),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppConstants.primaryColor,
          side: const BorderSide(color: AppConstants.primaryColor),
          padding: const EdgeInsets.symmetric(
            vertical: AppConstants.defaultPadding,
            horizontal: AppConstants.largePadding,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
          textStyle: AppConstants.buttonTextStyle.copyWith(
            color: AppConstants.primaryColor,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppConstants.primaryColor,
          textStyle: AppConstants.bodyStyle,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: AppConstants.headlineStyle,
        titleLarge: AppConstants.headlineStyle,
        bodyMedium: AppConstants.bodyStyle,
        labelLarge: AppConstants.buttonTextStyle,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          borderSide: const BorderSide(
            color: AppConstants.primaryColor,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          borderSide: const BorderSide(color: AppConstants.errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          borderSide: const BorderSide(
            color: AppConstants.errorColor,
            width: 2,
          ),
        ),
        labelStyle: AppConstants.bodyStyle.copyWith(
          color: AppConstants.textSecondaryColor,
        ),
        prefixIconColor: AppConstants.textSecondaryColor,
        suffixIconColor: AppConstants.textSecondaryColor,
      ),
      iconTheme: const IconThemeData(
        color: AppConstants.textPrimaryColor,
        size: AppConstants.iconSize,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      dividerTheme: const DividerThemeData(
        color: AppConstants.textSecondaryColor,
        thickness: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppConstants.backgroundColor,
        selectedColor: AppConstants.primaryColor.withValues(alpha: 0.2),
        secondarySelectedColor: AppConstants.secondaryColor,
        labelStyle: AppConstants.bodyStyle,
        padding: const EdgeInsets.all(AppConstants.smallPadding),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
      ),
    );
  }
}
