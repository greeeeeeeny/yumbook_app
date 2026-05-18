import 'package:intl/intl.dart';

class FoodRecordImage {
  final int? id;
  final String imageUrl;
  final int order;

  const FoodRecordImage({
    this.id,
    required this.imageUrl,
    this.order = 0,
  });

  FoodRecordImage copyWith({
    int? id,
    String? imageUrl,
    int? order,
  }) {
    return FoodRecordImage(
      id: id ?? this.id,
      imageUrl: imageUrl ?? this.imageUrl,
      order: order ?? this.order,
    );
  }
}

class FoodRecord {
  final int? id;
  final String? userId;
  final int? restaurantId;
  final String restaurantName;
  final String menuName;
  final double rating;
  final String review;
  final double? price;
  final List<String> tags;
  final DateTime? visitedAt;
  final bool isPublic;
  final List<FoodRecordImage> images;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const FoodRecord({
    this.id,
    this.userId,
    this.restaurantId,
    this.restaurantName = '',
    this.menuName = '',
    required this.rating,
    this.review = '',
    this.price,
    this.tags = const [],
    this.visitedAt,
    this.isPublic = true,
    this.images = const [],
    this.createdAt,
    this.updatedAt,
  });

  FoodRecord copyWith({
    int? id,
    String? userId,
    int? restaurantId,
    String? restaurantName,
    String? menuName,
    double? rating,
    String? review,
    double? price,
    List<String>? tags,
    DateTime? visitedAt,
    bool? isPublic,
    List<FoodRecordImage>? images,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearRestaurant = false,
    bool clearPrice = false,
    bool clearVisitedAt = false,
  }) {
    return FoodRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      restaurantId: clearRestaurant ? null : (restaurantId ?? this.restaurantId),
      restaurantName: restaurantName ?? this.restaurantName,
      menuName: menuName ?? this.menuName,
      rating: rating ?? this.rating,
      review: review ?? this.review,
      price: clearPrice ? null : (price ?? this.price),
      tags: tags ?? this.tags,
      visitedAt: clearVisitedAt ? null : (visitedAt ?? this.visitedAt),
      isPublic: isPublic ?? this.isPublic,
      images: images ?? this.images,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

extension FoodRecordFormat on FoodRecord {
  String get formattedVisitedAt {
    final value = visitedAt;
    if (value == null) return '';
    return DateFormat('yyyy-MM-dd').format(value);
  }
}
