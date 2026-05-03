import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../models/listing_enums.dart';
import '../models/listing_model.dart';
import '../providers/listings_providers.dart';

/// Two segments: "All in SoHo" (everyone can see) and "Mine" (only shown to
/// users who own a business profile). Tap a row -> /listings/:id; tap the
/// "+" FAB (business owners only) -> /listings/new.
class ListingsBrowseScreen extends ConsumerStatefulWidget {
  const ListingsBrowseScreen({super.key});

  @override
  ConsumerState<ListingsBrowseScreen> createState() =>
      _ListingsBrowseScreenState();
}

enum _Tab { all, mine }

class _ListingsBrowseScreenState extends ConsumerState<ListingsBrowseScreen> {
  _Tab _tab = _Tab.all;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final canAuthor = ref.watch(canAuthorListingsProvider);

    final activeTab = canAuthor ? _tab : _Tab.all;
    final listingsAsync = activeTab == _Tab.mine
        ? ref.watch(myListingsProvider)
        : ref.watch(neighborhoodListingsProvider);

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
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
          'Listings',
          style: GoogleFonts.outfit(
            color: c.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (canAuthor)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: _SegmentToggle(
                  active: activeTab,
                  onChanged: (v) => setState(() => _tab = v),
                ),
              )
            else
              const SizedBox(height: 8),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.accent,
                onRefresh: () async {
                  ref
                    ..invalidate(neighborhoodListingsProvider)
                    ..invalidate(myListingsProvider);
                  if (activeTab == _Tab.mine) {
                    await ref.read(myListingsProvider.future);
                  } else {
                    await ref.read(neighborhoodListingsProvider.future);
                  }
                },
                child: listingsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, _) => _ErrorState(
                    message: err.toString(),
                    onRetry: () {
                      ref
                        ..invalidate(neighborhoodListingsProvider)
                        ..invalidate(myListingsProvider);
                    },
                  ),
                  data: (listings) {
                    if (listings.isEmpty) {
                      return _EmptyState(forOwner: activeTab == _Tab.mine);
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                      itemCount: listings.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => _ListingCard(
                        listing: listings[i],
                        onTap: () =>
                            context.push('/listings/${listings[i].id}'),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: canAuthor
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.accent,
              onPressed: () => context.push('/listings/new'),
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                'New listing',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          : null,
    );
  }
}

class _SegmentToggle extends StatelessWidget {
  final _Tab active;
  final ValueChanged<_Tab> onChanged;

  const _SegmentToggle({required this.active, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          _Segment(
            label: 'All in SoHo',
            active: active == _Tab.all,
            onTap: () => onChanged(_Tab.all),
          ),
          _Segment(
            label: 'Mine',
            active: active == _Tab.mine,
            onTap: () => onChanged(_Tab.mine),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _Segment({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? AppColors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: GoogleFonts.outfit(
              color: active ? Colors.white : c.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _ListingCard extends StatelessWidget {
  final Listing listing;
  final VoidCallback onTap;

  const _ListingCard({required this.listing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _TypeBadge(type: listing.type),
                  const SizedBox(width: 8),
                  if (listing.status != ListingStatus.active)
                    _StatusBadge(status: listing.status),
                  const Spacer(),
                  Text(
                    listing.priceLabel,
                    style: GoogleFonts.outfit(
                      color: c.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                listing.title,
                style: GoogleFonts.outfit(
                  color: c.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if ((listing.description ?? '').isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  listing.description!,
                  style: GoogleFonts.outfit(
                    color: c.textSecondary,
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (listing.hashtags.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final tag in listing.hashtags.take(4))
                      _HashtagChip(tag: tag),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final ListingType type;
  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final icon = switch (type) {
      ListingType.service => Icons.handyman_outlined,
      ListingType.item => Icons.shopping_bag_outlined,
      ListingType.event => Icons.event_outlined,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accentDim,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.accent, size: 14),
          const SizedBox(width: 4),
          Text(
            type.displayName,
            style: GoogleFonts.outfit(
              color: AppColors.accent,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final ListingStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: c.border),
      ),
      child: Text(
        status.displayName,
        style: GoogleFonts.outfit(
          color: c.textSecondary,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _HashtagChip extends StatelessWidget {
  final String tag;
  const _HashtagChip({required this.tag});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '#$tag',
        style: GoogleFonts.outfit(
          color: c.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool forOwner;
  const _EmptyState({required this.forOwner});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        Center(
          child: Icon(
            Icons.storefront_outlined,
            color: c.textMuted,
            size: 56,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            forOwner ? 'No listings yet' : 'Nothing for sale here yet',
            style: GoogleFonts.outfit(
              color: c.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            forOwner
                ? 'Tap "New listing" to add your first service, item, or event.'
                : 'Be the first to discover new SoHo listings here. '
                    'Pull to refresh.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: c.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        Center(
          child: Icon(
            Icons.error_outline,
            color: AppColors.error,
            size: 56,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            "Couldn't load listings",
            style: GoogleFonts.outfit(
              color: c.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: c.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: onRetry,
            child: Text(
              'Try again',
              style: GoogleFonts.outfit(
                color: AppColors.accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
