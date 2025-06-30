import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // CHANGED: Show error message if exists
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
                    ),
                    validator: (value) =>
                        value?.isEmpty == true ? 'Required' : null,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    // CHANGED: Use AuthProvider loading state
                    onPressed: authProvider.isLoading
                        ? null
                        : _acceptInvitation,
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

      // ADDED: Show loading dialog
      _showLoadingDialog();

      try {
        final success = await authProvider.verifyInvitationToken(
          widget.token,
          _displayNameController.text,
        );

        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog

          if (success) {
            // ADDED: Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Invitation accepted successfully!'),
                backgroundColor: Colors.green,
              ),
            );

            Navigator.of(context).pushReplacementNamed(AppRoutes.taskList);
          } else {
            // ADDED: Show error if no specific error message
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

  // ADDED: Decline invitation handler
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
        Navigator.of(context).pop();
      }
    }
  }
}
