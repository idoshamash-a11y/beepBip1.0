import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/serial_id_lookup_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/serial_id_chip.dart';
import '../../../profile/models/business_profile_model.dart';
import '../../../profile/models/profile_model.dart';

/// Cover + logo + name + verified/founding badges + signature hashtags.
/// Renders as a fixed-height block (no parallax SliverAppBar — kept simple
/// and predictable for V1, can be upgraded later without changing callers).
class BusinessPageHero extends StatelessWidget {
  const BusinessPageHero({
    required this.profile,
    required this.business,
    super.key,
  });

  final ProfileModel profile;
  final BusinessProfileModel business;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _Cover(coverUrl: business.coverUrl, c: c),
        Positioned(
          left: 20,
          right: 20,
          bottom: -36,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _Logo(logoUrl: business.logoUrl, c: c),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(bottom: 44),
                child: Row(
                  children: [
                    if (profile.isVerified)
                      const _Badge(
                        icon: Icons.verified_rounded,
                        label: 'Verified',
                        color: AppColors.accent,
                      ),
                    if (profile.isVerified && profile.isFoundingBusiness)
                      const SizedBox(width: 6),
                    if (profile.isFoundingBusiness)
                      const _Badge(
                        icon: Icons.workspace_premium_rounded,
                        label: 'Founding',
                        color: AppColors.success,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({required this.coverUrl, required this.c});
  final String? coverUrl;
  final AppColors c;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: c.surface2,
      ),
      child: coverUrl == null || coverUrl!.isEmpty
          ? Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.accent.withValues(alpha: 0.45),
                    c.surface2,
                  ],
                ),
              ),
            )
          : CachedNetworkImage(
              imageUrl: coverUrl!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: 180,
              errorWidget: (_, __, ___) => Container(
                color: c.surface2,
                alignment: Alignment.center,
                child: Icon(Icons.image_outlined, color: c.textMuted),
              ),
            ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({required this.logoUrl, required this.c});
  final String? logoUrl;
  final AppColors c;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.bg, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: logoUrl == null || logoUrl!.isEmpty
          ? const Icon(
              Icons.storefront_rounded,
              color: AppColors.accent,
              size: 38,
            )
          : ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: CachedNetworkImage(
                imageUrl: logoUrl!,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => const Icon(
                  Icons.storefront_rounded,
                  color: AppColors.accent,
                  size: 38,
                ),
              ),
            ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.outfit(
              color: color,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Name + category + signature hashtag chips. Rendered below the hero so the
/// logo can spill out past the cover edge.
class BusinessPageNameBlock extends ConsumerWidget {
  const BusinessPageNameBlock({
    required this.profile,
    required this.business,
    super.key,
  });

  final ProfileModel profile;
  final BusinessProfileModel business;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final serialId =
        ref.watch(serialIdForProfileProvider(profile.id)).asData?.value;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 6,
            children: [
              Text(
                business.businessName,
                style: GoogleFonts.outfit(
                  color: c.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  height: 1.15,
                ),
              ),
              if (serialId != null) SerialIdChip(serialId: serialId),
            ],
          ),
          if ((business.category ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              business.category!,
              style: GoogleFonts.outfit(
                color: c.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
          if (business.hashtags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final tag in business.hashtags)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentDim,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '#$tag',
                      style: GoogleFonts.outfit(
                        color: AppColors.accent,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
