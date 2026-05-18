import 'package:flutter/material.dart';
import 'package:yumbook_app/models/food_record.dart';

class FoodRecordCard extends StatelessWidget {
  final FoodRecord record;
  final VoidCallback? onTap;

  const FoodRecordCard({super.key, required this.record, this.onTap});

  static const Color _textDark = Color(0xFF303030);
  static const Color _textMuted = Color(0xFF7A7A7A);
  static const Color _border = Color(0xFFE5E5EA);
  static const Color _ratingColor = Color(0xFFD45425);

  @override
  Widget build(BuildContext context) {
    final titleParts = [
      if (record.restaurantName.isNotEmpty) record.restaurantName,
      if (record.menuName.isNotEmpty) record.menuName,
    ];
    final title = titleParts.isEmpty
        ? 'Untitled record'
        : titleParts.join(' · ');

    final firstImage = record.images.isNotEmpty
        ? record.images.first.imageUrl
        : null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: _border),
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (firstImage != null && firstImage.isNotEmpty)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  firstImage,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFFEAEAEA),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.broken_image_outlined,
                      color: _textMuted,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: _textDark,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Pretendard',
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _RatingBadge(rating: record.rating),
                    ],
                  ),
                  if (record.review.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      record.review,
                      style: const TextStyle(
                        color: _textDark,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        fontFamily: 'Pretendard',
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (record.formattedVisitedAt.isNotEmpty) ...[
                        const Icon(
                          Icons.event,
                          size: 14,
                          color: _textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          record.formattedVisitedAt,
                          style: const TextStyle(
                            color: _textMuted,
                            fontSize: 12,
                            fontFamily: 'Pretendard',
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (!record.isPublic)
                        const _PrivacyChip(),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RatingBadge extends StatelessWidget {
  final double rating;
  const _RatingBadge({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1EC),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, color: FoodRecordCard._ratingColor, size: 14),
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(
              color: FoodRecordCard._ratingColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              fontFamily: 'Pretendard',
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacyChip extends StatelessWidget {
  const _PrivacyChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFEFEFEF),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'Private',
        style: TextStyle(
          color: Color(0xFF6E6E6E),
          fontSize: 11,
          fontWeight: FontWeight.w500,
          fontFamily: 'Pretendard',
        ),
      ),
    );
  }
}
