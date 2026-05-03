import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../posts/models/post_model.dart';

/// "Updates" — the business's recent posts. Designed to be compact (3 cards
/// visible by default with a "see all" affordance later) so the page stays
/// scannable.
class BusinessUpdatesSection extends StatelessWidget {
  const BusinessUpdatesSection({required this.posts, super.key});

  final List<Post> posts;

  static const int _previewCount = 3;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final visible = posts.where((p) => !p.isExpired).take(_previewCount).toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Updates',
            style: GoogleFonts.outfit(
              color: c.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          for (final p in visible) ...[
            _PostCard(post: p),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final firstImage = post.images.isNotEmpty ? post.images.first : null;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (firstImage != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: CachedNetworkImage(
                  imageUrl: firstImage,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: c.surface2),
                  errorWidget: (_, __, ___) => Container(color: c.surface2),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          Text(
            post.content,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              color: c.textPrimary,
              fontSize: 13.5,
              height: 1.5,
            ),
          ),
          if (post.hashtags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final t in post.hashtags)
                  Text(
                    '#$t',
                    style: GoogleFonts.outfit(
                      color: AppColors.accent,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 6),
          Text(
            _humanRemaining(post.timeRemaining),
            style: GoogleFonts.outfit(
              color: c.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  static String _humanRemaining(Duration d) {
    if (d.inMinutes <= 0) return 'Expired';
    if (d.inHours < 1) return 'Expires in ${d.inMinutes}m';
    if (d.inHours < 24) return 'Expires in ${d.inHours}h';
    return 'Expires in ${d.inDays}d';
  }
}
