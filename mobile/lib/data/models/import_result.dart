/// Result of an import operation
class ImportResult {
  final int totalFound;
  final int imported;
  final int skipped;
  final int errors;
  final List<String> errorDetails;
  final Duration duration;

  const ImportResult({
    required this.totalFound,
    required this.imported,
    required this.skipped,
    this.errors = 0,
    this.errorDetails = const [],
    required this.duration,
  });

  bool get hasErrors => errors > 0;
  bool get hasSkipped => skipped > 0;
  int get processed => imported + skipped + errors;

  @override
  String toString() {
    return 'ImportResult(total: $totalFound, imported: $imported, skipped: $skipped, errors: $errors)';
  }
}
