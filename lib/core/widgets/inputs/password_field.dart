import 'package:flutter/material.dart';
import 'custom_text_field.dart';

class PasswordField extends StatefulWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final void Function(String)? onSubmitted;

  const PasswordField({
    Key? key,
    this.controller,
    this.hintText,
    this.labelText,
    this.validator,
    this.onChanged,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
  }) : super(key: key);

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: widget.controller,
      hintText: widget.hintText,
      labelText: widget.labelText,
      obscureText: _obscureText,
      keyboardType: TextInputType.visiblePassword,
      validator: widget.validator,
      onChanged: widget.onChanged,
      focusNode: widget.focusNode,
      textInputAction: widget.textInputAction,
      onSubmitted: widget.onSubmitted,
      suffixIcon: IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_off : Icons.visibility,
          color: Colors.grey,
        ),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
      ),
    );
  }
}