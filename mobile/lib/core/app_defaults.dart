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

  // Response time → FSRS rating inference (MC cards)
  // Correct answers below this threshold are rated Easy (strong recall).
  static const int mcFastThresholdMs = 3000;
  // Correct answers above this threshold are rated Hard (weak recall).
  // Between fast and slow → Good.
  static const int mcSlowThresholdMs = 8000;
  // Response times above this are likely AFK/distracted — excluded from
  // calibration data to avoid skewing percentiles.
  static const int mcOutlierCeilingMs = 30000;
  // Minimum correct MC reviews needed before switching from fixed thresholds
  // to personalized percentile-based thresholds.
  static const int mcCalibrationMinSamples = 30;
  // Number of recent correct MC reviews to sample for percentile calculation.
  static const int mcCalibrationHistorySize = 200;
  // Percentile of the user's response time distribution used as the
  // fast (Easy) threshold. Below p33 = faster than 2/3 of their answers.
  static const double mcCalibrationFastPercentile = 0.33;
  // Percentile used as the slow (Hard) threshold. Above p67 = slower
  // than 2/3 of their answers.
  static const double mcCalibrationSlowPercentile = 0.67;

  // Display
  static const String nativeLanguageCode = 'de';
}
