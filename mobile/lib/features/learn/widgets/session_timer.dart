import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/color_tokens.dart';
import '../../../core/theme/text_styles.dart';

/// Widget displaying countdown timer for a learning session
/// Tracks elapsed time and shows remaining time
class SessionTimer extends StatefulWidget {
  const SessionTimer({
    super.key,
    required this.totalSeconds,
    required this.onTimeUp,
    required this.onTick,
    this.isPaused = false,
    this.initialElapsed = 0,
  });

  /// Total session duration in seconds
  final int totalSeconds;

  /// Callback when time is up
  final VoidCallback onTimeUp;

  /// Callback on each tick with elapsed seconds
  final ValueChanged<int> onTick;

  /// Whether the timer is paused
  final bool isPaused;

  /// Initial elapsed time (for resume)
  final int initialElapsed;

  @override
  State<SessionTimer> createState() => _SessionTimerState();
}

class _SessionTimerState extends State<SessionTimer> {
  Timer? _timer;
  late int _elapsedSeconds;

  @override
  void initState() {
    super.initState();
    _elapsedSeconds = widget.initialElapsed;
    _startTimer();
  }

  @override
  void didUpdateWidget(SessionTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPaused != oldWidget.isPaused) {
      if (widget.isPaused) {
        _stopTimer();
      } else {
        _startTimer();
      }
    }
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _elapsedSeconds++;
        });
        widget.onTick(_elapsedSeconds);

        if (_elapsedSeconds >= widget.totalSeconds) {
          _stopTimer();
          widget.onTimeUp();
        }
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final remainingSeconds = (widget.totalSeconds - _elapsedSeconds).clamp(0, widget.totalSeconds);
    final progress = _elapsedSeconds / widget.totalSeconds;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Progress indicator
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              strokeWidth: 3,
              backgroundColor: isDark ? MasteryColors.mutedDark : MasteryColors.mutedLight,
              valueColor: AlwaysStoppedAnimation<Color>(
                _getProgressColor(progress, isDark),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Time display
          Text(
            _formatTime(remainingSeconds),
            style: MasteryTextStyles.bodyBold.copyWith(
              fontSize: 18,
              fontFamily: 'monospace',
              color: _getProgressColor(progress, isDark),
            ),
          ),
          // Pause indicator
          if (widget.isPaused) ...[
            const SizedBox(width: 8),
            Icon(
              Icons.pause,
              size: 16,
              color: isDark ? MasteryColors.mutedForegroundDark : MasteryColors.mutedForegroundLight,
            ),
          ],
        ],
      ),
    );
  }

  Color _getProgressColor(double progress, bool isDark) {
    if (progress >= 0.9) {
      // Almost done - warning color
      return isDark ? MasteryColors.warningDark : MasteryColors.warningLight;
    } else if (progress >= 0.75) {
      // Getting close
      return isDark ? MasteryColors.accentDark : MasteryColors.accentLight;
    }
    // Normal
    return isDark ? MasteryColors.primaryDark : MasteryColors.primaryLight;
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
