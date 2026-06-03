import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/viewmodels/auth/auth_view_model.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/inputs/password_field.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String? token;

  const ResetPasswordScreen({super.key, this.token});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isSuccess = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (widget.token == null || widget.token!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('invalid_token')), backgroundColor: AppColors.warning),
        );
        return;
      }

      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

      try {
        final success = await authViewModel.resetPassword(widget.token!, _passwordController.text);

        if (!mounted) return;

        if (success) {
          setState(() {
            _isSuccess = true;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authViewModel.errorMessage ?? context.tr('reset_password_failed')),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      } catch (e) {
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: _isSuccess
                ? _buildSuccessState(context)
                : _buildFormState(context, authViewModel),
          ),
        ),
      ),
    );
  }

  Widget _buildFormState(BuildContext context, AuthViewModel authViewModel) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 16),
          // Logo
          Image.asset(
            'assets/apps_logo/app-icon-ngobrolin-enhanced-transparent.png',
            width: 150,
            height: 150,
          ),
          const SizedBox(height: 16),

          Text(
            context.tr('reset_password'),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),

          Text(
            context.tr('reset_password_desc'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: AppColors.text),
          ),
          const SizedBox(height: 32),

          PasswordField(
            controller: _passwordController,
            hintText: context.tr('enter_new_password'),
            labelText: context.tr('new_password'),
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

          PasswordField(
            controller: _confirmPasswordController,
            hintText: context.tr('confirm_new_password'),
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
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 32),

          PrimaryButton(
            text: context.tr('reset_password'),
            onPressed: authViewModel.isLoading ? null : _submit,
            isLoading: authViewModel.isLoading,
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 48),
        const Icon(Icons.check_circle_outline, size: 100, color: Colors.green),
        const SizedBox(height: 24),
        Text(
          context.tr('password_reset_success'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          context.tr('password_reset_success_desc'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, color: AppColors.text),
        ),
        const SizedBox(height: 48),
        PrimaryButton(
          text: context.tr('back_to_login'),
          onPressed: () {
            Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
          },
        ),
      ],
    );
  }
}
