-- ============================================================
-- YumBook: food_records Storage 버킷 + RLS 정책 셋업
--
-- 실행 위치: Supabase Dashboard → SQL Editor
-- 권한:     service_role 또는 dashboard owner
-- 멱등성:   여러 번 실행해도 안전 (DROP POLICY IF EXISTS 사용)
--
-- 정책 요약:
--   * 버킷:   food_records (public read)
--   * 업로드: 인증 사용자만, 경로 첫 폴더가 "user/{auth.uid}/" 일 때
--   * 수정:   본인이 업로드한 객체만
--   * 삭제:   본인이 업로드한 객체만
--   * 조회:   anon/authenticated 모두 허용 (public)
-- ============================================================

-- 1) 버킷 생성 (이미 있으면 public 플래그만 보장)
insert into storage.buckets (id, name, public)
values ('food_records', 'food_records', true)
on conflict (id) do update set public = excluded.public;

-- 2) 기존 정책 제거 (재실행 안전)
drop policy if exists "food_records_public_read"    on storage.objects;
drop policy if exists "food_records_user_insert"    on storage.objects;
drop policy if exists "food_records_user_update"    on storage.objects;
drop policy if exists "food_records_user_delete"    on storage.objects;

-- 3) 공개 read
create policy "food_records_public_read"
  on storage.objects for select
  using (bucket_id = 'food_records');

-- 4) 인증 사용자만 자기 폴더에 업로드
--    Flutter 업로드 경로: user/{uid}/{timestamp}_{filename}
create policy "food_records_user_insert"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'food_records'
    and (storage.foldername(name))[1] = 'user'
    and (storage.foldername(name))[2] = auth.uid()::text
  );

-- 5) 본인 객체만 수정/삭제 (소유자 컬럼 = 업로더 uid)
create policy "food_records_user_update"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'food_records'
    and owner = auth.uid()
  );

create policy "food_records_user_delete"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'food_records'
    and owner = auth.uid()
  );

-- 6) (선택) 빠른 검증 쿼리 — 주석 해제해서 확인
-- select id, name, public from storage.buckets where id = 'food_records';
-- select policyname, cmd from pg_policies
--   where schemaname='storage' and tablename='objects'
--   and policyname like 'food_records_%';
