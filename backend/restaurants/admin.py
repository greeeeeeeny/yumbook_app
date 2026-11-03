from django import forms
from django.contrib import admin, messages
from django.shortcuts import redirect, render
from django.urls import path, reverse
from django.utils.html import format_html

from .importer import import_restaurants_from_file
from .models import Region, Restaurant, RestaurantImage, RestaurantPolicy


@admin.register(Region)
class RegionAdmin(admin.ModelAdmin):
    list_display = ("slug", "name", "display_order", "is_active")
    list_editable = ("display_order", "is_active")
    search_fields = ("slug", "name")
    prepopulated_fields = {"slug": ("name",)}


class CsvImportForm(forms.Form):
    # 식당 CSV 업로드 폼. importer가 fileobj를 직접 파싱한다.
    csv_file = forms.FileField(label="CSV 파일")
    update = forms.BooleanField(
        label="기존 식당 업데이트(update)",
        required=False,
        initial=True,
        help_text="(name, region)이 일치하는 기존 식당이 있으면 갱신한다.",
    )
    dry_run = forms.BooleanField(
        label="모의 실행(dry-run)",
        required=False,
        help_text="실제로 저장하지 않고 결과만 미리 본다.",
    )


class RestaurantPolicyInline(admin.StackedInline):
    model = RestaurantPolicy
    can_delete = False


class RestaurantImageInline(admin.TabularInline):
    model = RestaurantImage
    extra = 1
    fields = ("image_url", "storage_path", "is_primary", "sort_order", "alt_text")


@admin.action(description="선택한 식당을 지정한 지역으로 이동")
def assign_region(modeladmin, request, queryset):
    # 중간 페이지에서 대상 Region을 고르고 일괄 적용한다.
    if "apply" in request.POST:
        region_id = request.POST.get("region")
        if not region_id:
            modeladmin.message_user(
                request, "지역을 선택해야 합니다.", level=messages.ERROR
            )
            return None
        region = Region.objects.filter(pk=region_id).first()
        if region is None:
            modeladmin.message_user(
                request, "선택한 지역을 찾을 수 없습니다.", level=messages.ERROR
            )
            return None
        updated = queryset.update(region=region)
        modeladmin.message_user(
            request,
            f"{updated}개 식당을 '{region.name}' 지역으로 이동했습니다.",
            level=messages.SUCCESS,
        )
        return None

    return render(
        request,
        "admin/restaurants/assign_region.html",
        {
            "title": "지역 일괄 지정",
            "queryset": queryset,
            "regions": Region.objects.all(),
            "action_name": "assign_region",
            "opts": modeladmin.model._meta,
        },
    )


@admin.action(description="선택한 식당의 지역 해제")
def clear_region(modeladmin, request, queryset):
    # 안전한 일괄 작업: 선택한 식당의 지역을 비운다(SET_NULL과 동일 효과).
    updated = queryset.update(region=None)
    modeladmin.message_user(
        request,
        f"{updated}개 식당의 지역을 해제했습니다.",
        level=messages.SUCCESS,
    )


@admin.register(Restaurant)
class RestaurantAdmin(admin.ModelAdmin):
    change_list_template = "admin/restaurants/restaurant_changelist.html"
    list_display = ("name", "region", "location", "raw_category", "rating", "review_count")
    search_fields = ("name", "location", "raw_category")
    list_filter = ("region", "location", "raw_category")
    autocomplete_fields = ("region",)
    inlines = [RestaurantImageInline, RestaurantPolicyInline]
    actions = [assign_region, clear_region]

    def get_urls(self):
        urls = super().get_urls()
        custom = [
            path(
                "import-csv/",
                self.admin_site.admin_view(self.import_csv_view),
                name="restaurants_restaurant_import_csv",
            ),
        ]
        return custom + urls

    def import_csv_view(self, request):
        # 식당 변경목록에서 "Import CSV" 버튼이 여는 커스텀 업로드 뷰.
        if request.method == "POST":
            form = CsvImportForm(request.POST, request.FILES)
            if form.is_valid():
                update = form.cleaned_data["update"]
                dry_run = form.cleaned_data["dry_run"]
                csv_file = form.cleaned_data["csv_file"]
                try:
                    stats = import_restaurants_from_file(
                        csv_file, update=update, dry_run=dry_run
                    )
                except Exception as exc:  # noqa: BLE001 - 업로드 오류를 관리자에게 표시
                    self.message_user(
                        request,
                        f"CSV 가져오기 실패: {exc}",
                        level=messages.ERROR,
                    )
                else:
                    summary = ", ".join(
                        f"{key}={value}" for key, value in (stats or {}).items()
                    )
                    prefix = "(dry-run) " if dry_run else ""
                    self.message_user(
                        request,
                        f"{prefix}CSV 가져오기 완료: {summary}"
                        if summary
                        else f"{prefix}CSV 가져오기 완료.",
                        level=messages.SUCCESS,
                    )
                    if not dry_run:
                        changelist_url = reverse(
                            "admin:restaurants_restaurant_changelist"
                        )
                        return redirect(changelist_url)
        else:
            form = CsvImportForm()

        context = {
            **self.admin_site.each_context(request),
            "title": "식당 CSV 가져오기",
            "form": form,
            "opts": self.model._meta,
        }
        return render(request, "admin/restaurants/import_csv.html", context)


@admin.register(RestaurantImage)
class RestaurantImageAdmin(admin.ModelAdmin):
    list_display = ("restaurant", "is_primary", "sort_order", "preview")
    list_filter = ("is_primary",)
    search_fields = ("restaurant__name", "alt_text", "image_url")
    autocomplete_fields = ("restaurant",)

    @admin.display(description="미리보기")
    def preview(self, obj):
        if obj.image_url:
            return format_html(
                '<img src="{}" style="height:40px;border-radius:4px;" />',
                obj.image_url,
            )
        return "—"


@admin.register(RestaurantPolicy)
class RestaurantPolicyAdmin(admin.ModelAdmin):
    list_display = ("restaurant", "deposit_type", "deposit_amount", "free_cancel_days")
