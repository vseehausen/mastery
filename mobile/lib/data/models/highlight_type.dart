/// Type of highlight from Kindle
enum HighlightType {
  highlight,
  note;

  String toJson() => name;

  static HighlightType fromJson(String json) {
    return HighlightType.values.firstWhere(
      (e) => e.name == json,
      orElse: () => HighlightType.highlight,
    );
  }
}
