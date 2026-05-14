import os
from functools import lru_cache
from pathlib import Path

from dotenv import load_dotenv
from supabase import create_client

load_dotenv(Path(__file__).resolve().parent / ".env")


class SupabaseConfigurationError(RuntimeError):
    pass


@lru_cache(maxsize=1)
def get_supabase_client():
    url = os.getenv("SUPABASE_URL")
    key = os.getenv("SUPABASE_ANON_KEY") or os.getenv("SUPABASE_KEY")

    missing = []
    if not url:
        missing.append("SUPABASE_URL")
    if not key:
        missing.append("SUPABASE_ANON_KEY")

    if missing:
        raise SupabaseConfigurationError(
            "Supabase 환경변수가 필요합니다: " + ", ".join(missing)
        )

    return create_client(url, key)


class _SupabaseProxy:
    def __getattr__(self, name):
        return getattr(get_supabase_client(), name)


supabase = _SupabaseProxy()
