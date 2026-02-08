# Quickstart: Word-Level Progress & Motivation

**Feature**: 006-word-progress
**For**: Developers implementing word progress tracking
**Prerequisites**: Flutter 3.x, Supabase setup, familiarity with Riverpod

## 30-Second Overview

Add competence-based progress tracking for vocabulary words. Words progress through 5 stages (Captured → Practicing → Stabilizing → Active → Mastered) based on user-driven learning events. Display real-time micro-feedback during sessions and post-session recaps.

---

## Architecture at a Glance

```
User reviews word
       ↓
Calculate stage BEFORE review (from FSRS metrics)
       ↓
Submit grade → Update FSRS state
       ↓
Calculate stage AFTER review
       ↓
Stage changed? → Show micro-feedback + Track transition
       ↓
Session ends → Show recap card
```

**Key Principle**: Stage calculation is deterministic (no ML, no randomness). Computed client-side from FSRS metrics + review history.

---

## Quick Start Steps

### 1. Run Migration (Backend)

```bash
cd supabase
supabase db push
# Applies migration: 20260208_add_progress_tracking.sql
# Adds progress_stage column to learning_cards table
```

### 2. Add ProgressStage Enum (Mobile)

**File**: `mobile/lib/domain/models/progress_stage.dart`

```dart
enum ProgressStage {
  captured,
  practicing,
  stabilizing,
  active,
  mastered;

  String get displayName {
    switch (this) {
      case captured: return 'Captured';
      case practicing: return 'Practicing';
      case stabilizing: return 'Stabilizing';
      case active: return 'Active';
      case mastered: return 'Mastered';
    }
  }
}
```

### 3. Implement Stage Calculation Service

**File**: `mobile/lib/data/services/progress_stage_service.dart`

```dart
class ProgressStageService {
  ProgressStage calculateStage({
    required LearningCard? card,
    required int nonTranslationSuccessCount,
  }) {
    // No card yet → Captured (word exists but not reviewed)
    if (card == null) {
      return ProgressStage.captured;
    }

    // Has reviews → Check stability/reps/lapses (all user-driven)
    if (card.stability >= 90 && card.reps >= 12 && card.lapses <= 1 && card.state == 2) {
      return ProgressStage.mastered;
    }

    if (card.stability >= 1.0 && card.reps >= 3 && card.lapses <= 2 && card.state == 2) {
      if (nonTranslationSuccessCount >= 1) {
        return ProgressStage.active;
      }
      return ProgressStage.stabilizing;
    }

    if (card.reps >= 1) {
      return ProgressStage.practicing;
    }

    return ProgressStage.captured;
  }
}
```

### 4. Track Transitions During Session

**File**: `mobile/lib/features/learn/providers/session_provider.dart` (extend existing)

```dart
class SessionState {
  final List<StageTransition> transitions = [];

  void recordReview(LearningCard card, int grade) {
    final stageBefore = _calculateStage(card);

    // Submit grade to FSRS (existing logic)
    final updatedCard = fsrsService.processReview(card, grade);

    final stageAfter = _calculateStage(updatedCard);

    if (stageBefore != stageAfter) {
      transitions.add(StageTransition(
        vocabularyId: card.vocabularyId,
        wordText: card.word,
        fromStage: stageBefore,
        toStage: stageAfter,
        timestamp: DateTime.now(),
      ));
      _showMicroFeedback(stageAfter);
    }
  }
}
```

### 5. Display Micro-Feedback

**File**: `mobile/lib/features/learn/widgets/progress_micro_feedback.dart`

```dart
class ProgressMicroFeedback extends StatefulWidget {
  final ProgressStage stage;

  @override
  State<ProgressMicroFeedback> createState() => _ProgressMicroFeedbackState();
}

class _ProgressMicroFeedbackState extends State<ProgressMicroFeedback> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 100), () {
      setState(() => _visible = true);
    });
    Future.delayed(Duration(milliseconds: 2600), () {
      if (mounted) setState(() => _visible = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.masteryColors;
    return AnimatedOpacity(
      duration: Duration(milliseconds: 300),
      opacity: _visible ? 1.0 : 0.0,
      child: Badge(
        label: Text(widget.stage.displayName),
        backgroundColor: widget.stage.getColor(colors),
      ),
    );
  }
}
```

### 6. Show Session Recap

**File**: `mobile/lib/features/session/screens/session_complete_screen.dart` (extend existing)

```dart
if (session.progressSummary.hasTransitions)
  Card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Progress Made', style: MasteryTextStyles.h4),
        SizedBox(height: 12),
        if (summary.stabilizingCount > 0)
          _ProgressRow(
            icon: Icons.trending_up,
            count: summary.stabilizingCount,
            label: 'Stabilizing',
            color: colors.accent,
          ),
        if (summary.activeCount > 0)
          _ProgressRow(
            icon: Icons.star,
            count: summary.activeCount,
            label: 'Active',
            color: colors.success,
            isRare: true,
          ),
      ],
    ),
  ),
```

---

## Testing Checklist

### Unit Tests

```bash
cd mobile
flutter test test/unit/services/progress_stage_service_test.dart
```

**Test cases**:
- ✅ Captured: No card exists (word not reviewed yet)
- ✅ Practicing: Card with reps >= 1
- ✅ Stabilizing: stability >= 1.0, reps >= 3, lapses <= 2
- ✅ Active: All stabilizing + non-translation success
- ✅ Mastered: stability >= 90, reps >= 12, lapses <= 1

### Widget Tests

```bash
flutter test test/widgets/learn/progress_micro_feedback_test.dart
```

**Test cases**:
- ✅ Badge appears on transition
- ✅ Badge disappears after 2.5 seconds
- ✅ Correct color for each stage
- ✅ Screen reader announcement

### Integration Tests

1. Complete learning session with words at different stages
2. Verify micro-feedback appears on transitions
3. Verify session recap shows correct counts
4. Verify vocabulary list displays correct stage badges

---

## Common Patterns

### Pattern 1: Calculate Stage for Vocabulary List

```dart
// In VocabularyProvider
Future<List<VocabularyWithStage>> loadVocabulary() async {
  final words = await supabase.from('vocabulary').select('*, learning_cards(*)');

  return words.map((row) {
    final card = row['learning_cards'] as Map?;
    final stage = _progressService.calculateStage(
      card: card != null ? LearningCard.fromJson(card) : null,
      nonTranslationSuccessCount: 0, // Calculated separately if needed for Active stage
    );
    return VocabularyWithStage(word: row, stage: stage);
  }).toList();
}
```

### Pattern 2: Update Cached Stage After Review

```dart
// After FSRS update
await supabase
  .from('learning_cards')
  .update({'progress_stage': newStage.name})
  .eq('id', card.id);
```

### Pattern 3: Query Non-Translation Success Count

```dart
Future<int> getNonTranslationSuccessCount(String learningCardId) async {
  final result = await supabase
    .from('review_logs')
    .select('id', const FetchOptions(count: CountOption.exact))
    .eq('learning_card_id', learningCardId)
    .gte('rating', 3)
    .inFilter('cue_type', ['definition', 'synonym', 'context_cloze', 'disambiguation']);

  return result.count ?? 0;
}
```

---

## Debugging Tips

### Issue: Stage not updating after review

**Check**:
1. FSRS metrics updated? (`stability`, `reps`, `lapses`)
2. Review log created with correct `cue_type`?
3. Stage calculation logic correct for thresholds?

**Debug**:
```dart
print('Stage before: $stageBefore');
print('Card state: ${card.state}, stability: ${card.stability}, reps: ${card.reps}, lapses: ${card.lapses}');
print('Non-translation count: $nonTransSuccessCount');
print('Stage after: $stageAfter');
```

### Issue: Micro-feedback not appearing

**Check**:
1. Stage actually changed? (before != after)
2. Widget mounted when showing feedback?
3. Timer cleanup in `dispose()`?

**Debug**:
```dart
print('Showing micro-feedback for stage: ${stage.displayName}');
// Add to ProgressMicroFeedback initState
```

### Issue: Session recap shows wrong counts

**Check**:
1. Transitions list populated during session?
2. Filtering logic correct in SessionProgressSummary?

**Debug**:
```dart
print('Transitions: ${transitions.map((t) => t.toStage.displayName).join(', ')}');
print('Stabilizing count: $stabilizingCount, Active count: $activeCount');
```

---

## Performance Targets

| Operation | Target | Current | Status |
|-----------|--------|---------|--------|
| Stage calculation (per word) | <50ms | TBD | ⏳ |
| Vocabulary list load (100 words) | <500ms | TBD | ⏳ |
| Session recap generation | <200ms | TBD | ⏳ |
| Micro-feedback display latency | <100ms | TBD | ⏳ |

**Measurement**:
```dart
final stopwatch = Stopwatch()..start();
final stage = _progressService.calculateStage(...);
stopwatch.stop();
print('Stage calculation took: ${stopwatch.elapsedMilliseconds}ms');
```

---

## Next Steps

1. ✅ Implement ProgressStageService
2. ✅ Add micro-feedback widget
3. ✅ Update SessionCompleteScreen
4. ⏳ Update VocabularyListItem with stage badge
5. ⏳ Write unit tests for stage calculation
6. ⏳ Write widget tests for micro-feedback
7. ⏳ Manual testing on simulator
8. ⏳ Deploy migration to staging

---

## Resources

- **Spec**: [spec.md](./spec.md)
- **Research**: [research.md](./research.md)
- **Data Model**: [data-model.md](./data-model.md)
- **FSRS Documentation**: [FSRS Algorithm](https://github.com/open-spaced-repetition/fsrs-algorithm)
- **Flutter Animation Guide**: [Flutter Animations](https://docs.flutter.dev/development/ui/animations)
