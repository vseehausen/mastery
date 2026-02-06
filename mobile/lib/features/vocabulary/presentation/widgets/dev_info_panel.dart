import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../providers/dev_mode_provider.dart';

/// Developer information panel for debugging and monitoring.
///
/// Shows enrichment metadata when dev mode is enabled:
/// - Confidence score and source
/// - Created/updated timestamps
/// - Enrichment queue status (if available)
class DevInfoPanel extends ConsumerWidget {
  const DevInfoPanel({
    super.key,
    required this.meaning,
    this.queueStatus,
  });

  final Map<String, dynamic> meaning;
  final Map<String, dynamic>? queueStatus;

  static final _dateFormat = DateFormat('MMM d, yyyy HH:mm');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDevMode = ref.watch(devModeProvider);

    if (!isDevMode) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confidence = (meaning['confidence'] as num?)?.toDouble() ?? 1.0;
    final source = meaning['source'] as String? ?? 'ai';
    final createdAt = _parseDateTime(meaning['created_at']);
    final updatedAt = _parseDateTime(meaning['updated_at']);

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          width: 1,
        ),
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
                  color: isDark ? Colors.orange[900] : Colors.orange[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'DEV',
                  style: MasteryTextStyles.caption.copyWith(
                    color: isDark ? Colors.orange[200] : Colors.orange[900],
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
            isDark,
          ),
          const SizedBox(height: 4),
          _buildInfoRow('Source', source, isDark),

          // Timestamps
          if (createdAt != null) ...[
            const SizedBox(height: 4),
            _buildInfoRow('Created', _dateFormat.format(createdAt), isDark),
          ],
          if (updatedAt != null) ...[
            const SizedBox(height: 4),
            _buildInfoRow('Updated', _dateFormat.format(updatedAt), isDark),
          ],

          // Queue status (if provided)
          if (queueStatus != null) ...[
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            _buildInfoRow(
              'Queue Status',
              queueStatus!['status'] as String? ?? 'unknown',
              isDark,
            ),
            if (queueStatus!['position'] != null) ...[
              const SizedBox(height: 4),
              _buildInfoRow(
                'Position',
                queueStatus!['position'].toString(),
                isDark,
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: MasteryTextStyles.caption.copyWith(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontFamily: 'monospace',
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: MasteryTextStyles.caption.copyWith(
              color: isDark ? Colors.grey[300] : Colors.grey[800],
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
