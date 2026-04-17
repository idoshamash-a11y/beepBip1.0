import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/posts_provider.dart';

class PostCreationScreen extends ConsumerStatefulWidget {
  const PostCreationScreen({super.key});

  @override
  ConsumerState<PostCreationScreen> createState() => _PostCreationScreenState();
}

class _PostCreationScreenState extends ConsumerState<PostCreationScreen> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _hashtagController = TextEditingController();

  bool _locationEnabled = true;
  bool _isPublic = true;
  String _selectedCategory = 'General';
  final List<String> _hashtags = [];
  final List<String> _mediaFiles = [];
  bool _isPosting = false;

  final List<String> _categories = [
    'General', 'Food & Drink', 'Events', 'Services',
    'Lost & Found', 'For Sale', 'Help Needed',
  ];

  void _addHashtag() {
    final tag = _hashtagController.text.trim().replaceAll('#', '');
    if (tag.isNotEmpty && !_hashtags.contains(tag)) {
      setState(() { _hashtags.add(tag); _hashtagController.clear(); });
    }
  }

  Future<void> _submitPost() async {
    if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please write something for your post',
              style: GoogleFonts.outfit()),
          backgroundColor: context.colors.surface,
        ),
      );
      return;
    }

    setState(() => _isPosting = true);
    await Future.delayed(const Duration(milliseconds: 500));

    ref.read(postsProvider.notifier).addPost(
      text: _textController.text.trim(),
      hashtags: List.from(_hashtags),
      category: _selectedCategory,
      isPublic: _isPublic,
      hasLocation: _locationEnabled,
    );

    if (mounted) {
      setState(() => _isPosting = false);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Post shared nearby!', style: GoogleFonts.outfit(color: Colors.white)),
          backgroundColor: AppColors.accent,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _hashtagController.dispose();
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
          icon: Icon(Icons.close, color: c.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Create Post',
            style: GoogleFonts.outfit(
                color: c.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: c.border),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _PostButton(isPosting: _isPosting, onTap: _submitPost, bgColor: c.bg),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author row
            Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: c.surface2, shape: BoxShape.circle),
                  child: const Icon(Icons.person_rounded, color: AppColors.accent, size: 24),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('You',
                        style: GoogleFonts.outfit(
                            color: c.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
                    GestureDetector(
                      onTap: () => setState(() => _isPublic = !_isPublic),
                      child: Row(
                        children: [
                          Icon(
                            _isPublic ? Icons.public : Icons.lock_outline,
                            color: AppColors.accent, size: 13,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            _isPublic ? 'Public' : 'Private',
                            style: GoogleFonts.outfit(
                                color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Text input
            TextField(
              controller: _textController,
              style: GoogleFonts.outfit(color: c.textPrimary, fontSize: 16),
              maxLines: 6,
              minLines: 3,
              decoration: InputDecoration(
                hintText: "What's happening nearby?",
                hintStyle: GoogleFonts.outfit(color: c.textSecondary, fontSize: 16),
                border: InputBorder.none,
              ),
            ),

            // Media previews
            if (_mediaFiles.isNotEmpty) ...[
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _mediaFiles.length,
                  itemBuilder: (context, index) => Stack(
                    children: [
                      Container(
                        width: 100, height: 100,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: c.surface2,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.image, color: c.textSecondary, size: 40),
                      ),
                      Positioned(
                        top: 4, right: 12,
                        child: GestureDetector(
                          onTap: () => setState(() => _mediaFiles.removeAt(index)),
                          child: Container(
                            width: 20, height: 20,
                            decoration: const BoxDecoration(color: Colors.black87, shape: BoxShape.circle),
                            child: const Icon(Icons.close, color: Colors.white, size: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            Divider(color: c.border),
            const SizedBox(height: 12),

            // Hashtag input
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: c.inputBg, borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: TextField(
                      controller: _hashtagController,
                      style: GoogleFonts.outfit(color: c.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Add hashtag...',
                        hintStyle: GoogleFonts.outfit(color: c.textSecondary),
                        border: InputBorder.none,
                        prefixText: '# ',
                        prefixStyle: const TextStyle(color: AppColors.accent),
                      ),
                      onSubmitted: (_) => _addHashtag(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _addHashtag,
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.accent, borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.add, color: c.bg),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (_hashtags.isNotEmpty)
              Wrap(
                spacing: 8, runSpacing: 6,
                children: _hashtags.map((tag) => Chip(
                  label: Text('#$tag',
                      style: GoogleFonts.outfit(color: AppColors.accent, fontSize: 13)),
                  backgroundColor: c.surface2,
                  side: const BorderSide(color: AppColors.accent),
                  deleteIcon: Icon(Icons.close, size: 16, color: c.textSecondary),
                  onDeleted: () => setState(() => _hashtags.remove(tag)),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                )).toList(),
              ),

            const SizedBox(height: 16),

            Text('Category',
                style: GoogleFonts.outfit(
                    color: c.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final selected = _selectedCategory == cat;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.accent : c.surface2,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected ? AppColors.accent : c.border,
                        ),
                      ),
                      child: Text(
                        cat,
                        style: GoogleFonts.outfit(
                          color: selected ? c.bg : c.textSecondary,
                          fontSize: 13,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            Divider(color: c.border),
            const SizedBox(height: 12),

            // Location toggle
            Row(
              children: [
                Icon(Icons.location_on_outlined, color: AppColors.accent, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Attach Location',
                      style: GoogleFonts.outfit(color: c.textSecondary, fontSize: 14)),
                ),
                Switch(
                  value: _locationEnabled,
                  onChanged: (v) => setState(() => _locationEnabled = v),
                  activeColor: AppColors.accent,
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Media actions
            Row(
              children: [
                _MediaAction(icon: Icons.photo_library_outlined, label: 'Photo',
                    color: c.textSecondary,
                    onTap: () => setState(() => _mediaFiles.add('photo'))),
                const SizedBox(width: 20),
                _MediaAction(icon: Icons.videocam_outlined, label: 'Video',
                    color: c.textSecondary, onTap: () {}),
                const SizedBox(width: 20),
                _MediaAction(icon: Icons.attach_money, label: 'Payment',
                    color: c.textSecondary, onTap: () {}),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _PostButton extends StatefulWidget {
  final bool isPosting;
  final VoidCallback onTap;
  final Color bgColor;
  const _PostButton({required this.isPosting, required this.onTap, required this.bgColor});

  @override
  State<_PostButton> createState() => _PostButtonState();
}

class _PostButtonState extends State<_PostButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: widget.isPosting
              ? SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(widget.bgColor),
                  ),
                )
              : Text('Post',
                  style: GoogleFonts.outfit(
                      color: widget.bgColor, fontWeight: FontWeight.w700, fontSize: 14)),
        ),
      ),
    );
  }
}

class _MediaAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _MediaAction({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 4),
          Text(label, style: GoogleFonts.outfit(color: color, fontSize: 13)),
        ],
      ),
    );
  }
}
