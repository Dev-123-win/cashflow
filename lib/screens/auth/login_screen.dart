import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/theme/colors.dart';
import '../../core/constants/dimensions.dart';
import '../../core/constants/app_assets.dart';
import '../../services/auth_service.dart';
import '../../providers/user_provider.dart';
import '../../widgets/core/app_button.dart';
import '../../widgets/core/app_text_field.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onSignUpTap;

  const LoginScreen({super.key, required this.onSignUpTap});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _error;
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userCredential = await _authService.signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
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

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userCredential = await _authService.signInWithGoogle();

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
    if (error.contains('user-not-found')) {
      return 'No user found with this email.';
    } else if (error.contains('wrong-password')) {
      return 'Incorrect password.';
    } else if (error.contains('invalid-email')) {
      return 'Invalid email address.';
    }
    return 'An error occurred. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Scaffold(
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
                  Icon(
                    Icons.monetization_on_rounded,
                    size: 64,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: AppDimensions.space24),
                  Text(
                    'Welcome Back!',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: AppDimensions.space8),
                  Text(
                    'Login to continue earning',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
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
                    hint: 'Enter your password',
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
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),

                  // Forgot Password
                  Align(
                    alignment: Alignment.centerRight,
                    child: AppButton.text(
                      label: 'Forgot Password?',
                      onPressed: _isLoading
                          ? null
                          : () {
                              Navigator.of(
                                context,
                              ).pushNamed('/forgot-password');
                            },
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space24),

                  // Login Button
                  AppButton(
                    label: 'Login',
                    onPressed: _handleLogin,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: AppDimensions.space24),

                  // Divider
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.space16,
                        ),
                        child: Text(
                          'OR',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.space24),

                  // Google Sign In
                  OutlinedButton(
                    onPressed: _isLoading ? null : _handleGoogleSignIn,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppDimensions.space16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusM,
                        ),
                      ),
                      side: BorderSide(
                        color: isLight
                            ? AppColors.borderLight
                            : AppColors.borderDark,
                      ),
                      foregroundColor: isLight
                          ? AppColors.textPrimaryLight
                          : AppColors.textPrimaryDark,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          AppAssets.googleIcon,
                          height: 24,
                          width: 24,
                        ),
                        const SizedBox(width: AppDimensions.space12),
                        Text(
                          'Continue with Google',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppDimensions.space32),

                  // Sign Up Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      GestureDetector(
                        onTap: _isLoading ? null : widget.onSignUpTap,
                        child: Text(
                          'Sign Up',
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
