import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
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

  void _openPostCreation() {
    _fabController.forward().then((_) => _fabController.reverse());
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
        onPostTap: _openPostCreation,
        fabScale: _fabScale,
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
