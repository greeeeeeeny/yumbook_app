"""CSV 파일로부터 식당 데이터를 임포트하는 관리 명령어.

이미 호스팅된 image_url 을 그대로 받는다(로컬 이미지 업로드 X).
실제 임포트 로직은 restaurants.importer 에 있고, admin 임포트 뷰와 공유한다.

사용법:
    python manage.py import_restaurants <csv_path>
    python manage.py import_restaurants <csv_path> --update     # 기존 식당 필드도 갱신
    python manage.py import_restaurants <csv_path> --dry-run     # DB 반영 없이 결과만 출력

CSV 헤더:
    name,region,category,image_url,address,description,rating
    (선택 컬럼: is_primary, storage_path)
"""

from django.core.management.base import BaseCommand, CommandError

from restaurants.importer import import_restaurants_from_file


class Command(BaseCommand):
    help = "Import region-tagged restaurants from a CSV file (already-hosted image URLs)."

    def add_arguments(self, parser):
        parser.add_argument(
            "csv_path",
            help="Path to the CSV file to import.",
        )
        parser.add_argument(
            "--update",
            action="store_true",
            help="Update fields on existing restaurants instead of skipping them.",
        )
        parser.add_argument(
            "--dry-run",
            action="store_true",
            help="Parse and validate without writing to the database.",
        )

    def handle(self, *args, **options):
        csv_path = options["csv_path"]
        update = options["update"]
        dry_run = options["dry_run"]

        try:
            with open(csv_path, "rb") as fileobj:
                stats = import_restaurants_from_file(
                    fileobj, update=update, dry_run=dry_run
                )
        except FileNotFoundError:
            raise CommandError(f"CSV 파일을 찾을 수 없습니다: {csv_path}")
        except OSError as exc:
            raise CommandError(f"CSV 파일을 열 수 없습니다: {csv_path} ({exc})")

        mode = "DRY-RUN (no changes written)" if dry_run else "applied"
        self.stdout.write(
            self.style.SUCCESS(
                "Import {mode}:\n"
                "  restaurants: {rc} created, {ru} updated, {rs} skipped\n"
                "  regions:     {regc} created\n"
                "  images:      {ic} created, {iu} updated".format(
                    mode=mode,
                    rc=stats["restaurants_created"],
                    ru=stats["restaurants_updated"],
                    rs=stats["restaurants_skipped"],
                    regc=stats["regions_created"],
                    ic=stats["images_created"],
                    iu=stats["images_updated"],
                )
            )
        )

        if stats["errors"]:
            self.stdout.write(self.style.WARNING(f"{len(stats['errors'])} warning(s):"))
            for err in stats["errors"]:
                self.stdout.write(self.style.WARNING(f"  - {err}"))
