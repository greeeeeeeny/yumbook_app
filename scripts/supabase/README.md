# Supabase 셋업 스크립트

## food_records 버킷 (음식 기록 사진)

Flutter 앱의 기록 작성 화면에서 사진을 업로드할 Storage 버킷입니다.

### 1. SQL 실행

[Supabase Dashboard](https://supabase.com/dashboard) → 프로젝트 선택 → **SQL Editor** → `New query`

`setup_food_records_bucket.sql` 내용을 붙여넣고 **Run**.

이 스크립트는 멱등(idempotent)하므로 여러 번 실행해도 됩니다.

### 2. 동작 검증

Dashboard → **Storage** → `food_records` 버킷이 보이고 **Public** 뱃지가 붙어 있어야 합니다.

Dashboard → **Storage** → `food_records` → **Policies** 탭에서 4개 정책이 보여야 합니다:
- `food_records_public_read` (SELECT)
- `food_records_user_insert` (INSERT)
- `food_records_user_update` (UPDATE)
- `food_records_user_delete` (DELETE)

### 3. 업로드 경로 규약

Flutter `SupabaseStorageService.uploadFoodRecordImage` 가 사용하는 경로:

```
user/{auth.uid}/{timestamp}_{sanitized_filename}
```

RLS 정책이 이 경로의 첫 두 폴더 (`user/{uid}`) 와 `auth.uid()` 가 일치하는지 검증하므로,
경로 규약을 바꾸려면 SQL 정책도 같이 수정해야 합니다.

### 4. 비용/용량 주의

- public 버킷이라 누구나 URL 만 알면 이미지를 볼 수 있습니다 (URL 추측은 어렵지만 인덱싱 가능)
- 운영 단계에서는 thumbnail 변환 + 용량 제한 (`file_size_limit`) 추가 검토
