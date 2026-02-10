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

/// Global dictionary model — shared enrichment data for a word.
/// Mirrors the `global_dictionary` table.
class GlobalDictionaryModel {
  const GlobalDictionaryModel({
    required this.id,
    required this.lemma,
    this.partOfSpeech,
    this.englishDefinition,
    this.pronunciationIpa,
    required this.translations,
    required this.synonyms,
    required this.antonyms,
    required this.confusables,
    required this.exampleSentences,
    this.cefrLevel,
    this.confidence,
  });

  factory GlobalDictionaryModel.fromJson(Map<String, dynamic> json) {
    return GlobalDictionaryModel(
      id: json['id'] as String,
      lemma: json['word'] as String? ?? json['lemma'] as String? ?? '',
      partOfSpeech: json['part_of_speech'] as String?,
      englishDefinition: json['english_definition'] as String?,
      pronunciationIpa: json['pronunciation_ipa'] as String?,
      translations: _parseTranslations(json['translations']),
      synonyms: _parseStringList(json['synonyms']),
      antonyms: _parseStringList(json['antonyms']),
      confusables: _parseConfusables(json['confusables']),
      exampleSentences: _parseClozeTextList(json['example_sentences']),
      cefrLevel: json['cefr_level'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble(),
    );
  }

  final String id;
  final String lemma;
  final String? partOfSpeech;
  final String? englishDefinition;
  final String? pronunciationIpa;
  final Map<String, LanguageTranslations> translations;
  final List<String> synonyms;
  final List<String> antonyms;
  final List<Confusable> confusables;
  final List<ClozeText> exampleSentences;
  final String? cefrLevel;
  final double? confidence;

  /// Get the primary translation for a given language code
  String? primaryTranslation(String languageCode) {
    return translations[languageCode]?.primary;
  }

  /// Get alternative translations for a given language code
  List<String> alternativeTranslations(String languageCode) {
    return translations[languageCode]?.alternatives ?? [];
  }

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
}
