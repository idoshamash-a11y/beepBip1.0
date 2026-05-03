import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../listings/models/listing_enums.dart';
import '../../../listings/models/listing_model.dart';

/// Tabs for Services / Items / Events with a grid of listing cards under each.
/// Tabs that have zero listings render an inline empty state instead of being
/// hidden — easier to discover, and lets the owner see "you have nothing
/// listed in this category" at a glance.
class BusinessCatalogSection extends StatefulWidget {
  const BusinessCatalogSection({
    required this.listings,
    required this.bookingsEnabled,
    required this.stripeChargesEnabled,
    super.key,
  });

  final List<Listing> listings;

  /// Global feature flag — when off, no booking CTA is shown anywhere.
  final bool bookingsEnabled;

  /// Per-business flag — when off, the CTA degrades to "View" only.
  final bool stripeChargesEnabled;

  @override
  State<BusinessCatalogSection> createState() => _BusinessCatalogSectionState();
}

class _BusinessCatalogSectionState extends State<BusinessCatalogSection>
    with SingleTickerProviderStateMixin {
  late final TabController _controller =
      TabController(length: ListingType.values.length, vsync: this);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Listing> _filterByType(ListingType type) {
    return widget.listings.where((l) => l.type == type).toList();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
          child: Text(
            'Catalog',
            style: GoogleFonts.outfit(
              color: c.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        TabBar(
          controller: _controller,
          isScrollable: true,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          labelColor: AppColors.accent,
          unselectedLabelColor: c.textSecondary,
          indicatorColor: AppColors.accent,
          indicatorWeight: 2.5,
          labelStyle: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
          tabs: [
            for (final t in ListingType.values)
              Tab(
                text:
                    '${_pluralizeTab(t)} · ${_filterByType(t).length}',
              ),
          ],
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: _gridHeight(),
          child: TabBarView(
            controller: _controller,
            children: [
              for (final t in ListingType.values)
                _CatalogGrid(
                  listings: _filterByType(t),
                  bookingsEnabled: widget.bookingsEnabled &&
                      widget.stripeChargesEnabled,
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// We render the section inside a CustomScrollView, so the TabBarView
  /// needs an explicit height. Compute it from the largest tab.
  double _gridHeight() {
    final maxCount = ListingType.values
        .map(_filterByType)
        .map((rows) => rows.length)
        .reduce((a, b) => a > b ? a : b);
    if (maxCount == 0) return 160;
    final rows = (maxCount / 2).ceil();
    // 230 px per row card incl. padding.
    return (rows * 230) + 16;
  }
}

String _pluralizeTab(ListingType t) {
  return switch (t) {
    ListingType.service => 'Services',
    ListingType.item => 'Items',
    ListingType.event => 'Events',
  };
}

class _CatalogGrid extends StatelessWidget {
  const _CatalogGrid({
    required this.listings,
    required this.bookingsEnabled,
  });

  final List<Listing> listings;
  final bool bookingsEnabled;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (listings.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            'Nothing here yet.',
            style: GoogleFonts.outfit(color: c.textSecondary, fontSize: 13),
          ),
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: listings.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemBuilder: (context, index) {
        final l = listings[index];
        return _ListingCard(listing: l, bookingsEnabled: bookingsEnabled);
      },
    );
  }
}

class _ListingCard extends StatelessWidget {
  const _ListingCard({
    required this.listing,
    required this.bookingsEnabled,
  });

  final Listing listing;
  final bool bookingsEnabled;

  String get _ctaLabel {
    if (!bookingsEnabled) return 'View';
    return switch (listing.type) {
      ListingType.service => 'Book',
      ListingType.item => 'Buy',
      ListingType.event => 'Reserve',
    };
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final firstImage = listing.images.isNotEmpty ? listing.images.first : null;

    return GestureDetector(
      onTap: () => context.push('/listings/${listing.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 1.05,
              child: firstImage == null
                  ? Container(
                      color: c.surface2,
                      alignment: Alignment.center,
                      child: Icon(
                        switch (listing.type) {
                          ListingType.service => Icons.handyman_outlined,
                          ListingType.item => Icons.shopping_bag_outlined,
                          ListingType.event => Icons.event_outlined,
                        },
                        color: c.textMuted,
                        size: 32,
                      ),
                    )
                  : CachedNetworkImage(
                      imageUrl: firstImage,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: c.surface2),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      color: c.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    listing.priceLabel,
                    style: GoogleFonts.outfit(
                      color: AppColors.accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _ctaLabel,
                      style: GoogleFonts.outfit(
                        color: c.bg,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
