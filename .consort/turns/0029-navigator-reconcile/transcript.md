# navigator-reconcile (navigator) – sonnet

## Prompt

```
FEATURE-COMPLETE RECONCILIATION for F1-stock-visibility: every story is now designed + gated. Independently check the WHOLE set of stories against ITSELF — symmetrically, every story vs every other, INCLUDING the first-designed story (which was never checked against its later siblings). The cross-story context (all stories' ACs + the architecture's open_decisions + its mandated not-null fields) is injected below. Look ONLY for CROSS-STORY defects: an AC that contradicts another story's gated AC; a mandated (not-null) field no story's submit AC supplies; two stories' ACs overlapping on the same observable behavior; a persistence invariant anchored to the wrong story. Do NOT re-review a single story in isolation — each already passed its own reflect + gate. Write the verdict to <PROJECT_ROOT>/.consort/features/F1-stock-visibility/reconcile-verdict.json: {"version":1,"passed":<bool>,"findings":[{"owner":"spec-author"|"test-strategist"|"architect-reviewer"|"ux-designer","story":"<the OWNING story to change>","detail":"<the cross-story defect>","ac_ids":["<exact AC id(s)>"],"severity":"blocking"|"advisory"}]}. Use passed:true with findings:[] when the stories are mutually consistent. Each finding names the OWNING story (the one reopened + changed) and its author. Produce ONLY the verdict file, then stop.FEATURE-COMPLETE CROSS-STORY RECONCILIATION — every story below is now designed + gated. Check the WHOLE set against ITSELF, symmetrically (every story vs every other, including the first-designed one): an AC that contradicts another story's gated AC; a mandated (not-null) field no story's submit AC supplies; two stories' ACs that overlap on the same observable behavior; an invariant anchored to the wrong story. For each defect, name the OWNING story (the one to change) + its author (owner). This IS the context — do not run `consort-cross-story-context` yourself.

{
  "stories": [
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
    },
    {
      "story": "S3-sku-detail-view",
      "acs": [
        {
          "ac_id": "AC1-lists-stock-across-locations",
          "status": "draft",
          "layer": "E2E",
          "given": "a SKU has stock filed at two or more locations",
          "when": "the operator opens that SKU's detail view",
          "then": "the detail view lists each location holding that SKU with its quantity, one entry per (sku, location) record and only that SKU's records",
          "architectural_notes": "E2E: the /sku/:sku React page renders the real EP5 GET /api/skus/{sku} response, verified by Playwright against the live API on the paired branch; seed two+ locations for the SKU plus another SKU's row to prove only this SKU's records appear. Read path app/routes/stock.py -> app/services/stock_service.py -> app/repositories/stock_repository.py (WHERE sku = :sku AND quantity > 0, served by the UNIQUE(sku, location) index PI1); quantity-0 rows are excluded consistent with OD3/EP4."
        },
        {
          "ac_id": "AC2-shows-tracking-code",
          "status": "draft",
          "layer": "E2E",
          "given": "a SKU has stock records whose combined tracking codes were filed",
          "when": "the operator opens that SKU's detail view",
          "then": "each location entry shows that record's combined tracking code, or an explicit \"not tracked\" where none was filed, never blank",
          "architectural_notes": "E2E: each sku-location entry renders tracking_code from the real EP5 response; a null tracking_code (nullable column, no not_null invariant) renders the sku-not-tracked badge client-side, never blank. Verified by Playwright on the paired branch with one tracked and one untracked location for the SKU; no server logic beyond the EP5 read path."
        },
        {
          "ac_id": "AC3-par-level-not-tracked",
          "status": "draft",
          "layer": "E2E",
          "given": "a SKU has stock filed but no par level is tracked for it",
          "when": "the operator opens that SKU's detail view",
          "then": "the par level region shows a clear \"not tracked\" instead of a blank region, and the view renders without error",
          "architectural_notes": "E2E: F1 stores no par level (no column; par levels are owned by a later feature, OD4 deferred), so the service returns par_level null in EP5 and the client renders sku-par-level with the sku-par-not-tracked state instead of a blank region. Verified by Playwright against the live API: the page renders without error and the par region shows Not tracked. No schema change."
        },
        {
          "ac_id": "AC4-sku-with-no-stock-empty-state",
          "status": "draft",
          "layer": "E2E",
          "given": "a SKU has no stock filed at any location",
          "when": "the operator opens that SKU's detail view",
          "then": "an explicit empty state says the SKU has no stock at any location, instead of a blank page, an empty list or an error page",
          "architectural_notes": "E2E: stock_records remains the SKU authority (OD1 deferred), so a SKU with no stocked row (never filed, or only quantity-0 rows) is not an error: the service returns 200 with an empty locations list (never 404/5xx) and the client renders sku-empty with the Receive CTA to /receive?sku=<sku>, no sku-location entries. Verified by Playwright against the live API on the paired branch."
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
    },
    {
      "id": "OD4-par-level-source",
      "question": "Where will a SKU's par level be stored (a per-SKU or per-(sku, location) column/table) when a later feature tracks it? F1 stores none and EP5 returns par_level null.",
      "decision_status": "deferred"
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

- Write {"file_path":"<PROJECT_ROOT>/.consort/features/F1-stock-visibility/reconcile-verdict.json","content":"{\"version\":1,\"passed\":true,\"findings\":[]}\n"}

## Final reasoning

I wrote the reconcile verdict as `passed: true` with no findings, because I found no cross-story defects across S1, S2 and S3.
