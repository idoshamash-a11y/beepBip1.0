import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../listings/providers/listings_providers.dart';
import '../../business_page_providers.dart';
import '../widgets/business_about_section.dart';
import '../widgets/business_catalog_section.dart';
import '../widgets/business_page_hero.dart';
import '../widgets/business_updates_section.dart';
import '../widgets/photos_strip.dart';

/// Public business page (storefront). Renders read-only for everyone; if the
/// signed-in user owns the underlying profile, the app bar shows an "Edit"
/// affordance routing to [BusinessPageEditScreen].
///
/// Composes the existing pieces:
///   * profile + business profile + hours (identity + about)
///   * active listings (catalog tabs)
///   * recent posts (updates)
///   * stripe_accounts.charges_enabled (whether to show book CTA)
class BusinessPageScreen extends ConsumerWidget {
  const BusinessPageScreen({required this.profileId, super.key});

  final String profileId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final bundleAsync =
        ref.watch(businessPageBundleProvider(profileId));
    final bookingsFlagAsync = ref.watch(bookingsEnabledFlagProvider);
    final myBusiness = ref.watch(currentBusinessProfileProvider);
    final isOwner = myBusiness != null && myBusiness.id == profileId;

    return Scaffold(
      backgroundColor: c.bg,
      body: bundleAsync.when(
        loading: () => const _LoadingState(),
        error: (e, _) => _ErrorState(
          message: e.toString(),
          onRetry: () =>
              ref.invalidate(businessPageBundleProvider(profileId)),
        ),
        data: (bundle) {
          if (bundle == null || bundle.business == null) {
            return const _NotFoundState();
          }

          final business = bundle.business!;
          final bookingsEnabled =
              bookingsFlagAsync.asData?.value ?? false;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: c.bg,
                surfaceTintColor: c.bg,
                elevation: 0,
                iconTheme: IconThemeData(color: c.textPrimary),
                leading: IconButton(
                  icon: Icon(Icons.arrow_back, color: c.textPrimary),
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/home');
                    }
                  },
                ),
                title: Text(
                  business.businessName,
                  style: GoogleFonts.outfit(
                    color: c.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                actions: [
                  if (isOwner)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: IconButton(
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: AppColors.accent,
                        ),
                        tooltip: 'Edit page',
                        onPressed: () =>
                            context.push('/business/$profileId/manage'),
                      ),
                    ),
                ],
              ),
              SliverToBoxAdapter(
                child: BusinessPageHero(
                  profile: bundle.profile,
                  business: business,
                ),
              ),
              SliverToBoxAdapter(
                child: BusinessPageNameBlock(
                  profile: bundle.profile,
                  business: business,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 18)),
              SliverToBoxAdapter(
                child: BusinessAboutSection(
                  business: business,
                  hours: bundle.hours,
                ),
              ),
              if (bundle.aggregatedListingImages.isNotEmpty) ...[
                const SliverToBoxAdapter(child: SizedBox(height: 18)),
                SliverToBoxAdapter(
                  child: PhotosStrip(urls: bundle.aggregatedListingImages),
                ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 18)),
              SliverToBoxAdapter(
                child: BusinessCatalogSection(
                  listings: bundle.activeListings,
                  bookingsEnabled: bookingsEnabled,
                  stripeChargesEnabled: bundle.stripeChargesEnabled,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              SliverToBoxAdapter(
                child: BusinessUpdatesSection(posts: bundle.recentPosts),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          );
        },
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 180,
            color: c.surface2,
          ),
          const SizedBox(height: 60),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 22,
              width: 200,
              decoration: BoxDecoration(
                color: c.surface2,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 14,
              width: 130,
              decoration: BoxDecoration(
                color: c.surface2,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const Spacer(),
          const Center(child: CircularProgressIndicator()),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _NotFoundState extends StatelessWidget {
  const _NotFoundState();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.storefront_outlined,
                color: c.textMuted,
                size: 56,
              ),
              const SizedBox(height: 12),
              Text(
                "We couldn't find this business page.",
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  color: c.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "It may have been removed, or you don't have access.",
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  color: c.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  color: AppColors.error, size: 48),
              const SizedBox(height: 12),
              Text(
                'Something went wrong loading this page.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  color: c.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  color: c.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: onRetry,
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
