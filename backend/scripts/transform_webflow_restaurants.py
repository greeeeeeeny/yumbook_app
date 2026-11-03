#!/usr/bin/env python3
"""Transform a raw Webflow restaurant CSV export into the canonical CSV that
`python manage.py import_restaurants` consumes.

This is a standalone script (no Django required). It is intentionally tolerant
of column-name variations and missing optional fields.

Usage:
    python scripts/transform_webflow_restaurants.py INPUT.csv OUTPUT.csv
    python scripts/transform_webflow_restaurants.py INPUT.csv OUTPUT.csv --dry-run

Canonical output headers (exact order):
    name,region,category,image_url,address,description,rating,price_level,latitude,longitude

A row is KEPT only if it yields a non-empty `name` AND `region`. Otherwise it is
skipped (with a warning). Missing optional fields are left blank.

Note: the current importer consumes name/region/category/image_url/address/
description/rating. price_level/latitude/longitude are emitted for completeness
but are not stored by today's importer (see PRODUCTION_RUNBOOK.md §4.1).
"""

import argparse
import csv
import sys

CANONICAL_HEADERS = [
    "name",
    "region",
    "category",
    "image_url",
    "address",
    "description",
    "rating",
    "price_level",
    "latitude",
    "longitude",
]

# Candidate source column names per canonical field (matched case/space-insensitively,
# tried in order; first non-empty value wins).
FIELD_CANDIDATES = {
    "name": ["nameEnglish", "name", "Name (English)", "restaurant name", "Title"],
    "category": ["Category 1", "Category 2", "Category 3", "category", "cuisine"],
    "image_url": ["image_url", "imageUrl", "image", "photo"],
    "address": ["Address (English)", "address", "Address"],
    "description": [
        "Restaurant Description",
        "description",
        "Restaurant Description (Short)",
        "summary",
    ],
    "rating": ["rating", "Rating", "stars", "score"],
    "price_level": ["price_level", "Price ($)", "price", "Price", "price level"],
    "latitude": ["latitude", "Latitude", "lat", "Lat"],
    "longitude": ["longitude", "Longitude", "lng", "Lng", "lon"],
}

# Columns scanned (in addition to an explicit region column) to infer the region.
REGION_SOURCE_CANDIDATES = [
    "region",
    "Location",
    "neighborhood",
    "area",
    "태그",
    "tags",
    "Address (English)",
    "Address",
]

# The five supported home-screen regions → canonical slug.
KNOWN_REGIONS = ["insadong", "hongdae", "itaewon", "seongsu", "gangnam"]


def _norm(text):
    return (text or "").strip().lower()


def _build_lookup(fieldnames):
    """normalized header -> original header (first occurrence wins)."""
    lookup = {}
    for original in fieldnames or []:
        key = _norm(original)
        if key and key not in lookup:
            lookup[key] = original
    return lookup


def _resolve(candidates, lookup):
    """Return the list of actual column names present, in candidate priority order."""
    resolved = []
    for cand in candidates:
        original = lookup.get(_norm(cand))
        if original and original not in resolved:
            resolved.append(original)
    return resolved


def _first_value(row, columns):
    for col in columns:
        value = (row.get(col) or "").strip()
        if value:
            return value
    return ""


def _slugify(text):
    """Generic slug: lowercase, keep a-z0-9, collapse the rest away."""
    out = []
    for ch in _norm(text):
        if ch.isalnum():
            out.append(ch)
    return "".join(out)


def _infer_region(row, region_columns):
    """Return (slug, warning_or_None)."""
    # Concatenate all region-source values to scan for known region keywords.
    haystack = " ".join((row.get(c) or "") for c in region_columns).lower()
    for slug in KNOWN_REGIONS:
        if slug in haystack:
            return slug, None

    # Fallback: slugify the first segment of the first region-source value.
    raw = _first_value(row, region_columns)
    if not raw:
        return "", "region could not be determined"
    first_segment = raw.split(",")[0]
    slug = _slugify(first_segment)
    if not slug:
        return "", f"region could not be slugified from {raw!r}"
    return slug, f"non-standard region {raw!r} → slug {slug!r}"


def _pick_category(row, category_columns):
    """Prefer a real cuisine over Webflow 'Taste <area>' tag columns."""
    values = [(row.get(c) or "").strip() for c in category_columns]
    values = [v for v in values if v]
    for v in values:
        if not v.lower().startswith("taste "):
            return v
    return values[0] if values else ""


def _parse_price_level(text):
    """'$$$' / '₩₩' / '3' / 'moderate' → '1'..'4' or '' if unknown."""
    text = (text or "").strip()
    if not text:
        return ""
    if text.isdigit():
        n = int(text)
        return str(n) if 1 <= n <= 4 else ""
    symbols = sum(text.count(s) for s in ("$", "₩", "€", "£", "¥"))
    if symbols:
        return str(min(max(symbols, 1), 4))
    return ""


def _parse_float(text):
    text = (text or "").strip()
    if not text:
        return ""
    try:
        return str(float(text))
    except ValueError:
        return ""


def _parse_image_url(text):
    """Keep only real http(s) URLs. Wix/relative refs are dropped (with a warning)."""
    text = (text or "").strip()
    if not text:
        return "", None
    if text.startswith("http://") or text.startswith("https://"):
        return text, None
    return "", f"non-URL image reference dropped ({text[:40]!r})"


def transform(input_path, output_path, dry_run=False):
    stats = {"read": 0, "written": 0, "skipped": 0, "warnings": []}
    output_rows = []

    with open(input_path, "r", encoding="utf-8-sig", newline="") as f:
        reader = csv.DictReader(f)
        lookup = _build_lookup(reader.fieldnames)

        cols = {
            field: _resolve(cands, lookup)
            for field, cands in FIELD_CANDIDATES.items()
        }
        region_cols = _resolve(REGION_SOURCE_CANDIDATES, lookup)

        for index, row in enumerate(reader, start=1):
            stats["read"] += 1

            name = _first_value(row, cols["name"])
            region, region_warn = _infer_region(row, region_cols)

            if not name:
                stats["skipped"] += 1
                stats["warnings"].append(f"row {index}: skipped (no name)")
                continue
            if not region:
                stats["skipped"] += 1
                detail = region_warn or "no region"
                stats["warnings"].append(
                    f"row {index} ({name!r}): skipped ({detail})"
                )
                continue
            if region_warn:
                stats["warnings"].append(f"row {index} ({name!r}): {region_warn}")

            image_url, image_warn = _parse_image_url(
                _first_value(row, cols["image_url"])
            )
            if image_warn:
                stats["warnings"].append(f"row {index} ({name!r}): {image_warn}")

            output_rows.append(
                {
                    "name": name,
                    "region": region,
                    "category": _pick_category(row, cols["category"]),
                    "image_url": image_url,
                    "address": _first_value(row, cols["address"]),
                    "description": _first_value(row, cols["description"]),
                    "rating": _parse_float(_first_value(row, cols["rating"])),
                    "price_level": _parse_price_level(
                        _first_value(row, cols["price_level"])
                    ),
                    "latitude": _parse_float(_first_value(row, cols["latitude"])),
                    "longitude": _parse_float(_first_value(row, cols["longitude"])),
                }
            )
            stats["written"] += 1

    if not dry_run:
        with open(output_path, "w", encoding="utf-8", newline="") as out:
            writer = csv.DictWriter(out, fieldnames=CANONICAL_HEADERS)
            writer.writeheader()
            writer.writerows(output_rows)

    return stats


def main(argv=None):
    # Windows 콘솔(cp949)에서 유니코드 출력이 깨지지 않도록 utf-8 강제.
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except Exception:
        pass

    parser = argparse.ArgumentParser(
        description="Transform a raw Webflow restaurant CSV into the canonical "
        "import_restaurants format."
    )
    parser.add_argument("input", help="Path to the raw Webflow CSV export.")
    parser.add_argument("output", help="Path to write the canonical CSV.")
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Parse and report only; do not write the output file.",
    )
    args = parser.parse_args(argv)

    try:
        stats = transform(args.input, args.output, dry_run=args.dry_run)
    except FileNotFoundError:
        parser.error(f"input CSV not found: {args.input}")

    mode = "DRY-RUN (no file written)" if args.dry_run else f"wrote {args.output}"
    print(f"Transform {mode}:")
    print(f"  rows read:    {stats['read']}")
    print(f"  rows written: {stats['written']}")
    print(f"  rows skipped: {stats['skipped']}")
    print(f"  warnings:     {len(stats['warnings'])}")
    for warn in stats["warnings"]:
        print(f"    - {warn}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
