/// Source of import operation
enum ImportSource {
  file,
  device;

  String toJson() => name;

  static ImportSource fromJson(String json) {
    return ImportSource.values.firstWhere(
      (e) => e.name == json,
      orElse: () => ImportSource.file,
    );
  }
}
