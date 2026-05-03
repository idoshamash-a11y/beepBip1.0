import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/image_upload_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/listing_enums.dart';
import '../models/listing_model.dart';
import '../providers/listings_providers.dart';

/// Create or edit a listing. When [existing] is null we create a new one;
/// otherwise we pre-fill the form and PATCH on save.
class ListingFormScreen extends ConsumerStatefulWidget {
  final Listing? existing;

  const ListingFormScreen({this.existing, super.key});

  @override
  ConsumerState<ListingFormScreen> createState() => _ListingFormScreenState();
}

class _ListingFormScreenState extends ConsumerState<ListingFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _price;
  late final TextEditingController _duration;
  late final TextEditingController _capacity;
  late final TextEditingController _stock;
  late final TextEditingController _hashtagInput;

  ListingType _type = ListingType.service;
  ListingStatus _status = ListingStatus.active;
  DateTime? _startsAt;
  DateTime? _endsAt;
  final List<String> _hashtags = [];

  /// Already-uploaded image URLs (watermarked) — either pre-existing on the
  /// edited listing, or freshly uploaded during this session.
  final List<String> _imageUrls = [];

  /// Uploads in flight; we render placeholders for these so the user sees
  /// progress without being able to submit until they finish.
  int _uploadsInFlight = 0;

  /// Hard-cap on attachable images per listing. The DB doesn't enforce a
  /// count (only a JSONB shape) but a sane UI limit keeps cards predictable.
  static const int _maxImages = 6;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title = TextEditingController(text: e?.title ?? '');
    _description = TextEditingController(text: e?.description ?? '');
    _price = TextEditingController(
      text: e == null ? '' : e.priceDollars.toStringAsFixed(2),
    );
    _duration = TextEditingController(
      text: e?.durationMinutes?.toString() ?? '',
    );
    _capacity = TextEditingController(text: e?.capacity?.toString() ?? '');
    _stock = TextEditingController(text: e?.stock?.toString() ?? '');
    _hashtagInput = TextEditingController();

    if (e != null) {
      _type = e.type;
      _status = e.status;
      _startsAt = e.startsAt;
      _endsAt = e.endsAt;
      _hashtags.addAll(e.hashtags);
      _imageUrls.addAll(e.images);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _price.dispose();
    _duration.dispose();
    _capacity.dispose();
    _stock.dispose();
    _hashtagInput.dispose();
    super.dispose();
  }

  // --- Save flow ------------------------------------------------------------

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    final priceCents = _parsePriceCents(_price.text);
    if (priceCents == null) {
      _showError('Enter a valid price (e.g. 12.50).');
      return;
    }

    if (_type == ListingType.event) {
      if (_startsAt == null || _endsAt == null) {
        _showError('Events need a start and end date.');
        return;
      }
      if (_endsAt!.isBefore(_startsAt!)) {
        _showError('End date must be after the start date.');
        return;
      }
    }

    if (_uploadsInFlight > 0) {
      _showError('Please wait for image uploads to finish.');
      return;
    }

    final controller = ref.read(listingFormControllerProvider.notifier);
    final ok = _isEdit
        ? await controller.updateListing(
            id: widget.existing!.id,
            type: _type,
            title: _title.text.trim(),
            description: _emptyToNull(_description.text),
            priceCents: priceCents,
            durationMinutes:
                _type == ListingType.service ? _parseInt(_duration.text) : null,
            capacity:
                _type == ListingType.event ? _parseInt(_capacity.text) : null,
            stock:
                _type == ListingType.item ? _parseInt(_stock.text) : null,
            hashtags: _hashtags,
            images: List.unmodifiable(_imageUrls),
            status: _status,
            startsAt: _type == ListingType.event ? _startsAt : null,
            endsAt: _type == ListingType.event ? _endsAt : null,
          )
        : await controller.createListing(
            type: _type,
            title: _title.text.trim(),
            description: _emptyToNull(_description.text),
            priceCents: priceCents,
            durationMinutes:
                _type == ListingType.service ? _parseInt(_duration.text) : null,
            capacity:
                _type == ListingType.event ? _parseInt(_capacity.text) : null,
            stock:
                _type == ListingType.item ? _parseInt(_stock.text) : null,
            hashtags: _hashtags,
            images: List.unmodifiable(_imageUrls),
            status: _status,
            startsAt: _type == ListingType.event ? _startsAt : null,
            endsAt: _type == ListingType.event ? _endsAt : null,
          );

    if (!mounted) return;
    if (ok) {
      final saved = ref.read(listingFormControllerProvider).lastSaved;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEdit ? 'Listing updated.' : 'Listing created.')),
      );
      // For edits we already have an id; for creates use lastSaved.
      final id = _isEdit ? widget.existing!.id : saved?.id;
      if (id != null) {
        ref.invalidate(listingByIdProvider(id));
        if (_isEdit) {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/listings/$id');
          }
        } else {
          context.go('/listings/$id');
        }
      } else {
        context.go('/listings');
      }
    } else {
      _showError(
        ref.read(listingFormControllerProvider).error ??
            'Could not save listing.',
      );
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // --- Hashtag input --------------------------------------------------------

  void _addHashtagFromInput() {
    final raw = _hashtagInput.text.trim();
    if (raw.isEmpty) return;
    final parts = raw
        .replaceAll('#', '')
        .split(RegExp(r'[,\s]+'))
        .map((s) => s.trim().toLowerCase())
        .where((s) => s.isNotEmpty);
    setState(() {
      for (final p in parts) {
        if (_hashtags.length >= 10) break;
        if (!_hashtags.contains(p)) _hashtags.add(p);
      }
      _hashtagInput.clear();
    });
  }

  void _removeHashtag(String tag) {
    setState(() => _hashtags.remove(tag));
  }

  // --- Image upload ---------------------------------------------------------

  Future<void> _addPhoto() async {
    if (_imageUrls.length + _uploadsInFlight >= _maxImages) {
      _showError('You can attach up to $_maxImages photos.');
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
            feature: ImageUploadFeature.listings,
            bytes: bytes,
          );
      if (!mounted) return;
      setState(() => _imageUrls.add(url));
    } catch (e) {
      if (!mounted) return;
      _showError('Could not upload photo. Try again.');
    } finally {
      if (mounted) setState(() => _uploadsInFlight--);
    }
  }

  void _removePhoto(String url) {
    setState(() => _imageUrls.remove(url));
  }

  // --- Date pickers ---------------------------------------------------------

  Future<void> _pickStartsAt() async {
    final picked = await _pickDateTime(_startsAt ?? DateTime.now());
    if (picked != null) setState(() => _startsAt = picked);
  }

  Future<void> _pickEndsAt() async {
    final base = _endsAt ?? _startsAt ?? DateTime.now();
    final picked = await _pickDateTime(base);
    if (picked != null) setState(() => _endsAt = picked);
  }

  Future<DateTime?> _pickDateTime(DateTime initial) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (date == null || !mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return null;
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  // --- Build ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final formState = ref.watch(listingFormControllerProvider);

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: c.textPrimary),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/listings');
            }
          },
        ),
        title: Text(
          _isEdit ? 'Edit listing' : 'New listing',
          style: GoogleFonts.outfit(
            color: c.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              _Label('Type'),
              const SizedBox(height: 8),
              _TypeSelector(
                value: _type,
                onChanged: (t) => setState(() => _type = t),
              ),
              const SizedBox(height: 6),
              Text(
                _type.hint,
                style: GoogleFonts.outfit(
                  color: c.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 22),
              _Label('Title'),
              const SizedBox(height: 8),
              _TextField(
                controller: _title,
                hint: 'A short, descriptive name',
                maxLength: 120,
                validator: (v) {
                  final t = v?.trim() ?? '';
                  if (t.length < 2) return 'Title must be at least 2 characters.';
                  if (t.length > 120) return 'Title must be 120 characters or fewer.';
                  return null;
                },
              ),
              const SizedBox(height: 18),
              _Label('Description (optional)'),
              const SizedBox(height: 8),
              _TextField(
                controller: _description,
                hint: 'What buyers should know before booking',
                minLines: 3,
                maxLines: 6,
                maxLength: 4000,
              ),
              const SizedBox(height: 18),
              _Label('Price (USD)'),
              const SizedBox(height: 8),
              _TextField(
                controller: _price,
                hint: '0.00',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                ],
                validator: (v) {
                  if (_parsePriceCents(v ?? '') == null) {
                    return 'Enter a valid price.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),
              ..._typeSpecificFields(),
              _Label('Hashtags (up to 10)'),
              const SizedBox(height: 8),
              _HashtagEditor(
                controller: _hashtagInput,
                tags: _hashtags,
                disabled: _hashtags.length >= 10,
                onSubmit: _addHashtagFromInput,
                onRemove: _removeHashtag,
              ),
              const SizedBox(height: 18),
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
              const SizedBox(height: 18),
              _Label('Status'),
              const SizedBox(height: 8),
              _StatusSelector(
                value: _status,
                onChanged: (s) => setState(() => _status = s),
              ),
              const SizedBox(height: 32),
              _PrimaryButton(
                label: _isEdit ? 'Save changes' : 'Publish listing',
                isLoading: formState.isSubmitting,
                onTap: formState.isSubmitting ? null : _onSave,
              ),
              const SizedBox(height: 12),
              if (_isEdit)
                Center(
                  child: TextButton(
                    onPressed: () => context.canPop()
                        ? context.pop()
                        : context.go('/listings'),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.outfit(
                        color: c.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _typeSpecificFields() {
    switch (_type) {
      case ListingType.service:
        return [
          _Label('Duration in minutes (optional)'),
          const SizedBox(height: 8),
          _TextField(
            controller: _duration,
            hint: 'e.g. 60',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: _validatePositiveIntOptional,
          ),
          const SizedBox(height: 18),
        ];
      case ListingType.item:
        return [
          _Label('Stock (optional)'),
          const SizedBox(height: 8),
          _TextField(
            controller: _stock,
            hint: 'How many you have available',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: _validateNonNegativeIntOptional,
          ),
          const SizedBox(height: 18),
        ];
      case ListingType.event:
        return [
          _Label('Capacity (optional)'),
          const SizedBox(height: 8),
          _TextField(
            controller: _capacity,
            hint: 'Max attendees',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: _validatePositiveIntOptional,
          ),
          const SizedBox(height: 18),
          _Label('Starts at'),
          const SizedBox(height: 8),
          _DateTimeRow(
            value: _startsAt,
            onTap: _pickStartsAt,
            placeholder: 'Pick a start date',
          ),
          const SizedBox(height: 18),
          _Label('Ends at'),
          const SizedBox(height: 8),
          _DateTimeRow(
            value: _endsAt,
            onTap: _pickEndsAt,
            placeholder: 'Pick an end date',
          ),
          const SizedBox(height: 18),
        ];
    }
  }

  // --- Validators -----------------------------------------------------------

  String? _validatePositiveIntOptional(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    final n = int.tryParse(v.trim());
    if (n == null || n <= 0) return 'Enter a positive whole number.';
    return null;
  }

  String? _validateNonNegativeIntOptional(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    final n = int.tryParse(v.trim());
    if (n == null || n < 0) return 'Enter a non-negative whole number.';
    return null;
  }

  String? _emptyToNull(String input) {
    final trimmed = input.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  int? _parseInt(String input) {
    final t = input.trim();
    if (t.isEmpty) return null;
    return int.tryParse(t);
  }
}

/// Convert "12", "12.5", "12.50" -> cents (integer). Returns null on garbage.
int? _parsePriceCents(String input) {
  final t = input.trim();
  if (t.isEmpty) return null;
  final v = double.tryParse(t);
  if (v == null || v < 0) return null;
  return (v * 100).round();
}

// ---------------------------------------------------------------------------
// Form widgets
// ---------------------------------------------------------------------------

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

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int? minLines;
  final int? maxLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final FormFieldValidator<String>? validator;

  const _TextField({
    required this.controller,
    required this.hint,
    this.minLines,
    this.maxLines = 1,
    this.maxLength,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return TextFormField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: GoogleFonts.outfit(color: c.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.outfit(color: c.textMuted, fontSize: 15),
        filled: true,
        fillColor: c.inputBg,
        counterText: '',
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
          borderSide:
              const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
    );
  }
}

class _TypeSelector extends StatelessWidget {
  final ListingType value;
  final ValueChanged<ListingType> onChanged;
  const _TypeSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final t in ListingType.values) ...[
          Expanded(
            child: _TypeChip(
              type: t,
              active: value == t,
              onTap: () => onChanged(t),
            ),
          ),
          if (t != ListingType.values.last) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  final ListingType type;
  final bool active;
  final VoidCallback onTap;
  const _TypeChip({
    required this.type,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final icon = switch (type) {
      ListingType.service => Icons.handyman_outlined,
      ListingType.item => Icons.shopping_bag_outlined,
      ListingType.event => Icons.event_outlined,
    };
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: active ? AppColors.accentDim : c.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? AppColors.accent : c.border,
            width: active ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: active ? AppColors.accent : c.textSecondary,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              type.displayName,
              style: GoogleFonts.outfit(
                color: active ? AppColors.accent : c.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusSelector extends StatelessWidget {
  final ListingStatus value;
  final ValueChanged<ListingStatus> onChanged;
  const _StatusSelector({required this.value, required this.onChanged});

  /// We deliberately surface only the three states a business owner picks.
  /// `soldOut` is generally set by the booking flow once stock hits zero;
  /// `removed` is essentially a soft delete — for V1 we use hard delete.
  static const _options = [
    ListingStatus.active,
    ListingStatus.draft,
    ListingStatus.paused,
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final s in _options) ...[
          Expanded(
            child: _StatusChip(
              status: s,
              active: value == s,
              onTap: () => onChanged(s),
            ),
          ),
          if (s != _options.last) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final ListingStatus status;
  final bool active;
  final VoidCallback onTap;

  const _StatusChip({
    required this.status,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppColors.accentDim : c.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? AppColors.accent : c.border,
            width: active ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          status.displayName,
          style: GoogleFonts.outfit(
            color: active ? AppColors.accent : c.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _HashtagEditor extends StatelessWidget {
  final TextEditingController controller;
  final List<String> tags;
  final bool disabled;
  final VoidCallback onSubmit;
  final void Function(String tag) onRemove;

  const _HashtagEditor({
    required this.controller,
    required this.tags,
    required this.disabled,
    required this.onSubmit,
    required this.onRemove,
  });

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
                enabled: !disabled,
                style:
                    GoogleFonts.outfit(color: c.textPrimary, fontSize: 15),
                onSubmitted: (_) => onSubmit(),
                decoration: InputDecoration(
                  hintText: disabled
                      ? 'Maximum reached'
                      : 'handmade, vintage  (comma to add)',
                  hintStyle:
                      GoogleFonts.outfit(color: c.textMuted, fontSize: 14),
                  filled: true,
                  fillColor: c.inputBg,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
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
                    borderSide:
                        const BorderSide(color: AppColors.accent, width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton(
              onPressed: disabled ? null : onSubmit,
              icon: const Icon(Icons.add_circle, color: AppColors.accent),
              tooltip: 'Add',
            ),
          ],
        ),
        if (tags.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in tags)
                InputChip(
                  label: Text('#$t', style: GoogleFonts.outfit(fontSize: 12)),
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

class _DateTimeRow extends StatelessWidget {
  final DateTime? value;
  final VoidCallback onTap;
  final String placeholder;

  const _DateTimeRow({
    required this.value,
    required this.onTap,
    required this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: c.inputBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.border),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 18, color: c.textSecondary),
            const SizedBox(width: 12),
            Text(
              value == null ? placeholder : _format(value!),
              style: GoogleFonts.outfit(
                color: value == null ? c.textMuted : c.textPrimary,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _format(DateTime dt) {
    final local = dt.toLocal();
    final mm = local.month.toString().padLeft(2, '0');
    final dd = local.day.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final mi = local.minute.toString().padLeft(2, '0');
    return '${local.year}-$mm-$dd $hh:$mi';
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onTap;

  const _PrimaryButton({
    required this.label,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final disabled = onTap == null;
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 120),
        opacity: disabled ? 0.6 : 1.0,
        child: Container(
          height: 54,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.25),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: isLoading
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(c.bg),
                  ),
                )
              : Text(
                  label,
                  style: GoogleFonts.outfit(
                    color: c.bg,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
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
        _PhotoTile(
          url: url,
          onRemove: () => onRemove(url),
        ),
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
              border: Border.all(color: c.border, style: BorderStyle.solid),
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

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tiles,
    );
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
