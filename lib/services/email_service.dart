import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/task_model.dart';
import '../core/utils/date_helper.dart';

class EmailService {
  static String get _serviceId => const String.fromEnvironment(
    'EMAILJS_SERVICE_ID',
    defaultValue: 'service_gevpfid',
  );
  static String get _taskTemplateId => const String.fromEnvironment(
    'EMAILJS_TASK_TEMPLATE_ID',
    defaultValue: 'template_77yrls5',
  );
  static String get _invitationTemplateId => const String.fromEnvironment(
    'EMAILJS_INVITATION_TEMPLATE_ID',
    defaultValue: 'template_5p71bhu',
  );
  static String get _publicKey => const String.fromEnvironment(
    'EMAILJS_PUBLIC_KEY',
    defaultValue: 'NNbZWvJBb1rruB8eY',
  );
  static String get _baseUrl => const String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://task-manager-1763e.web.app',
  );
  static const String _apiUrl = 'https://api.emailjs.com/api/v1.0/email/send';
  static bool _isValidEmail(String email) {
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(email);
  }

  static Future<bool> _sendEmailWithRetry({
    required Map<String, dynamic> requestBody,
    int maxRetries = 3,
  }) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final response = await http.post(
          Uri.parse(_apiUrl),
          headers: {
            'Content-Type': 'application/json',
            'origin': 'http://localhost',
          },
          body: json.encode(requestBody),
        );

        if (response.statusCode == 200) {
          return true;
        }

        if (attempt == maxRetries) {
          throw Exception(
            'Failed after $maxRetries attempts: ${response.body}',
          );
        }

        // Wait before retry with exponential backoff
        await Future.delayed(Duration(seconds: attempt * 2));
      } catch (e) {
        if (attempt == maxRetries) {
          rethrow;
        }
        await Future.delayed(Duration(seconds: attempt * 2));
      }
    }
    return false;
  }

  // Send task assignment notification
  static Future<bool> sendTaskAssignmentNotification({
    required TaskModel task,
    required List<Map<String, dynamic>> assignees,
    required Map<String, dynamic> creator,
  }) async {
    try {
      for (final assignee in assignees) {
        if (assignee['isRegistered'] == true &&
            assignee['emailNotifications'] == false) {
          continue;
        }

        // ADDED: Email validation
        if (!_isValidEmail(assignee['email'])) {
          if (kDebugMode) {
            print('Invalid email format: ${assignee['email']}');
          }
          continue;
        }

        final templateParams = {
          'to_name': assignee['displayName'] ?? assignee['email'].split('@')[0],
          'to_email': assignee['email'],
          'task_title': task.title,
          'task_description': task.description,
          'task_priority': task.priority.displayName,
          'task_priority_class': task.priority.displayName.toLowerCase(),
          'task_due_date': task.dueDate != null
              ? DateHelper.formatDate(task.dueDate!)
              : 'Not set',
          'creator_name':
              creator['displayName'] ?? creator['email'].split('@')[0],
          'creator_email': creator['email'],
          // CHANGED: Use deep link instead of web URL
          'task_link': 'taskmanager://task?id=${task.id}',
          'web_task_link': '$_baseUrl/task/${task.id}',
          'unsubscribe_link': assignee['isRegistered']
              ? '$_baseUrl/unsubscribe/${assignee['id']}'
              : '',
        };

        final requestBody = {
          'service_id': _serviceId,
          'template_id': _taskTemplateId,
          'user_id': _publicKey,
          'template_params': templateParams,
        };

        // CHANGED: Use retry mechanism
        final success = await _sendEmailWithRetry(requestBody: requestBody);

        if (!success) {
          if (kDebugMode) {
            print('Failed to send email to ${assignee['email']} after retries');
          }
        }

        await Future.delayed(const Duration(seconds: 2));
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Email notification failed: $e');
      }
      return false;
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
      // ADDED: Email validation
      if (!_isValidEmail(recipientEmail)) {
        throw Exception('Invalid email format');
      }

      final templateParams = {
        'to_name': recipientEmail.split('@')[0],
        'to_email': recipientEmail,
        'inviter_name': inviterName,
        'inviter_email': inviterEmail,
        // CHANGED: Use deep link for mobile app
        'invitation_link': 'taskmanager://invite?token=$invitationToken',
        'web_invitation_link':
            '$_baseUrl/accept-invitation?token=$invitationToken',
        'app_name': 'Task Manager',
      };

      final requestBody = {
        'service_id': _serviceId,
        'template_id': _invitationTemplateId,
        'user_id': _publicKey,
        'template_params': templateParams,
      };

      // CHANGED: Use retry mechanism
      return await _sendEmailWithRetry(requestBody: requestBody);
    } catch (e) {
      if (kDebugMode) {
        print('Invitation email failed: $e');
      }
      return false;
    }
  }
}
