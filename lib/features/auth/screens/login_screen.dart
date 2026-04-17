import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

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

  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _emailFocused = false;
  bool _passwordFocused = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideIn = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _emailFocus.addListener(() => setState(() => _emailFocused = _emailFocus.hasFocus));
    _passwordFocus.addListener(() => setState(() => _passwordFocused = _passwordFocus.hasFocus));

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
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

                    // Logo row
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
                          child: Icon(Icons.location_on_rounded, color: c.bg, size: 26),
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
                        onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                        child: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
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
                          onTap: () => setState(() => _rememberMe = !_rememberMe),
                          child: Row(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: _rememberMe ? AppColors.accent : Colors.transparent,
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(
                                    color: _rememberMe ? AppColors.accent : c.border,
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
                                style: GoogleFonts.outfit(color: c.textSecondary, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {},
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
                      isLoading: _isLoading,
                      bgColor: c.bg,
                      onTap: () {
                        setState(() => _isLoading = true);
                        Future.delayed(const Duration(seconds: 2), () {
                          if (mounted) setState(() => _isLoading = false);
                        });
                      },
                    ),

                    const SizedBox(height: 28),

                    Row(
                      children: [
                        Expanded(child: Container(height: 1, color: c.border)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            'or continue with',
                            style: GoogleFonts.outfit(color: c.textSecondary, fontSize: 12),
                          ),
                        ),
                        Expanded(child: Container(height: 1, color: c.border)),
                      ],
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: _SocialButton(
                            label: 'Google',
                            icon: _GoogleIcon(),
                            bg: c.surface,
                            border: c.border,
                            textColor: c.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SocialButton(
                            label: 'Facebook',
                            icon: _FacebookIcon(),
                            bg: c.surface,
                            border: c.border,
                            textColor: c.textPrimary,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: GoogleFonts.outfit(color: c.textSecondary, fontSize: 14),
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
        style: GoogleFonts.outfit(color: color, fontSize: 13, fontWeight: FontWeight.w500),
      );
}

class _PremiumField extends StatelessWidget {
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
          color: isFocused ? AppColors.accent.withValues(alpha: 0.7) : border,
          width: isFocused ? 1.5 : 1.0,
        ),
        boxShadow: isFocused
            ? [BoxShadow(color: AppColors.accent.withValues(alpha: 0.06), blurRadius: 12)]
            : [],
      ),
      child: TextField(
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
  final VoidCallback onTap;
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
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
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
                    width: 22, height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(widget.bgColor),
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

class _SocialButton extends StatefulWidget {
  final String label;
  final Widget icon;
  final Color bg;
  final Color border;
  final Color textColor;

  const _SocialButton({
    required this.label,
    required this.icon,
    required this.bg,
    required this.border,
    required this.textColor,
  });

  @override
  State<_SocialButton> createState() => _SocialButtonState();
}

class _SocialButtonState extends State<_SocialButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
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
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(width: 20, height: 20, child: CustomPaint(painter: _GooglePainter()));
  }
}

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -0.1, 1.7, true, paint);
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), 1.6, 1.6, true, paint);
    paint.color = const Color(0xFFFBBC04);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), 3.2, 0.8, true, paint);
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), 4.0, 1.3, true, paint);
    // White center cutout
    paint.color = Colors.white;
    canvas.drawCircle(center, radius * 0.55, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FacebookIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: const BoxDecoration(color: Color(0xFF1877F2), shape: BoxShape.circle),
      child: const Center(
        child: Text('f',
            style: TextStyle(
                color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, height: 1.2)),
      ),
    );
  }
}
