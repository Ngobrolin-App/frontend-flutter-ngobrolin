import 'package:flutter/material.dart';
import 'package:ngobrolin_app/core/providers/socket_provider.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/viewmodels/auth/auth_view_model.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/inputs/custom_text_field.dart';
import '../../../core/widgets/inputs/password_field.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import 'dart:developer' as developer;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameOrEmailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameOrEmailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState?.validate() ?? false) {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      try {
        final success = await authViewModel.signIn(
          _usernameOrEmailController.text,
          _passwordController.text,
        );

        // Sinkronisasi state ke provider lama agar tetap konsisten
        await authProvider.signIn(
          _usernameOrEmailController.text,
          _passwordController.text,
        );

        if (!mounted) return;

        if (success) {
          final socketProvider = Provider.of<SocketProvider>(
            context,
            listen: false,
          );
          await socketProvider.init(token: authViewModel.token);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  context.tr(authViewModel.successMessage ?? 'login_success'),
                ),
                backgroundColor: AppColors.accent,
              ),
            );
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil(AppRoutes.main, (route) => false);
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.tr(authViewModel.errorMessage ?? 'login_failed'),
              ),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      } catch (e) {
        developer.log('LoginScreen - _login() error: $e', name: 'LoginScreen');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.warning,
          ),
        );
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

                  // App name
                  Text(
                    context.tr('sign_in'),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Username field
                  CustomTextField(
                    controller: _usernameOrEmailController,
                    hintText: context.tr('enter_username_or_email'),
                    labelText: context.tr('username_or_email'),
                    prefixIcon: const Icon(Icons.person_outline),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return context.tr('please_enter_username_or_email');
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
                      return null;
                    },
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _login(),
                  ),
                  const SizedBox(height: 8),

                  // Forgot password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(
                          context,
                        ).pushNamed(AppRoutes.forgotPassword);
                      },
                      child: Text(
                        context.tr('forgot_password'),
                        style: const TextStyle(color: AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Login button
                  PrimaryButton(
                    text: context.tr('sign_in'),
                    onPressed: authViewModel.isLoading
                        ? null
                        : () {
                            _login();
                          },
                    isLoading: authViewModel.isLoading,
                  ),
                  const SizedBox(height: 24),

                  // Register link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(context.tr('dont_have_account')),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushNamed(AppRoutes.register);
                        },
                        child: Text(
                          context.tr('register'),
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
