import 'app_defaults.dart';

/// Returns the effective "today" date in local time, accounting for
/// [AppDefaults.dayStartHour]. Before that hour, it's still "yesterday".
DateTime effectiveToday() {
  final now = DateTime.now();
  if (now.hour < AppDefaults.dayStartHour) {
    return DateTime(now.year, now.month, now.day - 1);
  }
  return DateTime(now.year, now.month, now.day);
}

/// Returns the effective date for a given [DateTime], accounting for
/// [AppDefaults.dayStartHour].
DateTime effectiveDate(DateTime dt) {
  final local = dt.toLocal();
  if (local.hour < AppDefaults.dayStartHour) {
    return DateTime(local.year, local.month, local.day - 1);
  }
  return DateTime(local.year, local.month, local.day);
}

/// Checks whether two [DateTime]s fall on the same effective day,
/// accounting for [AppDefaults.dayStartHour].
bool isSameEffectiveDay(DateTime a, DateTime b) {
  final ea = effectiveDate(a);
  final eb = effectiveDate(b);
  return ea.year == eb.year && ea.month == eb.month && ea.day == eb.day;
}

/// Returns the UTC [DateTime] representing the start of the current
/// effective day, accounting for [AppDefaults.dayStartHour].
DateTime effectiveDayStartUtc() {
  final today = effectiveToday();
  final localStart = DateTime(
    today.year, today.month, today.day, AppDefaults.dayStartHour);
  return localStart.toUtc();
}
