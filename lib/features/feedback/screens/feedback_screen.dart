import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

class FeedbackScreen extends StatefulWidget {
  final String? targetUserId;
  final String? targetUserName;
  const FeedbackScreen({super.key, this.targetUserId, this.targetUserName});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  String? _selectedType;
  int _rating = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _submitted = false;

  final List<_FeedbackOption> _options = [
    _FeedbackOption(type: 'positive', icon: Icons.thumb_up_outlined, label: 'Positive', color: AppColors.success),
    _FeedbackOption(type: 'neutral', icon: Icons.thumbs_up_down_outlined, label: 'Neutral', color: Colors.grey),
    _FeedbackOption(type: 'negative', icon: Icons.thumb_down_outlined, label: 'Negative', color: AppColors.error),
    _FeedbackOption(type: 'spam', icon: Icons.report_outlined, label: 'Spam', color: Colors.orangeAccent),
    _FeedbackOption(type: 'suggestion', icon: Icons.lightbulb_outlined, label: 'Suggestion', color: AppColors.accent),
  ];

  final List<_HistoryItem> _history = [
    _HistoryItem(type: 'positive', comment: 'Great experience meeting nearby!', date: '2 days ago', icon: Icons.thumb_up_outlined, color: AppColors.success),
    _HistoryItem(type: 'suggestion', comment: 'Would love a filter for business posts.', date: '1 week ago', icon: Icons.lightbulb_outlined, color: AppColors.accent),
  ];

  void _submit() {
    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please select a feedback type', style: GoogleFonts.outfit()),
        backgroundColor: context.colors.surface,
      ));
      return;
    }
    setState(() => _submitted = true);
  }

  @override
  void dispose() { _commentController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: c.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.targetUserName != null ? 'Feedback for ${widget.targetUserName}' : 'Send Feedback',
          style: GoogleFonts.outfit(color: c.textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: c.border),
        ),
      ),
      body: _submitted ? _buildSuccess(c) : _buildForm(c),
    );
  }

  Widget _buildForm(AppColors c) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats card
          Container(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
            decoration: BoxDecoration(
              color: c.surface, borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _Stat(value: '48', label: 'Total', icon: Icons.feedback_outlined, c: c),
                Container(width: 1, height: 36, color: c.border),
                _Stat(value: '87%', label: 'Positive', icon: Icons.sentiment_satisfied_alt_rounded, c: c),
                Container(width: 1, height: 36, color: c.border),
                _Stat(value: '4.6', label: 'Rating', icon: Icons.star_outline_rounded, c: c),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text('How was your experience?',
              style: GoogleFonts.outfit(color: c.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10, runSpacing: 10,
            children: _options.map((opt) {
              final selected = _selectedType == opt.type;
              return GestureDetector(
                onTap: () => setState(() => _selectedType = opt.type),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? opt.color.withValues(alpha: 0.12) : c.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected ? opt.color : c.border,
                      width: selected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(opt.icon, color: selected ? opt.color : c.textSecondary, size: 18),
                      const SizedBox(width: 6),
                      Text(opt.label,
                          style: GoogleFonts.outfit(
                            color: selected ? opt.color : c.textSecondary,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                            fontSize: 13,
                          )),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          Text('Rate your experience',
              style: GoogleFonts.outfit(color: c.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Row(
            children: List.generate(5, (i) => GestureDetector(
              onTap: () => setState(() => _rating = i + 1),
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(
                  i < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: i < _rating ? AppColors.accent : c.textSecondary,
                  size: 36,
                ),
              ),
            )),
          ),
          const SizedBox(height: 24),

          Text('Additional comments (optional)',
              style: GoogleFonts.outfit(color: c.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: c.inputBg, borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.border),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: TextField(
              controller: _commentController,
              style: GoogleFonts.outfit(color: c.textPrimary, fontSize: 14),
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Tell us more about your experience...',
                hintStyle: GoogleFonts.outfit(color: c.textSecondary, fontSize: 14),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text('Submit Feedback',
                  style: GoogleFonts.outfit(color: c.bg, fontWeight: FontWeight.w700, fontSize: 16)),
            ),
          ),

          if (_history.isNotEmpty) ...[
            const SizedBox(height: 32),
            Text('Your Feedback History',
                style: GoogleFonts.outfit(color: c.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            ..._history.map((item) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: c.surface, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.12), shape: BoxShape.circle),
                    child: Icon(item.icon, color: item.color, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.comment,
                            style: GoogleFonts.outfit(color: c.textPrimary, fontSize: 13)),
                        const SizedBox(height: 2),
                        Text(item.date,
                            style: GoogleFonts.outfit(color: c.textSecondary, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            )),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSuccess(AppColors c) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 48),
            ),
            const SizedBox(height: 24),
            Text('Thank You!',
                style: GoogleFonts.outfit(color: c.textPrimary, fontSize: 24, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Your feedback has been submitted successfully.',
                style: GoogleFonts.outfit(color: c.textSecondary, fontSize: 15),
                textAlign: TextAlign.center),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text('Back',
                  style: GoogleFonts.outfit(color: c.bg, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value, label;
  final IconData icon;
  final AppColors c;
  const _Stat({required this.value, required this.label, required this.icon, required this.c});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.accent, size: 20),
        const SizedBox(height: 5),
        Text(value, style: GoogleFonts.outfit(color: c.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
        Text(label, style: GoogleFonts.outfit(color: c.textSecondary, fontSize: 11)),
      ],
    );
  }
}

class _FeedbackOption {
  final String type, label;
  final IconData icon;
  final Color color;
  const _FeedbackOption({required this.type, required this.icon, required this.label, required this.color});
}

class _HistoryItem {
  final String type, comment, date;
  final IconData icon;
  final Color color;
  const _HistoryItem({required this.type, required this.comment, required this.date, required this.icon, required this.color});
}
