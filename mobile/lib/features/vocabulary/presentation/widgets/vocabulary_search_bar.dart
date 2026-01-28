import 'package:flutter/material.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor =
        isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey[300];

    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Search words...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: controller?.text.isNotEmpty ?? false
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  controller?.clear();
                  onClear?.call();
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor ?? Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor ?? Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }
}
