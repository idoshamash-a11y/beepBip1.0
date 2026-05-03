import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../listings/providers/listings_providers.dart';
import '../../../profile/models/business_hours_model.dart';
import '../../../profile/models/business_profile_model.dart';
import '../../../profile/providers/profile_provider.dart';
import '../../../stripe/presentation/booking_demo_sheet.dart';
import '../../../stripe/providers/stripe_providers.dart';
import '../../business_page_providers.dart';
import '../widgets/single_image_picker.dart';

/// Owner-only editor for the business page. Guards the route by redirecting
/// any caller that isn't the owner of [profileId] back to the public viewer.
///
/// Lays out the editable fields in a single scrollable form so the owner can
/// scan + tweak top-to-bottom: cover, logo, name, category, hashtags,
/// description, hours, contact, social handles, Stripe Connect banner.
class BusinessPageEditScreen extends ConsumerStatefulWidget {
  const BusinessPageEditScreen({required this.profileId, super.key});

  final String profileId;

  @override
  ConsumerState<BusinessPageEditScreen> createState() =>
      _BusinessPageEditScreenState();
}

class _BusinessPageEditScreenState
    extends ConsumerState<BusinessPageEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessName = TextEditingController();
  final _category = TextEditingController();
  final _description = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _website = TextEditingController();
  final _hashtagInput = TextEditingController();
  final _instagram = TextEditingController();
  final _tiktok = TextEditingController();
  final _twitter = TextEditingController();

  String? _logoUrl;
  String? _coverUrl;
  final List<String> _hashtags = [];
  Map<int, BusinessHoursModel> _hoursByDay = {};
  bool _initialized = false;
  bool _saving = false;

  @override
  void dispose() {
    _businessName.dispose();
    _category.dispose();
    _description.dispose();
    _phone.dispose();
    _email.dispose();
    _website.dispose();
    _hashtagInput.dispose();
    _instagram.dispose();
    _tiktok.dispose();
    _twitter.dispose();
    super.dispose();
  }

  void _seedFromBundle(BusinessProfileModel b, List<BusinessHoursModel> hours) {
    if (_initialized) return;
    _initialized = true;
    _businessName.text = b.businessName;
    _category.text = b.category ?? '';
    _description.text = b.description ?? '';
    _phone.text = b.phone ?? '';
    _email.text = b.email ?? '';
    _website.text = b.website ?? '';
    _logoUrl = b.logoUrl;
    _coverUrl = b.coverUrl;
    _hashtags
      ..clear()
      ..addAll(b.hashtags);
    _instagram.text = b.socialHandles['instagram'] ?? '';
    _tiktok.text = b.socialHandles['tiktok'] ?? '';
    _twitter.text = b.socialHandles['x'] ?? b.socialHandles['twitter'] ?? '';

    // Seed 7 rows; missing rows fall back to "closed".
    final byDay = <int, BusinessHoursModel>{};
    for (final h in hours) {
      byDay[h.dayOfWeek] = h;
    }
    for (var d = 0; d < 7; d++) {
      byDay[d] ??= BusinessHoursModel(
        id: const Uuid().v4(),
        businessProfileId: b.id,
        dayOfWeek: d,
        isClosed: true,
        createdAt: DateTime.now(),
      );
    }
    _hoursByDay = byDay;
  }

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

  Map<String, String> _socialHandlesPayload() {
    final out = <String, String>{};
    final ig = _instagram.text.trim();
    final tt = _tiktok.text.trim();
    final tw = _twitter.text.trim();
    final web = _website.text.trim();
    if (ig.isNotEmpty) out['instagram'] = ig;
    if (tt.isNotEmpty) out['tiktok'] = tt;
    if (tw.isNotEmpty) out['x'] = tw;
    if (web.isNotEmpty) out['website'] = web;
    return out;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final repo = ref.read(profileRepositoryProvider);
      final profileResult = await repo.updateBusinessProfile(
        profileId: widget.profileId,
        businessName: _businessName.text.trim(),
        category: _category.text.trim(),
        description: _description.text.trim(),
        phone: _phone.text.trim(),
        email: _email.text.trim(),
        website: _website.text.trim(),
        logoUrl: _logoUrl ?? '',
        coverUrl: _coverUrl ?? '',
        hashtags: _hashtags,
        socialHandles: _socialHandlesPayload(),
      );

      if (profileResult.isErr) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(profileResult.failureOrNull?.message ??
                "Couldn't save profile."),
          ),
        );
        return;
      }

      final hoursResult = await repo.upsertBusinessHours(
        widget.profileId,
        _hoursByDay.values.toList(),
      );
      if (hoursResult.isErr) {
        AppLogger.w(
          'upsertBusinessHours failed: ${hoursResult.failureOrNull?.message}',
          tag: 'business_page',
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(hoursResult.failureOrNull?.message ??
                "Couldn't save hours."),
          ),
        );
        return;
      }

      // Refresh the public page so it picks up the new fields immediately.
      ref.invalidate(businessPageBundleProvider(widget.profileId));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Business page saved.')),
      );
      context.pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bundleAsync = ref.watch(businessPageBundleProvider(widget.profileId));
    final myBusiness = ref.watch(currentBusinessProfileProvider);

    // Owner-only guard. Once the user's profile resolves, kick non-owners
    // back to the public viewer; we do this in build so a sign-out / role
    // change in another tab also redirects.
    if (myBusiness != null && myBusiness.id != widget.profileId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/business/${widget.profileId}');
      });
    }

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: c.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Edit business page',
          style: GoogleFonts.outfit(
            color: c.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      'Save',
                      style: GoogleFonts.outfit(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: bundleAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              "Couldn't load this page for editing.\n\n$e",
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: c.textSecondary),
            ),
          ),
        ),
        data: (bundle) {
          if (bundle == null || bundle.business == null) {
            return Center(
              child: Text(
                'Business profile not found.',
                style: GoogleFonts.outfit(color: c.textSecondary),
              ),
            );
          }
          _seedFromBundle(bundle.business!, bundle.hours);

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                if (!bundle.stripeChargesEnabled)
                  _StripeBanner(profileId: widget.profileId),
                const _Label('Cover'),
                const SizedBox(height: 8),
                SingleImagePicker.cover(
                  url: _coverUrl,
                  onChanged: (url) => setState(() => _coverUrl = url),
                ),
                const SizedBox(height: 18),
                const _Label('Logo'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    SizedBox(
                      width: 96,
                      child: SingleImagePicker.logo(
                        url: _logoUrl,
                        onChanged: (url) =>
                            setState(() => _logoUrl = url),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _LabeledInput(
                  label: 'Business name',
                  controller: _businessName,
                  validator: (v) =>
                      (v?.trim().isEmpty ?? true) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                _LabeledInput(
                  label: 'Category',
                  controller: _category,
                  hint: 'e.g. Cafe, Boutique, Studio',
                ),
                const SizedBox(height: 12),
                _LabeledInput(
                  label: 'Description',
                  controller: _description,
                  hint: 'A short blurb about your business',
                  maxLines: 4,
                ),
                const SizedBox(height: 18),
                const _Label('Signature hashtags (up to 5)'),
                const SizedBox(height: 8),
                _HashtagEditor(
                  controller: _hashtagInput,
                  hashtags: _hashtags,
                  onAdd: _addHashtagsFromInput,
                  onRemove: (t) => setState(() => _hashtags.remove(t)),
                ),
                const SizedBox(height: 18),
                const _Label('Hours'),
                const SizedBox(height: 8),
                _HoursEditor(
                  hoursByDay: _hoursByDay,
                  onChanged: (next) => setState(() => _hoursByDay = next),
                ),
                const SizedBox(height: 18),
                _LabeledInput(
                  label: 'Phone',
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                _LabeledInput(
                  label: 'Email',
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                _LabeledInput(
                  label: 'Website',
                  controller: _website,
                  keyboardType: TextInputType.url,
                  hint: 'https://yourbusiness.com',
                ),
                const SizedBox(height: 18),
                const _Label('Social handles'),
                const SizedBox(height: 8),
                _LabeledInput(
                  label: 'Instagram',
                  controller: _instagram,
                  hint: '@your_handle',
                  inputFormatters: const [],
                ),
                const SizedBox(height: 8),
                _LabeledInput(
                  label: 'TikTok',
                  controller: _tiktok,
                  hint: '@your_handle',
                ),
                const SizedBox(height: 8),
                _LabeledInput(
                  label: 'X (Twitter)',
                  controller: _twitter,
                  hint: '@your_handle',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.outfit(
        color: context.colors.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
      ),
    );
  }
}

class _LabeledInput extends StatelessWidget {
  const _LabeledInput({
    required this.label,
    required this.controller,
    this.hint,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
    this.inputFormatters,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(label),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          inputFormatters: inputFormatters,
          style: GoogleFonts.outfit(color: c.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.outfit(color: c.textMuted, fontSize: 13),
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
      ],
    );
  }
}

class _HashtagEditor extends StatelessWidget {
  const _HashtagEditor({
    required this.controller,
    required this.hashtags,
    required this.onAdd,
    required this.onRemove,
  });

  final TextEditingController controller;
  final List<String> hashtags;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: hashtags.length < 5,
                onSubmitted: (_) => onAdd(),
                style: GoogleFonts.outfit(color: c.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: hashtags.length >= 5
                      ? 'Maximum 5 reached'
                      : 'cafe, organic  (comma to add)',
                  hintStyle: GoogleFonts.outfit(
                    color: c.textMuted,
                    fontSize: 13,
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
            IconButton(
              onPressed: hashtags.length >= 5 ? null : onAdd,
              icon: const Icon(Icons.add_circle, color: AppColors.accent),
            ),
          ],
        ),
        if (hashtags.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final t in hashtags)
                InputChip(
                  label: Text(
                    '#$t',
                    style: GoogleFonts.outfit(fontSize: 12),
                  ),
                  backgroundColor: c.surface2,
                  side: BorderSide(color: c.border),
                  deleteIcon: const Icon(Icons.close, size: 14),
                  onDeleted: () => onRemove(t),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _HoursEditor extends StatelessWidget {
  const _HoursEditor({required this.hoursByDay, required this.onChanged});

  final Map<int, BusinessHoursModel> hoursByDay;
  final ValueChanged<Map<int, BusinessHoursModel>> onChanged;

  static const _dayNames = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border),
      ),
      child: Column(
        children: [
          for (var d = 0; d < 7; d++) ...[
            _HoursRow(
              dayName: _dayNames[d],
              hours: hoursByDay[d]!,
              onChanged: (next) {
                final updated = {...hoursByDay, d: next};
                onChanged(updated);
              },
            ),
            if (d < 6) Divider(height: 1, color: c.divider),
          ],
        ],
      ),
    );
  }
}

class _HoursRow extends StatelessWidget {
  const _HoursRow({
    required this.dayName,
    required this.hours,
    required this.onChanged,
  });

  final String dayName;
  final BusinessHoursModel hours;
  final ValueChanged<BusinessHoursModel> onChanged;

  Future<void> _pickTime(
    BuildContext context, {
    required bool open,
  }) async {
    final initial = TimeOfDay(
      hour: open
          ? int.tryParse((hours.openTime ?? '09:00').split(':').first) ?? 9
          : int.tryParse((hours.closeTime ?? '17:00').split(':').first) ?? 17,
      minute: open
          ? int.tryParse((hours.openTime ?? '09:00').split(':').last) ?? 0
          : int.tryParse((hours.closeTime ?? '17:00').split(':').last) ?? 0,
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    final formatted =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    onChanged(hours.copyWith(
      isClosed: false,
      openTime: open ? formatted : hours.openTime ?? '09:00',
      closeTime: open ? hours.closeTime ?? '17:00' : formatted,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              dayName,
              style: GoogleFonts.outfit(
                color: c.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (hours.isClosed)
            Expanded(
              child: Text(
                'Closed',
                style: GoogleFonts.outfit(
                  color: c.textSecondary,
                  fontSize: 13,
                ),
              ),
            )
          else ...[
            Expanded(
              child: Row(
                children: [
                  _TimeChip(
                    label: hours.openTime ?? '09:00',
                    onTap: () => _pickTime(context, open: true),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '–',
                    style: GoogleFonts.outfit(color: c.textSecondary),
                  ),
                  const SizedBox(width: 6),
                  _TimeChip(
                    label: hours.closeTime ?? '17:00',
                    onTap: () => _pickTime(context, open: false),
                  ),
                ],
              ),
            ),
          ],
          Switch(
            value: !hours.isClosed,
            activeThumbColor: AppColors.accent,
            onChanged: (open) => onChanged(hours.copyWith(
              isClosed: !open,
              openTime: open ? (hours.openTime ?? '09:00') : hours.openTime,
              closeTime:
                  open ? (hours.closeTime ?? '17:00') : hours.closeTime,
            )),
          ),
        ],
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: c.surface2,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: c.border),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            color: c.textPrimary,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Banner shown at the top of the editor when the business hasn't connected
/// Stripe yet. Tapping kicks off the onboarding link via the
/// `create-stripe-connect-account` Edge Function (the action is wired in
/// the Stripe Connect step of the plan).
class _StripeBanner extends ConsumerWidget {
  const _StripeBanner({required this.profileId});

  final String profileId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accentDim,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accent),
      ),
      child: Row(
        children: [
          const Icon(Icons.account_balance_wallet_outlined,
              color: AppColors.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Connect Stripe to take bookings',
                  style: GoogleFonts.outfit(
                    color: AppColors.accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Required before buyers can pay through your page.',
                  style: GoogleFonts.outfit(
                    color: c.textPrimary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _startOnboarding(context, ref),
            child: Text(
              'Connect',
              style: GoogleFonts.outfit(
                color: AppColors.accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startOnboarding(BuildContext context, WidgetRef ref) async {
    final demoMode =
        ref.read(bookingsDemoModeFlagProvider).asData?.value ?? false;
    if (demoMode) {
      await StripeConnectDemoSheet.show(context);
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final url = await ref
        .read(stripeOnboardingProvider.notifier)
        .startOnboarding(profileId);
    if (url == null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            ref.read(stripeOnboardingProvider).error ??
                "Couldn't start Stripe onboarding.",
          ),
        ),
      );
      return;
    }
  }
}
