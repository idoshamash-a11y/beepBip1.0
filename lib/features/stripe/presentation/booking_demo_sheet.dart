import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../listings/models/listing_enums.dart';
import '../../listings/models/listing_model.dart';

/// Result of the mock checkout flow. Mirrors the shape we'll get back from
/// the real Stripe Checkout redirect so the calling code can stay identical
/// once `bookings.demo_mode` flips to false.
enum BookingDemoOutcome { paid, cancelled }

/// A polished bottom sheet that fakes a Stripe Checkout flow end-to-end.
/// Used when `bookings.demo_mode` is on so the team / stakeholders can
/// click through Book / Reserve / Buy without having a real Stripe account
/// wired up.
///
/// Visually mirrors the eventual real UX: itemized total, platform-fee
/// disclosure, "Pay" CTA with a fake processing state. The CTA resolves
/// after ~1.2s with a success toast — long enough to feel real, short
/// enough to demo cleanly.
class BookingDemoSheet extends StatefulWidget {
  final Listing listing;
  final int quantity;

  const BookingDemoSheet({
    super.key,
    required this.listing,
    this.quantity = 1,
  });

  /// 8% platform fee — same value the real `create-booking-checkout`
  /// Edge Function applies. Defined here as a UI-side constant so the
  /// breakdown stays in sync with what the user will see live.
  static const double platformFeeRate = 0.08;

  static Future<BookingDemoOutcome?> show(
    BuildContext context, {
    required Listing listing,
    int quantity = 1,
  }) {
    return showModalBottomSheet<BookingDemoOutcome>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BookingDemoSheet(
        listing: listing,
        quantity: quantity,
      ),
    );
  }

  @override
  State<BookingDemoSheet> createState() => _BookingDemoSheetState();
}

class _BookingDemoSheetState extends State<BookingDemoSheet> {
  bool _isProcessing = false;

  String get _ctaLabel => switch (widget.listing.type) {
        ListingType.service => 'Pay & book',
        ListingType.item => 'Pay & buy',
        ListingType.event => 'Pay & reserve',
      };

  String _money(int cents) {
    final amount = (cents / 100).toStringAsFixed(2);
    final symbol = widget.listing.currency == 'USD' ? '\$' : '${widget.listing.currency} ';
    return '$symbol$amount';
  }

  Future<void> _handlePay() async {
    setState(() => _isProcessing = true);
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    Navigator.of(context).pop(BookingDemoOutcome.paid);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final subtotal = widget.listing.priceCents * widget.quantity;
    final fee = (subtotal * BookingDemoSheet.platformFeeRate).round();
    final total = subtotal + fee;

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: c.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: c.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'DEMO MODE',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.accent,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No card will be charged',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: c.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.listing.title,
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              switch (widget.listing.type) {
                ListingType.service => 'Service booking',
                ListingType.item => 'Purchase',
                ListingType.event => 'Event reservation',
              },
              style: GoogleFonts.inter(
                fontSize: 13,
                color: c.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            _line(
              context,
              label: 'Subtotal',
              value: _money(subtotal),
              subtitle: widget.quantity > 1
                  ? '${widget.listing.priceLabel} × ${widget.quantity}'
                  : null,
            ),
            const SizedBox(height: 8),
            _line(
              context,
              label: 'Platform fee (8%)',
              value: _money(fee),
              subtitle: 'Same fee the live Edge Function will apply',
              muted: true,
            ),
            const Divider(height: 28),
            _line(
              context,
              label: 'Total',
              value: _money(total),
              bold: true,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _handlePay,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: c.bg,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        '$_ctaLabel · ${_money(total)}',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: _isProcessing
                    ? null
                    : () =>
                        Navigator.of(context).pop(BookingDemoOutcome.cancelled),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: c.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _line(
    BuildContext context, {
    required String label,
    required String value,
    String? subtitle,
    bool bold = false,
    bool muted = false,
  }) {
    final c = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: bold ? 15 : 14,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                  color: muted ? c.textSecondary : c.textPrimary,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: c.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: bold ? 17 : 14,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            color: muted ? c.textSecondary : c.textPrimary,
          ),
        ),
      ],
    );
  }
}

/// Companion sheet for the "Connect Stripe" banner. Mirrors the eventual
/// onboarding experience by walking through three placeholder steps so the
/// owner can see what the flow will feel like.
class StripeConnectDemoSheet extends StatelessWidget {
  const StripeConnectDemoSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const StripeConnectDemoSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: c.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: c.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'DEMO MODE',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.accent,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Stripe Connect onboarding preview',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: c.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Connect your Stripe account',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Once your founder hands us the Stripe keys, tapping this button will launch the real onboarding link.",
              style: GoogleFonts.inter(
                fontSize: 13,
                color: c.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            const _Step(
              index: 1,
              title: 'Verify your business',
              body: 'Stripe collects EIN, address, and ID — same as any payout-enabled marketplace.',
            ),
            const _Step(
              index: 2,
              title: 'Add a payout method',
              body: 'Bank account or debit card. Funds arrive within 2 business days of each booking.',
            ),
            const _Step(
              index: 3,
              title: 'Start accepting bookings',
              body: 'Charges flow through Stripe Checkout with an 8% platform fee deducted automatically.',
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: c.bg,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Got it',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final int index;
  final String title;
  final String body;
  const _Step({
    required this.index,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$index',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.accent,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: c.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
