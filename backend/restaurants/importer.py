"""CSV 기반 식당 임포트 로직.

관리 명령어(import_restaurants)와 admin 임포트 뷰가 공통으로 호출하는 재사용 함수를 모았다.

CSV 헤더(컬럼):
    name,region,category,image_url,address,description,rating
선택 컬럼:
    is_primary   - 대표 이미지 여부 ("true"/"1"/"yes" 등). 미지정 시 True.
    storage_path - Supabase Storage 경로(있으면 RestaurantImage.storage_path 에 저장).

매핑 규칙:
    category    -> Restaurant.raw_category
    address     -> Restaurant.location
    image_url   -> Restaurant.image_url (대표 이미지 미러, 하위 호환용)
                   + RestaurantImage(image_url, is_primary=True) 한 건
    region(slug)-> Region.get_or_create(slug=...) name 기본값은 slug.upper()

Restaurant 는 (name, region) 키로 update_or_create 한다.
"""

import csv
import io
from decimal import Decimal, InvalidOperation

from django.db import transaction

from restaurants.models import Region, Restaurant, RestaurantImage

# CSV 필수 헤더 (이 순서로 문서화하지만, 파싱은 컬럼명 기준으로 한다)
REQUIRED_COLUMNS = ["name", "region", "category", "image_url", "address", "description", "rating"]
OPTIONAL_COLUMNS = ["is_primary", "storage_path"]

_TRUE_VALUES = {"1", "true", "t", "yes", "y", "on"}


def _clean(value):
    """None / 공백 처리. 항상 trim 된 문자열을 돌려준다."""
    if value is None:
        return ""
    return str(value).strip()


def _parse_bool(value, default=True):
    text = _clean(value).lower()
    if text == "":
        return default
    return text in _TRUE_VALUES


def _parse_rating(value):
    """rating 문자열을 Decimal 로 변환. 비거나 잘못되면 Decimal('0')."""
    text = _clean(value)
    if text == "":
        return Decimal("0")
    try:
        return Decimal(text)
    except (InvalidOperation, ValueError):
        return Decimal("0")


def _get_or_create_region(slug, *, dry_run=False):
    """region slug 로 Region 을 확보한다. name 기본값은 slug.upper()."""
    slug = _clean(slug).lower()
    if dry_run:
        # dry-run 에서는 DB 를 건드리지 않되 기존 레코드는 조회로 확인한다.
        region = Region.objects.filter(slug=slug).first()
        created = region is None
        return region, created
    region, created = Region.objects.get_or_create(
        slug=slug,
        defaults={"name": slug.upper()},
    )
    return region, created


def import_restaurants_from_rows(rows, update=False, dry_run=False):
    """이미 파싱된 행(dict 리스트)을 임포트한다.

    각 row 는 CSV DictReader 형태의 dict (키: 컬럼명).

    Args:
        rows: dict 의 이터러블. 최소 name, region 컬럼 필요.
        update: True 면 기존 식당의 필드도 갱신한다. False 면 신규만 생성.
        dry_run: True 면 트랜잭션을 롤백하여 DB 에 반영하지 않는다.

    Returns:
        stats dict: {
            restaurants_created, restaurants_updated, restaurants_skipped,
            regions_created, images_created, images_updated, errors(list[str])
        }
    """
    stats = {
        "restaurants_created": 0,
        "restaurants_updated": 0,
        "restaurants_skipped": 0,
        "regions_created": 0,
        "images_created": 0,
        "images_updated": 0,
        "errors": [],
    }

    def _process():
        for index, raw in enumerate(rows, start=1):
            name = _clean(raw.get("name"))
            region_slug = _clean(raw.get("region")).lower()

            if not name:
                stats["errors"].append(f"행 {index}: name 이 비어 있어 건너뜀")
                continue
            if not region_slug:
                stats["errors"].append(f"행 {index}: region(slug) 이 비어 있어 건너뜀 (name={name})")
                continue

            region, region_created = _get_or_create_region(region_slug, dry_run=dry_run)
            if region_created:
                stats["regions_created"] += 1

            # dry-run + 신규 region 인 경우 region 객체가 None 일 수 있다.
            image_url = _clean(raw.get("image_url"))
            defaults = {
                "raw_category": _clean(raw.get("category")),
                "location": _clean(raw.get("address")),
                "description": _clean(raw.get("description")),
                "rating": _parse_rating(raw.get("rating")),
                "image_url": image_url,
            }

            existing = Restaurant.objects.filter(name=name, region=region).first()

            if existing is None:
                if dry_run:
                    restaurant = None
                    stats["restaurants_created"] += 1
                else:
                    restaurant = Restaurant.objects.create(
                        name=name, region=region, **defaults
                    )
                    stats["restaurants_created"] += 1
            else:
                if update:
                    if not dry_run:
                        for field, value in defaults.items():
                            setattr(existing, field, value)
                        existing.save(update_fields=list(defaults.keys()))
                    restaurant = existing
                    stats["restaurants_updated"] += 1
                else:
                    restaurant = existing
                    stats["restaurants_skipped"] += 1

            # 이미지 처리: image_url 이 있으면 대표 이미지 1건 보장.
            if image_url:
                is_primary = _parse_bool(raw.get("is_primary"), default=True)
                storage_path = _clean(raw.get("storage_path"))
                if dry_run or restaurant is None:
                    # dry-run 에서는 생성/갱신 여부만 추정한다.
                    img_exists = (
                        restaurant is not None
                        and RestaurantImage.objects.filter(
                            restaurant=restaurant, image_url=image_url
                        ).exists()
                    )
                    if img_exists:
                        stats["images_updated"] += 1
                    else:
                        stats["images_created"] += 1
                else:
                    image, img_created = RestaurantImage.objects.update_or_create(
                        restaurant=restaurant,
                        image_url=image_url,
                        defaults={
                            "is_primary": is_primary,
                            "storage_path": storage_path,
                        },
                    )
                    if img_created:
                        stats["images_created"] += 1
                    else:
                        stats["images_updated"] += 1

    # 항상 atomic 으로 감싼다. dry_run 이면 강제 롤백.
    if dry_run:
        try:
            with transaction.atomic():
                _process()
                raise _DryRunRollback()
        except _DryRunRollback:
            pass
    else:
        with transaction.atomic():
            _process()

    return stats


def import_restaurants_from_file(fileobj, update=False, dry_run=False):
    """파일 객체(또는 텍스트/바이트 스트림)에서 CSV 를 읽어 임포트한다.

    바이트 스트림이면 UTF-8 로 디코드한다(BOM 허용).

    Returns:
        import_restaurants_from_rows 와 동일한 stats dict.
    """
    data = fileobj.read()
    if isinstance(data, bytes):
        text = data.decode("utf-8-sig")
    else:
        # 텍스트라도 BOM 이 섞여 들어올 수 있어 제거.
        text = data.lstrip("﻿")

    reader = csv.DictReader(io.StringIO(text))
    rows = list(reader)
    return import_restaurants_from_rows(rows, update=update, dry_run=dry_run)


class _DryRunRollback(Exception):
    """dry-run 트랜잭션을 강제 롤백하기 위한 내부 예외."""
    pass
