import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../services/user_service.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isEditing = false;
  bool _isLoading = false;
  String? _errorMessage;
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();

      // Use cached data or Firebase Auth fallback immediately
      if (authProvider.userModel != null) {
        _displayNameController.text = authProvider.userModel!.displayName;
        _emailController.text = authProvider.userModel!.email;
      } else if (authProvider.user != null) {
        // Fallback to Firebase Auth user
        _displayNameController.text = authProvider.user!.displayName ?? '';
        _emailController.text = authProvider.user!.email ?? '';
      }

      // Try to load fresh data in background
      _loadUserDataInBackground();
    });
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.profileTitle),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: () {
              if (_isEditing) {
                _saveProfile();
              } else {
                setState(() {
                  _isEditing = true;
                });
              }
            },
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final userModel = authProvider.userModel;
          if (userModel == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 50,
                      child: Text(
                        userModel.displayName.isNotEmpty
                            ? userModel.displayName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(fontSize: 40),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppConstants.largePadding),
                  CustomTextField(
                    controller: _displayNameController,
                    labelText: 'Display Name',
                    prefixIcon: Icons.person,
                    validator: Validators.validateDisplayName,
                    readOnly: !_isEditing,
                    onChanged: (value) {},
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                  CustomTextField(
                    controller: _emailController,
                    labelText: 'Email',
                    prefixIcon: Icons.email,
                    readOnly: true,
                    onChanged: (value) {},
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                  ListTile(
                    leading: const Icon(Icons.verified),
                    title: Text(
                      userModel.isEmailVerified
                          ? 'Email Verified'
                          : 'Email Not Verified',
                      style: TextStyle(
                        color: userModel.isEmailVerified
                            ? AppConstants.successColor
                            : AppConstants.errorColor,
                      ),
                    ),
                    trailing: userModel.isEmailVerified
                        ? null
                        : TextButton(
                            onPressed: _sendVerificationEmail,
                            child: const Text('Verify Now'),
                          ),
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                  ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: Text(
                      'Account Created: ${DateTime.now().difference(userModel.createdAt).inDays} days ago',
                      style: AppConstants.bodyStyle,
                    ),
                  ),
                  const SizedBox(height: AppConstants.largePadding),
                  if (_isEditing)
                    CustomButton(
                      text: _isLoading ? 'Saving...' : 'Save Changes',
                      onPressed: _isLoading ? null : _saveProfile,
                    ),
                  const SizedBox(height: AppConstants.defaultPadding),
                  CustomButton(
                    text: 'Sign Out',
                    backgroundColor: AppConstants.errorColor,
                    onPressed: () => _showSignOutDialog(context),
                  ),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(
                        top: AppConstants.defaultPadding,
                      ),
                      child: Text(
                        _errorMessage!,
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

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user!.uid;
    final newDisplayName = _displayNameController.text.trim();

    try {
      await _userService.updateUser(userId, {'displayName': newDisplayName});
      await authProvider.user!.updateDisplayName(newDisplayName);
      await authProvider.loadUserData(); // Refresh user data
      if (mounted) {
        setState(() {
          _isEditing = false;
          _isLoading = false;
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppConstants.successMessage)),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to update profile: $e';
        _isLoading = false;
      });
    }
  }

  void _sendVerificationEmail() async {
    final authProvider = context.read<AuthProvider>();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await authProvider.sendEmailVerification();
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification email sent')),
        );
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to send verification email: $e';
        _isLoading = false;
      });
    }
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              if (mounted) {
                await context.read<AuthProvider>().signOut();
              }
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _loadUserDataInBackground() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.userModel == null && authProvider.user != null) {
      try {
        final userModel = await _userService.getOrCreateUser(
          authProvider.user!.uid,
          authProvider.user!.email ?? '',
          authProvider.user!.displayName ?? '',
        );

        if (mounted && userModel != null) {
          authProvider.updateUserModel(userModel);

          if (_displayNameController.text != userModel.displayName) {
            _displayNameController.text = userModel.displayName;
          }
        }
      } catch (e) {
        debugPrint('Background user data load failed: $e');
      }
    }
  }
}
