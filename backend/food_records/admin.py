from django.contrib import admin

from .models import FoodRecord, FoodRecordImage


class FoodRecordImageInline(admin.TabularInline):
    model = FoodRecordImage
    extra = 1


@admin.register(FoodRecord)
class FoodRecordAdmin(admin.ModelAdmin):
    list_display = (
        "id",
        "user",
        "restaurant",
        "menu_name",
        "rating",
        "is_public",
        "created_at",
    )
    list_filter = ("is_public",)
    search_fields = ("user", "menu_name", "restaurant_name", "review")
    inlines = [FoodRecordImageInline]
