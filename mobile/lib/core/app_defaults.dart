abstract final class AppDefaults {
  // Session length (minutes)
  static const int sessionQuick = 3;
  static const int sessionRegular = 5;
  static const int sessionSerious = 8;
  static const int sessionDefault = sessionRegular;

  // New words rate (per session)
  static const int newWordsFew = 3;
  static const int newWordsNormal = 5;
  static const int newWordsMany = 8;
  static const int newWordsDefault = newWordsNormal;

  // Review intensity (target retention)
  static const double retentionEfficient = 0.85;
  static const double retentionBalanced = 0.90;
  static const double retentionReinforced = 0.93;
  static const double retentionDefault = retentionBalanced;

  // Day boundary: hour (local time) when a new day starts.
  // Before this hour, activity counts toward the previous day.
  static const int dayStartHour = 4;

  // Display
  static const String nativeLanguageCode = 'de';
}
