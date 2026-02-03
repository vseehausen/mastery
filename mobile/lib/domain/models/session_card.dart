import 'cue_type.dart';
import 'learning_card.dart';

/// A meaning returned as part of a session card.
/// Contains the essential fields needed for learning display.
class SessionMeaning {
  const SessionMeaning({
    required this.id,
    required this.primaryTranslation,
    required this.englishDefinition,
    this.extendedDefinition,
    this.partOfSpeech,
    required this.synonyms,
    required this.isPrimary,
    required this.sortOrder,
  });

  factory SessionMeaning.fromJson(Map<String, dynamic> json) {
    return SessionMeaning(
      id: json['id'] as String,
      primaryTranslation: json['primary_translation'] as String,
      englishDefinition: json['english_definition'] as String,
      extendedDefinition: json['extended_definition'] as String?,
      partOfSpeech: json['part_of_speech'] as String?,
      synonyms: _parseSynonyms(json['synonyms']),
      isPrimary: json['is_primary'] as bool? ?? false,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  final String id;
  final String primaryTranslation;
  final String englishDefinition;
  final String? extendedDefinition;
  final String? partOfSpeech;
  final List<String> synonyms;
  final bool isPrimary;
  final int sortOrder;

  static List<String> _parseSynonyms(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }
}

/// A cue returned as part of a session card.
/// Contains the prompt and answer for a specific cue type.
class SessionCue {
  const SessionCue({
    required this.id,
    required this.meaningId,
    required this.cueType,
    required this.promptText,
    required this.answerText,
    this.hintText,
  });

  factory SessionCue.fromJson(Map<String, dynamic> json) {
    return SessionCue(
      id: json['id'] as String,
      meaningId: json['meaning_id'] as String,
      cueType: CueType.fromDbString(json['cue_type'] as String),
      promptText: json['prompt_text'] as String,
      answerText: json['answer_text'] as String,
      hintText: json['hint_text'] as String?,
    );
  }

  final String id;
  final String meaningId;
  final CueType cueType;
  final String promptText;
  final String answerText;
  final String? hintText;
}

/// A learning card with all data needed for a session.
/// Returned by the get_session_cards RPC function, this model contains
/// the card state, vocabulary info, meanings, and cues in a single object.
class SessionCard {
  const SessionCard({
    required this.cardId,
    required this.vocabularyId,
    required this.state,
    required this.due,
    required this.stability,
    required this.difficulty,
    required this.reps,
    required this.lapses,
    this.lastReview,
    required this.isLeech,
    required this.createdAt,
    required this.word,
    this.stem,
    required this.meanings,
    required this.cues,
    required this.hasEncounterContext,
    required this.hasConfusables,
  });

  factory SessionCard.fromJson(Map<String, dynamic> json) {
    return SessionCard(
      cardId: json['card_id'] as String,
      vocabularyId: json['vocabulary_id'] as String,
      state: json['state'] as int,
      due: DateTime.parse(json['due'] as String),
      stability: (json['stability'] as num).toDouble(),
      difficulty: (json['difficulty'] as num).toDouble(),
      reps: json['reps'] as int,
      lapses: json['lapses'] as int,
      lastReview: json['last_review'] != null
          ? DateTime.parse(json['last_review'] as String)
          : null,
      isLeech: json['is_leech'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      word: json['word'] as String,
      stem: json['stem'] as String?,
      meanings: _parseMeanings(json['meanings']),
      cues: _parseCues(json['cues']),
      hasEncounterContext: json['has_encounter_context'] as bool? ?? false,
      hasConfusables: json['has_confusables'] as bool? ?? false,
    );
  }

  // Learning card fields
  final String cardId;
  final String vocabularyId;
  final int state; // 0=new, 1=learning, 2=review, 3=relearning
  final DateTime due;
  final double stability;
  final double difficulty;
  final int reps;
  final int lapses;
  final DateTime? lastReview;
  final bool isLeech;
  final DateTime createdAt;

  // Vocabulary fields
  final String word;
  final String? stem;

  // Aggregated data
  final List<SessionMeaning> meanings;
  final List<SessionCue> cues;

  // Eligibility flags for cue selection
  final bool hasEncounterContext;
  final bool hasConfusables;

  /// Whether this card has any meaning data
  bool get hasMeaning => meanings.isNotEmpty;

  /// Get the primary meaning, or the first meaning if none is marked primary
  SessionMeaning? get primaryMeaning {
    if (meanings.isEmpty) return null;
    return meanings.firstWhere(
      (m) => m.isPrimary,
      orElse: () => meanings.first,
    );
  }

  /// Get a cue by type
  SessionCue? getCue(CueType type) {
    for (final cue in cues) {
      if (cue.cueType == type) return cue;
    }
    return null;
  }

  /// Whether this is a new word (state == 0)
  bool get isNewWord => state == 0;

  static List<SessionMeaning> _parseMeanings(dynamic value) {
    if (value == null) return [];
    if (value is! List) return [];
    return value
        .map((m) => SessionMeaning.fromJson(m as Map<String, dynamic>))
        .toList();
  }

  static List<SessionCue> _parseCues(dynamic value) {
    if (value == null) return [];
    if (value is! List) return [];
    return value
        .map((c) => SessionCue.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  /// Convert to LearningCardModel for use with SrsScheduler.
  /// The userId is required since it's not stored in session cards.
  LearningCardModel toLearningCard(String userId) {
    final now = DateTime.now().toUtc();
    return LearningCardModel(
      id: cardId,
      userId: userId,
      vocabularyId: vocabularyId,
      state: state,
      due: due,
      stability: stability,
      difficulty: difficulty,
      reps: reps,
      lapses: lapses,
      lastReview: lastReview,
      isLeech: isLeech,
      createdAt: createdAt,
      updatedAt: now,
      deletedAt: null,
      version: 1,
    );
  }
}
