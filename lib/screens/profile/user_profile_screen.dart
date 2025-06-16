import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/loading_widget.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _displayNameController;
  late TextEditingController _emailController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController();
    _emailController = TextEditingController();
    _loadUserData();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user != null) {
      userProvider.fetchCurrentUser(authProvider.user!.uid).then((_) {
        if (userProvider.currentUser != null) {
          _displayNameController.text = userProvider.currentUser!.displayName;
          _emailController.text = userProvider.currentUser!.email;
        }
      });
    }
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user != null) {
        await userProvider.updateUserProfile(
          authProvider.user!.uid,
          displayName: _displayNameController.text.trim(),
          email: _emailController.text.trim(),
        );
        if (userProvider.errorMessage == null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(AppConstants.successMessage)),
          );
          _toggleEdit();
        }
      }
    }
  }

  void _sendVerificationEmail() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user != null && !authProvider.user!.emailVerified) {
      try {
        await authProvider.sendEmailVerification();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Verification email sent!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to send verification email: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (!_isEditing)
            IconButton(icon: const Icon(Icons.edit), onPressed: _toggleEdit),
        ],
      ),
      body: Consumer2<UserProvider, AuthProvider>(
        builder: (context, userProvider, authProvider, child) {
          if (userProvider.isLoading || authProvider.isLoading) {
            return const Center(child: LoadingWidget());
          }
          if (userProvider.errorMessage != null) {
            return Center(
              child: Text(
                userProvider.errorMessage!,
                style: const TextStyle(color: AppConstants.errorColor),
              ),
            );
          }
          if (userProvider.currentUser == null || authProvider.user == null) {
            return const Center(child: Text('No user data available'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomTextField(
                    controller: _displayNameController,
                    labelText: 'Display Name',
                    readOnly: !_isEditing,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Display name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                  CustomTextField(
                    controller: _emailController,
                    labelText: 'Email',
                    readOnly: !_isEditing,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email is required';
                      }
                      if (!RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      ).hasMatch(value)) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                  if (!authProvider.user!.emailVerified)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Email not verified',
                          style: AppConstants.bodyStyle.copyWith(
                            color: AppConstants.errorColor,
                          ),
                        ),
                        const SizedBox(height: AppConstants.smallPadding),
                        CustomButton(
                          text: 'Send Verification Email',
                          onPressed: _sendVerificationEmail,
                          backgroundColor: AppConstants.primaryColor,
                        ),
                      ],
                    ),
                  if (_isEditing)
                    Padding(
                      padding: const EdgeInsets.only(
                        top: AppConstants.largePadding,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CustomButton(
                            text: 'Cancel',
                            onPressed: _toggleEdit,
                            backgroundColor: AppConstants.textSecondaryColor,
                          ),
                          CustomButton(
                            text: 'Save',
                            onPressed: _saveProfile,
                            backgroundColor: AppConstants.primaryColor,
                          ),
                        ],
                      ),
                    ),
                  if (userProvider.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(
                        top: AppConstants.defaultPadding,
                      ),
                      child: Text(
                        userProvider.errorMessage!,
                        style: const TextStyle(color: AppConstants.errorColor),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
