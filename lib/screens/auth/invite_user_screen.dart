import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
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

      try {
        await invitationService.sendInvitation(
          email: _emailController.text.trim(),
          inviterEmail: currentUser.email,
          invitedByName: currentUser.displayName,
          invitedBy: currentUser.id,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invitation sent successfully!'),
              backgroundColor: AppConstants.successColor,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          String errorMessage;
          if (e.toString().contains('Invalid email format')) {
            errorMessage = 'Please enter a valid email address.';
          } else if (e.toString().contains(
            'User with this email already exists',
          )) {
            errorMessage = 'This user is already registered.';
          } else if (e.toString().contains('Failed to send invitation email')) {
            errorMessage =
                'Failed to send email. Please check EmailJS settings.';
          } else if (e.toString().contains('permission-denied')) {
            errorMessage =
                'Permission denied. Please check your account settings.';
          } else if (e.toString().contains(
            'Null check operator used on a null value',
          )) {
            errorMessage =
                'An unexpected null value occurred. Please try again or contact support.';
          } else {
            errorMessage = 'An error occurred: ${e.toString()}';
          }
          if (kDebugMode) {
            print('Invitation error: $errorMessage');
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: AppConstants.errorColor,
            ),
          );
          Navigator.pop(context, false);
        }
      }
      setState(() => _isLoading = false);
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
                text: _isLoading ? 'Sending...' : 'Send Invitation',
                onPressed: _isLoading ? null : _sendInvitation,
              ),
            ],
          ),
        ),
      ),
    );
  }
}