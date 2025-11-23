import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../providers/user_provider.dart';

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
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError('Please fill all fields');
      return;
    }

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
        // Initialize user provider
        if (mounted) {
          await context.read<UserProvider>().initializeUser(
            userCredential.user!.uid,
          );
        }

        // Navigate to home
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      }
    } catch (e) {
      _showError(e.toString());
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
        // Initialize user provider
        if (mounted) {
          await context.read<UserProvider>().initializeUser(
            userCredential.user!.uid,
          );
        }

        // Navigate to home
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    setState(() {
      _error = message;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.space24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppTheme.space32),
                Center(
                  child: Column(
                    children: [
                      Text(
                        '💰',
                        style: Theme.of(
                          context,
                        ).textTheme.headlineLarge?.copyWith(fontSize: 64.0),
                      ),
                      const SizedBox(height: AppTheme.space16),
                      Text(
                        'EarnQuest',
                        style: Theme.of(context).textTheme.headlineLarge,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.space40),
                Text(
                  'Welcome Back!',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppTheme.space8),
                Text(
                  'Login to start earning money',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppTheme.space32),
                if (_error != null)
                  Container(
                    padding: const EdgeInsets.all(AppTheme.space12),
                    margin: const EdgeInsets.only(bottom: AppTheme.space16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(AppTheme.radiusS),
                      border: Border.all(color: Colors.red),
                    ),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                TextField(
                  controller: _emailController,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    hintText: 'Email Address',
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: AppTheme.space16),
                TextField(
                  controller: _passwordController,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    hintText: 'Password',
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
                  ),
                  obscureText: _obscurePassword,
                ),
                const SizedBox(height: AppTheme.space8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            // Navigate to forgot password
                            Navigator.of(context).pushNamed('/forgot-password');
                          },
                    child: Text(
                      'Forgot Password?',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.space24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Text('Login'),
                  ),
                ),
                const SizedBox(height: AppTheme.space24),
                Row(
                  children: [
                    Expanded(
                      child: Divider(color: AppTheme.surfaceVariant, height: 1),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.space12,
                      ),
                      child: Text(
                        'OR',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                    Expanded(
                      child: Divider(color: AppTheme.surfaceVariant, height: 1),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.space24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _handleGoogleSignIn,
                    icon: const Text('🔍'),
                    label: const Text('Continue with Google'),
                  ),
                ),
                const SizedBox(height: AppTheme.space32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: _isLoading ? null : widget.onSignUpTap,
                      child: Text(
                        'Sign Up',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppTheme.primaryColor,
                        ),
                      ),
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
