import 'package:intl/intl.dart';

class DateHelper {
  // Format DateTime to a readable string (e.g., "Jan 15, 2025")
  static String formatDate(DateTime? date) {
    if (date == null) return 'Not set';
    return DateFormat('MMM d, yyyy').format(date);
  }

  // Format DateTime to a full date and time string (e.g., "Jan 15, 2025 3:30 PM")
  static String formatDateTime(DateTime? date) {
    if (date == null) return 'Not set';
    return DateFormat('MMM d, yyyy h:mm a').format(date);
  }

  // Parse string to DateTime (expects format "yyyy-MM-dd")
  static DateTime? parseDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    try {
      return DateFormat('yyyy-MM-dd').parse(dateString);
    } catch (e) {
      return null;
    }
  }

  // Check if a date is overdue
  static bool isOverdue(DateTime? dueDate) {
    if (dueDate == null) return false;
    final now = DateTime.now();
    return dueDate.isBefore(now);
  }

  // Check if a date is today
  static bool isToday(DateTime? date) {
    if (date == null) return false;
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  // Get days difference between two dates
  static int daysDifference(DateTime? start, DateTime? end) {
    if (start == null || end == null) return 0;
    return end.difference(start).inDays;
  }

  // Get a default start date (today)
  static DateTime getDefaultStartDate() {
    return DateTime.now();
  }

  // Get a default due date (tomorrow)
  static DateTime getDefaultDueDate() {
    return DateTime.now().add(const Duration(days: 1));
  }
}
