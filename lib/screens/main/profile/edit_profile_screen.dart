import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/material_symbols.dart';
import 'package:ngobrolin_app/core/viewmodels/profile/profile_view_model.dart';
import 'package:ngobrolin_app/core/models/user_model.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/inputs/custom_text_field.dart';
import '../../../core/widgets/inputs/password_field.dart';
import '../../../theme/app_colors.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;

  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _bioController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;
  late final TextEditingController _currentPasswordController;

  File? _imageFile;
  bool _isLoading = false;
  bool _changePassword = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _emailController = TextEditingController(text: widget.user.email ?? '');
    _bioController = TextEditingController(text: widget.user.bio ?? '');
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _currentPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _currentPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    // OPTIMASI: Bungkus dengan try-catch untuk mengantisipasi penolakan permission storage oleh user
    try {
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth:
            512, // Batasi resolusi gambar sebelum di-upload untuk menghemat bandwidth
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('failed_to_pick_image'))),
      );
    }
  }

  // OPTIMASI: Bersihkan input password saat form password disembunyikan
  void _toggleChangePassword(bool value) {
    setState(() {
      _changePassword = value;
      if (!_changePassword) {
        _currentPasswordController.clear();
        _passwordController.clear();
        _confirmPasswordController.clear();
      }
    });
    // Validasi ulang form agar sisa error validasi password hilang seketika
    _formKey.currentState?.validate();
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        final profileVM = Provider.of<ProfileViewModel>(context, listen: false);

        final success = await profileVM.updateProfile(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          bio: _bioController.text.trim(),
          avatarUrl: _imageFile?.path,
          newPassword: _changePassword ? _passwordController.text.trim() : null,
          currentPassword: _changePassword
              ? _currentPasswordController.text.trim()
              : null,
        );

        if (!mounted) return;

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('profile_updated')),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(
            context,
          ).pop(); // Kembalikan ke halaman profil setelah berhasil update
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.tr(
                  profileVM.errorMessage ?? 'failed_to_update_profile',
                ),
              ),
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
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('edit_profile'))),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Profile picture section
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: _imageFile != null
                            ? FileImage(_imageFile!)
                            : (widget.user.avatarUrl != null
                                  ? NetworkImage(widget.user.avatarUrl!)
                                  : null),
                        child:
                            (_imageFile == null &&
                                widget.user.avatarUrl == null)
                            ? Text(
                                widget.user.name.isNotEmpty
                                    ? widget.user.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 50,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: InkWell(
                          onTap: _pickImage,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                            ),
                            child: const Iconify(
                              MaterialSymbols.android_camera,
                              color: AppColors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Name field
                CustomTextField(
                  controller: _nameController,
                  labelText: context.tr('name'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return context.tr('please_enter_name');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Email field
                CustomTextField(
                  controller: _emailController,
                  labelText: context.tr('email'),
                  keyboardType: TextInputType.emailAddress,
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
                ),
                const SizedBox(height: 16),

                // Bio field
                CustomTextField(
                  controller: _bioController,
                  labelText: context.tr('bio'),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                // Change password option
                CheckboxListTile(
                  title: Text(context.tr('change_password')),
                  value: _changePassword,
                  onChanged: (value) => _toggleChangePassword(value ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.primary,
                ),

                // Password fields with Dynamic Visibility Switching
                if (_changePassword) ...[
                  const SizedBox(height: 16),
                  PasswordField(
                    controller: _currentPasswordController,
                    labelText: context.tr('current_password'),
                    validator: (value) {
                      if (_changePassword && (value == null || value.isEmpty)) {
                        return context.tr('please_enter_current_password');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  PasswordField(
                    controller: _passwordController,
                    labelText: context.tr('new_password'),
                    validator: (value) {
                      if (_changePassword) {
                        if (value == null || value.isEmpty) {
                          return context.tr('please_enter_new_password');
                        }
                        if (value.length < 6) {
                          return context.tr('password_too_short');
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  PasswordField(
                    controller: _confirmPasswordController,
                    labelText: context.tr('confirm_new_password'),
                    validator: (value) {
                      if (_changePassword) {
                        if (value == null || value.isEmpty) {
                          return context.tr('please_confirm_password');
                        }
                        if (value != _passwordController.text) {
                          return context.tr('passwords_do_not_match');
                        }
                      }
                      return null;
                    },
                  ),
                ],

                const SizedBox(height: 32),

                // Save button
                PrimaryButton(
                  text: context.tr('save_changes'),
                  onPressed: _saveProfile,
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
