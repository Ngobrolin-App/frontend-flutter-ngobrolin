import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/localization/app_localizations.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/inputs/custom_text_field.dart';
import '../../../core/widgets/inputs/password_field.dart';
import '../../../theme/app_colors.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const EditProfileScreen({
    Key? key,
    required this.userData,
  }) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;
  
  File? _imageFile;
  bool _isLoading = false;
  bool _changePassword = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userData['name']);
    _bioController = TextEditingController(text: widget.userData['bio']);
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
        // TODO: Implement API call to update profile
        await Future.delayed(const Duration(seconds: 1)); // Simulate API call

        if (!mounted) return;

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('profile_updated')),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.of(context).pop();
      } catch (e) {
        // Show error message
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
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
      appBar: AppBar(
        title: Text(context.tr('edit_profile')),
      ),
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
                            : (widget.userData['avatarUrl'] != null
                                ? NetworkImage(widget.userData['avatarUrl'])
                                : null),
                        child: (_imageFile == null && widget.userData['avatarUrl'] == null)
                            ? Text(
                                widget.userData['name'][0].toUpperCase(),
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
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
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