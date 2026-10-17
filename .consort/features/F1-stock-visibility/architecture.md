# Architecture – F1-stock-visibility

Layering (project convention): boundary `app/routes/` (JSON API, React SPA in `client/` renders) -> service `app/services/` -> repository `app/repositories/` (sole ORM/session owner; `session.py` `get_session` re-exported by the service) -> models package `app/models/` (`stock_record.py`). Infrastructure: `app/database.py`.

S1-file-stock: all three ACs are `E2E` (form submit / retrieve panel / location combobox render real server responses). Endpoints EP1 `POST /api/stock` (upsert), EP2 `GET /api/stock?sku=&location=`, EP3 `GET /api/locations`.

S2-stock-by-location-table: all three ACs are `E2E` (home `stock-table`, quantity alignment, `stock-empty` state all render real EP4 responses). Endpoint EP4 `GET /api/stock/records?location=` (bare list); read query AP2 (filter/order by location, sku). Read path plus one additive migration: index `ix_stock_records_location_sku (location, sku)` on the pre-existing `stock_records` (AP2, SC5), reversible with row survival (PI8, NFR1 clause 2).

S3-sku-detail-view: all four ACs are `E2E` (`/sku/:sku` page renders the real EP5 `GET /api/skus/{sku}` object: per-location qty + tracking code or Not tracked, par level Not tracked, `sku-empty`). Read-only; no migration and no new persistence invariant. Query `WHERE sku = :sku AND quantity > 0 ORDER BY location` is served by the existing UNIQUE(sku, location) index (leads on sku), so no new access pattern is declared.

## Architectural Concerns Mapping

| Concern | Owner layer | Module | Notes |
|---|---|---|---|
| Input validation (field-named messages) | Boundary | `app/routes/stock.py` (Pydantic schemas) | 422 `{errors:[{field,message}]}` |
| Business rule: upsert by (sku, location) | Service | `app/services/stock_service.py` | transaction boundary |
| Persistence / ON CONFLICT upsert | Repository | `app/repositories/stock_repository.py` | only layer touching session |
| Uniqueness / non-negative qty | DB schema | migration `stock_records` | PI1, PI5 |
| Transactions | Service | `stock_service.py` | one commit per filing |
| Config / DB URL | Infrastructure | `app/database.py` | `DATABASE_URL` only |
| Logging | Cross-cutting | app logger | N/A beyond default for F1 |
| AuthN/AuthZ | — | — | Out of bounds V1 |
| Stock listing + location filter | Repository | `stock_repository.list_records` | AP2; EP4 bare list |
| Not-tracked / empty-state / alignment rendering | Client presentation | `client/src/components/StockTable.tsx`, `pages/Home.tsx` | never blank cells |
| SKU detail read + par-level null | Service / Repository | `stock_service.get_sku_detail`, `stock_repository.list_by_sku` | EP5 object; par_level null (OD4) |
| SKU detail rendering (not-tracked, empty) | Client presentation | `client/src/pages/SkuDetail.tsx` | never blank |
| Caching | — | — | Out of bounds V1 |

## Pattern proposals

- Repository pattern: `StockRepository.upsert / get / list_locations`; service depends on it (DIP), route depends on service only.
- One model module per aggregate in `app/models/` (`StockRecord`); `tracking_code` nullable.
- Client: `client/src/api/stock.ts` -> `hooks/` -> `pages/FileStock.tsx`; combobox options refetched after each filing.
- S2: `StockService.list_stock(location=None)` -> `StockRepository.list_records`; client `api/stock.ts listStock` -> `hooks/useStockRecords` -> `components/StockTable.tsx` in `pages/Home.tsx`; `warehouse-select` reuses EP3.
- S3: `StockService.get_sku_detail(sku)` -> `StockRepository.list_by_sku`; client `api/stock.ts getSkuDetail` -> `hooks/useSkuDetail` -> `pages/SkuDetail.tsx`.

## Risks

- `ON CONFLICT` is Postgres-specific; acceptable (real branch only, no in-memory DB).
- Distinct-location query scans `stock_records`; served by `ix_stock_records_location` (S1, AP1); the S2 location filter is served by the additive `ix_stock_records_location_sku` migration (PI8).
- tracking_code split (F6) will need an additive migration preserving codes (OD2).
- Unfiltered EP4 returns all rows (no pagination in V1); revisit if stock_records grows large.
- OD3 resolved by S2: an empty location = all its rows at quantity 0; EP4 hides quantity-0 rows. Revisit if a locations registry is introduced.
- Par level not stored in F1 (OD4 deferred); a later feature adds it via an additive migration and EP5 then populates `par_level`.

## Decisions

- Collision = update in place, response `created=false` -> UI shows `file-stock-updated` note. Recommend: accept.
- Locations are derived from `stock_records` (no locations table for V1). Recommend: accept.
- SKU catalog authority deferred (OD1). R2 overcommit and R1 adjustment-actor clauses are N/A in F1 (no pick/adjust operation).
- OD3 (resolved by S2-stock-by-location-table): an empty location is one whose stock_records rows are all at quantity 0. EP4 `GET /api/stock/records` excludes quantity-0 rows (`WHERE quantity > 0`), so the location filter returns `[]` and the client renders `stock-empty`; EP3 `GET /api/locations` still lists the location so `warehouse-select` offers it. AC1's 'one row per record' means per stocked (quantity > 0) record. T43 seeding a quantity-0 filing is therefore consistent; T44 asserts no rows render.
- S3: an unknown/never-filed SKU returns 200 with `locations: []` (renders `sku-empty`), not 404 — consistent with OD1 (deferred) and S1 (first filing establishes a SKU). Recommend: accept.

## Test strategy

Real integration tests against the paired Lakebase branch (pytest-bdd, Alembic applied first, FK-aware targeted DELETE cleanup); no mocks/in-memory DB. AC1–AC3 verified via API branch tests plus Playwright e2e against the live API. S2 AC1–AC3 verified via an EP4 API branch test plus Playwright e2e against the live API. S3 AC1–AC4 verified via an EP5 API branch test plus Playwright e2e against the live API. PI1–PI8 each get a real-branch DB test.

## Sign-off

Recommendation: proceed. – Architect Reviewer
