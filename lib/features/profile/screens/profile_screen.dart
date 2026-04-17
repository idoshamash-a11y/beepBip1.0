import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/theme_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeIn,
          child: CustomScrollView(
            slivers: [
              // App bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Profile',
                          style: GoogleFonts.outfit(
                              color: c.textPrimary, fontSize: 22, fontWeight: FontWeight.w700)),
                      Row(
                        children: [
                          _IconBtn(icon: Icons.share_outlined, color: c, onTap: () {}),
                          const SizedBox(width: 6),
                          // Theme toggle
                          GestureDetector(
                            onTap: () => ref.read(themeModeProvider.notifier).toggle(),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              width: 38, height: 38,
                              decoration: BoxDecoration(
                                color: c.surface,
                                borderRadius: BorderRadius.circular(11),
                                border: Border.all(color: c.border),
                              ),
                              child: Center(
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: Icon(
                                    isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                                    key: ValueKey(isDark),
                                    color: isDark ? const Color(0xFFFFD54F) : c.textSecondary,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          _IconBtn(icon: Icons.settings_outlined, color: c, onTap: () {}),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Avatar + name
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 100, height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.accent, width: 2.5),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.accent.withValues(alpha: 0.15),
                                  blurRadius: 20, spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.network(
                                'https://picsum.photos/seed/profile11/300/300',
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: c.surface2,
                                  child: const Icon(Icons.person_rounded, color: AppColors.accent, size: 48),
                                ),
                              ),
                            ),
                          ),
                          Container(
                            width: 28, height: 28,
                            decoration: BoxDecoration(
                              color: AppColors.accent, shape: BoxShape.circle,
                              border: Border.all(color: c.bg, width: 2),
                            ),
                            child: Icon(Icons.verified_rounded, color: c.bg, size: 15),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text('Alex Morgan',
                          style: GoogleFonts.outfit(
                              color: c.textPrimary, fontSize: 24,
                              fontWeight: FontWeight.w700, letterSpacing: -0.3)),
                      const SizedBox(height: 4),
                      Text('26 · New York City',
                          style: GoogleFonts.outfit(color: c.textSecondary, fontSize: 14)),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => setState(() => _isVisible = !_isVisible),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: _isVisible
                                ? AppColors.success.withValues(alpha: 0.1)
                                : c.surface2,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _isVisible
                                  ? AppColors.success.withValues(alpha: 0.4)
                                  : c.border,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6, height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _isVisible ? AppColors.success : c.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _isVisible ? 'Visible to nearby' : 'Hidden',
                                style: GoogleFonts.outfit(
                                  color: _isVisible ? AppColors.success : c.textSecondary,
                                  fontSize: 12, fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: _ActionButton(
                              label: 'Edit Profile', icon: Icons.edit_outlined,
                              primary: true, bgColor: c.bg, borderColor: c.border, onTap: () {},
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: _ActionButton(
                              label: 'Feedback', icon: Icons.feedback_outlined,
                              primary: false, bgColor: c.bg, borderColor: c.border,
                              onTap: () => Navigator.of(context).pushNamed('/feedback'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // Stats
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: c.border),
                    ),
                    child: Row(
                      children: [
                        _StatItem(value: '142', label: 'Connections', textPrimary: c.textPrimary, textSecondary: c.textSecondary),
                        _StatDivider(color: c.border),
                        _StatItem(value: '1.2k', label: 'Views', textPrimary: c.textPrimary, textSecondary: c.textSecondary),
                        _StatDivider(color: c.border),
                        _StatItem(value: '38', label: 'Matches', textPrimary: c.textPrimary, textSecondary: c.textSecondary),
                        _StatDivider(color: c.border),
                        _StatItem(value: '4.8', label: 'Rating', textPrimary: c.textPrimary, textSecondary: c.textSecondary),
                      ],
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 14)),

              // Profile completion
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: c.surface, borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: c.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Profile completion',
                                style: GoogleFonts.outfit(color: c.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text('85%',
                                  style: GoogleFonts.outfit(
                                      color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: 0.85, minHeight: 6,
                            backgroundColor: c.border,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 14)),

              // About
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _SectionCard(
                    title: 'About', icon: Icons.info_outline_rounded, c: c,
                    child: Text(
                      'Coffee enthusiast · Travel lover · Always up for new adventures. Looking to connect with like-minded people nearby.',
                      style: GoogleFonts.outfit(color: c.textSecondary, fontSize: 14, height: 1.6),
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 14)),

              // Interests
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _SectionCard(
                    title: 'Interests', icon: Icons.favorite_border_rounded, c: c,
                    child: Wrap(
                      spacing: 8, runSpacing: 8,
                      children: ['Coffee', 'Travel', 'Photography', 'Music', 'Tech', 'Fitness']
                          .map((tag) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: c.surface2,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: c.border),
                                ),
                                child: Text(tag,
                                    style: GoogleFonts.outfit(color: c.textSecondary, fontSize: 12)),
                              ))
                          .toList(),
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconBtn extends StatefulWidget {
  final IconData icon;
  final AppColors color;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.color, required this.onTap});

  @override
  State<_IconBtn> createState() => _IconBtnState();
}

class _IconBtnState extends State<_IconBtn> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: widget.color.surface,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: widget.color.border),
          ),
          child: Icon(widget.icon, color: widget.color.textSecondary, size: 18),
        ),
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool primary;
  final Color bgColor;
  final Color borderColor;
  final VoidCallback onTap;
  const _ActionButton({
    required this.label, required this.icon, required this.primary,
    required this.bgColor, required this.borderColor, required this.onTap,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          height: 46,
          decoration: BoxDecoration(
            color: widget.primary ? AppColors.accent : context.colors.surface,
            borderRadius: BorderRadius.circular(13),
            border: widget.primary ? null : Border.all(color: widget.borderColor),
            boxShadow: widget.primary
                ? [BoxShadow(color: AppColors.accent.withValues(alpha: 0.2), blurRadius: 14, offset: const Offset(0, 4))]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon,
                  color: widget.primary ? widget.bgColor : context.colors.textSecondary, size: 18),
              const SizedBox(width: 6),
              Text(widget.label,
                  style: GoogleFonts.outfit(
                    color: widget.primary ? widget.bgColor : context.colors.textSecondary,
                    fontSize: 13, fontWeight: FontWeight.w600,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value, label;
  final Color textPrimary, textSecondary;
  const _StatItem({required this.value, required this.label, required this.textPrimary, required this.textSecondary});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: GoogleFonts.outfit(color: textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text(label, style: GoogleFonts.outfit(color: textSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  final Color color;
  const _StatDivider({required this.color});
  @override
  Widget build(BuildContext context) => Container(width: 1, height: 36, color: color);
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final AppColors c;
  final Widget child;
  const _SectionCard({required this.title, required this.icon, required this.c, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.surface, borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.accent, size: 18),
              const SizedBox(width: 8),
              Text(title, style: GoogleFonts.outfit(color: c.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
