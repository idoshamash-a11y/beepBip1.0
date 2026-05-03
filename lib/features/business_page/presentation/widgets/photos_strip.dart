import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';

/// Horizontal strip of photos auto-aggregated from the business's listing
/// images. Tapping a photo opens a full-screen carousel.
///
/// We keep it small (≤ 6 visible at a time) so the page doesn't turn into an
/// Instagram grid; if the owner wants more curation later we can promote
/// this into a dedicated `business_media` table.
class PhotosStrip extends StatelessWidget {
  const PhotosStrip({required this.urls, super.key});

  final List<String> urls;

  static const int _maxVisible = 6;

  @override
  Widget build(BuildContext context) {
    if (urls.isEmpty) return const SizedBox.shrink();
    final c = context.colors;
    final visible =
        urls.length <= _maxVisible ? urls : urls.take(_maxVisible).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Photos',
                style: GoogleFonts.outfit(
                  color: c.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (urls.length > _maxVisible)
                GestureDetector(
                  onTap: () => _openGallery(context, urls, 0),
                  child: Text(
                    'View all (${urls.length})',
                    style: GoogleFonts.outfit(
                      color: AppColors.accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: visible.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                return GestureDetector(
                  onTap: () => _openGallery(context, urls, i),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: visible[i],
                      width: 96,
                      height: 96,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: c.surface2,
                        width: 96,
                        height: 96,
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: c.surface2,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: c.textMuted,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openGallery(BuildContext context, List<String> all, int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _PhotoCarousel(urls: all, initialIndex: index),
      ),
    );
  }
}

/// Lightweight full-screen carousel — pinch to zoom (via InteractiveViewer)
/// and swipe to navigate.
class _PhotoCarousel extends StatelessWidget {
  const _PhotoCarousel({required this.urls, required this.initialIndex});

  final List<String> urls;
  final int initialIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: PageView.builder(
        controller: PageController(initialPage: initialIndex),
        itemCount: urls.length,
        itemBuilder: (context, i) {
          return InteractiveViewer(
            minScale: 1,
            maxScale: 4,
            child: Center(
              child: CachedNetworkImage(
                imageUrl: urls[i],
                fit: BoxFit.contain,
              ),
            ),
          );
        },
      ),
    );
  }
}
