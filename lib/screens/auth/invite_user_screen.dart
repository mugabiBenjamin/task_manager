import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/enums/task_priority.dart';
import '../../core/enums/task_status.dart';
import '../../models/task_model.dart';
import '../../services/email_service.dart';
import '../../widgets/common/custom_button.dart';
import '../../providers/auth_provider.dart';

class InviteUserScreen extends StatefulWidget {
  const InviteUserScreen({super.key});

  @override
  State<InviteUserScreen> createState() => _InviteUserScreenState();
}

class _InviteUserScreenState extends State<InviteUserScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendInvitation() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = await authProvider.authService.getCurrentUserData();

      if (currentUser == null ||
          currentUser.email.isEmpty ||
          currentUser.displayName.isEmpty ||
          currentUser.id.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Failed to retrieve valid user information. Please ensure you are logged in and try again.',
              ),
              backgroundColor: AppConstants.errorColor,
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      if (kDebugMode) {
        print(
          'Current user data: id=${currentUser.id}, '
          'email=${currentUser.email}, displayName=${currentUser.displayName}',
        );
      }

      final invitationService = authProvider.invitationService;
      final email = _emailController.text.trim();
      final displayName = email.split(
        '@',
      )[0]; // ADDED: Extract display name from email
      bool invitationSent = false;
      String? invitationError;

      // CHANGED: Try to send invitation but don't fail if user exists
      try {
        // ADDED: Check if user exists first
        final userService = authProvider.userService;
        final existingUsers = await userService.searchUsers(email);
        final userExists = existingUsers.any(
          (user) => user.email.toLowerCase() == email.toLowerCase(),
        );

        if (userExists) {
          // ADDED: Show snackbar for existing user but don't return - still send assignment email
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('This user is already registered.'),
                backgroundColor: AppConstants
                    .warningColor, // CHANGED: Use warning color instead of error
              ),
            );
          }
          invitationError = 'User already registered';
        } else {
          // ADDED: Only send invitation if user doesn't exist
          await invitationService.sendInvitation(
            email: email,
            inviterEmail: currentUser.email,
            invitedByName: currentUser.displayName,
            invitedBy: currentUser.id,
          );
          invitationSent = true;
        }
      } catch (e) {
        invitationError = e.toString();
        if (kDebugMode) {
          print('Invitation failed: $e');
        }
      }

      // ADDED: Always send assignment email regardless of invitation outcome
      await _sendAssignmentEmail(email, displayName);

      if (mounted) {
        if (invitationSent) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Invitation and assignment email sent successfully!',
              ), // CHANGED: Updated message
              backgroundColor: AppConstants.successColor,
            ),
          );
        } else if (invitationError == 'User already registered') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Assignment email sent to existing user!',
              ), // ADDED: Success message for existing users
              backgroundColor: AppConstants.successColor,
            ),
          );
        } else {
          // ADDED: Handle other invitation errors but still acknowledge assignment email
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Invitation failed but assignment email sent: ${invitationError ?? 'Unknown error'}',
              ),
              backgroundColor: AppConstants.warningColor,
            ),
          );
        }
        Navigator.pop(context, true);
      }

      setState(() => _isLoading = false);
    }
  }

  // ADDED: New function to send assignment email for invited users
  Future<void> _sendAssignmentEmail(String email, String displayName) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = await authProvider.authService.getCurrentUserData();

      if (currentUser == null) return;

      // Create a welcome task for the invited user
      final welcomeTask = TaskModel(
        id: 'welcome-${DateTime.now().millisecondsSinceEpoch}',
        title: 'Welcome to Task Manager!',
        description:
            'You have been invited to collaborate on tasks. This is your welcome assignment.',
        priority: TaskPriority.medium,
        status: TaskStatus.notStarted,
        createdBy: currentUser.id,
        assignedTo: [email], // Use email as identifier for non-registered users
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        dueDate: DateTime.now().add(const Duration(days: 3)),
        labels: ['welcome'],
        isStarred: false,
      );

      // Prepare assignee data
      final assigneeData = {
        'id': email,
        'email': email,
        'displayName': displayName,
        'isRegistered': false,
        'emailNotifications': true,
      };

      // Prepare creator data
      final creatorData = {
        'id': currentUser.id,
        'email': currentUser.email,
        'displayName': currentUser.displayName,
        'emailNotifications': true,
      };

      // Send assignment email
      await EmailService.sendTaskAssignmentNotification(
        task: welcomeTask,
        assignees: [assigneeData],
        creator: creatorData,
      );

      if (kDebugMode) {
        print('Assignment email sent to: $email');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to send assignment email: $e');
      }
      // Don't throw error - assignment email failure shouldn't block invitation
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invite User')),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an email';
                  }
                  if (!RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  ).hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              CustomButton(
                text: _isLoading
                    ? 'Sending...'
                    : 'Send Invitation & Assignment',
                onPressed: _isLoading ? null : _sendInvitation,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
