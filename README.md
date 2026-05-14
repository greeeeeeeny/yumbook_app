# YumBook

음식 기반 기록·예약 서비스. Flutter 앱 + Django REST API + Supabase Auth 구성의 모노레포.

## 디렉토리 구조

```
yumbook_app/
├── frontend/          # Flutter 앱 (package: yumbook_app)
│   ├── lib/           # Dart 소스
│   ├── android/ ios/ web/ macos/ linux/ windows/
│   ├── assets/
│   └── pubspec.yaml
├── backend/           # Django REST API
│   ├── yumbook_server/    # Django 프로젝트 설정
│   ├── reservations/      # Django 앱 (모델/시리얼라이저/뷰셋)
│   ├── supabase_client.py # Supabase 클라이언트 헬퍼
│   ├── manage.py
│   ├── requirements.txt
│   └── Dockerfile
├── shared/            # 언어 무관 API 계약
│   └── api/           # OpenAPI 스펙 등 (예정)
├── docker/            # Docker 보조 설정
├── docker-compose.yml # 로컬 풀스택 구동
├── scripts/           # 개발/테스트 스크립트
└── README.md
```

## 빠른 시작

### 백엔드만 (Django dev server)

```bash
./scripts/dev_backend.sh
# http://127.0.0.1:8000/api/reservations/
```

### 프론트엔드만 (Flutter web)

```bash
./scripts/dev_frontend.sh
```

### 풀스택 (Docker)

```bash
cp backend/.env.example backend/.env   # 값 채우기
docker compose up backend
```

### 테스트

```bash
./scripts/test_all.sh                  # Django 테스트 + Flutter analyze
```

## 인증 흐름

1. Flutter 가 `supabase_flutter` 로 Supabase Auth 에 직접 로그인 → access_token 획득
2. Django 호출 시 `Authorization: Bearer <token>` 헤더 동봉
3. 백엔드 `reservations/authentication.py` 의 `SupabaseAuthentication` 이
   Supabase 에 토큰 검증 후 `request.user.id` 로 사용자 식별

## 기술 스택

- **Frontend**: Flutter 3.x, Dart, Riverpod, go_router, Supabase Auth (`supabase_flutter`), `http`
- **Backend**: Django 6 + DRF, SQLite (dev), Supabase Auth 위임
- **Auth/Storage**: Supabase
- **DevOps**: Docker, GitHub Actions (예정)

## 서비스 개요

YumBook 은 사용자가 맛집·메뉴·식사 경험을 기록하고 공유하며, 식당 예약까지 수행할 수 있는 서비스입니다.

### 주요 사용자
- 일반 사용자 (음식 기록·예약)
- 음식 리뷰 작성자
- 맛집 탐색 사용자
- 관리자

### 핵심 시나리오
1. **회원가입/로그인** — Supabase OTP/비밀번호 인증
2. **음식 기록 작성** — 사진·평점·후기 업로드
3. **맛집 검색** — 키워드/지역/필터
4. **리뷰 좋아요·댓글** — 사회적 상호작용
5. **컬렉션 관리** — 가보고 싶은 곳, 데이트 맛집 등 저장
6. **식당 예약** — 날짜·인원 선택 후 Django 백엔드로 저장 (`/api/reservations/`)
