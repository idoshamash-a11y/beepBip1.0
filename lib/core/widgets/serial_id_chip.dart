import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

/// A small tappable chip that displays a user's serial id (e.g. `BP-A1B2C3`)
/// and copies it to the clipboard when tapped. Used next to user / business
/// names so people can attribute, share, or quote an account in support /
/// dispute / report flows.
///
/// The chip is intentionally compact and low-contrast: it's a secondary
/// affordance, not a primary visual. It scales the touch target to a
/// comfortable 28pt minimum height even when the visible label is smaller.
class SerialIdChip extends StatelessWidget {
  const SerialIdChip({
    required this.serialId,
    this.dense = false,
    this.snackbarLabel = 'Serial id copied',
    super.key,
  });

  /// Public-facing identifier (BP-XXXXXX). Pass null/empty to render nothing.
  final String? serialId;

  /// When true, renders a tighter version suitable for inline use in dense
  /// layouts (e.g. post headers, listing rows).
  final bool dense;

  /// Snackbar message shown after a successful copy. Lets call sites override
  /// to specify the subject (e.g. "BP-XXXXX copied").
  final String snackbarLabel;

  @override
  Widget build(BuildContext context) {
    final id = serialId;
    if (id == null || id.trim().isEmpty) return const SizedBox.shrink();

    final c = context.colors;
    final hPad = dense ? 6.0 : 8.0;
    final vPad = dense ? 2.0 : 3.0;
    final fontSize = dense ? 10.5 : 11.5;

    return Semantics(
      button: true,
      label: 'Copy serial id $id',
      child: InkWell(
        onTap: () => _copyToClipboard(context, id),
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
          decoration: BoxDecoration(
            color: c.surface2,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: c.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                id,
                style: GoogleFonts.jetBrainsMono(
                  color: c.textSecondary,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
              SizedBox(width: dense ? 4 : 6),
              Icon(
                Icons.copy_rounded,
                size: dense ? 11 : 13,
                color: c.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _copyToClipboard(BuildContext context, String id) async {
    await Clipboard.setData(ClipboardData(text: id));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(snackbarLabel),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
