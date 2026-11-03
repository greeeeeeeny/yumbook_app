from rest_framework import serializers

from .models import Region, Restaurant, RestaurantImage, RestaurantPolicy


class RegionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Region
        fields = ["id", "slug", "name", "display_order", "is_active"]


class RestaurantImageSerializer(serializers.ModelSerializer):
    class Meta:
        model = RestaurantImage
        fields = [
            "id",
            "image_url",
            "storage_path",
            "is_primary",
            "sort_order",
            "alt_text",
        ]


class RestaurantPolicySerializer(serializers.ModelSerializer):
    class Meta:
        model = RestaurantPolicy
        exclude = ("id", "restaurant")


class RestaurantSerializer(serializers.ModelSerializer):
    policy = RestaurantPolicySerializer(read_only=True)
    # region은 Region.slug 문자열로 직렬화한다. 예: "hongdae"
    region = serializers.SlugRelatedField(slug_field="slug", read_only=True)
    region_detail = RegionSerializer(source="region", read_only=True)
    images = RestaurantImageSerializer(many=True, read_only=True)

    class Meta:
        model = Restaurant
        fields = [
            "id",
            "name",
            "location",
            "description",
            "image_url",
            "tags",
            "raw_category",
            "region",
            "region_detail",
            "images",
            "lat",
            "lng",
            "price_level",
            "rating",
            "review_count",
            "policy",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["id", "created_at", "updated_at"]
