import 'learning_card.dart';

/// A cloze text with pre-split parts for UI rendering
class ClozeText {
  const ClozeText({
    required this.sentence,
    required this.before,
    required this.blank,
    required this.after,
  });

  factory ClozeText.fromJson(Map<String, dynamic> json) {
    return ClozeText(
      sentence: json['sentence'] as String? ?? '',
      before: json['before'] as String? ?? '',
      blank: json['blank'] as String? ?? '',
      after: json['after'] as String? ?? '',
    );
  }

  final String sentence;
  final String before;
  final String blank;
  final String after;
}

/// A confusable word with disambiguation information
class Confusable {
  const Confusable({
    required this.word,
    required this.disambiguationSentence,
  });

  factory Confusable.fromJson(Map<String, dynamic> json) {
    final disambigJson = json['disambiguation_sentence'];
    ClozeText? disambig;
    if (disambigJson is Map<String, dynamic>) {
      disambig = ClozeText.fromJson(disambigJson);
    }

    return Confusable(
      word: json['word'] as String,
      disambiguationSentence: disambig,
    );
  }

  final String word;
  final ClozeText? disambiguationSentence;
}

/// Translations for a specific language
class LanguageTranslations {
  const LanguageTranslations({
    required this.primary,
    required this.alternatives,
  });

  factory LanguageTranslations.fromJson(Map<String, dynamic> json) {
    return LanguageTranslations(
      primary: json['primary'] as String? ?? '',
      alternatives: _parseStringList(json['alternatives']),
    );
  }

  final String primary;
  final List<String> alternatives;

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }
}

/// A learning card with all data needed for a session.
/// Returned by the get_session_cards RPC function, this model contains
/// the card state, vocabulary info, and global dictionary data.
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
    required this.stem,
    required this.englishDefinition,
    this.partOfSpeech,
    required this.synonyms,
    required this.antonyms,
    required this.confusables,
    required this.exampleSentences,
    this.pronunciationIpa,
    required this.translations,
    this.cefrLevel,
    required this.overrides,
    this.encounterContext,
    required this.hasConfusables,
    required this.nonTranslationSuccessCount,
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
      stem: json['stem'] as String,
      englishDefinition: json['english_definition'] as String,
      partOfSpeech: json['part_of_speech'] as String?,
      synonyms: _parseStringList(json['synonyms']),
      antonyms: _parseStringList(json['antonyms']),
      confusables: _parseConfusables(json['confusables']),
      exampleSentences: _parseClozeTextList(json['example_sentences']),
      pronunciationIpa: json['pronunciation_ipa'] as String?,
      translations: _parseTranslations(json['translations']),
      cefrLevel: json['cefr_level'] as String?,
      overrides: _parseOverrides(json['overrides']),
      encounterContext: json['encounter_context'] as String?,
      hasConfusables: json['has_confusables'] as bool? ?? false,
      nonTranslationSuccessCount: json['non_translation_success_count'] as int? ?? 0,
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
  final String stem;

  /// The display form of the word: stem (base/lemma)
  String get displayWord => stem;

  // Global dictionary fields
  final String englishDefinition;
  final String? partOfSpeech;
  final List<String> synonyms;
  final List<String> antonyms;
  final List<Confusable> confusables;
  final List<ClozeText> exampleSentences;
  final String? pronunciationIpa;
  final Map<String, LanguageTranslations> translations;
  final String? cefrLevel;
  final Map<String, dynamic> overrides;

  // Encounter data
  final String? encounterContext;

  // Eligibility flags for cue selection
  final bool hasConfusables;

  // Progress tracking
  final int nonTranslationSuccessCount;

  /// Get the primary translation for the user's language
  String get primaryTranslation {
    // Check overrides first
    final overriddenTranslation = overrides['primary_translation'];
    if (overriddenTranslation != null && overriddenTranslation is String) {
      return overriddenTranslation;
    }

    // Fall back to first available translation
    // In a real app, this would use the user's language preference
    if (translations.isNotEmpty) {
      final firstLang = translations.values.first;
      return firstLang.primary;
    }

    return '';
  }

  /// Whether this is a new word (state == 0)
  bool get isNewWord => state == 0;

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }

  static List<Confusable> _parseConfusables(dynamic value) {
    if (value == null) return [];
    if (value is! List) return [];
    return value
        .map((c) => Confusable.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  static List<ClozeText> _parseClozeTextList(dynamic value) {
    if (value == null) return [];
    if (value is! List) return [];
    return value
        .map((c) => ClozeText.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  static Map<String, LanguageTranslations> _parseTranslations(dynamic value) {
    if (value == null) return {};
    if (value is! Map) return {};

    final result = <String, LanguageTranslations>{};
    value.forEach((key, val) {
      if (val is Map<String, dynamic>) {
        result[key.toString()] = LanguageTranslations.fromJson(val);
      }
    });
    return result;
  }

  static Map<String, dynamic> _parseOverrides(dynamic value) {
    if (value == null) return {};
    if (value is Map<String, dynamic>) return value;
    return {};
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
