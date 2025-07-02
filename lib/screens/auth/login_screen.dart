import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_routes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _tokenController = TextEditingController();
  bool _obscurePassword = true;
  bool _emailHasError = false;
  bool _passwordHasError = false;
  bool _showTokenField = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = context.read<AuthProvider>();
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      // Handle token if provided
      if (_showTokenField && _tokenController.text.isNotEmpty) {
        final success = await authProvider.acceptInvitation(
          _tokenController.text.trim(),
          email.split('@')[0], // Use email prefix as displayName
        );
        if (!success) {
          _highlightErrorFields(authProvider.errorMessage ?? 'Invalid token');
          return;
        }
      }

      final success = await authProvider.signIn(
        email: email,
        password: password,
      );

      if (!success && authProvider.errorMessage != null) {
        _highlightErrorFields(authProvider.errorMessage!);
      } else if (success && mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.taskList);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    final authProvider = context.read<AuthProvider>();
    // Support token with Google sign-in
    if (_showTokenField && _tokenController.text.isNotEmpty) {
      await authProvider.signInWithGoogle(
        invitationToken: _tokenController.text.trim(),
      );
    } else {
      await authProvider.signInWithGoogle();
    }
  }

  void _highlightErrorFields(String errorMessage) {
    setState(() {
      if (errorMessage.toLowerCase().contains('email') ||
          errorMessage.toLowerCase().contains('invalid email') ||
          errorMessage.toLowerCase().contains('token')) {
        _emailHasError = true;
        _passwordHasError = false;
      } else if (errorMessage.toLowerCase().contains('password') ||
          errorMessage.toLowerCase().contains('credential')) {
        _emailHasError = true;
        _passwordHasError = true;
      } else {
        _emailHasError = false;
        _passwordHasError = false;
      }
    });
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter your email address to receive a password reset link.',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (emailController.text.isNotEmpty) {
                final authProvider = context.read<AuthProvider>();
                final navigator = Navigator.of(context);
                final scaffoldMessenger = ScaffoldMessenger.of(context);

                final success = await authProvider.resetPassword(
                  emailController.text.trim(),
                );

                navigator.pop();

                if (!mounted) return;

                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Password reset email sent successfully!'
                          : 'Failed to send reset email. Please try again.',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Send Reset Link'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login'), centerTitle: true),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.task_alt,
                  size: 80,
                  color: AppConstants.primaryColor,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Task Manager',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),
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
                          'Received an invitation email? Click "Have an Invitation Token?" below and paste the token from the email.',
                          style: TextStyle(color: AppConstants.primaryColor),
                        ),
                      ),
                    ],
                  ),
                ),
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(
                          Icons.email,
                          color: _emailHasError ? Colors.red : null,
                        ),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: _emailHasError ? Colors.red : Colors.grey,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: _emailHasError ? Colors.red : Colors.grey,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: _emailHasError
                                ? Colors.red
                                : AppConstants.primaryColor,
                          ),
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(
                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                        ).hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        if (_emailHasError) {
                          setState(() {
                            _emailHasError = false;
                            _passwordHasError = false;
                          });
                        }
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(
                          Icons.lock,
                          color: _passwordHasError ? Colors.red : null,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: _passwordHasError ? Colors.red : Colors.grey,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: _passwordHasError ? Colors.red : Colors.grey,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: _passwordHasError
                                ? Colors.red
                                : AppConstants.primaryColor,
                          ),
                        ),
                      ),
                      obscureText: _obscurePassword,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        if (_passwordHasError) {
                          setState(() {
                            _emailHasError = false;
                            _passwordHasError = false;
                          });
                        }
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
                if (_showTokenField)
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      return TextFormField(
                        controller: _tokenController,
                        decoration: const InputDecoration(
                          labelText: 'Invitation Token',
                          prefixIcon: Icon(Icons.vpn_key),
                          border: OutlineInputBorder(),
                          helperText:
                              'Paste the token from your invitation email',
                          helperStyle: TextStyle(
                            color: AppConstants.primaryColor,
                          ),
                        ),
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            if (value.length < 32) {
                              return 'Token must be at least 32 characters';
                            }
                          }
                          return null;
                        },
                      );
                    },
                  ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _showTokenField = !_showTokenField;
                    });
                  },
                  child: Text(
                    _showTokenField
                        ? 'Hide Token Field'
                        : 'Have an Invitation Token?',
                    style: const TextStyle(
                      color: AppConstants.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => _showForgotPasswordDialog(),
                    child: const Text('Forgot Password?'),
                  ),
                ),
                const SizedBox(height: 8),
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    if (authProvider.errorMessage != null) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          border: Border.all(color: Colors.red.shade200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red.shade600,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                authProvider.errorMessage!,
                                style: TextStyle(color: Colors.red.shade700),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: authProvider.isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(16),
                            ),
                            child: authProvider.isLoading
                                ? const CircularProgressIndicator()
                                : const Text('Login'),
                          ),
                        ),
                        if (authProvider.shouldShowRetryDelay)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'Multiple failed attempts detected. Please wait before retrying.',
                              style: TextStyle(
                                color: Colors.orange.shade700,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: authProvider.isLoading
                            ? null
                            : _signInWithGoogle,
                        icon: Image.asset(
                          'assets/image/google.png',
                          width: 24,
                          height: 24,
                          fit: BoxFit.contain,
                        ),
                        label: const Text('Sign in with Google'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account? "),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(
                          context,
                          AppRoutes.signup,
                        );
                      },
                      child: const Text('Sign Up'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
