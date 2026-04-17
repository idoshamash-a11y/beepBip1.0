import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import 'chat_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<_Conversation> _conversations = [
    _Conversation(userId: '1', name: 'Rivera M.', lastMessage: 'Want to grab a coffee? ☕', time: '10:34 AM', avatar: 'https://picsum.photos/seed/Rivera/150/150', unread: 2, isOnline: true),
    _Conversation(userId: '2', name: 'Sasha K.', lastMessage: 'I saw your post about the event!', time: 'Yesterday', avatar: 'https://picsum.photos/seed/Sasha/150/150', unread: 0, isOnline: true),
    _Conversation(userId: '3', name: 'Zara P.', lastMessage: 'Thanks for connecting!', time: 'Mon', avatar: 'https://picsum.photos/seed/Zara/150/150', unread: 0, isOnline: false),
    _Conversation(userId: '4', name: 'Dani T.', lastMessage: 'Are you coming to the meetup?', time: 'Sun', avatar: 'https://picsum.photos/seed/Dani/150/150', unread: 1, isOnline: false),
    _Conversation(userId: '5', name: 'Arlo V.', lastMessage: 'Great seeing you nearby!', time: 'Sat', avatar: 'https://picsum.photos/seed/Arlo/150/150', unread: 0, isOnline: true),
  ];

  List<_Conversation> get _filtered {
    if (_searchQuery.isEmpty) return _conversations;
    return _conversations.where((c) =>
        c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        c.lastMessage.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            // App bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  Text('Messages',
                      style: GoogleFonts.outfit(
                          color: c.textPrimary, fontSize: 22, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  _BarBtn(icon: Icons.person_search_rounded, color: AppColors.accent,
                      onTap: () => Navigator.of(context).pushNamed('/contacts')),
                  const SizedBox(width: 6),
                  _BarBtn(icon: Icons.edit_square, color: c.textSecondary,
                      onTap: () => Navigator.of(context).pushNamed('/post/create')),
                ],
              ),
            ),

            // Search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: c.inputBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: c.border),
                ),
                child: TextField(
                  controller: _searchController,
                  style: GoogleFonts.outfit(color: c.textPrimary),
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search conversations...',
                    hintStyle: GoogleFonts.outfit(color: c.textSecondary),
                    prefixIcon: Icon(Icons.search, color: c.textSecondary),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Online strip
            SizedBox(
              height: 78,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: _conversations
                    .where((cv) => cv.isOnline)
                    .map((cv) => _OnlineAvatar(conv: cv, c: c, onTap: () => _openChat(cv)))
                    .toList(),
              ),
            ),

            Divider(color: c.divider, height: 1),

            // Conversations
            Expanded(
              child: _filtered.isEmpty
                  ? _EmptyState(c: c, onDiscover: () => Navigator.of(context).pushNamed('/contacts'))
                  : ListView.separated(
                      itemCount: _filtered.length,
                      separatorBuilder: (_, __) => Divider(color: c.divider, height: 1, indent: 80),
                      itemBuilder: (context, i) => _ConversationTile(
                        conv: _filtered[i], c: c,
                        onTap: () => _openChat(_filtered[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _openChat(_Conversation cv) {
    setState(() => cv.unread = 0);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ChatScreen(userId: cv.userId, userName: cv.name, userAvatar: cv.avatar),
    ));
  }
}

class _BarBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _BarBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: context.colors.border),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}

class _OnlineAvatar extends StatelessWidget {
  final _Conversation conv;
  final AppColors c;
  final VoidCallback onTap;
  const _OnlineAvatar({required this.conv, required this.c, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: c.border)),
                  child: ClipOval(
                    child: Image.network(
                      conv.avatar,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: c.surface2,
                        child: Center(
                          child: Text(conv.name[0],
                              style: GoogleFonts.outfit(color: AppColors.accent, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 1, right: 1,
                  child: Container(
                    width: 11, height: 11,
                    decoration: BoxDecoration(
                      color: AppColors.success, shape: BoxShape.circle,
                      border: Border.all(color: c.bg, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(conv.name.split(' ')[0],
                style: GoogleFonts.outfit(color: c.textSecondary, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final _Conversation conv;
  final AppColors c;
  final VoidCallback onTap;
  const _ConversationTile({required this.conv, required this.c, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: c.border)),
                  child: ClipOval(
                    child: Image.network(
                      conv.avatar, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: c.surface2,
                        child: Center(
                          child: Text(conv.name[0],
                              style: GoogleFonts.outfit(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 18)),
                        ),
                      ),
                    ),
                  ),
                ),
                if (conv.isOnline)
                  Positioned(
                    bottom: 1, right: 1,
                    child: Container(
                      width: 12, height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.success, shape: BoxShape.circle,
                        border: Border.all(color: c.bg, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(conv.name,
                          style: GoogleFonts.outfit(
                              color: c.textPrimary,
                              fontWeight: conv.unread > 0 ? FontWeight.w700 : FontWeight.w500,
                              fontSize: 15)),
                      Text(conv.time,
                          style: GoogleFonts.outfit(
                              color: conv.unread > 0 ? AppColors.accent : c.textSecondary,
                              fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(conv.lastMessage,
                            style: GoogleFonts.outfit(
                                color: conv.unread > 0 ? c.textPrimary : c.textSecondary,
                                fontSize: 13,
                                fontWeight: conv.unread > 0 ? FontWeight.w500 : FontWeight.normal),
                            overflow: TextOverflow.ellipsis),
                      ),
                      if (conv.unread > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 20, height: 20,
                          decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                          child: Center(
                            child: Text('${conv.unread}',
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final AppColors c;
  final VoidCallback onDiscover;
  const _EmptyState({required this.c, required this.onDiscover});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_bubble_outline_rounded, color: c.textSecondary, size: 48),
          const SizedBox(height: 12),
          Text('No conversations yet',
              style: GoogleFonts.outfit(color: c.textSecondary, fontSize: 16)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onDiscover,
            child: Text('Discover people nearby',
                style: GoogleFonts.outfit(
                    color: AppColors.accent, fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _Conversation {
  final String userId, name, lastMessage, time, avatar;
  int unread;
  final bool isOnline;
  _Conversation({
    required this.userId, required this.name, required this.lastMessage,
    required this.time, required this.avatar, required this.unread, required this.isOnline,
  });
}
