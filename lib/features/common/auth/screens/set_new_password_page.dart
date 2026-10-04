import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../providers/auth_providers.dart';

/// Opened from the `ourhostel://setup-password?token=...` link so a student
/// can set their first password, or from a reset link
/// (`...&forgotPassword=true`) to choose a new one.
class SetNewPasswordPage extends ConsumerStatefulWidget {
  const SetNewPasswordPage({super.key, required this.token, this.forgotPassword = false});

  final String token;

  /// True for a forgot-password reset link; sent along with the new password.
  final bool forgotPassword;

  @override
  ConsumerState<SetNewPasswordPage> createState() => _SetNewPasswordPageState();
}

class _SetNewPasswordPageState extends ConsumerState<SetNewPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  static String? _validatePassword(String? value) {
    final v = value ?? '';
    if (v.length < 6) return 'Use at least 6 characters';
    if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Add at least one capital letter';
    if (!RegExp(r'[a-z]').hasMatch(v)) return 'Add at least one small letter';
    if (!RegExp(r'\d').hasMatch(v)) return 'Add at least one number';
    if (!RegExp(r'[^A-Za-z0-9]').hasMatch(v)) return 'Add at least one special symbol';
    return null;
  }

  String? _validateConfirm(String? value) {
    if (value == null || value.isEmpty) return 'Required';
    return value == _passwordController.text ? null : 'Passwords do not match';
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);
    try {
      await ref.read(authRepositoryProvider).setupNewPassword(
            token: widget.token,
            newPassword: _passwordController.text,
            forgotPassword: widget.forgotPassword,
          );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      context.go(AppRoutes.login);
      messenger.showSnackBar(
        SnackBar(
          content: Text(widget.forgotPassword
              ? 'Password reset. Log in with your new password.'
              : 'Password set. You can now log in.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text(widget.forgotPassword ? 'Reset Password' : 'Set New Password'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.navy,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.go(AppRoutes.login),
        ),
      ),
      body: widget.token.isEmpty ? _invalidLink() : _form(),
    );
  }

  Widget _invalidLink() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.link_off_rounded, color: AppColors.navyAlpha(0.4), size: 40),
            const SizedBox(height: 14),
            Text(
              widget.forgotPassword
                  ? 'This password reset link is invalid. Please request a new one.'
                  : 'This password setup link is invalid. Please use the link from your email again.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.navyAlpha(0.6)),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.go(AppRoutes.login),
              child: const Text('Go to login'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _form() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        children: [
          Text(
            '${widget.forgotPassword ? 'Choose a new password for your account.' : 'Create a password for your account.'} '
            'It must be at least 6 characters and include a capital letter, a small letter, '
            'a number and a special symbol.',
            style: TextStyle(color: AppColors.navyAlpha(0.6), fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 24),
          AppTextField(
            label: 'New password',
            icon: Icons.lock_outline_rounded,
            isPassword: true,
            controller: _passwordController,
            validator: _validatePassword,
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Confirm password',
            icon: Icons.lock_reset_rounded,
            isPassword: true,
            controller: _confirmController,
            validator: _validateConfirm,
          ),
          const SizedBox(height: 28),
          GradientButton(
            label: 'Set password',
            icon: Icons.check_rounded,
            isLoading: _isSubmitting,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
