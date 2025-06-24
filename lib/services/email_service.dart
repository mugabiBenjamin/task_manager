import 'package:emailjs/emailjs.dart';
// ignore: library_prefixes
import 'package:emailjs/emailjs.dart' as EmailJS;
import '../models/task_model.dart';
import '../models/user_model.dart';

class EmailService {
  static const String _serviceId = 'YOUR_EMAILJS_SERVICE_ID';
  static const String _templateId = 'YOUR_EMAILJS_TEMPLATE_ID';
  static const String _publicKey = 'YOUR_EMAILJS_PUBLIC_KEY';

  // Send task assignment notification
  static Future<bool> sendTaskAssignmentNotification({
    required TaskModel task,
    required List<UserModel> assignees,
    required UserModel creator,
  }) async {
    try {
      for (final assignee in assignees) {
        // Skip if user opted out of email notifications
        if (assignee.emailNotifications == false) continue;

        await EmailJS.send(
          _serviceId,
          _templateId,
          {
            'to_email': assignee.email,
            'to_name': assignee.displayName.isNotEmpty
                ? assignee.displayName
                : assignee.email,
            'task_title': task.title,
            'task_description': task.description,
            'task_priority': task.priority.displayName,
            'task_due_date':
                task.dueDate?.toString().split(' ')[0] ?? 'Not set',
            'creator_name': creator.displayName.isNotEmpty
                ? creator.displayName
                : creator.email,
            'creator_email': creator.email,
            'unsubscribe_link':
                'https://yourapp.com/unsubscribe/${assignee.id}',
          },
          const Options(
            publicKey: _publicKey,
            limitRate: const LimitRate(
              id: 'app_email_limit',
              throttle: 10000, // 10 seconds between emails
            ),
          ),
        );
      }
      return true;
    } catch (e) {
      print('Email notification failed: $e');
      return false; // Don't block task assignment on email failure
    }
  }
}
