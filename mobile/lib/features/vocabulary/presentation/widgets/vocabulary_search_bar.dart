import 'package:flutter/material.dart';
import '../../../../core/theme/color_tokens.dart';

/// Search bar for vocabulary screen
class VocabularySearchBar extends StatelessWidget {
  const VocabularySearchBar({
    super.key,
    this.controller,
    this.onChanged,
    this.onClear,
  });

  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final colors = context.masteryColors;

    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Search words...',
        prefixIcon: Icon(Icons.search, color: colors.mutedForeground),
        suffixIcon: controller?.text.isNotEmpty ?? false
            ? IconButton(
                icon: Icon(Icons.close, color: colors.mutedForeground),
                onPressed: () {
                  controller?.clear();
                  onClear?.call();
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.ring, width: 2),
        ),
        filled: true,
        fillColor: colors.muted,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }
}
