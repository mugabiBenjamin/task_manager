import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/validators.dart';
import '../../routes/app_routes.dart';
import '../common/custom_button.dart';
import '../common/custom_text_field.dart';

class AuthForm extends StatefulWidget {
  final bool isLogin;
  final void Function({
    required String email,
    required String password,
    String? displayName,
  })
  onSubmit;
  final VoidCallback onGoogleSignIn;
  final String? errorMessage;
  final bool isLoading;

  const AuthForm({
    super.key,
    required this.isLogin,
    required this.onSubmit,
    required this.onGoogleSignIn,
    this.errorMessage,
    this.isLoading = false,
  });

  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.task_alt,
            size: 80,
            color: AppConstants.primaryColor,
          ),
          const SizedBox(height: AppConstants.largePadding),
          Text(
            widget.isLogin ? AppConstants.loginTitle : AppConstants.signupTitle,
            style: AppConstants.headlineStyle,
          ),
          const SizedBox(height: AppConstants.largePadding),
          if (!widget.isLogin)
            CustomTextField(
              controller: _displayNameController,
              labelText: 'Display Name',
              prefixIcon: Icons.person,
              validator: Validators.validateDisplayName,
              onChanged: (value) {},
            ),
          if (!widget.isLogin)
            const SizedBox(height: AppConstants.defaultPadding),
          CustomTextField(
            controller: _emailController,
            labelText: 'Email',
            prefixIcon: Icons.email,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.validateEmail,
            onChanged: (value) {},
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          CustomTextField(
            controller: _passwordController,
            labelText: 'Password',
            prefixIcon: Icons.lock,
            suffixIcon: _obscurePassword
                ? Icons.visibility
                : Icons.visibility_off,
            onSuffixIconTap: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
            obscureText: _obscurePassword,
            validator: Validators.validatePassword,
            onChanged: (value) {},
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          // CHANGED: Use AuthProvider's error mapping directly
          if (widget.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(
                bottom: AppConstants.defaultPadding,
              ),
              child: Text(
                widget
                    .errorMessage!, // Using pre-mapped error from AuthProvider
                style: const TextStyle(color: AppConstants.errorColor),
                textAlign: TextAlign.center,
              ),
            ),
          CustomButton(
            text: widget.isLoading
                ? (widget.isLogin ? 'Logging in...' : 'Signing up...')
                : (widget.isLogin ? 'Login' : 'Sign Up'),
            onPressed: widget.isLoading ? null : _handleSubmit,
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          CustomButton(
            text: widget.isLogin
                ? 'Sign in with Google'
                : 'Sign up with Google',
            backgroundColor: AppConstants.secondaryColor,
            onPressed: widget.isLoading ? null : widget.onGoogleSignIn,
            isLoading: widget.isLoading,
          ),
          const SizedBox(height: AppConstants.largePadding),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.isLogin
                    ? "Don't have an account? "
                    : 'Already have an account? ',
                style: AppConstants.bodyStyle,
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(
                    context,
                    widget.isLogin ? AppRoutes.signup : AppRoutes.login,
                  );
                },
                child: Text(
                  widget.isLogin ? 'Sign Up' : 'Login',
                  style: AppConstants.bodyStyle.copyWith(
                    color: AppConstants.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleSubmit() {
    // ADDED: Form validation before submission
    if (_formKey.currentState!.validate()) {
      widget.onSubmit(
        email: _emailController.text.trim(), // ADDED: trim whitespace
        password: _passwordController.text,
        displayName: widget.isLogin ? null : _displayNameController.text.trim(),
      );
    }
  }
}
