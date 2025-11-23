import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../providers/user_provider.dart';

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
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      _showError('Please fill all fields');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('Passwords do not match');
      return;
    }

    if (_passwordController.text.length < 6) {
      _showError('Password must be at least 6 characters');
      return;
    }

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
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onLoginTap,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.space24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppTheme.space16),
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
                        'Create Account',
                        style: Theme.of(context).textTheme.headlineLarge,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.space40),
                Text(
                  'Join EarnQuest Today',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppTheme.space8),
                Text(
                  'Start earning money with simple tasks',
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
                  controller: _nameController,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    hintText: 'Full Name',
                    prefixIcon: const Icon(Icons.person_outlined),
                  ),
                  keyboardType: TextInputType.name,
                ),
                const SizedBox(height: AppTheme.space16),
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
                const SizedBox(height: AppTheme.space16),
                TextField(
                  controller: _confirmPasswordController,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    hintText: 'Confirm Password',
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
                  ),
                  obscureText: _obscureConfirmPassword,
                ),
                const SizedBox(height: AppTheme.space24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSignUp,
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Text('Create Account'),
                  ),
                ),
                const SizedBox(height: AppTheme.space32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: _isLoading ? null : widget.onLoginTap,
                      child: Text(
                        'Login',
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
