import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/hostel_colors.dart';
import '../model/user_role.dart';
import '../providers/auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (ref.read(authControllerProvider).isLoading ||
        !(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    FocusScope.of(context).unfocus();
    ref
        .read(authControllerProvider.notifier)
        .login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authControllerProvider, (previous, next) {
      next.whenOrNull(
        data: (role) {
          if (role == null) return;
          final destination = role == UserRole.student
              ? AppRoutes.studentHome
              : AppRoutes.adminHome;
          TextInput.finishAutofillContext();
          context.go(destination);
        },
        error: (error, _) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(error.toString())));
        },
      );
    });

    final isLoading = ref.watch(authControllerProvider).isLoading;

    final theme = Theme.of(context);
    final colors =
        theme.extension<HostelColors>() ??
        (theme.brightness == Brightness.dark
            ? HostelColors.dark
            : HostelColors.light);
    final topPadding = MediaQuery.paddingOf(context).top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: colors.surface,
        body: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 310 + topPadding,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.brand,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(28),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: CustomScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  slivers: [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              24,
                              92 + topPadding,
                              24,
                              32,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: colors.brandRaised,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(
                                    Icons.bed_outlined,
                                    color: colors.marigold,
                                    size: 30,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Our Hostel',
                                  style: TextStyle(
                                    color: colors.onBrand,
                                    fontSize: 32,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -1,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Attendance, leave and hostel notices in one place.',
                                  style: TextStyle(
                                    color: colors.onBrandMuted,
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
                            decoration: BoxDecoration(
                              color: colors.surfaceRaised,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: colors.line),
                              boxShadow: [
                                BoxShadow(
                                  color: colors.scrim.withValues(alpha: 0.12),
                                  offset: const Offset(0, 8),
                                  blurRadius: 20,
                                ),
                                BoxShadow(
                                  color: colors.scrim.withValues(alpha: 0.04),
                                  offset: const Offset(0, 2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: AutofillGroup(
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      'Sign in',
                                      style: TextStyle(
                                        color: colors.ink,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    _fieldLabel('College email', colors),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: _emailController,
                                      enabled: !isLoading,
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.next,
                                      autofillHints: const [
                                        AutofillHints.username,
                                        AutofillHints.email,
                                      ],
                                      autocorrect: false,
                                      style: TextStyle(
                                        color: colors.ink,
                                        fontSize: 14,
                                      ),
                                      decoration: _inputDecoration(
                                        colors,
                                        icon: Icons.mail_outline_rounded,
                                        hint: 'arun.kumar@college.edu',
                                      ),
                                      autovalidateMode:
                                          AutovalidateMode.onUserInteraction,
                                      validator: (value) {
                                        final email = value?.trim() ?? '';
                                        if (email.isEmpty) {
                                          return 'Enter your email address';
                                        }
                                        return RegExp(
                                              r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                            ).hasMatch(email)
                                            ? null
                                            : 'Enter a valid email address';
                                      },
                                    ),
                                    const SizedBox(height: 18),
                                    _fieldLabel('Password', colors),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: _passwordController,
                                      enabled: !isLoading,
                                      obscureText: _obscurePassword,
                                      autocorrect: false,
                                      enableSuggestions: false,
                                      textInputAction: TextInputAction.done,
                                      autofillHints: const [
                                        AutofillHints.password,
                                      ],
                                      onFieldSubmitted: (_) => _handleLogin(),
                                      style: TextStyle(
                                        color: colors.ink,
                                        fontSize: 14,
                                      ),
                                      decoration:
                                          _inputDecoration(
                                            colors,
                                            icon: Icons.lock_outline_rounded,
                                          ).copyWith(
                                            suffixIcon: IconButton(
                                              tooltip: _obscurePassword
                                                  ? 'Show password'
                                                  : 'Hide password',
                                              onPressed: isLoading
                                                  ? null
                                                  : () => setState(() {
                                                      _obscurePassword =
                                                          !_obscurePassword;
                                                    }),
                                              icon: Icon(
                                                _obscurePassword
                                                    ? Icons.visibility_outlined
                                                    : Icons
                                                          .visibility_off_outlined,
                                                color: colors.inkMuted,
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                      autovalidateMode:
                                          AutovalidateMode.onUserInteraction,
                                      validator: (value) =>
                                          value == null || value.isEmpty
                                          ? 'Enter your password'
                                          : null,
                                    ),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        style: TextButton.styleFrom(
                                          foregroundColor: colors.primary,
                                          padding: EdgeInsets.zero,
                                          textStyle: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        onPressed: isLoading
                                            ? null
                                            : () => context.push(
                                                AppRoutes.forgotPassword,
                                                extra: _emailController.text
                                                    .trim(),
                                              ),
                                        child: const Text('Forgot password?'),
                                      ),
                                    ),
                                    FilledButton(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: colors.primary,
                                        foregroundColor: colors.onPrimary,
                                        disabledBackgroundColor: colors.primary,
                                        disabledForegroundColor:
                                            colors.onPrimary,
                                        minimumSize: const Size.fromHeight(48),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        textStyle: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      onPressed: isLoading
                                          ? null
                                          : _handleLogin,
                                      child: isLoading
                                          ? SizedBox.square(
                                              dimension: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: colors.onPrimary,
                                                semanticsLabel: 'Signing in',
                                              ),
                                            )
                                          : const Text('Sign in'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          const Spacer(),
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              28,
                              0,
                              28,
                              44 + MediaQuery.paddingOf(context).bottom,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  size: 20,
                                  color: colors.inkMuted,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    "There's no sign-up. Your hostel office creates your account and emails you a link to set your password.",
                                    style: TextStyle(
                                      color: colors.inkMuted,
                                      fontSize: 12,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fieldLabel(String label, HostelColors colors) => Text(
    label,
    style: TextStyle(
      color: colors.ink,
      fontSize: 12,
      fontWeight: FontWeight.w600,
      height: 1.5,
    ),
  );

  InputDecoration _inputDecoration(
    HostelColors colors, {
    required IconData icon,
    String? hint,
  }) {
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: width),
        );
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: colors.inkMuted, fontSize: 14),
      filled: true,
      fillColor: colors.surfaceRaised,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      prefixIcon: Icon(icon, size: 20, color: colors.inkMuted),
      border: border(colors.lineStrong),
      enabledBorder: border(colors.lineStrong),
      disabledBorder: border(colors.line),
      focusedBorder: border(colors.focus, 1.5),
      errorBorder: border(colors.danger),
      focusedErrorBorder: border(colors.danger, 1.5),
      errorStyle: TextStyle(color: colors.danger),
      errorMaxLines: 3,
    );
  }
}
