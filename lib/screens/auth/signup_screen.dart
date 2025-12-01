import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/colors.dart';
import '../../core/constants/dimensions.dart';
import '../../services/auth_service.dart';
import '../../providers/user_provider.dart';
import '../../widgets/core/app_button.dart';
import '../../widgets/core/app_text_field.dart';
import '../../widgets/core/app_bar.dart';

class SignUpScreen extends StatefulWidget {
  final VoidCallback onLoginTap;

  const SignUpScreen({super.key, required this.onLoginTap});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _error;
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userCredential = await _authService.signUpWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _nameController.text.trim(),
      );

      if (userCredential != null && mounted) {
        await context.read<UserProvider>().initializeUser(
          userCredential.user!.uid,
        );

        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = _getFriendlyErrorMessage(e.toString());
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getFriendlyErrorMessage(String error) {
    if (error.contains('email-already-in-use')) {
      return 'This email is already registered.';
    } else if (error.contains('weak-password')) {
      return 'Password is too weak.';
    } else if (error.contains('invalid-email')) {
      return 'Invalid email address.';
    }
    return 'An error occurred. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: '', onBackTap: widget.onLoginTap),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.space24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text('🚀', style: TextStyle(fontSize: 40)),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space24),
                  Text(
                    'Create Account',
                    style: Theme.of(context).textTheme.displaySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppDimensions.space8),
                  Text(
                    'Start earning money with simple tasks',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppDimensions.space32),

                  // Error Message
                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(AppDimensions.space12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusM,
                        ),
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: AppColors.error,
                            size: 20,
                          ),
                          const SizedBox(width: AppDimensions.space8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: const TextStyle(color: AppColors.error),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimensions.space24),
                  ],

                  // Name Field
                  AppTextField(
                    label: 'Full Name',
                    controller: _nameController,
                    hint: 'Enter your full name',
                    keyboardType: TextInputType.name,
                    textInputAction: TextInputAction.next,
                    enabled: !_isLoading,
                    prefixIcon: const Icon(Icons.person_outlined),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppDimensions.space16),

                  // Email Field
                  AppTextField(
                    label: 'Email',
                    controller: _emailController,
                    hint: 'Enter your email',
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    enabled: !_isLoading,
                    prefixIcon: const Icon(Icons.email_outlined),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppDimensions.space16),

                  // Password Field
                  AppTextField(
                    label: 'Password',
                    controller: _passwordController,
                    hint: 'Create a password',
                    obscureText: _obscurePassword,
                    enabled: !_isLoading,
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppDimensions.space16),

                  // Confirm Password Field
                  AppTextField(
                    label: 'Confirm Password',
                    controller: _confirmPasswordController,
                    hint: 'Confirm your password',
                    obscureText: _obscureConfirmPassword,
                    enabled: !_isLoading,
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppDimensions.space32),

                  // Sign Up Button
                  AppButton(
                    label: 'Create Account',
                    onPressed: _handleSignUp,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: AppDimensions.space24),

                  // Login Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      GestureDetector(
                        onTap: _isLoading ? null : widget.onLoginTap,
                        child: Text(
                          'Login',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
