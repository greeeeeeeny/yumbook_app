"""Supabase Storage 헬퍼.

'restaurants' 버킷에 이미지를 업로드하고 공개 URL 을 돌려준다.
SERVICE ROLE 키를 사용하므로 서버사이드(관리자/수동 작업) 전용이다.
v1 CSV 임포터는 이 모듈을 호출하지 않는다(CSV 는 이미 호스팅된 URL 만 받음).

필요 환경변수:
    SUPABASE_URL                - 예: https://<ref>.supabase.co
    SUPABASE_SERVICE_ROLE_KEY   - service_role 키 (절대 클라이언트에 노출 금지)
    SUPABASE_STORAGE_BUCKET     - 기본값 'restaurants'
"""

import os
from functools import lru_cache

from supabase import create_client

DEFAULT_BUCKET = "restaurants"


class StorageConfigurationError(RuntimeError):
    """Storage 관련 환경변수가 없거나 잘못되었을 때 발생."""
    pass


def _get_bucket_name():
    return os.getenv("SUPABASE_STORAGE_BUCKET") or DEFAULT_BUCKET


@lru_cache(maxsize=1)
def _get_service_client():
    """SERVICE ROLE 키로 만든 Supabase 클라이언트.

    환경변수가 없으면 명확한 에러를 던진다.
    """
    url = os.getenv("SUPABASE_URL")
    service_key = os.getenv("SUPABASE_SERVICE_ROLE_KEY")

    missing = []
    if not url:
        missing.append("SUPABASE_URL")
    if not service_key:
        missing.append("SUPABASE_SERVICE_ROLE_KEY")

    if missing:
        raise StorageConfigurationError(
            "Supabase Storage 환경변수가 필요합니다: " + ", ".join(missing)
        )

    return create_client(url, service_key)


def upload_restaurant_image(file_bytes, dest_path, content_type="image/jpeg"):
    """식당 이미지 바이트를 'restaurants' 버킷에 업로드하고 공개 URL 을 반환한다.

    Args:
        file_bytes: 업로드할 바이너리 데이터(bytes).
        dest_path: 버킷 내부 경로. 예: "hongdae/alpero/cover.jpg".
        content_type: MIME 타입. 기본 'image/jpeg'.

    Returns:
        업로드된 객체의 공개 URL(str).

    Raises:
        StorageConfigurationError: 환경변수 누락 시.
    """
    if not file_bytes:
        raise StorageConfigurationError("업로드할 file_bytes 가 비어 있습니다.")
    if not dest_path:
        raise StorageConfigurationError("dest_path 가 비어 있습니다.")

    client = _get_service_client()
    bucket_name = _get_bucket_name()
    bucket = client.storage.from_(bucket_name)

    # 동일 경로 재업로드를 허용하기 위해 upsert.
    bucket.upload(
        path=dest_path,
        file=file_bytes,
        file_options={"content-type": content_type, "upsert": "true"},
    )

    return bucket.get_public_url(dest_path)
