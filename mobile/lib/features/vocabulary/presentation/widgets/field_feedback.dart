import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/supabase_provider.dart';
import '../../../../core/theme/text_styles.dart';

/// Per-field rating row widget with thumbs up/down and flag icon buttons.
/// Shows current rating state and allows flagging issues via modal bottom sheet.
class FieldFeedback extends ConsumerStatefulWidget {
  const FieldFeedback({
    super.key,
    required this.meaningId,
    required this.fieldName,
    required this.userId,
    this.existingFeedback,
  });

  final String meaningId;
  final String fieldName;
  final String userId;
  final Map<String, dynamic>? existingFeedback;

  @override
  ConsumerState<FieldFeedback> createState() => _FieldFeedbackState();
}

class _FieldFeedbackState extends ConsumerState<FieldFeedback> {
  String? _currentRating;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.existingFeedback?['rating'] as String?;
  }

  Future<void> _submitFeedback(String rating) async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final service = ref.read(supabaseDataServiceProvider);
      await service.createEnrichmentFeedback(
        userId: widget.userId,
        meaningId: widget.meaningId,
        fieldName: widget.fieldName,
        rating: rating,
      );

      setState(() {
        _currentRating = rating;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Feedback saved'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save feedback: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _showFlagSheet() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => _FlagIssueSheet(fieldName: widget.fieldName),
    );

    if (result != null && mounted) {
      setState(() {
        _isSaving = true;
      });

      try {
        final service = ref.read(supabaseDataServiceProvider);
        await service.createEnrichmentFeedback(
          userId: widget.userId,
          meaningId: widget.meaningId,
          fieldName: widget.fieldName,
          rating: 'down',
          flagCategory: result,
        );

        setState(() {
          _currentRating = 'down';
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Issue reported: $result'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to report issue: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Thumbs up
        IconButton(
          icon: Icon(
            _currentRating == 'up'
                ? Icons.thumb_up
                : Icons.thumb_up_outlined,
            size: 16,
          ),
          onPressed: _isSaving ? null : () => _submitFeedback('up'),
          color: _currentRating == 'up'
              ? Colors.green
              : (isDark ? Colors.white54 : Colors.black54),
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: 32,
            minHeight: 32,
          ),
        ),

        const SizedBox(width: 4),

        // Thumbs down
        IconButton(
          icon: Icon(
            _currentRating == 'down'
                ? Icons.thumb_down
                : Icons.thumb_down_outlined,
            size: 16,
          ),
          onPressed: _isSaving ? null : () => _submitFeedback('down'),
          color: _currentRating == 'down'
              ? Colors.red
              : (isDark ? Colors.white54 : Colors.black54),
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: 32,
            minHeight: 32,
          ),
        ),

        const SizedBox(width: 4),

        // Flag
        IconButton(
          icon: const Icon(
            Icons.flag_outlined,
            size: 16,
          ),
          onPressed: _isSaving ? null : _showFlagSheet,
          color: isDark ? Colors.white54 : Colors.black54,
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: 32,
            minHeight: 32,
          ),
        ),
      ],
    );
  }
}

/// Modal bottom sheet for selecting flag category
class _FlagIssueSheet extends StatelessWidget {
  const _FlagIssueSheet({required this.fieldName});

  final String fieldName;

  static const _categories = [
    'Wrong Translation',
    'Inaccurate Definition',
    'Bad Synonyms',
    'Wrong Part of Speech',
    'Missing Context',
    'Confusables Wrong',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Report Issue',
              style: MasteryTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'What\'s wrong with this $fieldName?',
              style: MasteryTextStyles.bodySmall.copyWith(
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 24),
            ..._categories.map((category) {
              return Column(
                children: [
                  ListTile(
                    title: Text(
                      category,
                      style: MasteryTextStyles.body,
                    ),
                    onTap: () => Navigator.of(context).pop(category),
                    contentPadding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                  const Divider(height: 1),
                ],
              );
            }),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
