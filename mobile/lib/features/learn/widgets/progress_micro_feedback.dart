import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:mastery/core/theme/color_tokens.dart';
import 'package:mastery/domain/models/progress_stage.dart';

/// Displays brief micro-feedback when a word transitions to a new progress stage.
///
/// Shows an animated badge overlay for 2.5 seconds with the word and stage name.
/// Fades in (300ms) → Holds (2000ms) → Fades out (400ms).
///
/// Format:
/// - Standard stages: "word → Stage"
/// - Mastered: "word — Mastered."
///
/// Designed to be non-intrusive and contextual - appears near the card being reviewed.
/// Follows the "minimal cognitive noise" design principle.
class ProgressMicroFeedback extends StatefulWidget {
  const ProgressMicroFeedback({
    required this.stage,
    required this.wordText,
    super.key,
  });

  /// The progress stage to display.
  final ProgressStage stage;

  /// The word that progressed.
  final String wordText;

  @override
  State<ProgressMicroFeedback> createState() => _ProgressMicroFeedbackState();
}

class _ProgressMicroFeedbackState extends State<ProgressMicroFeedback> {
  bool _visible = false;
  Timer? _fadeInTimer;
  Timer? _fadeOutTimer;

  @override
  void initState() {
    super.initState();

    // Fade in after 100ms delay
    _fadeInTimer = Timer(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() => _visible = true);
        // Announce to screen readers
        final announcement = widget.stage == ProgressStage.mastered
            ? '${widget.wordText} — Mastered'
            : '${widget.wordText} moved to ${widget.stage.displayName}';
        // ignore: deprecated_member_use
        SemanticsService.announce(
          announcement,
          TextDirection.ltr,
        );
      }
    });

    // Fade out after 2600ms total (100ms delay + 2500ms visible)
    _fadeOutTimer = Timer(const Duration(milliseconds: 2600), () {
      if (mounted) {
        setState(() => _visible = false);
      }
    });
  }

  @override
  void dispose() {
    _fadeInTimer?.cancel();
    _fadeOutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.masteryColors;

    // Format: "word → Stage" or "word — Mastered."
    final text = widget.stage == ProgressStage.mastered
        ? '${widget.wordText} — Mastered.'
        : '${widget.wordText} → ${widget.stage.displayName}';

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: _visible ? 1.0 : 0.0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: widget.stage.getColor(colors),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
