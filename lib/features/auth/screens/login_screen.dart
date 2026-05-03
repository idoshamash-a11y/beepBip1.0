import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideIn;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _emailFocused = false;
  bool _passwordFocused = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideIn = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _emailFocus.addListener(
      () => setState(() => _emailFocused = _emailFocus.hasFocus),
    );
    _passwordFocus.addListener(
      () => setState(() => _passwordFocused = _passwordFocus.hasFocus),
    );

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _handleEmailSignIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || !email.contains('@')) {
      _showError('Please enter a valid email address.');
      return;
    }
    if (password.isEmpty) {
      _showError('Please enter your password.');
      return;
    }

    final ok = await ref
        .read(authControllerProvider.notifier)
        .signInWithEmail(email: email, password: password);

    if (!mounted) return;
    if (ok) {
      // Router will redirect based on onboarding state automatically.
      return;
    }
    _showError(
      ref.read(authControllerProvider).error ?? 'Sign in failed.',
    );
  }

  Future<void> _handleSocial(Future<bool> Function() op) async {
    final ok = await op();
    if (!mounted) return;
    if (ok) return; // router handles it
    _showError(
      ref.read(authControllerProvider).error ?? 'Sign in failed.',
    );
  }

  Future<void> _handleForgotPassword() async {
    final email = await _promptForResetEmail(
      initial: _emailController.text.trim(),
    );
    if (email == null || !mounted) return;

    final ok = await ref
        .read(authControllerProvider.notifier)
        .resetPassword(email);

    if (!mounted) return;
    if (ok) {
      // Supabase doesn't disclose whether the email exists — we say the same
      // thing either way so we don't leak which addresses are registered.
      _showMessage(
        "If an account exists for $email, we've sent a password reset link.",
      );
    } else {
      _showError(
        ref.read(authControllerProvider).error ??
            'Could not send reset email. Please try again.',
      );
    }
  }

  Future<String?> _promptForResetEmail({required String initial}) {
    final controller = TextEditingController(text: initial);
    final c = context.colors;
    return showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: c.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Reset your password',
            style: GoogleFonts.outfit(
              color: c.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Enter your account email and we'll send you a link to set a new password.",
                style: GoogleFonts.outfit(
                  color: c.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.emailAddress,
                style: GoogleFonts.outfit(color: c.textPrimary, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'you@example.com',
                  hintStyle: GoogleFonts.outfit(
                    color: c.textMuted,
                    fontSize: 15,
                  ),
                  filled: true,
                  fillColor: c.inputBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: c.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: c.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.accent, width: 1.5),
                  ),
                ),
                onSubmitted: (v) {
                  final trimmed = v.trim();
                  if (trimmed.isNotEmpty && trimmed.contains('@')) {
                    Navigator.of(ctx).pop(trimmed);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.outfit(color: c.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () {
                final v = controller.text.trim();
                if (v.isEmpty || !v.contains('@')) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid email address.'),
                    ),
                  );
                  return;
                }
                Navigator.of(ctx).pop(v);
              },
              child: Text(
                'Send link',
                style: GoogleFonts.outfit(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final auth = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: FadeTransition(
              opacity: _fadeIn,
              child: SlideTransition(
                position: _slideIn,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 56),

                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accent.withValues(alpha: 0.22),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.location_on_rounded,
                            color: c.bg,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'BEEPBIP',
                          style: GoogleFonts.outfit(
                            color: c.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2.5,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 44),

                    Text(
                      'Welcome back',
                      style: GoogleFonts.outfit(
                        color: c.textPrimary,
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Sign in to discover people near you',
                      style: GoogleFonts.outfit(
                        color: c.textSecondary,
                        fontSize: 15,
                      ),
                    ),

                    const SizedBox(height: 40),

                    _FieldLabel(label: 'Email address', color: c.textSecondary),
                    const SizedBox(height: 8),
                    _PremiumField(
                      controller: _emailController,
                      hint: 'you@example.com',
                      focusNode: _emailFocus,
                      isFocused: _emailFocused,
                      keyboardType: TextInputType.emailAddress,
                      icon: Icons.mail_outline_rounded,
                      inputBg: c.inputBg,
                      border: c.border,
                      textColor: c.textPrimary,
                      hintColor: c.textMuted,
                    ),

                    const SizedBox(height: 20),

                    _FieldLabel(label: 'Password', color: c.textSecondary),
                    const SizedBox(height: 8),
                    _PremiumField(
                      controller: _passwordController,
                      hint: '••••••••',
                      focusNode: _passwordFocus,
                      isFocused: _passwordFocused,
                      obscureText: _obscurePassword,
                      icon: Icons.lock_outline_rounded,
                      inputBg: c.inputBg,
                      border: c.border,
                      textColor: c.textPrimary,
                      hintColor: c.textMuted,
                      suffix: GestureDetector(
                        onTap: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                        child: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: c.textSecondary,
                          size: 20,
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => setState(
                            () => _rememberMe = !_rememberMe,
                          ),
                          child: Row(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: _rememberMe
                                      ? AppColors.accent
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(
                                    color: _rememberMe
                                        ? AppColors.accent
                                        : c.border,
                                    width: 1.5,
                                  ),
                                ),
                                child: _rememberMe
                                    ? Icon(Icons.check, color: c.bg, size: 13)
                                    : null,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Remember me',
                                style: GoogleFonts.outfit(
                                  color: c.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: auth.isLoading ? null : _handleForgotPassword,
                          child: Text(
                            'Forgot password?',
                            style: GoogleFonts.outfit(
                              color: AppColors.accent,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    _PrimaryButton(
                      label: 'Sign in',
                      isLoading: auth.isLoading,
                      bgColor: c.bg,
                      onTap: auth.isLoading ? null : _handleEmailSignIn,
                    ),

                    const SizedBox(height: 28),

                    Row(
                      children: [
                        Expanded(child: Container(height: 1, color: c.border)),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            'or continue with',
                            style: GoogleFonts.outfit(
                              color: c.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Expanded(child: Container(height: 1, color: c.border)),
                      ],
                    ),

                    const SizedBox(height: 20),

                    _SocialRow(
                      isLoading: auth.isLoading,
                      onApple: () => _handleSocial(
                        ref
                            .read(authControllerProvider.notifier)
                            .signInWithApple,
                      ),
                      onGoogle: () => _handleSocial(
                        ref
                            .read(authControllerProvider.notifier)
                            .signInWithGoogle,
                      ),
                      onFacebook: () => _handleSocial(
                        ref
                            .read(authControllerProvider.notifier)
                            .signInWithFacebook,
                      ),
                      bg: c.surface,
                      border: c.border,
                      textColor: c.textPrimary,
                    ),

                    const SizedBox(height: 40),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: GoogleFonts.outfit(
                            color: c.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.go('/register'),
                          child: Text(
                            'Sign up',
                            style: GoogleFonts.outfit(
                              color: AppColors.accent,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  final Color color;
  const _FieldLabel({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: GoogleFonts.outfit(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      );
}

class _PremiumField extends StatelessWidget {
  final TextEditingController? controller;
  final String hint;
  final FocusNode focusNode;
  final bool isFocused;
  final bool obscureText;
  final IconData icon;
  final Widget? suffix;
  final TextInputType keyboardType;
  final Color inputBg;
  final Color border;
  final Color textColor;
  final Color hintColor;

  const _PremiumField({
    this.controller,
    required this.hint,
    required this.focusNode,
    required this.isFocused,
    required this.icon,
    required this.inputBg,
    required this.border,
    required this.textColor,
    required this.hintColor,
    this.obscureText = false,
    this.suffix,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isFocused
              ? AppColors.accent.withValues(alpha: 0.7)
              : border,
          width: isFocused ? 1.5 : 1.0,
        ),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.06),
                  blurRadius: 12,
                ),
              ]
            : [],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: GoogleFonts.outfit(color: textColor, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.outfit(color: hintColor, fontSize: 15),
          prefixIcon: Icon(
            icon,
            color: isFocused ? AppColors.accent : hintColor,
            size: 20,
          ),
          suffixIcon: suffix != null
              ? Padding(padding: const EdgeInsets.only(right: 14), child: suffix)
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;
  final Color bgColor;

  const _PrimaryButton({
    required this.label,
    required this.onTap,
    required this.bgColor,
    this.isLoading = false,
  });

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onTap == null;
    return GestureDetector(
      onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
      onTapUp: disabled
          ? null
          : (_) {
              setState(() => _pressed = false);
              widget.onTap?.call();
            },
      onTapCancel: disabled ? null : () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: widget.isLoading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(widget.bgColor),
                    ),
                  )
                : Text(
                    widget.label,
                    style: GoogleFonts.outfit(
                      color: widget.bgColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Stacks Apple, Google and Facebook social buttons. We show three vertically
/// rather than three squeezed horizontally so each label is readable on
/// narrow phones, and so the order matches Apple's HIG (Apple at the top).
class _SocialRow extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onApple;
  final VoidCallback onGoogle;
  final VoidCallback onFacebook;
  final Color bg;
  final Color border;
  final Color textColor;

  const _SocialRow({
    required this.isLoading,
    required this.onApple,
    required this.onGoogle,
    required this.onFacebook,
    required this.bg,
    required this.border,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SocialButton(
          label: 'Continue with Apple',
          icon: const _AppleIcon(),
          bg: Colors.black,
          border: Colors.black,
          textColor: Colors.white,
          onTap: isLoading ? null : onApple,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SocialButton(
                label: 'Google',
                icon: _GoogleIcon(),
                bg: bg,
                border: border,
                textColor: textColor,
                onTap: isLoading ? null : onGoogle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SocialButton(
                label: 'Facebook',
                icon: const _FacebookIcon(),
                bg: bg,
                border: border,
                textColor: textColor,
                onTap: isLoading ? null : onFacebook,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SocialButton extends StatefulWidget {
  final String label;
  final Widget icon;
  final Color bg;
  final Color border;
  final Color textColor;
  final VoidCallback? onTap;

  const _SocialButton({
    required this.label,
    required this.icon,
    required this.bg,
    required this.border,
    required this.textColor,
    required this.onTap,
  });

  @override
  State<_SocialButton> createState() => _SocialButtonState();
}

class _SocialButtonState extends State<_SocialButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onTap == null;
    return GestureDetector(
      onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
      onTapUp: disabled
          ? null
          : (_) {
              setState(() => _pressed = false);
              widget.onTap?.call();
            },
      onTapCancel: disabled ? null : () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Opacity(
          opacity: disabled ? 0.5 : 1.0,
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: widget.bg,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: widget.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                widget.icon,
                const SizedBox(width: 8),
                Text(
                  widget.label,
                  style: GoogleFonts.outfit(
                    color: widget.textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AppleIcon extends StatelessWidget {
  const _AppleIcon();

  @override
  Widget build(BuildContext context) {
    return const Icon(Icons.apple, size: 20, color: Colors.white);
  }
}

class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GooglePainter()),
    );
  }
}

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -0.1,
      1.7,
      true,
      paint,
    );
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      1.6,
      1.6,
      true,
      paint,
    );
    paint.color = const Color(0xFFFBBC04);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      3.2,
      0.8,
      true,
      paint,
    );
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      4.0,
      1.3,
      true,
      paint,
    );
    paint.color = Colors.white;
    canvas.drawCircle(center, radius * 0.55, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FacebookIcon extends StatelessWidget {
  const _FacebookIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: const BoxDecoration(
        color: Color(0xFF1877F2),
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Text(
          'f',
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w900,
            height: 1.2,
          ),
        ),
      ),
    );
  }
}
