class Character {
  const Character({
    required this.name,
    required this.rawHeight,
    required this.url,
  });

  final String name;
  final String rawHeight;
  final String url;

  int? get heightCm {
    final parsed = int.tryParse(rawHeight);
    if (parsed == null || parsed <= 0) {
      return null;
    }
    return parsed;
  }

  String get heightLabel => heightCm?.toString() ?? 'unknown';

  double get rowHeight => (heightCm ?? 80).toDouble();
}
