import 'package:emailjs/emailjs.dart';
import 'package:flutter/foundation.dart';
import '../models/task_model.dart';
import '../core/utils/date_helper.dart';

class EmailService {
  static const String _serviceId = 'service_gevpfid';
  static const String _templateId = 'template_77yrls5';
  static const String _publicKey = 'NNbZWvJBb1rruB8eY';
  static const String _invitationTemplateId = 'template_5p71bhu';

  // Send task assignment notification
  static Future<bool> sendTaskAssignmentNotification({
    required TaskModel task,
    required List<Map<String, dynamic>>
    assignees, // Supports both registered and invited users
    required Map<String, dynamic> creator,
  }) async {
    try {
      for (final assignee in assignees) {
        // Skip if registered user opted out of email notifications
        if (assignee['isRegistered'] == true &&
            assignee['emailNotifications'] == false) {
          continue;
        }

        await send(
          _serviceId,
          _templateId,
          {
            'to_email': assignee['email'],
            'to_name':
                assignee['displayName'] ?? assignee['email'].split('@')[0],
            'task_title': task.title,
            'task_description': task.description,
            'task_priority': task.priority.displayName,
            'task_due_date': task.dueDate != null
                ? DateHelper.formatDate(task.dueDate!)
                : 'Not set',
            'creator_name':
                creator['displayName'] ?? creator['email'].split('@')[0],
            'creator_email': creator['email'],
            'task_link': 'https://task-manager-1763e.web.app/tasks/${task.id}',
            'unsubscribe_link': assignee['isRegistered']
                ? 'https://task-manager-1763e.web.app/unsubscribe/${assignee['id']}'
                : null,
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

  // Send invitation email
  static Future<bool> sendInvitationEmail({
    required String recipientEmail,
    required String inviterName,
    required String inviterEmail,
    required String invitationToken,
    required String verificationLink,
  }) async {
    try {
      await send(
        _serviceId,
        _invitationTemplateId,
        {
          'to_email': recipientEmail,
          'to_name': recipientEmail.split('@')[0],
          'inviter_name': inviterName,
          'inviter_email': inviterEmail,
          'invitation_link': verificationLink,
          'app_name': 'Task Manager',
        },
        const Options(
          publicKey: _publicKey,
          limitRate: LimitRate(
            id: 'invitation_email_limit',
            throttle: 15000, // 15 seconds between invitation emails
          ),
        ),
      );
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Invitation email failed: $e');
      }
      return false;
    }
  }
}
