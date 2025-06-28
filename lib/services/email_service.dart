import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/task_model.dart';
import '../core/utils/date_helper.dart';

class EmailService {
  static const String _serviceId = 'service_gevpfid';
  static const String _taskTemplateId = 'template_77yrls5';
  static const String _publicKey = 'NNbZWvJBb1rruB8eY';
  static const String _invitationTemplateId = 'template_tifeuzq';
  static const String _apiUrl = 'https://api.emailjs.com/api/v1.0/email/send';

  // Send task assignment notification
  static Future<bool> sendTaskAssignmentNotification({
    required TaskModel task,
    required List<Map<String, dynamic>> assignees,
    required Map<String, dynamic> creator,
  }) async {
    try {
      for (final assignee in assignees) {
        // Skip if registered user opted out of email notifications
        if (assignee['isRegistered'] == true &&
            assignee['emailNotifications'] == false) {
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
          'task_link': 'https://task-manager-1763e.web.app/tasks/${task.id}',
          'unsubscribe_link': assignee['isRegistered']
              ? 'https://task-manager-1763e.web.app/unsubscribe/${assignee['id']}'
              : '',
        };

        final response = await http.post(
          Uri.parse(_apiUrl),
          headers: {
            'Content-Type': 'application/json',
            'origin': 'http://localhost',
          },
          body: json.encode({
            'service_id': _serviceId,
            'template_id': _taskTemplateId,
            'user_id': _publicKey,
            'template_params': templateParams,
          }),
        );

        if (kDebugMode) {
          print('Email API Response Status: ${response.statusCode}');
          print('Email API Response Body: ${response.body}');
          print(
            'Request Body: ${json.encode({'service_id': _serviceId, 'template_id': _taskTemplateId, 'user_id': _publicKey, 'template_params': templateParams})}',
          );
        }

        if (response.statusCode != 200) {
          throw Exception('Failed to send email: ${response.body}');
        }

        // Add delay between emails to respect rate limiting
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
      final templateParams = {
        'to_name': recipientEmail.split('@')[0],
        'to_email': recipientEmail,
        'inviter_name': inviterName,
        'inviter_email': inviterEmail,
        'invitation_link': verificationLink,
        'app_name': 'Task Manager',
      };

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'origin': 'http://localhost',
        },
        body: json.encode({
          'service_id': _serviceId,
          'template_id': _invitationTemplateId,
          'user_id': _publicKey,
          'template_params': templateParams,
        }),
      );

      if (kDebugMode) {
        print('Email API Response Status: ${response.statusCode}');
        print('Email API Response Body: ${response.body}');
        print(
          'Request Body: ${json.encode({'service_id': _serviceId, 'template_id': _invitationTemplateId, 'user_id': _publicKey, 'template_params': templateParams})}',
        );
      }

      if (response.statusCode != 200) {
        throw Exception('Failed to send invitation: ${response.body}');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Invitation email failed: $e');
      }
      return false;
    }
  }
}
