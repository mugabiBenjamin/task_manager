import 'package:emailjs/emailjs.dart';
// ignore: library_prefixes
import 'package:emailjs/emailjs.dart' as EmailJS;
import 'package:flutter/foundation.dart';
import '../models/task_model.dart';
import '../models/user_model.dart';

class EmailService {
  static const String _serviceId = 'service_gevpfid';
  static const String _templateId = 'template_77yrls5';
  static const String _publicKey = 'NNbZWvJBb1rruB8eY';
  static const String _invitationTemplateId = 'template_5p71bhu';

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
            limitRate: LimitRate(
              id: 'app_email_limit',
              throttle: 10000, // 10 seconds between emails
            ),
          ),
        );
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Email notification failed: $e');
      }
      return false; // Don't block task assignment on email failure
    }
  }
}
