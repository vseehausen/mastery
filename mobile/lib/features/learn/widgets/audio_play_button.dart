import 'package:flutter/material.dart';

/// Compact speaker icon button for replaying word pronunciation.
/// Renders nothing when audioUrl is null.
class AudioPlayButton extends StatelessWidget {
  const AudioPlayButton({
    super.key,
    required this.audioUrl,
    required this.onPlay,
  });

  final String? audioUrl;
  final VoidCallback? onPlay;

  @override
  Widget build(BuildContext context) {
    if (audioUrl == null) return const SizedBox.shrink();

    return IconButton(
      icon: const Icon(Icons.volume_up, size: 20),
      onPressed: onPlay,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
    );
  }
}
