# what is schema when i call GET /api/categories api

Session: `32f06577-e762-43c8-82ca-6f703e46a711`
Saved: 2026-05-20T13:22:55.258Z

## User

what is schema when i call GET /api/categories api

## Assistant

`GET /api/categories` returns `CategoryEntity[]` directly — TypeORM `find()` → JSON. The endpoint is **auth-gated** (`@UseGuards(JwtAuthGuard)`), so it needs `Authorization: Bearer <token>`.

**Schema**

```ts
type CategoriesListResponse = Array<{
  id: string;             // uuid
  slug: string;           // e.g. "travel" — immutable
  title: {
    en: string;
    ko?: string;
    zh?: string;
  };
  description: {
    en: string;
    ko?: string;
    zh?: string;
  } | null;
  order_index: number;    // smallint, ASC
  is_active: boolean;     // always true for this endpoint
  created_at: string;     // ISO-8601 timestamptz
}>
```

**Example response**

```json
[
  {
    "id": "8c4ba1f0-1a44-4f0a-9b6e-7a4f2a8e3f01",
    "slug": "travel",
    "title": { "en": "Travel", "ko": "여행", "zh": "旅行" },
    "description": null,
    "order_index": 10,
    "is_active": true,
    "created_at": "2026-05-20T01:42:11.123Z"
  },
  {
    "id": "5a2c8f10-2bfb-4d9d-bb2a-3a51d3a0b9d2",
    "slug": "business",
    "title": { "en": "Business", "ko": "비즈니스", "zh": "商务" },
    "description": null,
    "order_index": 20,
    "is_active": true,
    "created_at": "2026-05-20T01:42:11.124Z"
  },
  {
    "id": "f0e1c4a2-9b3d-4d7b-91c8-1f8c6e9d4a55",
    "slug": "social",
    "title": { "en": "Social", "ko": "소셜", "zh": "社交" },
    "description": null,
    "order_index": 30,
    "is_active": true,
    "created_at": "2026-05-20T01:42:11.125Z"
  },
  {
    "id": "2d6a7e88-0f2e-4a0c-8b3a-50b2b8eee7c1",
    "slug": "daily",
    "title": { "en": "Daily", "ko": "일상", "zh": "日常" },
    "description": null,
    "order_index": 40,
    "is_active": true,
    "created_at": "2026-05-20T01:42:11.126Z"
  }
]
```

**Sort order**: `order_index ASC, slug ASC`.

**Notes**
- Inactive rows are omitted. Use the admin endpoint `GET /api/admin/categories` (gated on `categories.view`) if you need the full list including `is_active: false` rows.
- The Flutter app currently reads `scenario.category` as a slug string — no breaking change. The new `/api/categories` endpoint is the source-of-truth for the picker / filter chips when you wire them up.

If you want it documented in Swagger with the JSON shape made explicit, I can add an `ApiOkResponse({ schema: …, isArray: true })` decorator on the controller — say the word.
