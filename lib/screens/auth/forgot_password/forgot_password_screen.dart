import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/viewmodels/auth/auth_view_model.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/inputs/custom_text_field.dart';
import '../../../theme/app_colors.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

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
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Ambil dengan listen: false karena berada di dalam fungsi/event handler
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

    try {
      final success = await authViewModel.forgotPassword(
        _emailController.text
            .trim(), // Tambahkan .trim() untuk menghindari spasi tak sengaja
      );

      if (!mounted) return;

      if (success) {
        // Ambil key translasi terlebih dahulu
        final msgKey =
            authViewModel.successMessage ?? 'reset_password_email_sent_success';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr(msgKey)),
            backgroundColor: AppColors.accent,
          ),
        );
        setState(() {
          _isSuccess = true;
        });
      } else {
        final errorMsg =
            authViewModel.errorMessage ?? context.tr('forgot_password_failed');

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
    final isLoading = context.select<AuthViewModel, bool>((vm) => vm.isLoading);

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
                : _buildFormState(context, isLoading),
          ),
        ),
      ),
    );
  }

  Widget _buildFormState(BuildContext context, bool isLoading) {
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
            errorBuilder: (context, error, stackTrace) {
              // Fallback jika asset logo gagal dimuat/tidak ditemukan saat testing
              return const Icon(
                Icons.image_not_supported,
                size: 100,
                color: AppColors.grey,
              );
            },
          ),
          const SizedBox(height: 16),

          Text(
            context.tr('forgot_password'),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),

          Text(
            context.tr('forgot_password_desc'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: AppColors.text),
          ),
          const SizedBox(height: 32),

          CustomTextField(
            controller: _emailController,
            hintText: context.tr('enter_email'),
            labelText: context.tr('email'),
            prefixIcon: const Icon(Icons.email_outlined),
            keyboardType: TextInputType.emailAddress,
            enabled:
                !isLoading, // Cegah user mengubah input saat sedang loading
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
            textInputAction: TextInputAction.done,
            onSubmitted: isLoading ? null : (_) => _submit(),
          ),
          const SizedBox(height: 32),

          PrimaryButton(
            text: context.tr('send_reset_link'),
            onPressed: isLoading ? null : _submit,
            isLoading: isLoading,
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
        const Icon(
          Icons.mark_email_read_outlined,
          size: 100,
          color: AppColors.primary,
        ),
        const SizedBox(height: 24),
        Text(
          context.tr('email_sent'),
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          context.tr('reset_email_sent_desc'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, color: AppColors.text),
        ),
        const SizedBox(height: 48),
        PrimaryButton(
          text: context.tr('back_to_login'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
