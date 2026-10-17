# architect-reviewer (architect-reviewer) – opus

## Prompt

```
Annotate story S3-sku-detail-view's acceptance criteria + nfrs.md coverage. Author architectural_notes for ALL of story S3-sku-detail-view's ACs: AC1-lists-stock-across-locations, AC2-shows-tracking-code, AC3-par-level-not-tracked, AC4-sku-with-no-stock-empty-state. Every one of this story's ACs MUST end up with a non-empty "architectural_notes" field in its acs/<AC>.json (the layer it lives in + how it realizes the design) — the design gate verifies that, and the spec-author's "layer" field does NOT count. architectural_notes are per-AC, so author the scoped ACs above even when the feature-level architecture.json already exists from an earlier story. For every E2E AC, ALSO pass consort-annotate-ac --ui-seams with the ia.md data-testid seam token(s) the AC's UI drives — the column / cell / region / empty-state / form field it asserts (e.g. "stock-cell-tracking,stock-not-tracked"). A deterministic gate checks each seam is named in <PROJECT_ROOT>/.consort/design/ia.md; if the AC needs a surface the IA does not yet name, declare the seam you need anyway and the gate routes the ux-designer to add it to ia.md. In architecture.json, make an EXPLICIT service_backed call (required): set service_backed:true if the feature persists data (a DB table/migration) or carries business logic, and then you MUST declare boundary, service, and repository layers (plus a "models" PACKAGE app/models/, one module per domain object, NOT a flat app/models.py, when it persists entities); set false ONLY for a trivial static/read-through endpoint. An Infra-layer AC or a migration/schema/storage NFR while service_backed is false hard-blocks the gate. When service_backed:true you MUST also declare architecture.json persistence_invariants[]: the DB-level guarantees the schema enforces (each with id, type one of unique|foreign_key|cascade|not_null|check|transactional|migration_reversible, table, and a one-line brief), covering unique/composite keys, foreign keys + cascade rules, NOT NULL / CHECK constraints, any transactional-atomicity boundary, and migration reversibility. The test-strategist must cover each with a real-branch test; a service_backed feature with no persistence_invariants hard-blocks the gate. When THIS story introduces a NEW read/query shape over the schema — a filter, lookup, sort, or join an AC drives (e.g. "list stock filtered by location", "look up a SKU's rows by sku") that is an INDEX candidate — declare it in architecture.json access_patterns[] (id, a one-line brief, and the table + column(s) it reads) so the DBA is pulled back in to reconsider the physical design for it; this is how a later READ story evolves the schema, since a story that adds no persistence_invariant would otherwise skip the DBA. Declare an access_pattern ONLY for a genuinely new query shape (not for every read, and not for one already covered by a prior story's pattern or a primary-key lookup). REUSE the established project architecture conventions (set by F1-stock-visibility): boundary=app/routes (react), service=app/services, repository=app/repositories, models=app/models, infrastructure=app/database.py. Declare the SAME role -> module paths in architecture.json, do NOT remap or rename an established layer; a divergent layout hard-blocks the spec gate and mismatches the inherited code. Author this story's architectural_notes FRESH from the ACs + IA on disk this turn. On a reflect-revise re-run the self-heal clears this story's prior architectural_notes BY DESIGN, so an absent/empty prior is the expected revise state — re-derive against the corrected ACs + IA. Write every artifact under the ABSOLUTE artifact root <PROJECT_ROOT>/.consort (this feature: <PROJECT_ROOT>/.consort/features/F1-stock-visibility/; this story: <PROJECT_ROOT>/.consort/features/F1-stock-visibility/stories/S3-sku-detail-view/); use that absolute path and never resolve or guess the project root yourself.CROSS-STORY CONTEXT — this story is NOT reviewed in isolation. The feature's OTHER stories' ACs, the architecture's open_decisions, and its mandated (not-null) persistence fields are below; use them for the cross-story checks (an AC contradicting a gated sibling AC; a mandated field no sibling submit AC supplies). This IS that context — do not run `consort-cross-story-context` yourself.

{
  "current_story": "S3-sku-detail-view",
  "sibling_stories": [
    {
      "story": "S1-file-stock",
      "acs": [
        {
          "ac_id": "AC1-file-stock-record",
          "status": "draft",
          "layer": "E2E",
          "given": "the operator is on the file-stock screen, where locations already on record are offered to choose from and a brand-new location can still be entered",
          "when": "the operator submits a SKU, a location (chosen from the offered locations or newly entered), a quantity and a tracking code",
          "then": "the screen confirms the stock was filed for that (sku, location), showing its quantity and tracking code, and a newly entered location is accepted without being blocked",
          "architectural_notes": "E2E: a client form submission whose confirmation is derived from the real POST /api/stock response, so it is verified by Playwright against the live API on the paired branch. Boundary app/routes/stock.py validates input and calls app/services/stock_service.py (upsert by (sku, location)), which persists via app/repositories/stock_repository.py; the field-location combobox options come from GET /api/locations (EP3-list-locations), and a new location is plain free text, never rejected. Validation messages name the offending field at the boundary; no actor/auth (out of bounds V1)."
        },
        {
          "ac_id": "AC2-retrieve-stock-record",
          "status": "draft",
          "layer": "E2E",
          "given": "a stock record has been filed for a SKU at a location with a quantity and tracking code",
          "when": "the operator retrieves the stock for that (sku, location) later",
          "then": "the returned record shows the same SKU, location, quantity and combined tracking code that were filed, and that location is now offered as a known location when filing stock",
          "architectural_notes": "E2E: the retrieve panel renders the server's GET /api/stock?sku=&location= response, and the field-location combobox is re-queried from GET /api/locations after filing, so both halves are client-server contracts verified by Playwright on the paired branch. Read path is boundary app/routes/stock.py -> app/services/stock_service.py -> app/repositories/stock_repository.py (lookup on the unique (sku, location) key; distinct-locations query AP1); durability is proven by a real-DB read-back, never a mock."
        },
        {
          "ac_id": "AC3-collision-resolved-at-write",
          "status": "draft",
          "layer": "E2E",
          "given": "a stock record already exists for a (sku, location) pair",
          "when": "the operator files stock for the same (sku, location) pair again with a different quantity or tracking code",
          "then": "the existing record is updated in place with the new values, exactly one record exists for that pair, no duplicate is stored, and the operator sees a normal confirmation rather than an error page",
          "architectural_notes": "E2E: re-submitting the form for an existing (sku, location) must render a normal confirmation with the file-stock-updated note derived from the real POST response (created=false), never an error page. The collision is resolved in the repository via a single INSERT ... ON CONFLICT (sku, location) DO UPDATE inside the service-owned transaction, backed by the unique constraint PI1 so concurrent writes can never store a duplicate; a branch-DB test asserts exactly one row for the pair."
        }
      ]
    },
    {
      "story": "S2-stock-by-location-table",
      "acs": [
        {
          "ac_id": "AC1-table-lists-stock-by-location",
          "status": "draft",
          "layer": "E2E",
          "given": "stock records exist for several (sku, location) pairs, some with a tracking code and some without",
          "when": "the operator opens the home screen",
          "then": "a stock-by-location table shows one row per (sku, location) record with SKU, location, quantity and tracking code columns; each tracking code cell shows its value, or an explicit \"not tracked\" when absent, and is never blank",
          "architectural_notes": "E2E: the home stock-table renders the real EP4 GET /api/stock/records response, verified by Playwright against the live API on the paired branch. One row per STOCKED (sku, location) record: EP4 excludes quantity-0 rows (OD3 resolved), so seeded rows must have quantity > 0; a null tracking_code renders the stock-not-tracked badge client-side, never blank. Read path app/routes/stock.py -> app/services/stock_service.py -> app/repositories/stock_repository.py (AP2, ix_stock_records_location_sku)."
        },
        {
          "ac_id": "AC2-quantity-right-aligned",
          "status": "draft",
          "layer": "E2E",
          "given": "the home-screen stock table lists stock records with quantities of differing digit lengths",
          "when": "the operator scans the quantity column",
          "then": "quantity values are right-aligned in their column so magnitudes line up for scanning",
          "architectural_notes": "E2E: quantity cells rendered from real EP4 rows (quantity > 0, differing digit lengths) are asserted right-aligned (computed text-align right, tabular-nums) in Playwright against the live API. Pure presentation in the React stock-table component under client/src/components; no server logic beyond the EP4 read path."
        },
        {
          "ac_id": "AC3-empty-location-state",
          "status": "draft",
          "layer": "E2E",
          "given": "a location is on record but has no stock filed at it",
          "when": "the operator views that location's stock on the home screen",
          "then": "an explicit \"No stock at this location\" state is shown instead of a blank page or empty table",
          "architectural_notes": "E2E: OD3 resolved - a location on record with no stock is one whose stock_records rows are all at quantity 0; seed it via a quantity-0 filing (valid under CHECK quantity >= 0). EP3 GET /api/locations still lists it so warehouse-select offers it, while EP4 GET /api/stock/records?location= excludes quantity-0 rows (repository WHERE quantity > 0) and returns [], so the client renders stock-empty 'No stock at this location' and no stock-table rows. Verified by Playwright against the live API on the paired branch."
        }
      ]
    }
  ],
  "open_decisions": [
    {
      "id": "OD1-sku-catalog-authority",
      "question": "Is stock_records the authority on whether a SKU is 'known' (first filing establishes the SKU), or will a later feature introduce a separate SKU catalog?",
      "decision_status": "deferred"
    },
    {
      "id": "OD2-tracking-code-split",
      "question": "When the combined tracking_code is split into location/batch/serial (F6), is it an additive column migration on stock_records preserving existing codes?",
      "decision_status": "deferred"
    },
    {
      "id": "OD3-empty-location-representation",
      "question": "Locations are derived from stock_records (no locations table), so how is a location 'on record but with no stock' represented: rows at quantity 0 (and does the filtered table then hide zero-quantity rows), or a separate locations registry?",
      "decision_status": "resolved",
      "resolved_by_story": "S2-stock-by-location-table",
      "resolution": "A location 'on record with no stock' is one whose stock_records rows are all at quantity 0 (no locations registry). EP4 GET /api/stock/records excludes quantity-0 rows, so filtering to such a location returns [] and renders stock-empty; EP3 GET /api/locations still lists it (distinct over all rows), so warehouse-select offers it. Consistent with S1: a quantity-0 filing is valid (CHECK quantity >= 0) and S1 AC2 retrieve by (sku, location) via EP2 still returns the qty-0 record."
    }
  ],
  "required_persistence_fields": [
    {
      "invariant_id": "PI2-not-null-sku",
      "table": "stock_records",
      "brief": "sku is NOT NULL: inserting a row with a null sku is rejected by the database."
    },
    {
      "invariant_id": "PI3-not-null-location",
      "table": "stock_records",
      "brief": "location is NOT NULL: inserting a row with a null location is rejected by the database."
    },
    {
      "invariant_id": "PI4-not-null-quantity",
      "table": "stock_records",
      "brief": "quantity is NOT NULL: inserting a row with a null quantity is rejected by the database (tracking_code is deliberately nullable — absent renders as 'not tracked')."
    }
  ]
} Be terse: produce ONLY the required artifact file(s) on disk, then stop with at most a one-line confirmation. Do NOT print a plan, a summary of what you did, rationale, tables, or restate the artifacts to stdout, that output is wasted latency. The files on disk are the deliverable, not your prose.
```

## Tools used

- Bash {"command":"cd <PROJECT_ROOT>/.consort/features/F1-stock-visibility; for f in stories/S3-sku-detail-view/acs/*.json; do echo \"== $f\"; cat $f; echo; done; cat architecture.json; grep -n \"sku\" ../../design/ia.md | head -60","description":"Read S3 ACs, architecture, IA seams"}
- Bash {"command":"cd <PROJECT_ROOT> && F=F1-stock-visibility S=S3-sku-detail-view\n./scripts/lk consort-annotate-ac --feature $F --story $S --ac AC1-lists-stock-across-locations --layer E2E --api-contract EP5-get-sku-detail --ui-seams \"sku-detail,sku-locations,sku-location-<loc>,sku-qty-<loc>\" --notes \"E2E: the /sku/:sku React page renders the real EP5 GET /api/skus/{sku} response, verified by Playwright against the live API on the paired branch; seed two+ locations for the SKU plus another SKU's row to prove only this SKU's records appear. Read path app/routes/stock.py -> app/services/stock_service.py -> app/repositories/stock_repository.py (WHERE sku = :sku AND quantity > 0, served by the UNIQUE(sku, location) index PI1); quantity-0 rows are excluded consistent with OD3/EP4.\" &&\n./scripts/lk consort-annotate-ac --feature $F --story $S --ac AC2-shows-tracking-code --layer E2E --api-contract EP5-get-sku-detail --ui-seams \"sku-tracking-<loc>,sku-not-tracked\" --notes \"E2E: each sku-location entry renders tracking_code from the real EP5 response; a null tracking_code (nullable column, no not_null invariant) renders the sku-not-tracked badge client-side, never blank. Verified by Playwright on the paired branch with one tracked and one untracked location for the SKU; no server logic beyond the EP5 read path.\" &&\n./scripts/lk consort-annotate-ac --feature $F --story $S --ac AC3-par-level-not-tracked --layer E2E --api-contract EP5-get-sku-detail --ui-seams \"sku-par-level,sku-par-not-tracked\" --notes \"E2E: F1 stores no par level (no column; par levels are owned by a later feature, OD4 deferred), so the service returns par_level null in EP5 and the client renders sku-par-level with the sku-par-not-tracked state instead of a blank region. Verified by Playwright against the live API: the page renders without error and the par region shows Not tracked. No schema change.\" &&\n./scripts/lk consort-annotate-ac --feature $F --story $S --ac AC4-sku-with-no-stock-empty-state --layer E2E --api-contract EP5-get-sku-detail --ui-seams \"sku-empty\" --notes \"E2E: stock_records remains the SKU authority (OD1 deferred), so a SKU with no stocked row (never filed, or only quantity-0 rows) is not an error: the service returns 200 with an empty locations list (never 404/5xx) and the client renders sku-empty with the Receive CTA to /receive?sku=<sku>, no sku-location entries. Verified by Playwright against the live API on the paired branch.\"","description":"Annotate four S3 ACs"}
- Bash {"command":"grep -n \"^#\" architecture.md","description":"List architecture.md sections"}
- Bash {"command":"cd <PROJECT_ROOT>/.consort/features/F1-stock-visibility && ls; ls stories/*/","description":"List feature dir"}
- Read {"file_path":"<PROJECT_ROOT>/.consort/features/F1-stock-visibility/architecture.md"}
- Bash {"command":"python3 -I - <<'EOF'\nimport json\np='architecture.json'; a=json.load(open(p))\na['api_contracts']=[c for c in a['api_contracts'] if c['id']!='EP5-get-sku-detail']+[{\n \"id\":\"EP5-get-sku-detail\",\"method\":\"GET\",\"path\":\"/api/skus/{sku}\",\"shape\":\"object\",\n \"item\":\"200 {sku: str, par_level: int|null (always null in F1 - no par level stored), locations: [{location: str, quantity: int>0, tracking_code: str|null}]} with locations ordered by location, only this SKU's STOCKED rows (quantity-0 rows excluded per OD3); locations is [] for a SKU with no stocked row (never filed or only quantity-0 rows) - still 200, never 404 (OD1: stock_records is the SKU authority).\",\n \"story\":\"S3-sku-detail-view\"}]\nods=[o for o in a['open_decisions'] if o['id']!='OD4-par-level-source']\nods.append({\"id\":\"OD4-par-level-source\",\"question\":\"Where will a SKU's par level be stored (a per-SKU or per-(sku, location) column/table) when a later feature tracks it? F1 stores none and EP5 returns par_level null.\",\"decision_status\":\"deferred\"})\na['open_decisions']=ods\njson.dump(a,open(p,'w'),indent=2)\nEOF\npython3 -I - <<'EOF'\np='architecture.md'; s=open(p).read()\ns=s.replace(\"\\n## Architectural Concerns Mapping\",\"\\nS3-sku-detail-view: all four ACs are `E2E` (`/sku/:sku` page renders the real EP5 `GET /api/skus/{sku}` object: per-location qty + tracking code or Not tracked, par level Not tracked, `sku-empty`). Read-only; no migration and no new persistence invariant. Query `WHERE sku = :sku AND quantity > 0 ORDER BY location` is served by the existing UNIQUE(sku, location) index (leads on sku), so no new access pattern is declared.\\n\\n## Architectural Concerns Mapping\",1)\ns=s.replace(\"| Caching |\",\"| SKU detail read + par-level null | Service / Repository | `stock_service.get_sku_detail`, `stock_repository.list_by_sku` | EP5 object; par_level null (OD4) |\\n| SKU detail rendering (not-tracked, empty) | Client presentation | `client/src/pages/SkuDetail.tsx` | never blank |\\n| Caching |\",1)\ns=s.replace(\"\\n## Risks\",\"- S3: `StockService.get_sku_detail(sku)` -> `StockRepository.list_by_sku`; client `api/stock.ts getSkuDetail` -> `hooks/useSkuDetail` -> `pages/SkuDetail.tsx`.\\n\\n## Risks\",1)\ns=s.replace(\"\\n## Decisions\",\"- Par level not stored in F1 (OD4 deferred); a later feature adds it via an additive migration and EP5 then populates `par_level`.\\n\\n## Decisions\",1)\ns=s.replace(\"\\n## Test strategy\",\"- S3: an unknown/never-filed SKU returns 200 with `locations: []` (renders `sku-empty`), not 404 — consistent with OD1 (deferred) and S1 (first filing establishes a SKU). Recommend: accept.\\n\\n## Test strategy\",1)\ns=s.replace(\"PI1–PI7 each\",\"S3 AC1–AC4 verified via an EP5 API branch test plus Playwright e2e against the live API. PI1–PI8 each\",1)\nopen(p,'w').write(s)\nEOF\ncd <PROJECT_ROOT> && ./scripts/lk consort-response-formatter --role architect-reviewer --feature F1-stock-visibility --story S3-sku-detail-view","description":"Update architecture artifacts and self-check"}

## Final reasoning

All four S3 ACs now have `architectural_notes`, layer `E2E` and their UI seams. The architecture files are updated too: a new endpoint `EP5 GET /api/skus/{sku}` and a new open decision `OD4-par-level-source` (where par levels will be stored is deferred, so the endpoint always returns `par_level: null`). I added no new access pattern because the existing unique (sku, location) index already serves the SKU lookup. The self-check passes.
