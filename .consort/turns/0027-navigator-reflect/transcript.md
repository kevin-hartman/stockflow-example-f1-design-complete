# navigator-reflect (navigator) – sonnet

## Prompt

```
REFLECT on story S3-sku-detail-view BEFORE the build lane: independently critique its spec slice (<PROJECT_ROOT>/.consort/features/F1-stock-visibility/stories/S3-sku-detail-view/story.json + acs/*.json) and its test-list (<PROJECT_ROOT>/.consort/features/F1-stock-visibility/stories/S3-sku-detail-view/test-list-per-story.json) against the architecture (<PROJECT_ROOT>/.consort/features/F1-stock-visibility/architecture.md/.json), the NFRs (<PROJECT_ROOT>/.consort/nfrs.md — a project-level file, NOT under the feature dir), and the information architecture (<PROJECT_ROOT>/.consort/design/ia.md). RUBRIC (pre-extracted; judge against THIS) :: layer=E2E | required NFRs, NFR5-spa-json-boundary | design-token groups, app_name, app_icon, typography, colors, spacing, radius, shadows, breakpoints, motion, components. Look ONLY for design-time defects that would waste a build cycle. The DETERMINISTIC pre-reflect gate has ALREADY verified the structural classes — client-kind↔AC-layer coherence, E2E-layer coverage by a real Playwright spec, and that no real-browser navigation/reload assertion sits in the jsdom component harness — so do NOT spend a finding re-flagging those; focus on the SEMANTIC defects: (1) ACs that contradict each other; (2) an AC with no covering test, or a test that contradicts its AC; (3) an NFR with no fitness test; (4) a test asserting at a layer the architecture forbids; (5) an AC whose declared layer conflicts with the architecture; (6) an untestable/vacuous AC (no observable outcome); (7) a UI-styling test that asserts inline HTML style or raw CSS in the page SOURCE (e.g. a text-align/color/font check inside a style= attr) for a property the design-guide + design-adherence gate govern, instead of the rendered SEAM (the element carries the design-guide class / data-testid): such a test hard-codes the very inline style the design lane then refactors into a token-driven class, so it blocks that refactor (the ui-style-implementation-test smell); (8) for EACH user-facing AC (declared layer E2E or client): read <PROJECT_ROOT>/.consort/design/ia.md and locate the screen, form, or data-testid seam that AC asserts among the IA's Screens, Navigation, and User flows — emit a ux-designer finding naming every asserted surface the IA leaves out, because the architect would otherwise tag an E2E layer against a screen the IA does not define (the ia refinement adds the missing surface). ALSO, when that AC asserts an INTERACTIVE control (a filter, selector, combobox, search), the IA must name a control the user can OPERATE to reach EVERY state the AC asserts: the control's declared option source must cover the asserted values and its empty / no-match state must be reachable THROUGH the control (e.g. an all-values accessible combobox, not a native datalist whose options are only the filtered rows and whose empty option is unselectable) — emit a ux-designer finding when the IA's control cannot reach an asserted state. This control-SEMANTICS check is the twin of the surface-existence check: a surface the IA NAMES but whose control a user cannot operate to the asserted state is still an ia defect, not a build detail or a test bypass; Do NOT critique implementation, style, or scope, only buildability + internal consistency of THIS story's artifacts. BE EXHAUSTIVE in this ONE pass: findings[] is multi-valued — run EVERY check against EVERY AC, test-list item, and NFR, and emit a SEPARATE finding for EACH distinct defect (decompose a LEGACY multi-part singular NFR fitness_function into its sub-guarantees and flag every uncovered clause — but an NFR that already declares the ATOMIC fitness_functions ARRAY is coverage-checked DETERMINISTICALLY by checkFitnessClauseCoverage at the test_list gate, so do NOT re-decompose it). Do NOT return one finding at a time: the reflect↔revise loop is bounded and escalates after a few laps, so a piecemeal reflect burns that budget on repeated revise→re-test→reflect laps and can hand the human a still-defective design. Write your verdict to <PROJECT_ROOT>/.consort/features/F1-stock-visibility/stories/S3-sku-detail-view/reflect-verdict.json as {"version":1,"passed":<bool>,"findings":[{"owner":"spec-author"|"test-strategist"|"architect-reviewer"|"ux-designer","detail":"<the defect>","ac_ids":["<exact story AC id(s) this finding is about>"]}]}. passed:true with findings:[] when the spec + test-list are consistent + buildable (the common case, do NOT invent defects). Attribute each finding to its OWNING role so the fix routes to the right gate: spec-author (an AC/spec defect — the given/when/then or scope); architect-reviewer (an ARCHITECTURE defect — checks 4 and 5, i.e. a wrong layer tag, OR a route/path/contract in an AC's architectural_notes that disagrees with the IA or the tests, OR a persistence invariant that contradicts the AC; this is the architect's product, NOT the spec-author's, so do NOT attribute a notes/layer defect to spec-author); test-strategist (a test-list/coverage defect); ux-designer (a user-facing AC whose surface the IA does not name — defect 8). Set "ac_ids" to the EXACT story AC id(s) the finding concerns (verbatim, from this story's acs/) — the revise re-derives ONLY those ACs' test items; omit ac_ids (or []) ONLY for a whole-story defect that needs the entire test-list rebuilt. Write ONLY that file; the orchestrator routes any fix deterministically.CROSS-STORY CONTEXT — this story is NOT reviewed in isolation. The feature's OTHER stories' ACs, the architecture's open_decisions, and its mandated (not-null) persistence fields are below; use them for the cross-story checks (an AC contradicting a gated sibling AC; a mandated field no sibling submit AC supplies). This IS that context — do not run `consort-cross-story-context` yourself.

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

- Bash {"command":"cd <PROJECT_ROOT>/.consort/features/F1-stock-visibility/stories/S3-sku-detail-view && cat story.json acs/*.json test-list-per-story.json; cat ../../../design/ia.md; grep -n \"EP5\\|sku-detail\\|detail\" ../../architecture.md | head -50"}
- Bash {"command":"cd <PROJECT_ROOT>/.consort; ls design; grep -rn \"sku\" design/*.md | head -30; grep -n \"NFR5\" -A8 nfrs.md | head -30"}
- Bash {"command":"echo '{\"version\":1,\"passed\":true,\"findings\":[]}' > <PROJECT_ROOT>/.consort/features/F1-stock-visibility/stories/S3-sku-detail-view/reflect-verdict.json"}

## Final reasoning

S3-sku-detail-view passes REFLECT with no findings. I wrote `reflect-verdict.json` with `passed: true` and an empty `findings` list.

The four ACs and the seven test-list items are consistent with each other. The `/sku/:sku` screen and all the data-testid seams the ACs assert appear in `ia.md`. The one required NFR, NFR5-spa-json-boundary, is covered by fitness tests T45 and T50.

I did not re-read `nfrs.md` or `architecture.json`. The NFR5 check rests on the test items' own `nfr_id` tags.
