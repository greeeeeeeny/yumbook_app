from rest_framework import serializers

from .models import FoodRecord, FoodRecordImage


class FoodRecordImageSerializer(serializers.ModelSerializer):
    class Meta:
        model = FoodRecordImage
        fields = ["id", "image_url", "order"]


class FoodRecordSerializer(serializers.ModelSerializer):
    images = FoodRecordImageSerializer(many=True, required=False)
    user_id = serializers.CharField(source="user", read_only=True)

    class Meta:
        model = FoodRecord
        fields = [
            "id",
            "user",
            "user_id",
            "restaurant",
            "restaurant_name",
            "menu_name",
            "rating",
            "review",
            "price",
            "tags",
            "visited_at",
            "is_public",
            "images",
            "created_at",
            "updated_at",
        ]
        read_only_fields = [
            "id",
            "user",
            "user_id",
            "created_at",
            "updated_at",
        ]

    def create(self, validated_data):
        images = validated_data.pop("images", [])
        record = FoodRecord.objects.create(**validated_data)
        for index, image in enumerate(images):
            FoodRecordImage.objects.create(
                record=record,
                image_url=image["image_url"],
                order=image.get("order", index),
            )
        return record

    def update(self, instance, validated_data):
        images = validated_data.pop("images", None)
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()

        if images is not None:
            instance.images.all().delete()
            for index, image in enumerate(images):
                FoodRecordImage.objects.create(
                    record=instance,
                    image_url=image["image_url"],
                    order=image.get("order", index),
                )
        return instance
