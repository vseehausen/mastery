import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../providers/dev_mode_provider.dart';

/// Developer information panel for debugging and monitoring.
///
/// Shows enrichment metadata when dev mode is enabled:
/// - Confidence score and source
/// - Created/updated timestamps
/// - Enrichment queue status (if available)
class DevInfoPanel extends ConsumerWidget {
  const DevInfoPanel({super.key, required this.meaning, this.queueStatus});

  final Map<String, dynamic> meaning;
  final Map<String, dynamic>? queueStatus;

  static final _dateFormat = DateFormat('MMM d, yyyy HH:mm');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDevMode = ref.watch(devModeProvider);

    if (!isDevMode) {
      return const SizedBox.shrink();
    }

    final colors = context.masteryColors;
    final confidence = (meaning['confidence'] as num?)?.toDouble() ?? 1.0;
    final source = meaning['source'] as String? ?? 'ai';
    final createdAt = _parseDateTime(meaning['created_at']);
    final updatedAt = _parseDateTime(meaning['updated_at']);

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: colors.border, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // DEV badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.warningMuted,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'DEV',
                  style: MasteryTextStyles.caption.copyWith(
                    color: colors.warning,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Confidence and source
          _buildInfoRow(
            'Confidence',
            '${(confidence * 100).toStringAsFixed(0)}%',
            colors,
          ),
          const SizedBox(height: 4),
          _buildInfoRow('Source', source, colors),

          // Timestamps
          if (createdAt != null) ...[
            const SizedBox(height: 4),
            _buildInfoRow('Created', _dateFormat.format(createdAt), colors),
          ],
          if (updatedAt != null) ...[
            const SizedBox(height: 4),
            _buildInfoRow('Updated', _dateFormat.format(updatedAt), colors),
          ],

          // Queue status (if provided)
          if (queueStatus != null) ...[
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            _buildInfoRow(
              'Queue Status',
              queueStatus!['status'] as String? ?? 'unknown',
              colors,
            ),
            if (queueStatus!['position'] != null) ...[
              const SizedBox(height: 4),
              _buildInfoRow(
                'Position',
                queueStatus!['position'].toString(),
                colors,
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, MasteryColorScheme colors) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: MasteryTextStyles.caption.copyWith(
              color: colors.mutedForeground,
              fontFamily: 'monospace',
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: MasteryTextStyles.caption.copyWith(
              color: colors.foreground,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}
