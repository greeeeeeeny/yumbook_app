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
}