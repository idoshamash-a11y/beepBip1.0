import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/services/image_upload_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/providers/auth_provider.dart';

/// Pick + upload a single image (logo, cover, etc.) and surface the resulting
/// URL via [onChanged]. The widget renders the current image (if any), an
/// upload spinner mid-flight, and a "tap to change" affordance.
///
/// Two visual modes:
///   * [SingleImagePicker.cover] — wide 16:9 banner (used for `cover_url`).
///   * [SingleImagePicker.logo]  — square avatar (used for `logo_url`).
class SingleImagePicker extends ConsumerStatefulWidget {
  const SingleImagePicker._({
    required this.url,
    required this.onChanged,
    required this.feature,
    required this.height,
    required this.borderRadius,
    required this.aspectRatio,
    required this.placeholderIcon,
    required this.placeholderLabel,
  });

  /// Banner-style cover image.
  factory SingleImagePicker.cover({
    required String? url,
    required ValueChanged<String> onChanged,
    Key? key,
  }) {
    return SingleImagePicker._(
      url: url,
      onChanged: onChanged,
      feature: ImageUploadFeature.businessCovers,
      height: 160,
      borderRadius: 16,
      aspectRatio: null,
      placeholderIcon: Icons.image_outlined,
      placeholderLabel: 'Add a cover image',
    );
  }

  /// Square logo.
  factory SingleImagePicker.logo({
    required String? url,
    required ValueChanged<String> onChanged,
    Key? key,
  }) {
    return SingleImagePicker._(
      url: url,
      onChanged: onChanged,
      feature: ImageUploadFeature.businessLogos,
      height: 96,
      borderRadius: 14,
      aspectRatio: 1,
      placeholderIcon: Icons.business_rounded,
      placeholderLabel: 'Add logo',
    );
  }

  final String? url;
  final ValueChanged<String> onChanged;
  final ImageUploadFeature feature;
  final double height;
  final double borderRadius;
  final double? aspectRatio;
  final IconData placeholderIcon;
  final String placeholderLabel;

  @override
  ConsumerState<SingleImagePicker> createState() =>
      _SingleImagePickerState();
}

class _SingleImagePickerState extends ConsumerState<SingleImagePicker> {
  bool _uploading = false;

  Future<void> _pick() async {
    if (_uploading) return;

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

    setState(() => _uploading = true);
    try {
      final bytes = await picked.readAsBytes();
      final url = await ref.read(imageUploadServiceProvider).uploadUserImage(
            userId: user.id,
            serialId: me.serialId,
            feature: widget.feature,
            bytes: bytes,
          );
      if (!mounted) return;
      widget.onChanged(url);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not upload image: $e')),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final hasImage = widget.url != null && widget.url!.isNotEmpty;

    final inner = Stack(
      fit: StackFit.expand,
      children: [
        if (hasImage)
          ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: CachedNetworkImage(
              imageUrl: widget.url!,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: c.surface2),
              errorWidget: (_, __, ___) => Container(
                color: c.surface2,
                alignment: Alignment.center,
                child: Icon(Icons.broken_image_outlined, color: c.textMuted),
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: c.inputBg,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: Border.all(color: c.border),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.placeholderIcon,
                  color: c.textSecondary,
                  size: 28,
                ),
                const SizedBox(height: 6),
                Text(
                  widget.placeholderLabel,
                  style: GoogleFonts.outfit(
                    color: c.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        if (_uploading)
          Container(
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(widget.borderRadius),
            ),
            alignment: Alignment.center,
            child: const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
        if (hasImage && !_uploading)
          Positioned(
            bottom: 8,
            right: 8,
            child: GestureDetector(
              onTap: _pick,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.camera_alt_outlined,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Change',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );

    final framed = SizedBox(
      height: widget.height,
      child: widget.aspectRatio != null
          ? AspectRatio(
              aspectRatio: widget.aspectRatio!,
              child: inner,
            )
          : inner,
    );

    return GestureDetector(
      onTap: hasImage ? null : _pick,
      child: framed,
    );
  }
}
