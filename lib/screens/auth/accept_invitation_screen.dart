// NEW FILE: Complete file needed for invitation acceptance
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

      // CHANGED: Use AuthProvider's verifyInvitationToken method
      final success = await authProvider.verifyInvitationToken(
        widget.token,
        _displayNameController.text,
      );

      if (success && mounted) {
        // CHANGED: Use AppRoutes constant instead of hard-coded string
        Navigator.of(context).pushReplacementNamed(AppRoutes.taskList);
      }
      // Error handling is now managed by AuthProvider
    }
  }
}
