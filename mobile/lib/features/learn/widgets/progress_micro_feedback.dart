import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:mastery/core/theme/color_tokens.dart';
import 'package:mastery/domain/models/progress_stage.dart';

/// Displays brief micro-feedback when a word transitions to a new progress stage.
///
/// Shows an animated badge overlay for 2.5 seconds with the stage name.
/// Fades in (300ms) → Holds (2000ms) → Fades out (400ms).
///
/// Designed to be non-intrusive and contextual - appears near the card being reviewed.
/// Follows the "minimal cognitive noise" design principle.
class ProgressMicroFeedback extends StatefulWidget {
  const ProgressMicroFeedback({
    required this.stage,
    super.key,
  });

  /// The progress stage to display.
  final ProgressStage stage;

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
        SemanticsService.announce(
          'Word progressing to ${widget.stage.displayName}',
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

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: _visible ? 1.0 : 0.0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: widget.stage.getColor(colors),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          widget.stage.displayName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
