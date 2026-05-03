import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../profile/models/business_hours_model.dart';
import '../../../profile/models/business_profile_model.dart';

/// "About" card — description + business hours accordion + contact row +
/// social handles chips.
class BusinessAboutSection extends StatelessWidget {
  const BusinessAboutSection({
    required this.business,
    required this.hours,
    super.key,
  });

  final BusinessProfileModel business;
  final List<BusinessHoursModel> hours;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final hasDescription = (business.description ?? '').isNotEmpty;
    final hasHours = hours.isNotEmpty;
    final hasContact = (business.phone ?? '').isNotEmpty ||
        (business.email ?? '').isNotEmpty ||
        (business.website ?? '').isNotEmpty;
    final hasSocials = business.socialHandles.isNotEmpty;

    if (!hasDescription && !hasHours && !hasContact && !hasSocials) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: c.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasDescription) ...[
              Text(
                business.description!,
                style: GoogleFonts.outfit(
                  color: c.textPrimary,
                  fontSize: 14,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 14),
            ],
            if (hasHours) ...[
              const _SectionHeader(label: 'Hours', icon: Icons.schedule),
              const SizedBox(height: 8),
              _HoursList(hours: hours),
              const SizedBox(height: 14),
            ],
            if (hasContact) ...[
              const _SectionHeader(
                  label: 'Contact', icon: Icons.alternate_email),
              const SizedBox(height: 8),
              if ((business.phone ?? '').isNotEmpty)
                _ContactLine(
                  icon: Icons.phone_outlined,
                  text: business.phone!,
                  uri: 'tel:${business.phone!}',
                ),
              if ((business.email ?? '').isNotEmpty)
                _ContactLine(
                  icon: Icons.mail_outline,
                  text: business.email!,
                  uri: 'mailto:${business.email!}',
                ),
              if ((business.website ?? '').isNotEmpty)
                _ContactLine(
                  icon: Icons.public,
                  text: business.website!,
                  uri: business.website!,
                ),
              const SizedBox(height: 14),
            ],
            if (hasSocials) ...[
              const _SectionHeader(
                  label: 'Follow', icon: Icons.share_outlined),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final entry in business.socialHandles.entries)
                    _SocialChip(
                      platform: entry.key,
                      handle: entry.value,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Icon(icon, size: 14, color: c.textSecondary),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.outfit(
            color: c.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}

class _HoursList extends StatelessWidget {
  const _HoursList({required this.hours});
  final List<BusinessHoursModel> hours;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // Today first to make the most useful row most prominent.
    final today = DateTime.now().weekday % 7; // 0=Sunday in our schema
    final ordered = [...hours]
      ..sort((a, b) {
        final ai = (a.dayOfWeek - today + 7) % 7;
        final bi = (b.dayOfWeek - today + 7) % 7;
        return ai.compareTo(bi);
      });

    return Column(
      children: [
        for (final h in ordered) ...[
          Row(
            children: [
              SizedBox(
                width: 96,
                child: Text(
                  h.dayOfWeek == today ? 'Today' : h.dayName,
                  style: GoogleFonts.outfit(
                    color: h.dayOfWeek == today
                        ? AppColors.accent
                        : c.textPrimary,
                    fontSize: 13,
                    fontWeight: h.dayOfWeek == today
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  h.hoursDisplay,
                  style: GoogleFonts.outfit(
                    color: c.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
      ],
    );
  }
}

class _ContactLine extends StatelessWidget {
  const _ContactLine({
    required this.icon,
    required this.text,
    required this.uri,
  });

  final IconData icon;
  final String text;
  final String uri;

  Future<void> _open() async {
    final parsed = Uri.tryParse(uri);
    if (parsed == null) return;
    if (await canLaunchUrl(parsed)) {
      await launchUrl(parsed, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: _open,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 16, color: c.textSecondary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.outfit(
                  color: c.textPrimary,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.open_in_new, size: 14, color: c.textMuted),
          ],
        ),
      ),
    );
  }
}

class _SocialChip extends StatelessWidget {
  const _SocialChip({required this.platform, required this.handle});

  final String platform;
  final String handle;

  /// Translate the handle stored in the JSONB into a launchable URL.
  /// Convention: handles are stored without the leading `@`. `website` is
  /// stored as a full URL.
  String? _resolveUri() {
    final p = platform.toLowerCase();
    final h = handle.replaceFirst(RegExp(r'^@'), '').trim();
    if (h.isEmpty) return null;
    return switch (p) {
      'instagram' => 'https://instagram.com/$h',
      'tiktok' => 'https://tiktok.com/@$h',
      'x' || 'twitter' => 'https://x.com/$h',
      'website' =>
        h.startsWith('http') ? h : 'https://$h',
      _ => null,
    };
  }

  Future<void> _open() async {
    final url = _resolveUri();
    if (url == null) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final iconData = switch (platform.toLowerCase()) {
      'instagram' => Icons.camera_alt_outlined,
      'tiktok' => Icons.music_video_outlined,
      'x' || 'twitter' => Icons.alternate_email,
      'website' => Icons.public,
      _ => Icons.link,
    };
    return InkWell(
      onTap: _open,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: c.surface2,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(iconData, size: 13, color: c.textSecondary),
            const SizedBox(width: 6),
            Text(
              platform == 'website'
                  ? handle
                  : '@${handle.replaceFirst(RegExp(r'^@'), '')}',
              style: GoogleFonts.outfit(
                color: c.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
