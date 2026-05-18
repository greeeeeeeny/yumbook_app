from django.contrib import admin

from .models import Restaurant, RestaurantPolicy


class RestaurantPolicyInline(admin.StackedInline):
    model = RestaurantPolicy
    can_delete = False


@admin.register(Restaurant)
class RestaurantAdmin(admin.ModelAdmin):
    list_display = ("name", "location", "raw_category", "rating", "review_count")
    search_fields = ("name", "location", "raw_category")
    list_filter = ("location", "raw_category")
    inlines = [RestaurantPolicyInline]


@admin.register(RestaurantPolicy)
class RestaurantPolicyAdmin(admin.ModelAdmin):
    list_display = ("restaurant", "deposit_type", "deposit_amount", "free_cancel_days")
