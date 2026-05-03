import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../listings/providers/listings_providers.dart';
import '../../map/screens/map_screen.dart';
import '../../messages/screens/messages_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../search/screens/search_screen.dart';
import '../../posts/screens/post_creation_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _fabController;
  late Animation<double> _fabScale;

  final List<Widget> _pages = const [
    MapScreen(),
    MessagesScreen(),
    SearchScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 160));
    _fabScale = Tween<double>(begin: 1.0, end: 0.88)
        .animate(CurvedAnimation(parent: _fabController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  /// Tapping the center "+" used to open the post composer directly. Now it
  /// opens a Compose menu that lets the user pick **post** or **listing**.
  /// Listing creation is gated to users with a business profile (per MVP §3.4
  /// "Businesses only in V1"); the option is hidden for personal-only users
  /// rather than greyed-out, to avoid teasing UI they can't act on.
  void _openComposeMenu() {
    _fabController.forward().then((_) => _fabController.reverse());
    final canAuthorListing = ref.read(canAuthorListingsProvider);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => _ComposeSheet(
        canAuthorListing: canAuthorListing,
        onShareUpdate: () {
          Navigator.of(sheetCtx).pop();
          _openPostCreator();
        },
        onAddListing: () {
          Navigator.of(sheetCtx).pop();
          context.push('/listings/new');
        },
      ),
    );
  }

  void _openPostCreator() {
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (_, animation, __) => const PostCreationScreen(),
      transitionsBuilder: (_, animation, __, child) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
            .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
        child: child,
      ),
      transitionDuration: const Duration(milliseconds: 340),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.bg,
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: _BottomBar(
        selectedIndex: _selectedIndex,
        onTabChanged: (i) => setState(() => _selectedIndex = i),
        onPostTap: _openComposeMenu,
        fabScale: _fabScale,
      ),
    );
  }
}

/// Bottom sheet shown when the user taps the center "+". Two symmetric
/// authoring entry points:
///   - Share an update (post)  — everyone
///   - Add a listing            — business profile owners only
class _ComposeSheet extends StatelessWidget {
  final bool canAuthorListing;
  final VoidCallback onShareUpdate;
  final VoidCallback onAddListing;

  const _ComposeSheet({
    required this.canAuthorListing,
    required this.onShareUpdate,
    required this.onAddListing,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return SafeArea(
      top: false,
      child: Container(
        margin: EdgeInsets.fromLTRB(12, 0, 12, bottomPad + 12),
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 6, bottom: 14),
              decoration: BoxDecoration(
                color: c.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _ComposeOption(
              icon: Icons.bolt_rounded,
              title: 'Share an update',
              subtitle: 'Tell SoHo what\'s happening — auto-expires in 72h.',
              onTap: onShareUpdate,
            ),
            if (canAuthorListing) ...[
              const SizedBox(height: 8),
              _ComposeOption(
                icon: Icons.storefront_rounded,
                title: 'Add a listing',
                subtitle: 'Sell a service, item, or event.',
                onTap: onAddListing,
              ),
            ],
            const SizedBox(height: 6),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.outfit(
                  color: c.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComposeOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ComposeOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c.border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        color: c.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.outfit(
                        color: c.textSecondary,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_rounded,
                color: AppColors.accent,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabChanged;
  final VoidCallback onPostTap;
  final Animation<double> fabScale;

  const _BottomBar({
    required this.selectedIndex,
    required this.onTabChanged,
    required this.onPostTap,
    required this.fabScale,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      color: c.navBg,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(height: 1, color: c.navBorder),
          Padding(
            padding: EdgeInsets.only(top: 10, bottom: bottomPad + 10, left: 8, right: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(icon: Icons.explore_rounded, index: 0, selectedIndex: selectedIndex, onTap: onTabChanged),
                _NavItem(icon: Icons.chat_bubble_rounded, index: 1, selectedIndex: selectedIndex, onTap: onTabChanged),
                // Center post FAB
                ScaleTransition(
                  scale: fabScale,
                  child: GestureDetector(
                    onTap: onPostTap,
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(Icons.add_rounded, color: c.bg, size: 28),
                    ),
                  ),
                ),
                _NavItem(icon: Icons.search_rounded, index: 2, selectedIndex: selectedIndex, onTap: onTabChanged),
                _NavItem(icon: Icons.person_rounded, index: 3, selectedIndex: selectedIndex, onTap: onTabChanged),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final IconData icon;
  final int index;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.icon,
    required this.index,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.88)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.selectedIndex == widget.index;
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) { _controller.reverse(); widget.onTap(widget.index); },
      onTapCancel: () => _controller.reverse(),
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accent.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Icon(
              widget.icon,
              color: isSelected ? AppColors.accent : context.colors.textSecondary,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
