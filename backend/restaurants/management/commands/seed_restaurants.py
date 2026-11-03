"""[DEV-ONLY] Seed the database with mock region-tagged restaurants.

WARNING: This command is for LOCAL DEVELOPMENT ONLY. It inserts hardcoded mock
data and MUST NOT be run against production. For production data, use the CSV
importer instead:

    python manage.py import_restaurants <csv_path> [--update] [--dry-run]

Usage (dev only):
    python manage.py seed_restaurants          # insert missing, keep existing
    python manage.py seed_restaurants --flush   # delete all restaurants first

Each record carries the display fields the Flutter UI needs:
name, region, image_url, raw_category (category), location, description, tags,
lat/lng, rating, review_count.
"""

from decimal import Decimal

from django.core.management.base import BaseCommand
from django.db import transaction

from restaurants.models import Region, Restaurant

# region -> list of restaurants. Regions match the home screen tabs.
SEED_DATA = {
    "insadong": [
        {
            "name": "1993 Gogi",
            "location": "Insadong, Seoul",
            "description": (
                "A Korean barbecue restaurant popular for juicy Samgyeopsal, "
                "tender Moksal, and chewy Jjonddeuksal."
            ),
            "image_url": "https://images.unsplash.com/photo-1544025162-d76694265947",
            "raw_category": "Korean BBQ",
            "tags": ["₩₩", "Korean food", "Hidden Gems"],
            "lat": Decimal("37.5740"),
            "lng": Decimal("126.9850"),
            "rating": Decimal("4.50"),
            "review_count": 128,
        },
        {
            "name": "Osegyehyang",
            "location": "Insadong, Seoul",
            "description": (
                "A long-loved vegetarian restaurant serving hearty, plant-based "
                "Korean and Chinese-style dishes."
            ),
            "image_url": "https://images.unsplash.com/photo-1512621776951-a57141f2eefd",
            "raw_category": "Vegetarian",
            "tags": ["₩₩", "Vegetarian", "Korean"],
            "lat": Decimal("37.5732"),
            "lng": Decimal("126.9869"),
            "rating": Decimal("4.30"),
            "review_count": 86,
        },
    ],
    "hongdae": [
        {
            "name": "Alpero",
            "location": "Hongdae, Seoul",
            "description": "A cozy Italian restaurant serving authentic pasta and wine.",
            "image_url": "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4",
            "raw_category": "Italian",
            "tags": ["₩₩₩", "Italian", "Date Night"],
            "lat": Decimal("37.5563"),
            "lng": Decimal("126.9220"),
            "rating": Decimal("4.40"),
            "review_count": 152,
        },
        {
            "name": "Midnight Ramyun",
            "location": "Hongdae, Seoul",
            "description": (
                "A late-night noodle bar famous for rich tonkotsu broth and "
                "hand-pulled ramen."
            ),
            "image_url": "https://images.unsplash.com/photo-1569718212165-3a8278d5f624",
            "raw_category": "Ramen",
            "tags": ["₩", "Ramen", "Late Night"],
            "lat": Decimal("37.5550"),
            "lng": Decimal("126.9240"),
            "rating": Decimal("4.10"),
            "review_count": 64,
        },
    ],
    "itaewon": [
        {
            "name": "Casa Mezcal",
            "location": "Itaewon, Seoul",
            "description": (
                "A vibrant taqueria pouring agave spirits alongside street-style tacos."
            ),
            "image_url": "https://images.unsplash.com/photo-1565299624946-b28f40a0ae38",
            "raw_category": "Mexican",
            "tags": ["₩₩", "Mexican", "Bar"],
            "lat": Decimal("37.5340"),
            "lng": Decimal("126.9945"),
            "rating": Decimal("4.20"),
            "review_count": 73,
        },
    ],
    "seongsu": [
        {
            "name": "Daelim Warehouse",
            "location": "Seongsu, Seoul",
            "description": (
                "An industrial-chic brunch spot inside a converted warehouse, "
                "known for specialty coffee."
            ),
            "image_url": "https://images.unsplash.com/photo-1554118811-1e0d58224f24",
            "raw_category": "Brunch Cafe",
            "tags": ["₩₩", "Brunch", "Cafe"],
            "lat": Decimal("37.5445"),
            "lng": Decimal("127.0557"),
            "rating": Decimal("4.60"),
            "review_count": 201,
        },
    ],
    "gangnam": [
        {
            "name": "Hanok Table",
            "location": "Gangnam, Seoul",
            "description": (
                "A refined hanjeongsik course menu showcasing seasonal Korean ingredients."
            ),
            "image_url": "https://images.unsplash.com/photo-1504674900247-0877df9cc836",
            "raw_category": "Korean Fine Dining",
            "tags": ["₩₩₩₩", "Korean", "Fine Dining"],
            "lat": Decimal("37.4979"),
            "lng": Decimal("127.0276"),
            "rating": Decimal("4.70"),
            "review_count": 312,
        },
    ],
}


class Command(BaseCommand):
    help = "Seed region-tagged restaurants for the home screen region tabs."

    def add_arguments(self, parser):
        parser.add_argument(
            "--flush",
            action="store_true",
            help="Delete all existing restaurants before seeding.",
        )

    @transaction.atomic
    def handle(self, *args, **options):
        if options["flush"]:
            deleted, _ = Restaurant.objects.all().delete()
            self.stdout.write(self.style.WARNING(f"Flushed {deleted} existing rows."))

        created = 0
        skipped = 0
        for region_slug, items in SEED_DATA.items():
            # region 은 이제 Region FK 이므로 slug 로 Region 인스턴스를 확보한다.
            region, _ = Region.objects.get_or_create(
                slug=region_slug,
                defaults={"name": region_slug.upper()},
            )
            for item in items:
                _, was_created = Restaurant.objects.get_or_create(
                    name=item["name"],
                    region=region,
                    defaults={
                        "location": item["location"],
                        "description": item["description"],
                        "image_url": item["image_url"],
                        "raw_category": item["raw_category"],
                        "tags": item["tags"],
                        "lat": item["lat"],
                        "lng": item["lng"],
                        "rating": item["rating"],
                        "review_count": item["review_count"],
                    },
                )
                if was_created:
                    created += 1
                else:
                    skipped += 1

        self.stdout.write(
            self.style.SUCCESS(
                f"Seed complete: {created} created, {skipped} already existed "
                f"across {len(SEED_DATA)} regions."
            )
        )
