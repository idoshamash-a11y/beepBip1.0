import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

class ChatScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String? userAvatar;

  const ChatScreen({super.key, required this.userId, required this.userName, this.userAvatar});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocus = FocusNode();

  final List<_Message> _messages = [
    _Message(text: 'Hey! Are you nearby?', isMine: false, time: '10:32 AM', status: _MsgStatus.read),
    _Message(text: "Yeah, I'm about 500m from your location!", isMine: true, time: '10:33 AM', status: _MsgStatus.read),
    _Message(text: 'Nice! Want to grab a coffee? ☕', isMine: false, time: '10:34 AM', status: _MsgStatus.read),
    _Message(text: 'Sounds great, which place?', isMine: true, time: '10:35 AM', status: _MsgStatus.delivered),
  ];

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_Message(text: text, isMine: true, time: _formatNow(), status: _MsgStatus.sent));
    });
    _messageController.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatNow() {
    final now = DateTime.now();
    final h = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final m = now.minute.toString().padLeft(2, '0');
    return '$h:$m ${now.hour < 12 ? 'AM' : 'PM'}';
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: c.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: c.border)),
                  child: ClipOval(
                    child: widget.userAvatar != null
                        ? Image.network(widget.userAvatar!, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _InitialAvatar(name: widget.userName, c: c))
                        : _InitialAvatar(name: widget.userName, c: c),
                  ),
                ),
                Positioned(
                  bottom: 0, right: 0,
                  child: Container(
                    width: 10, height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.success, shape: BoxShape.circle,
                      border: Border.all(color: c.surface, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.userName,
                    style: GoogleFonts.outfit(
                        color: c.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                Text('Active now',
                    style: GoogleFonts.outfit(color: AppColors.success, fontSize: 11)),
              ],
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: c.border),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.location_on_outlined, color: AppColors.accent),
            onPressed: () {},
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: c.textPrimary),
            color: c.surface,
            onSelected: (value) {
              if (value == 'block') _showDialog('Block', 'block ${widget.userName}?', 'Block', Colors.red, c);
              if (value == 'report') _showReportSheet(c);
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(value: 'block', child: Row(children: [
                const Icon(Icons.block, color: Colors.redAccent, size: 18),
                const SizedBox(width: 8),
                Text('Block User', style: GoogleFonts.outfit(color: c.textPrimary)),
              ])),
              PopupMenuItem(value: 'report', child: Row(children: [
                Icon(Icons.flag_outlined, color: AppColors.accent, size: 18),
                const SizedBox(width: 8),
                Text('Report', style: GoogleFonts.outfit(color: c.textPrimary)),
              ])),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return Column(
                  children: [
                    if (index == 0) _DateDivider(label: 'Today', c: c),
                    _Bubble(msg: msg, c: c),
                  ],
                );
              },
            ),
          ),
          // Input bar
          Container(
            color: c.surface,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(height: 1, color: c.border),
                Padding(
                  padding: EdgeInsets.only(
                    left: 12, right: 12,
                    top: 10,
                    bottom: MediaQuery.of(context).padding.bottom + 10,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.attach_file_rounded, color: c.textSecondary),
                        onPressed: () {},
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      ),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: c.inputBg,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: c.border),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: TextField(
                            controller: _messageController,
                            focusNode: _inputFocus,
                            style: GoogleFonts.outfit(color: c.textPrimary),
                            decoration: InputDecoration(
                              hintText: 'Message...',
                              hintStyle: GoogleFonts.outfit(color: c.textSecondary),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 11),
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _sendMessage,
                        child: Container(
                          width: 42, height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.accent, shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accent.withValues(alpha: 0.3),
                                blurRadius: 10, offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Icon(Icons.send_rounded, color: c.bg, size: 18),
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
    );
  }

  void _showDialog(String title, String body, String action, Color actionColor, AppColors c) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: GoogleFonts.outfit(color: c.textPrimary, fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to $body',
            style: GoogleFonts.outfit(color: c.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: GoogleFonts.outfit(color: c.textSecondary))),
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: Text(action, style: GoogleFonts.outfit(color: actionColor, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  void _showReportSheet(AppColors c) {
    showModalBottomSheet(
      context: context,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Report', style: GoogleFonts.outfit(color: c.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            for (final reason in ['Spam', 'Harassment', 'Inappropriate content', 'Fake profile'])
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.radio_button_unchecked, color: AppColors.accent, size: 20),
                title: Text(reason, style: GoogleFonts.outfit(color: c.textPrimary)),
                onTap: () => Navigator.pop(ctx),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _InitialAvatar extends StatelessWidget {
  final String name;
  final AppColors c;
  const _InitialAvatar({required this.name, required this.c});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: c.surface2,
      child: Center(
        child: Text(name[0].toUpperCase(),
            style: GoogleFonts.outfit(color: AppColors.accent, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _DateDivider extends StatelessWidget {
  final String label;
  final AppColors c;
  const _DateDivider({required this.label, required this.c});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(child: Divider(color: c.border)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(label, style: GoogleFonts.outfit(color: c.textSecondary, fontSize: 12)),
          ),
          Expanded(child: Divider(color: c.border)),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final _Message msg;
  final AppColors c;
  const _Bubble({required this.msg, required this.c});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: msg.isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: msg.isMine ? AppColors.accent : c.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(msg.isMine ? 18 : 4),
            bottomRight: Radius.circular(msg.isMine ? 4 : 18),
          ),
          border: msg.isMine ? null : Border.all(color: c.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(msg.text,
                style: GoogleFonts.outfit(
                    color: msg.isMine ? const Color(0xFF0D0D0D) : c.textPrimary, fontSize: 15)),
            const SizedBox(height: 3),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(msg.time,
                    style: GoogleFonts.outfit(
                        color: msg.isMine ? const Color(0x990D0D0D) : c.textSecondary, fontSize: 11)),
                if (msg.isMine) ...[
                  const SizedBox(width: 3),
                  Icon(_statusIcon(msg.status), size: 13, color: _statusColor(msg.status)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _statusIcon(_MsgStatus s) {
    switch (s) {
      case _MsgStatus.sent: return Icons.check;
      case _MsgStatus.delivered: return Icons.done_all;
      case _MsgStatus.read: return Icons.done_all;
    }
  }

  Color _statusColor(_MsgStatus s) {
    if (s == _MsgStatus.read) return Colors.blue;
    return const Color(0x990D0D0D);
  }
}

class _Message {
  final String text, time;
  final bool isMine;
  final _MsgStatus status;
  const _Message({required this.text, required this.isMine, required this.time, required this.status});
}

enum _MsgStatus { sent, delivered, read }
