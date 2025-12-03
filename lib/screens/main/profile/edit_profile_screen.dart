import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/material_symbols.dart';
import 'package:ngobrolin_app/core/viewmodels/profile/profile_view_model.dart';
import 'package:ngobrolin_app/core/models/user.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/inputs/custom_text_field.dart';
import '../../../core/widgets/inputs/password_field.dart';
import '../../../theme/app_colors.dart';

class EditProfileScreen extends StatefulWidget {
  final User user;

  const EditProfileScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;
  late TextEditingController _currentPasswordController;

  File? _imageFile;
  bool _isLoading = false;
  bool _changePassword = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _bioController = TextEditingController(text: widget.user.bio ?? '');
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _currentPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _currentPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        final profileVM = Provider.of<ProfileViewModel>(context, listen: false);

        final updated = await profileVM.updateProfile(
          name: _nameController.text.trim(),
          bio: _bioController.text.trim(),
          avatarUrl: _imageFile?.path,
          newPassword: _changePassword ? _passwordController.text.trim() : null,
          currentPassword: _changePassword ? _currentPasswordController.text.trim() : null,
        );

        if (!mounted) return;

        if (updated) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.tr('profile_updated')), backgroundColor: Colors.green),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.warning));
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
                // Profile picture
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
                        child: (_imageFile == null && widget.user.avatarUrl == null)
                            ? Text(
                                widget.user.name.isNotEmpty ? widget.user.name[0].toUpperCase() : '?',
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
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                            ),
                            child: Iconify(
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
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
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
                const SizedBox(height: 24),

                // Change password option
                CheckboxListTile(
                  title: Text(context.tr('change_password')),
                  value: _changePassword,
                  onChanged: (value) {
                    setState(() {
                      _changePassword = value ?? false;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),

                // Password fields (only shown if change password is selected)
                if (_changePassword) ...[
                  const SizedBox(height: 16),
                  PasswordField(
                    controller: _currentPasswordController,
                    labelText: context.tr('current_password'),
                    validator: (value) {
                      if (_changePassword) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your current password';
                        }
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
                          return 'Please enter a new password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
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
                          return 'Please confirm your password';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
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
