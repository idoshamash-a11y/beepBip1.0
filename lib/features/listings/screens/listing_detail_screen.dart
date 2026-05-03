import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../business_page/business_page_providers.dart';
import '../../stripe/presentation/booking_demo_sheet.dart';
import '../../stripe/providers/stripe_providers.dart';
import '../models/listing_enums.dart';
import '../models/listing_model.dart';
import '../providers/listings_providers.dart';

/// Read-only detail view. If the signed-in user owns the listing, the
/// app bar exposes Edit + Delete actions.
class ListingDetailScreen extends ConsumerWidget {
  final String listingId;

  const ListingDetailScreen({required this.listingId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final async = ref.watch(listingByIdProvider(listingId));
    final ownerProfile = ref.watch(currentBusinessProfileProvider);

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
              context.go('/listings');
            }
          },
        ),
        title: Text(
          'Listing',
          style: GoogleFonts.outfit(
            color: c.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          async.maybeWhen(
            data: (listing) {
              if (listing == null) return const SizedBox.shrink();
              final isOwner =
                  ownerProfile != null && listing.profileId == ownerProfile.id;
              if (!isOwner) return const SizedBox.shrink();
              return Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.edit_outlined, color: c.textPrimary),
                    onPressed: () =>
                        context.push('/listings/${listing.id}/edit'),
                    tooltip: 'Edit',
                  ),
                  IconButton(
                    icon:
                        const Icon(Icons.delete_outline, color: AppColors.error),
                    onPressed: () => _confirmDelete(context, ref, listing),
                    tooltip: 'Delete',
                  ),
                  const SizedBox(width: 4),
                ],
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: SafeArea(
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                "Couldn't load this listing.\n\n${err.toString()}",
                textAlign: TextAlign.center,
                style:
                    GoogleFonts.outfit(color: c.textSecondary, fontSize: 14),
              ),
            ),
          ),
          data: (listing) {
            if (listing == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    "This listing isn't available.",
                    style: GoogleFonts.outfit(
                      color: c.textSecondary,
                      fontSize: 15,
                    ),
                  ),
                ),
              );
            }
            return _DetailBody(listing: listing);
          },
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Listing listing,
  ) async {
    final c = context.colors;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete listing?',
          style: GoogleFonts.outfit(
            color: c.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'This permanently removes "${listing.title}". '
          'You can\'t undo this.',
          style: GoogleFonts.outfit(color: c.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.outfit(color: c.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Delete',
              style: GoogleFonts.outfit(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final ok = await ref
        .read(listingFormControllerProvider.notifier)
        .deleteListing(listing.id);

    if (!context.mounted) return;
    if (ok) {
      ref.invalidate(listingByIdProvider(listing.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Listing deleted.')),
      );
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/listings');
      }
    } else {
      final err = ref.read(listingFormControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err ?? 'Could not delete listing.')),
      );
    }
  }
}

class _DetailBody extends StatelessWidget {
  final Listing listing;
  const _DetailBody({required this.listing});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _TypeBadge(type: listing.type),
              const SizedBox(width: 8),
              _StatusBadge(status: listing.status),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            listing.title,
            style: GoogleFonts.outfit(
              color: c.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            listing.priceLabel,
            style: GoogleFonts.outfit(
              color: AppColors.accent,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          if ((listing.description ?? '').isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              listing.description!,
              style: GoogleFonts.outfit(
                color: c.textPrimary,
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 20),
          _OwnerLink(profileId: listing.profileId),
          const SizedBox(height: 16),
          _BookingCta(listing: listing),
          const SizedBox(height: 24),
          _MetaGrid(listing: listing),
          if (listing.hashtags.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Tags',
              style: GoogleFonts.outfit(
                color: c.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tag in listing.hashtags) _Tag(tag: tag),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MetaGrid extends StatelessWidget {
  final Listing listing;
  const _MetaGrid({required this.listing});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final items = <Widget>[];

    if (listing.type == ListingType.service &&
        listing.durationMinutes != null) {
      items.add(_MetaRow(
        icon: Icons.schedule,
        label: 'Duration',
        value: '${listing.durationMinutes} min',
      ));
    }
    if (listing.type == ListingType.item && listing.stock != null) {
      items.add(_MetaRow(
        icon: Icons.inventory_2_outlined,
        label: 'In stock',
        value: '${listing.stock}',
      ));
    }
    if (listing.type == ListingType.event) {
      if (listing.startsAt != null) {
        items.add(_MetaRow(
          icon: Icons.event,
          label: 'Starts',
          value: _formatDateTime(listing.startsAt!),
        ));
      }
      if (listing.endsAt != null) {
        items.add(_MetaRow(
          icon: Icons.event_busy,
          label: 'Ends',
          value: _formatDateTime(listing.endsAt!),
        ));
      }
      if (listing.capacity != null) {
        items.add(_MetaRow(
          icon: Icons.people_outline,
          label: 'Capacity',
          value: '${listing.capacity}',
        ));
      }
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < items.length; i++) ...[
            items[i],
            if (i < items.length - 1) ...[
              const SizedBox(height: 8),
              Divider(height: 1, color: c.divider),
              const SizedBox(height: 8),
            ],
          ],
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    final mm = local.month.toString().padLeft(2, '0');
    final dd = local.day.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final mi = local.minute.toString().padLeft(2, '0');
    return '${local.year}-$mm-$dd $hh:$mi';
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _MetaRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Icon(icon, size: 18, color: c.textSecondary),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.outfit(
            color: c.textSecondary,
            fontSize: 13,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: c.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final ListingType type;
  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final icon = switch (type) {
      ListingType.service => Icons.handyman_outlined,
      ListingType.item => Icons.shopping_bag_outlined,
      ListingType.event => Icons.event_outlined,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.accentDim,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.accent, size: 16),
          const SizedBox(width: 6),
          Text(
            type.displayName,
            style: GoogleFonts.outfit(
              color: AppColors.accent,
              fontWeight: FontWeight.w700,
              fontSize: 12,
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
    final isActive = status == ListingStatus.active;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isActive ? const Color(0x1F4CAF50) : c.surface2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.border),
      ),
      child: Text(
        status.displayName,
        style: GoogleFonts.outfit(
          color: isActive ? AppColors.success : c.textSecondary,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

/// "Book / Reserve / Buy" CTA. Behavior:
///   * If `bookings.enabled` flag is off  → shows nothing (defer to V1.5).
///   * If seller hasn't connected Stripe → shows a disabled chip.
///   * Otherwise → invokes the `create-booking-checkout` Edge Function and
///     opens the returned Stripe Checkout URL.
///
/// We deliberately keep this simple in V1: 1 unit, no scheduling picker.
/// Quantity / scheduled_for selection lands in the deeper booking flow
/// (FOLLOWUPS — booking experience polish).
class _BookingCta extends ConsumerWidget {
  final Listing listing;
  const _BookingCta({required this.listing});

  String get _label => switch (listing.type) {
        ListingType.service => 'Book',
        ListingType.item => 'Buy',
        ListingType.event => 'Reserve',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final bookingsEnabledAsync = ref.watch(bookingsEnabledFlagProvider);
    final demoModeAsync = ref.watch(bookingsDemoModeFlagProvider);
    final flowState = ref.watch(bookingCheckoutProvider);
    final ownerProfile = ref.watch(currentBusinessProfileProvider);
    final isOwner =
        ownerProfile != null && listing.profileId == ownerProfile.id;

    if (isOwner) {
      // Owners shouldn't book their own listing; surface a "Manage" instead.
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => context.push('/listings/${listing.id}/edit'),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Manage listing'),
        ),
      );
    }

    final bookingsEnabled = bookingsEnabledAsync.asData?.value ?? false;
    if (!bookingsEnabled) {
      // CTA hidden behind feature flag for V1. Fall back to a "Message
      // owner" link so buyers still have a path to engage.
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () =>
              context.push('/business/${listing.profileId}'),
          icon: const Icon(Icons.storefront_outlined),
          label: const Text('Contact business'),
        ),
      );
    }

    final demoMode = demoModeAsync.asData?.value ?? false;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: flowState.isLoading
            ? null
            : () async {
                if (demoMode) {
                  final outcome = await BookingDemoSheet.show(
                    context,
                    listing: listing,
                  );
                  if (!context.mounted) return;
                  if (outcome == BookingDemoOutcome.paid) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Demo booking confirmed for '${listing.title}'. "
                          'Hook up Stripe keys to make it real.',
                        ),
                      ),
                    );
                  }
                  return;
                }
                final url = await ref
                    .read(bookingCheckoutProvider.notifier)
                    .startCheckout(listingId: listing.id);
                if (!context.mounted) return;
                if (url == null) {
                  final msg =
                      ref.read(bookingCheckoutProvider).error ??
                          "Couldn't start checkout.";
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(msg)),
                  );
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: c.bg,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: flowState.isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child:
                    CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                '$_label · ${listing.priceLabel}',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}

/// Tappable strip that opens the seller's business page. Renders as a small
/// row with a storefront icon + "Visit business page" label so the
/// affordance is discoverable but doesn't compete with the primary CTA.
class _OwnerLink extends StatelessWidget {
  final String profileId;
  const _OwnerLink({required this.profileId});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => context.push('/business/$profileId'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.storefront_outlined, color: AppColors.accent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Visit business page',
                style: GoogleFonts.outfit(
                  color: c.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: c.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String tag;
  const _Tag({required this.tag});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '#$tag',
        style: GoogleFonts.outfit(
          color: c.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
