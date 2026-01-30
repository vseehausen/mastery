import 'planned_item.dart';

/// Value object representing a session plan
class SessionPlan {
  SessionPlan({
    required this.items,
    required this.estimatedDurationSeconds,
    required this.newWordCount,
    required this.reviewCount,
    required this.leechCount,
  });

  /// Create an empty session plan
  factory SessionPlan.empty() {
    return SessionPlan(
      items: [],
      estimatedDurationSeconds: 0,
      newWordCount: 0,
      reviewCount: 0,
      leechCount: 0,
    );
  }

  /// Ordered list of items to present
  final List<PlannedItem> items;

  /// Total estimated session time in seconds
  final int estimatedDurationSeconds;

  /// Number of new words included
  final int newWordCount;

  /// Number of reviews included
  final int reviewCount;

  /// Number of leeches included
  final int leechCount;

  /// Total number of items
  int get totalItems => items.length;

  /// Whether the plan is empty
  bool get isEmpty => items.isEmpty;

  /// Whether the plan has items
  bool get isNotEmpty => items.isNotEmpty;

  /// Get estimated duration in minutes
  double get estimatedDurationMinutes => estimatedDurationSeconds / 60.0;

  /// Get item at index (returns null if out of bounds)
  PlannedItem? getItemAt(int index) {
    if (index < 0 || index >= items.length) return null;
    return items[index];
  }

  /// Get remaining items from index
  List<PlannedItem> getRemainingItems(int fromIndex) {
    if (fromIndex < 0 || fromIndex >= items.length) return [];
    return items.sublist(fromIndex);
  }

  @override
  String toString() {
    return 'SessionPlan('
        'items: ${items.length}, '
        'duration: ${estimatedDurationSeconds}s, '
        'new: $newWordCount, '
        'reviews: $reviewCount, '
        'leeches: $leechCount)';
  }
}
