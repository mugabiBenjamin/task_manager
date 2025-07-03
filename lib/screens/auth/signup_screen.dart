import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_routes.dart';

class SignupScreen extends StatefulWidget {
  final String? invitationToken;
  const SignupScreen({super.key, this.invitationToken});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _displayNameController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _emailHasError = false;
  bool _passwordHasError = false;
  bool _confirmPasswordHasError = false;
  bool _displayNameHasError = false;
  bool _isTokenInvalid = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<bool> _verifyInvitationToken() async {
    if (widget.invitationToken == null) return true;
    
    try {
      final authProvider = context.read<AuthProvider>();
      final isValid = await authProvider.verifyInvitationToken(
        widget.invitationToken!,
        _displayNameController.text.trim(),
      );
      
      if (mounted) {
        setState(() {
          _isTokenInvalid = !isValid;
        });
        
        if (!isValid) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid or expired invitation token'),
              backgroundColor: AppConstants.errorColor,
            ),
          );
        }
      }
      
      return isValid;
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTokenInvalid = true;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error verifying invitation: ${e.toString()}'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
      
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up'), centerTitle: true),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.person_add,
                  size: 80,
                  color: AppConstants.primaryColor,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Create Account',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _displayNameController,
                  decoration: InputDecoration(
                    labelText: 'Display Name',
                    prefixIcon: Icon(
                      Icons.person,
                      color: _displayNameHasError ? Colors.red : null,
                    ),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: _displayNameHasError ? Colors.red : Colors.grey,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: _displayNameHasError ? Colors.red : Colors.grey,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: _displayNameHasError
                            ? Colors.red
                            : AppConstants.primaryColor,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your display name';
                    }
                    if (value.length < 2) {
                      return 'Name must be at least 2 characters';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    if (_displayNameHasError) {
                      setState(() {
                        _clearErrorStates();
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(
                      Icons.email,
                      color: _emailHasError || _isTokenInvalid
                          ? Colors.red
                          : null,
                    ),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: _emailHasError || _isTokenInvalid
                            ? Colors.red
                            : Colors.grey,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: _emailHasError || _isTokenInvalid
                            ? Colors.red
                            : Colors.grey,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: _emailHasError || _isTokenInvalid
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
                    if (_isTokenInvalid) {
                      return 'Invalid invitation token';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    if (_emailHasError || _isTokenInvalid) {
                      setState(() {
                        _clearErrorStates();
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
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
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    if (_passwordHasError) {
                      setState(() {
                        _clearErrorStates();
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: _confirmPasswordHasError ? Colors.red : null,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: _confirmPasswordHasError
                            ? Colors.red
                            : Colors.grey,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: _confirmPasswordHasError
                            ? Colors.red
                            : Colors.grey,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: _confirmPasswordHasError
                            ? Colors.red
                            : AppConstants.primaryColor,
                      ),
                    ),
                  ),
                  obscureText: _obscureConfirmPassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    if (_confirmPasswordHasError) {
                      setState(() {
                        _clearErrorStates();
                      });
                    }
                  },
                ),
                const SizedBox(height: 24),
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
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: authProvider.isLoading || _isTokenInvalid
                            ? null
                            : _signUp,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                        ),
                        child: authProvider.isLoading
                            ? const CircularProgressIndicator()
                            : const Text('Sign Up'),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: authProvider.isLoading || _isTokenInvalid
                            ? null
                            : _signUpWithGoogle,
                        icon: Image.asset(
                          'assets/image/google.png',
                          width: 24,
                          height: 24,
                          fit: BoxFit.contain,
                        ),
                        label: const Text('Sign up with Google'),
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
                    const Text('Already have an account? '),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(
                          context,
                          AppRoutes.login,
                        );
                      },
                      child: const Text('Login'),
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

  void _signUp() async {
    if (_formKey.currentState!.validate()) {
      // Verify invitation token before proceeding with signup
      final tokenValid = await _verifyInvitationToken();
      if (!tokenValid) {
        return;
      }

      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _displayNameController.text.trim(),
        invitationToken: widget.invitationToken,
      );

      if (!success && authProvider.errorMessage != null) {
        _highlightErrorFields(authProvider.errorMessage!);
      }
    }
  }

  void _signUpWithGoogle() async {
    // Verify invitation token before proceeding with Google signup
    final tokenValid = await _verifyInvitationToken();
    if (!tokenValid) {
      return;
    }

    final authProvider = context.read<AuthProvider>();
    await authProvider.signInWithGoogle(
      invitationToken: widget.invitationToken,
    );
  }

  void _highlightErrorFields(String errorMessage) {
    setState(() {
      _clearErrorStates();

      final lowerError = errorMessage.toLowerCase();

      if (lowerError.contains('email') ||
          lowerError.contains('invalid email') ||
          lowerError.contains('email-already-in-use') ||
          lowerError.contains('already exists')) {
        _emailHasError = true;
      } else if (lowerError.contains('password') ||
          lowerError.contains('weak password') ||
          lowerError.contains('credential')) {
        _passwordHasError = true;
        _confirmPasswordHasError = true;
      } else if (lowerError.contains('display name') ||
          lowerError.contains('name')) {
        _displayNameHasError = true;
      } else if (lowerError.contains('invitation') ||
          lowerError.contains('token')) {
        _emailHasError = true;
      }
    });
  }

  void _clearErrorStates() {
    _emailHasError = false;
    _passwordHasError = false;
    _confirmPasswordHasError = false;
    _displayNameHasError = false;
    _isTokenInvalid = false;
  }
}