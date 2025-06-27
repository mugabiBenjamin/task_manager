import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../services/invitation_service.dart';
import '../../widgets/common/custom_button.dart';
import '../../services/auth_service.dart';

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

      final authService = AuthService();
      final currentUser = await authService.getCurrentUserData();

      // Check if current user data is available
      if (currentUser == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Unable to get user information. Please try again.',
              ),
              backgroundColor: AppConstants.errorColor,
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      final invitationService = InvitationService();
      try {
        await invitationService.sendInvitation(
          email: _emailController.text.trim(),
          inviterEmail: currentUser.email,
          invitedByName: currentUser.displayName,
          invitedBy: currentUser.id,
        );
        if (mounted) Navigator.pop(context, true);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to send invitation: $e'),
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
