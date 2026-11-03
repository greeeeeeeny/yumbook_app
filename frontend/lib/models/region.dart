// lib/models/region.dart
class Region {
  final int id;

  /// 지역 슬러그(예: 'hongdae'). 식당 필터 키로 사용된다.
  final String slug;

  /// 탭에 노출되는 라벨(예: 'HONGDAE').
  final String name;

  /// 탭 정렬 순서.
  final int displayOrder;

  /// 활성 여부.
  final bool isActive;

  const Region({
    required this.id,
    required this.slug,
    required this.name,
    this.displayOrder = 0,
    this.isActive = true,
  });

  factory Region.fromJson(Map<String, dynamic> json) {
    return Region(
      id: (json['id'] as num?)?.toInt() ?? 0,
      slug: json['slug'] as String? ?? '',
      name: json['name'] as String? ?? '',
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}
