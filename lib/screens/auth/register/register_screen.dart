import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/viewmodels/auth/auth_view_model.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/inputs/custom_text_field.dart';
import '../../../core/widgets/inputs/password_field.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';

/// Screen responsible for capturing new user registration details
/// and dispatching signup requests to the AuthViewModel.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Validates the registration form and executes the sign-up transaction via ViewModel.
  Future<void> _register() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

    try {
      final inputName = _nameController.text.trim();
      final inputEmail = _emailController.text.trim();
      final inputUsername = _usernameController.text.trim();
      final inputPassword = _passwordController.text;

      // 1. Executes the registration process exclusively through the ViewModel
      final success = await authViewModel.signUp(
        username: inputUsername,
        email: inputEmail,
        name: inputName,
        password: inputPassword,
      );

      if (!mounted) return;

      if (success) {
        final successMsg =
            authViewModel.successMessage ?? 'registration_success';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr(successMsg)),
            backgroundColor: AppColors.accent,
          ),
        );

        // Redirects to login screen after successful registration
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
      } else {
        final errorMsg =
            authViewModel.errorMessage ?? context.tr('registration_failed');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr(errorMsg)),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr(e.toString())),
          backgroundColor: AppColors.warning,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Selects the loading state specifically to minimize widget rebuilds
    final isLoading = context.select<AuthViewModel, bool>((vm) => vm.isLoading);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 32),

                  // App Logo
                  Image.asset(
                    'assets/apps_logo/app-icon-ngobrolin-enhanced-transparent.png',
                    width: 200,
                    height: 200,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.image_not_supported,
                      size: 100,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title Text
                  Text(
                    context.tr('sign_up'),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Name Input Field
                  CustomTextField(
                    controller: _nameController,
                    hintText: context.tr('enter_name'),
                    labelText: context.tr('name'),
                    prefixIcon: const Icon(Icons.person_outline),
                    textCapitalization: TextCapitalization.words,
                    enabled: !isLoading,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return context.tr('please_enter_name');
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),

                  // Email Input Field
                  CustomTextField(
                    controller: _emailController,
                    hintText: context.tr('enter_email'),
                    labelText: context.tr('email'),
                    prefixIcon: const Icon(Icons.email_outlined),
                    keyboardType: TextInputType.emailAddress,
                    enabled: !isLoading,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return context.tr('please_enter_email');
                      }
                      if (!RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      ).hasMatch(value.trim())) {
                        return context.tr('invalid_email');
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),

                  // Username Input Field
                  CustomTextField(
                    controller: _usernameController,
                    hintText: context.tr('enter_username'),
                    labelText: context.tr('username'),
                    prefixIcon: const Icon(Icons.alternate_email),
                    enabled: !isLoading,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return context.tr('please_enter_username');
                      }
                      if (value.trim().contains(' ')) {
                        return context.tr('username_cannot_contain_spaces');
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),

                  // Password Input Field
                  PasswordField(
                    controller: _passwordController,
                    hintText: context.tr('enter_password'),
                    labelText: context.tr('password'),
                    enabled: !isLoading,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return context.tr('please_enter_password');
                      }
                      if (value.length < 6) {
                        return context.tr(
                          'password_must_be_at_least_6_characters',
                        );
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),

                  // Confirm Password Input Field
                  PasswordField(
                    controller: _confirmPasswordController,
                    hintText: context.tr('enter_password'),
                    labelText: context.tr('confirm_password'),
                    enabled: !isLoading,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return context.tr('please_confirm_your_password');
                      }
                      if (value != _passwordController.text) {
                        return context.tr('passwords_do_not_match');
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.done,
                    onSubmitted: isLoading ? null : (_) => _register(),
                  ),
                  const SizedBox(height: 32),

                  // Registration Action Button
                  PrimaryButton(
                    text: context.tr('sign_up'),
                    onPressed: isLoading ? null : _register,
                    isLoading: isLoading,
                  ),
                  const SizedBox(height: 24),

                  // Login Redirection Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(context.tr('already_have_account')),
                      TextButton(
                        onPressed: isLoading
                            ? null
                            : () {
                                Navigator.of(context).pop();
                              },
                        child: Text(
                          context.tr('login'),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
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
      ),
    );
  }
}
