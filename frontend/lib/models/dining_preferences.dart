class DiningPreferences {
  final List<String> favoriteCuisines;
  final List<String> diningStyles;
  final List<String> dietaryRestrictions;
  final String additionalNotes;

  const DiningPreferences({
    this.favoriteCuisines = const [],
    this.diningStyles = const [],
    this.dietaryRestrictions = const [],
    this.additionalNotes = '',
  });

  DiningPreferences copyWith({
    List<String>? favoriteCuisines,
    List<String>? diningStyles,
    List<String>? dietaryRestrictions,
    String? additionalNotes,
  }) {
    return DiningPreferences(
      favoriteCuisines: favoriteCuisines ?? this.favoriteCuisines,
      diningStyles: diningStyles ?? this.diningStyles,
      dietaryRestrictions: dietaryRestrictions ?? this.dietaryRestrictions,
      additionalNotes: additionalNotes ?? this.additionalNotes,
    );
  }

  /// 백엔드(`/api/account/dining-preferences/`) 응답 → 모델.
  factory DiningPreferences.fromJson(Map<String, dynamic> json) {
    return DiningPreferences(
      favoriteCuisines: _toStringList(json['favorite_cuisines']),
      diningStyles: _toStringList(json['dining_styles']),
      dietaryRestrictions: _toStringList(json['dietary_restrictions']),
      additionalNotes: json['additional_notes'] as String? ?? '',
    );
  }

  /// PATCH 본문(snake_case).
  Map<String, dynamic> toJson() {
    return {
      'favorite_cuisines': favoriteCuisines,
      'dining_styles': diningStyles,
      'dietary_restrictions': dietaryRestrictions,
      'additional_notes': additionalNotes,
    };
  }

  static List<String> _toStringList(Object? value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return const [];
  }
}