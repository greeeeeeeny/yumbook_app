// lib/models/restaurant.dart
class Restaurant {
  final String id;
  final String name;

  // detail_screen.dart에서 쓰는 필드들
  final String location;
  final List<String> tags;
  final String description;
  final String imagePath; // URL이면 NetworkImage, asset이면 AssetImage로 처리

  // 선택 필드들
  final double rating;
  final int reviewCount;

  // ✅ Explore/Map용 (추가)
  final String? rawCategory;
  final double? lat;
  final double? lng;

  const Restaurant({
    required this.id,
    required this.name,
    required this.location,
    required this.tags,
    required this.description,
    required this.imagePath,

    // ✅ Explore/Map용 (추가)
    this.rawCategory,
    this.lat,
    this.lng,

    // 기존 선택값
    this.rating = 0,
    this.reviewCount = 0,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    final tagsValue = json['tags'];
    return Restaurant(
      id: json['id'].toString(),
      name: json['name'] as String? ?? '',
      location: json['location'] as String? ?? '',
      description: json['description'] as String? ?? '',
      imagePath: json['image_url'] as String? ?? '',
      tags: tagsValue is List
          ? tagsValue.map((e) => e.toString()).toList()
          : const [],
      rawCategory: json['raw_category'] as String?,
      lat: _toDouble(json['lat']),
      lng: _toDouble(json['lng']),
      rating: _toDouble(json['rating']) ?? 0,
      reviewCount: (json['review_count'] as int?) ?? 0,
    );
  }

  static double? _toDouble(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}