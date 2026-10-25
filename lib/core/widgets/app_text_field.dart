import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    required this.icon,
    this.isPassword = false,
    this.keyboardType,
    this.controller,
    this.validator,
    this.inputFormatters,
    this.maxLength,
    this.textInputAction,
    this.onFieldSubmitted,
    this.autofillHints,
    this.enabled = true,
    this.errorText,
  });

  final String label;
  final IconData icon;
  final bool isPassword;
  final TextInputType? keyboardType;
  final TextEditingController? controller;
  final FormFieldValidator<String>? validator;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final Iterable<String>? autofillHints;
  final bool enabled;
  final String? errorText;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      enabled: widget.enabled,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onFieldSubmitted,
      autofillHints: widget.autofillHints,
      autocorrect:
          !widget.isPassword &&
          widget.keyboardType != TextInputType.emailAddress,
      enableSuggestions: !widget.isPassword,
      scrollPadding: const EdgeInsets.all(32),
      validator: widget.validator,
      inputFormatters: widget.inputFormatters,
      maxLength: widget.maxLength,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      obscureText: widget.isPassword && _obscure,
      keyboardType: widget.keyboardType,
      style: const TextStyle(
        color: AppColors.navy,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: widget.label,
        errorText: widget.errorText,
        counterText: '',
        prefixIcon: Icon(
          widget.icon,
          color: AppColors.navyAlpha(0.6),
          size: 20,
        ),
        suffixIcon: widget.isPassword
            ? IconButton(
                tooltip: _obscure ? 'Show password' : 'Hide password',
                icon: Icon(
                  _obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.navyAlpha(0.5),
                  size: 20,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              )
            : null,
      ),
    );
  }
}
