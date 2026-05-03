import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/services/image_upload_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/providers/auth_provider.dart';

/// A grid of image tiles with an inline "add" button. Used by the business
/// page editor to manage logo + cover + curated gallery items.
///
/// The editor is a pure presentational widget — it doesn't own the URL list
/// itself. The parent passes [urls] in and listens to [onChanged] to persist
/// changes. The widget calls [ImageUploadService.uploadUserImage] internally
/// (with the user's serial id as watermark) so callers don't have to wire
/// the picker boilerplate themselves.
///
/// Failure handling: a single failed upload is shown as a snackbar; the rest
/// of the existing list is left untouched so the user can retry.
class ImageGridEditor extends ConsumerStatefulWidget {
  const ImageGridEditor({
    required this.urls,
    required this.onChanged,
    required this.feature,
    this.maxImages = 10,
    super.key,
  });

  /// Current list of image URLs (already in storage).
  final List<String> urls;

  /// Called whenever the list changes (after an add or a remove). The new
  /// list is a fresh instance — the parent can `setState` and persist on
  /// save.
  final ValueChanged<List<String>> onChanged;

  /// Where to upload picked images. See [ImageUploadFeature] for the
  /// available segments under the user's storage folder.
  final ImageUploadFeature feature;

  /// Hard cap on how many images the user can attach. The "+" tile hides
  /// once we hit this.
  final int maxImages;

  @override
  ConsumerState<ImageGridEditor> createState() => _ImageGridEditorState();
}

class _ImageGridEditorState extends ConsumerState<ImageGridEditor> {
  /// Number of uploads currently in flight; used to render placeholders and
  /// gate the "Add" button.
  int _uploadsInFlight = 0;

  Future<void> _pickAndAdd() async {
    if (widget.urls.length + _uploadsInFlight >= widget.maxImages) return;

    final user = ref.read(authStateProvider).asData?.value;
    final me = ref.read(currentUserProfileProvider).asData?.value;
    if (user == null || me == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Your session is still loading. Try again in a moment.'),
        ),
      );
      return;
    }

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 4096,
      maxHeight: 4096,
      imageQuality: 95,
    );
    if (picked == null) return;

    setState(() => _uploadsInFlight++);
    try {
      final bytes = await picked.readAsBytes();
      final url = await ref.read(imageUploadServiceProvider).uploadUserImage(
            userId: user.id,
            serialId: me.serialId,
            feature: widget.feature,
            bytes: bytes,
          );
      if (!mounted) return;
      widget.onChanged([...widget.urls, url]);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not upload image: $e')),
      );
    } finally {
      if (mounted) setState(() => _uploadsInFlight--);
    }
  }

  void _removeAt(int index) {
    final next = [...widget.urls]..removeAt(index);
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final canAddMore =
        widget.urls.length + _uploadsInFlight < widget.maxImages;
    final tileCount = widget.urls.length +
        _uploadsInFlight +
        (canAddMore ? 1 : 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: tileCount,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            if (index < widget.urls.length) {
              return _ImageTile(
                url: widget.urls[index],
                onRemove: () => _removeAt(index),
              );
            }
            if (index < widget.urls.length + _uploadsInFlight) {
              return const _UploadingTile();
            }
            return _AddTile(onTap: _pickAndAdd);
          },
        ),
        const SizedBox(height: 6),
        Text(
          '${widget.urls.length}/${widget.maxImages} photos',
          style: GoogleFonts.outfit(
            color: c.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _ImageTile extends StatelessWidget {
  const _ImageTile({required this.url, required this.onRemove});

  final String url;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(color: c.surface2),
            errorWidget: (_, __, ___) => Container(
              color: c.surface2,
              alignment: Alignment.center,
              child: Icon(Icons.broken_image_outlined, color: c.textMuted),
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }
}

class _UploadingTile extends StatelessWidget {
  const _UploadingTile();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.inputBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      alignment: Alignment.center,
      child: const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
        ),
      ),
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: c.inputBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.border),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.add_photo_alternate_outlined,
              color: AppColors.accent,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              'Add',
              style: GoogleFonts.outfit(
                color: AppColors.accent,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
