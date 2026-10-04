import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../providers/auth_providers.dart';

/// Asks for the account's email and requests a reset link. The emailed
/// `ourhostel://setup-password?forgotPassword=true&token=...` link then opens
/// the set-password page.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail});

  /// Prefilled from the login screen, if the user had typed one.
  final String? initialEmail;

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _emailController = TextEditingController(text: widget.initialEmail);
  bool _isSubmitting = false;

  /// The address the link was sent to; switches to the "check your email" view.
  String? _sentTo;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  static String? _validateEmail(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Required';
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v) ? null : 'Enter a valid email';
  }

  Future<void> _submit() async {
    if (_isSubmitting || !(_formKey.currentState?.validate() ?? false)) return;

    final email = _emailController.text.trim();
    setState(() => _isSubmitting = true);
    try {
      await ref.read(authRepositoryProvider).forgotPassword(email: email);
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _sentTo = email;
      });
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
        title: const Text('Forgot Password'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.navy,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: _sentTo == null ? _form() : _sent(_sentTo!),
    );
  }

  Widget _form() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        children: [
          Text(
            'Enter the email your account was created with. '
            "We'll send you a link to set a new password.",
            style: TextStyle(color: AppColors.navyAlpha(0.6), fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 24),
          AppTextField(
            label: 'Email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            controller: _emailController,
            validator: _validateEmail,
          ),
          const SizedBox(height: 28),
          GradientButton(
            label: 'Send reset link',
            icon: Icons.send_rounded,
            isLoading: _isSubmitting,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }

  Widget _sent(String email) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.mark_email_read_outlined, color: AppColors.white, size: 34),
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          'Check your email',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.navy, fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Text.rich(
          TextSpan(
            text: 'We sent a password reset link to ',
            children: [
              TextSpan(
                text: email,
                style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.w600),
              ),
              const TextSpan(text: '. Open it on this phone to choose a new password.'),
            ],
          ),
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.navyAlpha(0.6), fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 32),
        GradientButton(
          label: 'Back to login',
          icon: Icons.arrow_back_rounded,
          onPressed: () => context.go(AppRoutes.login),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _isSubmitting ? null : () => setState(() => _sentTo = null),
          child: const Text("Didn't get it? Try again"),
        ),
      ],
    );
  }
}
