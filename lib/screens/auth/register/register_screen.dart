import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/viewmodels/auth/auth_view_model.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/inputs/custom_text_field.dart';
import '../../../core/widgets/inputs/password_field.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_formKey.currentState?.validate() ?? false) {
      // Get the AuthViewModel
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

      // Also get the legacy AuthProvider for backward compatibility
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      try {
        // Use the new ViewModel for registration
        final success = await authViewModel.signUp(
          username: _usernameController.text,
          name: _nameController.text,
          password: _passwordController.text,
        );

        // Also update the legacy provider (sinkronisasi state)
        await authProvider.signUp(_usernameController.text, _passwordController.text);

        if (!mounted) return;

        if (success) {
          // Navigate to login screen on successful registration
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('registration_successful')),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.of(context).pushReplacementNamed(AppRoutes.login);
        } else {
          // Show error message if registration failed
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authViewModel.errorMessage ?? context.tr('registration_failed')),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      } catch (e) {
        // Show error message
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.warning));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);

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

                  // Logo
                  Image.asset(
                    'assets/apps_logo/app-icon-ngobrolin-enhanced-transparent.png',
                    width: 200,
                    height: 200,
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Text(
                    context.tr('sign_up'),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Name field
                  CustomTextField(
                    controller: _nameController,
                    hintText: context.tr('enter_name'),
                    labelText: context.tr('name'),
                    prefixIcon: const Icon(Icons.person_outline),
                    textCapitalization: TextCapitalization.words,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),

                  // Username field
                  CustomTextField(
                    controller: _usernameController,
                    hintText: context.tr('enter_username'),
                    labelText: context.tr('username'),
                    prefixIcon: const Icon(Icons.alternate_email),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return context.tr('please_enter_username');
                      }
                      if (value.contains(' ')) {
                        return context.tr('username_cannot_contain_spaces');
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),

                  // Password field
                  PasswordField(
                    controller: _passwordController,
                    hintText: context.tr('enter_password'),
                    labelText: context.tr('password'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return context.tr('please_enter_password');
                      }
                      if (value.length < 6) {
                        return context.tr('password_must_be_at_least_6_characters');
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),

                  // Confirm password field
                  PasswordField(
                    controller: _confirmPasswordController,
                    hintText: context.tr('enter_password'),
                    labelText: context.tr('confirm_password'),
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
                    onSubmitted: (_) => _register(),
                  ),
                  const SizedBox(height: 32),

                  // Register button
                  PrimaryButton(
                    text: context.tr('sign_up'),
                    onPressed: authViewModel.isLoading
                        ? null
                        : () {
                            _register();
                          },
                    isLoading: authViewModel.isLoading,
                  ),
                  const SizedBox(height: 24),

                  // Login link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(context.tr('already_have_account')),
                      TextButton(
                        onPressed: () {
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
