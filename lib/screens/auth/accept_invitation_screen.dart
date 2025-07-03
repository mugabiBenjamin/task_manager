import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_routes.dart';

class AcceptInvitationScreen extends StatefulWidget {
  final String token;

  const AcceptInvitationScreen({super.key, required this.token});

  @override
  State<AcceptInvitationScreen> createState() => _AcceptInvitationScreenState();
}

class _AcceptInvitationScreenState extends State<AcceptInvitationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Scaffold(
          appBar: AppBar(title: const Text('Accept Invitation')),
          body: Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppConstants.primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Enter a display name to accept your invitation. You may need to sign in with the invited email afterward.',
                            style: TextStyle(color: AppConstants.primaryColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (authProvider.errorMessage != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        authProvider.errorMessage!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  TextFormField(
                    controller: _displayNameController,
                    decoration: const InputDecoration(
                      labelText: 'Display Name',
                      border: OutlineInputBorder(),
                      helperText: 'Choose a name to display in the app',
                      helperStyle: TextStyle(color: AppConstants.primaryColor),
                    ),
                    validator: (value) =>
                        value?.isEmpty == true ? 'Required' : null,
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                  ElevatedButton(
                    onPressed: authProvider.isLoading
                        ? null
                        : _acceptInvitation,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                    child: authProvider.isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Accept Invitation'),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: authProvider.isLoading
                        ? null
                        : _declineInvitation,
                    child: const Text('Decline Invitation'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _acceptInvitation() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      _showLoadingDialog();

      try {
        final success = await authProvider.acceptInvitation(
          widget.token,
          _displayNameController.text,
        );

        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog

          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Invitation accepted successfully!'),
                backgroundColor: Colors.green,
              ),
            );

            if (!authProvider.isAuthenticated) {
              // CHANGED: Enhanced fallback message for unauthenticated users
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                    'Please sign in with the invited email to continue.',
                  ),
                  backgroundColor: Colors.blue,
                  duration: const Duration(seconds: 5),
                ),
              );
              Navigator.of(context).pushReplacementNamed(AppRoutes.login);
            } else {
              Navigator.of(context).pushReplacementNamed(AppRoutes.taskList);
            }
          } else {
            if (authProvider.errorMessage == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Failed to accept invitation. Please try again.',
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
      } catch (e) {
        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Accepting invitation...'),
          ],
        ),
      ),
    );
  }

  void _declineInvitation() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.declineInvitation(widget.token);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invitation declined'),
            backgroundColor: Colors.orange,
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Redirecting to login screen.'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
      }
    }
  }
}
