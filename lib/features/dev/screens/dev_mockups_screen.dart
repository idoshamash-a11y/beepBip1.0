import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/theme/app_colors.dart';

/// Dev-only screen that talks to the `dev-seed-mockups` Edge Function so a
/// developer can populate or wipe mockup accounts (4 personal + 6 business)
/// with one tap. Reachable from a debug-build-only tile on the profile
/// screen — the route itself also early-returns on release builds so a
/// stray push to `/dev/mockups` in production is harmless.
class DevMockupsScreen extends ConsumerStatefulWidget {
  const DevMockupsScreen({super.key});

  @override
  ConsumerState<DevMockupsScreen> createState() => _DevMockupsScreenState();
}

enum _Action { load, clear, reload, status }

class _DevMockupsState {
  const _DevMockupsState({
    this.busyAction,
    this.summary,
    this.lastAction,
    this.error,
  });

  final _Action? busyAction;
  final Map<String, int>? summary;
  final _Action? lastAction;
  final String? error;

  bool get isBusy => busyAction != null;

  _DevMockupsState copyWith({
    _Action? busyAction,
    bool clearBusy = false,
    Map<String, int>? summary,
    _Action? lastAction,
    String? error,
    bool clearError = false,
  }) {
    return _DevMockupsState(
      busyAction: clearBusy ? null : (busyAction ?? this.busyAction),
      summary: summary ?? this.summary,
      lastAction: lastAction ?? this.lastAction,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class _DevMockupsScreenState extends ConsumerState<DevMockupsScreen> {
  _DevMockupsState _state = const _DevMockupsState();

  @override
  void initState() {
    super.initState();
    // Pull initial counts so the user can see whether mockups are already
    // loaded before they decide what to do.
    if (kDebugMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _invoke(_Action.status));
    }
  }

  Future<void> _invoke(_Action action) async {
    if (_state.isBusy) return;
    setState(() => _state = _state.copyWith(busyAction: action, clearError: true));

    try {
      final response = await Supabase.instance.client.functions.invoke(
        'dev-seed-mockups',
        body: {'action': action.name},
      );
      final data = response.data;
      if (data is! Map) {
        throw StateError('Unexpected response: $data');
      }
      if (data['ok'] != true) {
        throw StateError(data['error']?.toString() ?? 'unknown_error');
      }
      final summary = (data['summary'] as Map?)?.map(
        (k, v) => MapEntry(k.toString(), (v as num).toInt()),
      );
      if (!mounted) return;
      setState(() => _state = _state.copyWith(
            clearBusy: true,
            summary: summary,
            lastAction: action,
            clearError: true,
          ));
    } catch (e, st) {
      AppLogger.e('dev-seed-mockups call failed',
          tag: 'dev', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() => _state = _state.copyWith(
            clearBusy: true,
            error: e.toString(),
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const Scaffold(
        body: Center(child: Text('Dev tools are disabled in release builds.')),
      );
    }

    final c = context.colors;
    final summary = _state.summary;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        elevation: 0,
        title: Text(
          'Dev · Mockup accounts',
          style: GoogleFonts.outfit(
            color: c.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: IconThemeData(color: c.textPrimary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Banner(c: c),
              const SizedBox(height: 16),
              _SummaryCard(c: c, summary: summary, busy: _state.isBusy),
              const SizedBox(height: 16),
              if (_state.error != null) ...[
                _ErrorCard(c: c, message: _state.error!),
                const SizedBox(height: 16),
              ],
              _ActionTile(
                c: c,
                title: 'Load mockup accounts',
                subtitle:
                    '4 personal + 6 business (goods, service, events) with photos, hours, and listings.',
                icon: Icons.cloud_download_outlined,
                primary: true,
                busy: _state.busyAction == _Action.load,
                disabled: _state.isBusy,
                onTap: () => _invoke(_Action.load),
              ),
              const SizedBox(height: 10),
              _ActionTile(
                c: c,
                title: 'Reload (clear + load)',
                subtitle:
                    'Wipe all current mockups and re-seed from scratch. Use this after editing the dataset.',
                icon: Icons.refresh_rounded,
                primary: false,
                busy: _state.busyAction == _Action.reload,
                disabled: _state.isBusy,
                onTap: () => _invoke(_Action.reload),
              ),
              const SizedBox(height: 10),
              _ActionTile(
                c: c,
                title: 'Clear all mockup accounts',
                subtitle:
                    'Delete every account whose email ends with @mockup.beepbip. Real accounts are untouched.',
                icon: Icons.delete_sweep_outlined,
                primary: false,
                destructive: true,
                busy: _state.busyAction == _Action.clear,
                disabled: _state.isBusy,
                onTap: () => _confirmAndInvoke(_Action.clear),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: _state.isBusy ? null : () => _invoke(_Action.status),
                icon: Icon(Icons.refresh, color: c.textSecondary, size: 16),
                label: Text(
                  'Refresh counts',
                  style: GoogleFonts.outfit(color: c.textSecondary, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmAndInvoke(_Action action) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear mockup accounts?'),
        content: const Text(
          'This deletes every auth user whose email ends with '
          '@mockup.beepbip and cascades through profiles, listings, and posts.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _invoke(action);
    }
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.c});
  final AppColors c;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.science_outlined,
              color: AppColors.accent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Dev-only utility. The Edge Function refuses to run unless '
              'SUPABASE_URL is local — this button is safe in release builds '
              'too, but the screen is hidden there anyway.',
              style: GoogleFonts.outfit(
                color: c.textSecondary,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.c,
    required this.summary,
    required this.busy,
  });
  final AppColors c;
  final Map<String, int>? summary;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final s = summary;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.people_alt_outlined,
                  color: AppColors.accent, size: 18),
              const SizedBox(width: 8),
              Text(
                'Current mockups',
                style: GoogleFonts.outfit(
                  color: c.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (busy)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.accent,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _Stat(label: 'Personal', value: s?['personal'], c: c),
              _StatDivider(c: c),
              _Stat(label: 'Business', value: s?['business'], c: c),
              _StatDivider(c: c),
              _Stat(label: 'Listings', value: s?['listings'], c: c),
              _StatDivider(c: c),
              _Stat(label: 'Posts', value: s?['posts'], c: c),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.c});
  final String label;
  final int? value;
  final AppColors c;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value?.toString() ?? '—',
            style: GoogleFonts.outfit(
              color: c.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.outfit(color: c.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider({required this.c});
  final AppColors c;
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 32, color: c.border);
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.c,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.primary,
    required this.busy,
    required this.disabled,
    required this.onTap,
    this.destructive = false,
  });

  final AppColors c;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool primary;
  final bool busy;
  final bool disabled;
  final bool destructive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = destructive ? AppColors.error : AppColors.accent;
    final bg = primary
        ? accent
        : (destructive
            ? AppColors.error.withValues(alpha: 0.06)
            : c.surface);
    final fg = primary ? c.bg : c.textPrimary;
    final border = primary
        ? Colors.transparent
        : (destructive
            ? AppColors.error.withValues(alpha: 0.4)
            : c.border);
    final iconColor = primary ? c.bg : accent;
    final subColor =
        primary ? c.bg.withValues(alpha: 0.7) : c.textSecondary;

    return Opacity(
      opacity: disabled && !busy ? 0.55 : 1,
      child: GestureDetector(
        onTap: disabled ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
            boxShadow: primary
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.25),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: primary
                      ? c.bg.withValues(alpha: 0.18)
                      : (destructive
                          ? AppColors.error.withValues(alpha: 0.1)
                          : c.surface2),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: busy
                    ? Padding(
                        padding: const EdgeInsets.all(10),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: iconColor,
                        ),
                      )
                    : Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        color: fg,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: GoogleFonts.outfit(
                        color: subColor,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.arrow_forward_ios_rounded,
                  color: primary ? c.bg : c.textSecondary, size: 13),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.c, required this.message});
  final AppColors c;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline,
              color: AppColors.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.outfit(
                color: c.textPrimary,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
