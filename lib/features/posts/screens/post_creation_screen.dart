import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/image_upload_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/serial_id_chip.dart';
import '../../auth/providers/auth_provider.dart';
import '../../listings/models/listing_model.dart';
import '../../listings/providers/listings_providers.dart';
import '../../profile/models/profile_enums.dart';
import '../../profile/models/profile_model.dart';
import '../models/post_model.dart';
import '../providers/posts_providers.dart';

/// Compose a real post against `public.posts`. Schema-aligned, no friction:
///
///   * Person verification happens upstream at signup/login (FOLLOWUPS §1.7.a).
///   * The act of posting is fast: type → tag → optionally link a listing →
///     post. The DB default `expires_at = NOW + 72h` is shown in the footer
///     so the auto-decay rule isn't a surprise.
///   * Banned hashtags fail-fast on the client (instant feedback) and again
///     on the server (defense in depth via the `enforce_banned_hashtags`
///     trigger).
///
/// Removed from the previous mock UI: `category` enum, `isPublic` toggle,
/// per-post location toggle. None of those exist in the schema; visibility
/// flows from the profile-level `location_sharing` setting (MVP §3.2).
class PostCreationScreen extends ConsumerStatefulWidget {
  const PostCreationScreen({super.key});

  @override
  ConsumerState<PostCreationScreen> createState() =>
      _PostCreationScreenState();
}

class _PostCreationScreenState extends ConsumerState<PostCreationScreen> {
  final _content = TextEditingController();
  final _hashtagInput = TextEditingController();
  final List<String> _hashtags = [];

  ProfileModel? _selectedAuthor;
  Listing? _linkedListing;
  PostVisibility _visibility = PostVisibility.public;

  /// Watermarked image URLs already uploaded for this draft.
  final List<String> _imageUrls = [];

  /// Number of uploads currently in flight; used to render placeholders and
  /// gate the post button.
  int _uploadsInFlight = 0;

  /// DB-enforced cap (`posts.images` constraint).
  static const int _maxImages = 4;

  @override
  void dispose() {
    _content.dispose();
    _hashtagInput.dispose();
    super.dispose();
  }

  // --- Hashtag editor -------------------------------------------------------

  void _addHashtagsFromInput() {
    final raw = _hashtagInput.text.trim();
    if (raw.isEmpty) return;
    final parts = raw
        .replaceAll('#', '')
        .split(RegExp(r'[,\s]+'))
        .map((s) => s.trim().toLowerCase())
        .where((s) => s.isNotEmpty);
    setState(() {
      for (final p in parts) {
        if (_hashtags.length >= 5) break;
        if (!_hashtags.contains(p)) _hashtags.add(p);
      }
      _hashtagInput.clear();
    });
  }

  void _removeHashtag(String t) {
    setState(() => _hashtags.remove(t));
  }

  // --- Image upload ---------------------------------------------------------

  Future<void> _addPhoto() async {
    if (_imageUrls.length + _uploadsInFlight >= _maxImages) {
      _showError('Up to $_maxImages photos per post.');
      return;
    }

    final user = ref.read(authStateProvider).asData?.value;
    final profile = ref.read(currentUserProfileProvider).asData?.value;
    if (user == null || profile == null) {
      _showError('Your session expired. Sign in again to upload photos.');
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
            serialId: profile.serialId,
            feature: ImageUploadFeature.posts,
            bytes: bytes,
          );
      if (!mounted) return;
      setState(() => _imageUrls.add(url));
    } catch (_) {
      if (!mounted) return;
      _showError('Could not upload photo. Try again.');
    } finally {
      if (mounted) setState(() => _uploadsInFlight--);
    }
  }

  void _removePhoto(String url) {
    setState(() => _imageUrls.remove(url));
  }

  // --- Submit ---------------------------------------------------------------

  Future<void> _submit() async {
    final author = _selectedAuthor ??
        (ref.read(currentUserProfilesProvider).asData?.value ?? const [])
            .firstOrNull;

    if (author == null) {
      _showError(
        "We couldn't find your profile. Try signing out and back in.",
      );
      return;
    }

    final content = _content.text.trim();
    if (content.isEmpty) {
      _showError('Write something before posting.');
      return;
    }
    if (content.length > 500) {
      _showError('Posts are limited to 500 characters.');
      return;
    }
    if (_uploadsInFlight > 0) {
      _showError('Please wait for image uploads to finish.');
      return;
    }

    final ok = await ref
        .read(postFormControllerProvider.notifier)
        .createPost(
          author: author,
          content: content,
          hashtags: List.unmodifiable(_hashtags),
          images: List.unmodifiable(_imageUrls),
          listingId: _linkedListing?.id,
          visibility: _visibility,
        );

    if (!mounted) return;
    if (ok) {
      final published = _visibility == PostVisibility.public;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            published
                ? 'Posted to SoHo. It will auto-expire in 72 hours.'
                : 'Saved as unlisted. Only people with the link can see it.',
            style: GoogleFonts.outfit(color: Colors.white),
          ),
          backgroundColor: AppColors.accent,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
      Navigator.of(context).pop();
    } else {
      _showError(
        ref.read(postFormControllerProvider).error ?? 'Could not post.',
      );
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // --- Author + listing pickers ---------------------------------------------

  Future<void> _pickAuthor(List<ProfileModel> profiles) async {
    if (profiles.length < 2) return; // nothing to pick from
    final picked = await showModalBottomSheet<ProfileModel>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ProfilePickerSheet(profiles: profiles),
    );
    if (picked != null) {
      setState(() {
        _selectedAuthor = picked;
        // If the new author has no listings (or only the old author had a
        // linked listing), clear the link so we don't post a personal-author
        // post pointing at someone else's listing.
        if (_linkedListing != null &&
            picked.profileType != ProfileType.business) {
          _linkedListing = null;
        }
      });
    }
  }

  Future<void> _pickListing(List<Listing> listings) async {
    if (listings.isEmpty) return;
    final picked = await showModalBottomSheet<Listing>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ListingPickerSheet(listings: listings),
    );
    if (picked != null) {
      setState(() => _linkedListing = picked);
    }
  }

  // --- Build ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final formState = ref.watch(postFormControllerProvider);
    final profilesAsync = ref.watch(currentUserProfilesProvider);
    // Pre-warm the banned-hashtag set so the moment the user submits we
    // already have it. Errors are non-fatal — server trigger is the backstop.
    ref.watch(bannedHashtagsProvider);

    final profiles = profilesAsync.asData?.value ?? const <ProfileModel>[];
    _selectedAuthor ??= profiles.firstOrNull;
    final author = _selectedAuthor;

    final myListingsAsync = ref.watch(myListingsProvider);
    final myListings = myListingsAsync.asData?.value ?? const <Listing>[];
    final canLinkListing =
        author?.profileType == ProfileType.business && myListings.isNotEmpty;

    final charCount = _content.text.characters.length;
    final tooLong = charCount > 500;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: c.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Share an update',
          style: GoogleFonts.outfit(
            color: c.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _PostButton(
              isPosting: formState.isSubmitting,
              enabled:
                  !formState.isSubmitting && !tooLong && _content.text.isNotEmpty,
              onTap: _submit,
              bgColor: c.bg,
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: c.border),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // "Posting as ..." row.
              if (author != null)
                _AuthorRow(
                  author: author,
                  serialId: ref
                      .watch(currentUserProfileProvider)
                      .asData
                      ?.value
                      ?.serialId,
                  switchable: profiles.length >= 2,
                  onTap: () => _pickAuthor(profiles),
                )
              else if (profilesAsync.isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(minHeight: 2),
                ),

              const SizedBox(height: 12),

              _VisibilityPicker(
                value: _visibility,
                onChanged: (v) => setState(() => _visibility = v),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: _content,
                style:
                    GoogleFonts.outfit(color: c.textPrimary, fontSize: 16),
                maxLines: 8,
                minLines: 4,
                maxLength: 500,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText:
                      "What's happening in SoHo? (visible to anyone in the neighborhood)",
                  hintStyle: GoogleFonts.outfit(
                    color: c.textSecondary,
                    fontSize: 16,
                  ),
                  border: InputBorder.none,
                  counterText: '',
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '$charCount / 500',
                  style: GoogleFonts.outfit(
                    color: tooLong ? AppColors.error : c.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),

              const SizedBox(height: 14),
              Divider(color: c.border, height: 1),
              const SizedBox(height: 14),

              // Linked listing (business + has listings).
              if (canLinkListing) ...[
                _LinkListingRow(
                  linked: _linkedListing,
                  onPick: () => _pickListing(myListings),
                  onClear: () => setState(() => _linkedListing = null),
                ),
                const SizedBox(height: 14),
              ],

              // Hashtag editor.
              _Label('Hashtags (up to 5)'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _hashtagInput,
                      enabled: _hashtags.length < 5,
                      onSubmitted: (_) => _addHashtagsFromInput(),
                      style: GoogleFonts.outfit(
                        color: c.textPrimary,
                        fontSize: 15,
                      ),
                      decoration: InputDecoration(
                        hintText: _hashtags.length >= 5
                            ? 'Maximum reached'
                            : 'opening, weekend  (comma to add)',
                        hintStyle: GoogleFonts.outfit(
                          color: c.textMuted,
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: c.inputBg,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: c.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: c.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.accent,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    onPressed: _hashtags.length >= 5
                        ? null
                        : _addHashtagsFromInput,
                    icon: const Icon(Icons.add_circle, color: AppColors.accent),
                    tooltip: 'Add',
                  ),
                ],
              ),
              if (_hashtags.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final t in _hashtags)
                      InputChip(
                        label: Text(
                          '#$t',
                          style: GoogleFonts.outfit(fontSize: 12),
                        ),
                        backgroundColor: c.surface2,
                        side: BorderSide(color: c.border),
                        deleteIcon: const Icon(Icons.close, size: 14),
                        onDeleted: () => _removeHashtag(t),
                      ),
                  ],
                ),
              ],

              const SizedBox(height: 22),
              _Label('Photos (up to $_maxImages)'),
              const SizedBox(height: 8),
              _PhotoStrip(
                urls: _imageUrls,
                uploadsInFlight: _uploadsInFlight,
                canAddMore:
                    _imageUrls.length + _uploadsInFlight < _maxImages,
                onAdd: _addPhoto,
                onRemove: _removePhoto,
              ),
              const SizedBox(height: 6),
              Text(
                'Each photo is automatically watermarked with your serial id.',
                style: GoogleFonts.outfit(
                  color: c.textSecondary,
                  fontSize: 12,
                ),
              ),

              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: c.border),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      color: c.textSecondary,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Your post auto-expires in 72 hours.",
                        style: GoogleFonts.outfit(
                          color: c.textSecondary,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _AuthorRow extends StatelessWidget {
  final ProfileModel author;
  final String? serialId;
  final bool switchable;
  final VoidCallback onTap;

  const _AuthorRow({
    required this.author,
    required this.serialId,
    required this.switchable,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isBusiness = author.profileType == ProfileType.business;

    return InkWell(
      onTap: switchable ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: c.surface2,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isBusiness
                    ? Icons.storefront_rounded
                    : Icons.person_rounded,
                color: AppColors.accent,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Posting as',
                    style: GoogleFonts.outfit(
                      color: c.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        isBusiness ? 'Business' : 'Personal',
                        style: GoogleFonts.outfit(
                          color: c.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accentDim,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          author.profileType.displayName,
                          style: GoogleFonts.outfit(
                            color: AppColors.accent,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (serialId != null) ...[
                        const SizedBox(width: 6),
                        SerialIdChip(serialId: serialId, dense: true),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (switchable)
              Icon(
                Icons.swap_horiz,
                color: c.textSecondary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

/// Two-pill segmented control for [PostVisibility]. Each option shows its
/// label with an explanatory tagline so the user understands the trade-off
/// without having to tap into help. Designed to feel like the public/private
/// pill in the previous mock — same affordance, schema-correct semantics.
class _VisibilityPicker extends StatelessWidget {
  final PostVisibility value;
  final ValueChanged<PostVisibility> onChanged;

  const _VisibilityPicker({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          for (final v in PostVisibility.values)
            Expanded(
              child: _VisibilityPill(
                visibility: v,
                selected: v == value,
                onTap: () => onChanged(v),
              ),
            ),
        ],
      ),
    );
  }
}

class _VisibilityPill extends StatelessWidget {
  final PostVisibility visibility;
  final bool selected;
  final VoidCallback onTap;

  const _VisibilityPill({
    required this.visibility,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final icon = visibility == PostVisibility.public
        ? Icons.public_rounded
        : Icons.lock_outline_rounded;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: selected ? Colors.white : c.textSecondary,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  visibility.displayName,
                  style: GoogleFonts.outfit(
                    color: selected ? Colors.white : c.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              visibility.tagline,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                color: selected
                    ? Colors.white.withValues(alpha: 0.85)
                    : c.textSecondary,
                fontSize: 10.5,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkListingRow extends StatelessWidget {
  final Listing? linked;
  final VoidCallback onPick;
  final VoidCallback onClear;

  const _LinkListingRow({
    required this.linked,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (linked == null) {
      return InkWell(
        onTap: onPick,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.border),
          ),
          child: Row(
            children: [
              Icon(Icons.link_rounded, color: AppColors.accent, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Link a listing (optional)',
                  style: GoogleFonts.outfit(
                    color: c.textPrimary,
                    fontSize: 14,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: c.textSecondary),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.accentDim,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent),
      ),
      child: Row(
        children: [
          Icon(Icons.link_rounded, color: AppColors.accent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Linked to listing',
                  style: GoogleFonts.outfit(
                    color: AppColors.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  linked!.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    color: c.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 18, color: c.textSecondary),
            onPressed: onClear,
            tooltip: 'Remove link',
          ),
        ],
      ),
    );
  }
}

class _ProfilePickerSheet extends StatelessWidget {
  final List<ProfileModel> profiles;
  const _ProfilePickerSheet({required this.profiles});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 16),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 4,
              alignment: Alignment.center,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: c.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Post as',
              style: GoogleFonts.outfit(
                color: c.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            for (final p in profiles)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: c.surface2,
                  child: Icon(
                    p.profileType == ProfileType.business
                        ? Icons.storefront_rounded
                        : Icons.person_rounded,
                    color: AppColors.accent,
                  ),
                ),
                title: Text(
                  p.profileType.displayName,
                  style: GoogleFonts.outfit(
                    color: c.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onTap: () => Navigator.of(context).pop(p),
              ),
          ],
        ),
      ),
    );
  }
}

class _ListingPickerSheet extends StatelessWidget {
  final List<Listing> listings;
  const _ListingPickerSheet({required this.listings});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 16),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 4,
              alignment: Alignment.center,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: c.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Link a listing',
              style: GoogleFonts.outfit(
                color: c.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: listings.length,
                separatorBuilder: (_, __) => Divider(color: c.divider),
                itemBuilder: (_, i) {
                  final l = listings[i];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      l.title,
                      style: GoogleFonts.outfit(
                        color: c.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      '${l.type.displayName} · ${l.priceLabel}',
                      style: GoogleFonts.outfit(
                        color: c.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    onTap: () => Navigator.of(context).pop(l),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: GoogleFonts.outfit(
          color: context.colors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      );
}

class _PostButton extends StatefulWidget {
  final bool isPosting;
  final bool enabled;
  final VoidCallback onTap;
  final Color bgColor;

  const _PostButton({
    required this.isPosting,
    required this.enabled,
    required this.onTap,
    required this.bgColor,
  });

  @override
  State<_PostButton> createState() => _PostButtonState();
}

class _PostButtonState extends State<_PostButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: widget.enabled ? 1.0 : 0.45,
      child: GestureDetector(
        onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: widget.enabled
            ? (_) {
                setState(() => _pressed = false);
                widget.onTap();
              }
            : null,
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.94 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: widget.isPosting
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(widget.bgColor),
                    ),
                  )
                : Text(
                    'Post',
                    style: GoogleFonts.outfit(
                      color: widget.bgColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _PhotoStrip extends StatelessWidget {
  final List<String> urls;
  final int uploadsInFlight;
  final bool canAddMore;
  final VoidCallback onAdd;
  final void Function(String url) onRemove;

  const _PhotoStrip({
    required this.urls,
    required this.uploadsInFlight,
    required this.canAddMore,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tiles = <Widget>[
      for (final url in urls)
        _PhotoTile(url: url, onRemove: () => onRemove(url)),
      for (var i = 0; i < uploadsInFlight; i++) const _PhotoUploadingTile(),
      if (canAddMore)
        GestureDetector(
          onTap: onAdd,
          child: Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: c.inputBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.border),
            ),
            child: Icon(Icons.add_a_photo_outlined, color: c.textSecondary),
          ),
        ),
    ];

    if (tiles.isEmpty) {
      return GestureDetector(
        onTap: onAdd,
        child: Container(
          height: 88,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: c.inputBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_a_photo_outlined, color: c.textSecondary),
              const SizedBox(width: 8),
              Text(
                'Add a photo',
                style: GoogleFonts.outfit(
                  color: c.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Wrap(spacing: 8, runSpacing: 8, children: tiles);
  }
}

class _PhotoTile extends StatelessWidget {
  final String url;
  final VoidCallback onRemove;

  const _PhotoTile({required this.url, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      height: 88,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: context.colors.surface2,
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: context.colors.textMuted,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 2,
            right: 2,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoUploadingTile extends StatelessWidget {
  const _PhotoUploadingTile();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: 88,
      height: 88,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.inputBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      child: const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2.5),
      ),
    );
  }
}
