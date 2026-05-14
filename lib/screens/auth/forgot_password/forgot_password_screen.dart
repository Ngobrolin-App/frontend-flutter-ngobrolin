import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/viewmodels/auth/auth_view_model.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/inputs/custom_text_field.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isSuccess = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

      try {
        final success = await authViewModel.forgotPassword(_emailController.text);

        if (!mounted) return;

        if (success) {
          setState(() {
            _isSuccess = true;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                authViewModel.errorMessage ??
                    context.tr('forgot_password_failed') ??
                    'Failed to send reset link',
              ),
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
            context.tr('forgot_password') ?? 'Forgot Password',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),

          Text(
            context.tr('forgot_password_desc') ??
                'Enter your email address and we will send you a link to reset your password.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: AppColors.text),
          ),
          const SizedBox(height: 32),

          CustomTextField(
            controller: _emailController,
            hintText: context.tr('enter_email') ?? 'Enter your email',
            labelText: context.tr('email') ?? 'Email',
            prefixIcon: const Icon(Icons.email_outlined),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return context.tr('please_enter_email') ?? 'Please enter your email';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return context.tr('invalid_email') ?? 'Please enter a valid email';
              }
              return null;
            },
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 32),

          PrimaryButton(
            text: context.tr('send_reset_link') ?? 'Send Reset Link',
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
        const Icon(Icons.mark_email_read_outlined, size: 100, color: AppColors.primary),
        const SizedBox(height: 24),
        Text(
          context.tr('email_sent') ?? 'Email Sent!',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          context.tr('reset_email_sent_desc') ??
              'We have sent a password reset link to your email. Please check your inbox and spam folder.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, color: AppColors.text),
        ),
        const SizedBox(height: 48),
        PrimaryButton(
          text: context.tr('back_to_login') ?? 'Back to Login',
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
