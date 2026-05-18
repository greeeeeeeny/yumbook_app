from rest_framework import serializers

from .models import Restaurant, RestaurantPolicy


class RestaurantPolicySerializer(serializers.ModelSerializer):
    class Meta:
        model = RestaurantPolicy
        exclude = ("id", "restaurant")


class RestaurantSerializer(serializers.ModelSerializer):
    policy = RestaurantPolicySerializer(read_only=True)

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
            "lat",
            "lng",
            "rating",
            "review_count",
            "policy",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["id", "created_at", "updated_at"]
