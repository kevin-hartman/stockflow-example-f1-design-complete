# architect-reviewer (architect-reviewer) – opus

## Prompt

```
REVISE (reflection gate): blocking smell "reflect-testlist-defect": reflection gate: T38/T39 assert an 'S2 add-index migration' (ix_stock_records_location_sku) but neither S2 AC nor the architecture declares such a migration: architecture.md/NFR1 state the only F1 migration is the initial create_table, and AP1 merely flags an index for a later DBA decision. The tests are mis-premised (a Driver would have to invent a migration or rewrite the shipped one). Either drop T38/T39, or have the architect declare the index migration (persistence invariant + AC note) first; row-survival (T39) then applies only to that additive migration.

This is a reflect ARCHITECTURE defect on the architect's own product: the flagged AC's architectural_notes (its layer, the route/path/contract, or a persistence invariant) were cleared and must be RE-ANNOTATED to resolve it — re-derive them against the ACs, the IA (ia.md), and architecture.json so the layer tag, the route/path, and the invariants agree with the IA and the tests. The acceptance criteria themselves are intact; author the architectural annotations only. The named fix is REQUIRED: the re-annotation MUST resolve the exact inconsistency described – do NOT omit it, weaken it, or defer it to an open question. If it genuinely cannot be resolved as written, name the concrete blocker; do not punt.

Annotate story S2-stock-by-location-table's acceptance criteria + nfrs.md coverage. Author architectural_notes for EXACTLY these un-noted AC(s): AC1-table-lists-stock-by-location, AC3-empty-location-state. Story S2-stock-by-location-table's remaining ACs (AC2-quantity-right-aligned) already carry valid notes and are OUT of scope this turn. Every one of this story's ACs MUST end up with a non-empty "architectural_notes" field in its acs/<AC>.json (the layer it lives in + how it realizes the design) — the design gate verifies that, and the spec-author's "layer" field does NOT count. architectural_notes are per-AC, so author the scoped ACs above even when the feature-level architecture.json already exists from an earlier story. For every E2E AC, ALSO pass consort-annotate-ac --ui-seams with the ia.md data-testid seam token(s) the AC's UI drives — the column / cell / region / empty-state / form field it asserts (e.g. "stock-cell-tracking,stock-not-tracked"). A deterministic gate checks each seam is named in <PROJECT_ROOT>/.consort/design/ia.md; if the AC needs a surface the IA does not yet name, declare the seam you need anyway and the gate routes the ux-designer to add it to ia.md. In architecture.json, make an EXPLICIT service_backed call (required): set service_backed:true if the feature persists data (a DB table/migration) or carries business logic, and then you MUST declare boundary, service, and repository layers (plus a "models" PACKAGE app/models/, one module per domain object, NOT a flat app/models.py, when it persists entities); set false ONLY for a trivial static/read-through endpoint. An Infra-layer AC or a migration/schema/storage NFR while service_backed is false hard-blocks the gate. When service_backed:true you MUST also declare architecture.json persistence_invariants[]: the DB-level guarantees the schema enforces (each with id, type one of unique|foreign_key|cascade|not_null|check|transactional|migration_reversible, table, and a one-line brief), covering unique/composite keys, foreign keys + cascade rules, NOT NULL / CHECK constraints, any transactional-atomicity boundary, and migration reversibility. The test-strategist must cover each with a real-branch test; a service_backed feature with no persistence_invariants hard-blocks the gate. When THIS story introduces a NEW read/query shape over the schema — a filter, lookup, sort, or join an AC drives (e.g. "list stock filtered by location", "look up a SKU's rows by sku") that is an INDEX candidate — declare it in architecture.json access_patterns[] (id, a one-line brief, and the table + column(s) it reads) so the DBA is pulled back in to reconsider the physical design for it; this is how a later READ story evolves the schema, since a story that adds no persistence_invariant would otherwise skip the DBA. Declare an access_pattern ONLY for a genuinely new query shape (not for every read, and not for one already covered by a prior story's pattern or a primary-key lookup). REUSE the established project architecture conventions (set by F1-stock-visibility): boundary=app/routes (react), service=app/services, repository=app/repositories, models=app/models, infrastructure=app/database.py. Declare the SAME role -> module paths in architecture.json, do NOT remap or rename an established layer; a divergent layout hard-blocks the spec gate and mismatches the inherited code. Author this story's architectural_notes FRESH from the ACs + IA on disk this turn. On a reflect-revise re-run the self-heal clears this story's prior architectural_notes BY DESIGN, so an absent/empty prior is the expected revise state — re-derive against the corrected ACs + IA. Write every artifact under the ABSOLUTE artifact root <PROJECT_ROOT>/.consort (this feature: <PROJECT_ROOT>/.consort/features/F1-stock-visibility/; this story: <PROJECT_ROOT>/.consort/features/F1-stock-visibility/stories/S2-stock-by-location-table/); use that absolute path and never resolve or guess the project root yourself.CROSS-STORY CONTEXT — this story is NOT reviewed in isolation. The feature's OTHER stories' ACs, the architecture's open_decisions, and its mandated (not-null) persistence fields are below; use them for the cross-story checks (an AC contradicting a gated sibling AC; a mandated field no sibling submit AC supplies). This IS that context — do not run `consort-cross-story-context` yourself.

{
  "current_story": "S2-stock-by-location-table",
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
      "decision_status": "open"
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

- Bash {"command":"cd <PROJECT_ROOT>/.consort/features/F1-stock-visibility; cat architecture.json; cat stories/S2-stock-by-location-table/acs/*.json; grep -n -i \"index\\|migration\\|AP1\\|AP2\" architecture.md | head -40; ls; grep -n -i \"stock-table\\|stock-row\\|location-filter\\|empty\" ../../design/ia.md | head -30"}
- Bash {"command":"cd <PROJECT_ROOT>/.consort/features/F1-stock-visibility; cat db-design.json; grep -n -i \"index\\|AP2\\|migration\" db-design.md; python3 -c \"\nimport json;d=json.load(open('test-list.json'))\nfor t in d.get('tests',d.get('items',[])):\n  if t.get('id') in('T38','T39'):print(json.dumps(t,indent=1))\""}
- Bash {"command":"cd <PROJECT_ROOT>/.consort/features/F1-stock-visibility; python3 - <<'EOF'\nimport json\np='architecture.json';d=json.load(open(p))\nd['persistence_invariants']=[x for x in d['persistence_invariants'] if not x['id'].startswith('PI8')]\nd['persistence_invariants'].append({\"id\":\"PI8-location-sku-index-migration-reversible\",\"type\":\"migration_reversible\",\"table\":\"stock_records\",\"brief\":\"S2-stock-by-location-table adds an ADDITIVE revision on the pre-existing stock_records (down_revision = the S1 create revision) creating btree ix_stock_records_location_sku (location, sku) for AP2. Downgrading to its down_revision drops only that index while stock_records and its existing rows persist unchanged; upgrade head recreates the index.\"})\nfor n in d['nfrs']:\n  if n['id']=='NFR1-stock-survives-migration':\n    n['requirement']=\"Stock data survives every schema migration. F1 has two migrations: the initial create_table (S1), whose guarantee is schema reversibility (PI7), and the S2 additive index migration ix_stock_records_location_sku (location, sku) on the pre-existing stock_records, whose guarantee is that rows filed before it persist across its downgrade/upgrade (PI8). The adjustment timestamp/actor clause is N/A for F1 (read-and-record only; no adjustment operation — owned by the adjustment feature).\"\n    n.pop('fitness_function',None)\n    n['fitness_functions']=[\n     {\"clause\":\"Downgrade the stock_records create migration to its down_revision then upgrade head on the paired branch; the table with its UNIQUE(sku, location) and CHECK(quantity >= 0) constraints is present again.\",\"realized_by\":[\"AC1-file-stock-record\"]},\n     {\"clause\":\"With stock rows filed, downgrade the S2 add-index migration (ix_stock_records_location_sku) to its down_revision then upgrade head on the paired branch; every previously filed row persists unchanged and the index exists again.\",\"realized_by\":[\"AC1-table-lists-stock-by-location\"]}]\nfor a in d['access_patterns']:\n  if a['id']=='AP2-stock-by-location-filter':\n    a['brief']+=\" Realized by the S2 additive migration adding ix_stock_records_location_sku (location, sku) (PI8, db-design SC5).\"\njson.dump(d,open(p,'w'),indent=2)\nEOF\nsed -i '' 's/Read-only: no new persistence invariants\\./Read path plus one additive migration: index `ix_stock_records_location_sku (location, sku)` on the pre-existing `stock_records` (AP2, SC5), reversible with row survival (PI8, NFR1 clause 2)./' architecture.md\nsed -i '' 's/AP1 flags it for an index decision by the DBA\\./served by `ix_stock_records_location` (S1, AP1); the S2 location filter is served by the additive `ix_stock_records_location_sku` migration (PI8)./' architecture.md\ngrep -n \"PI8\\|ix_stock\" architecture.md\ncd ../../..\n./scripts/lk consort-annotate-ac --feature F1-stock-visibility --story S2-stock-by-location-table --ac AC1-table-lists-stock-by-location --layer E2E --api-contract EP4-list-stock --ui-seams \"stock-table,stock-col-sku,stock-col-location,stock-col-quantity,stock-col-tracking,stock-row-<sku>-<loc>,stock-tracking-<sku>-<loc>,stock-not-tracked\" --notes \"E2E: the home stock-table renders the real EP4 GET /api/stock/records response, one row per (sku, location), with a null tracking_code rendered as the explicit stock-not-tracked badge, verified by Playwright against the live API on the paired branch. Read path app/routes/stock.py -> app/services/stock_service.py -> app/repositories/stock_repository.list_records (ORDER BY location, sku, AP2); this story ships one ADDITIVE migration on the pre-existing stock_records adding ix_stock_records_location_sku (location, sku) (db-design SC5), whose downgrade drops only the index and preserves filed rows (PI8, NFR1 clause 2).\" && \\\n./scripts/lk consort-annotate-ac --feature F1-stock-visibility --story S2-stock-by-location-table --ac AC3-empty-location-state --layer E2E --api-contract EP4-list-stock --ui-seams \"warehouse-select,stock-empty,stock-table\" --notes \"E2E: the operator picks an empty location through the warehouse-select combobox (options from EP3 GET /api/locations, all distinct locations) and the client renders stock-empty 'No stock at this location' from the real EP4 GET /api/stock/records?location= empty-list response, verified by Playwright on the paired branch. The filtered read uses the S2 index ix_stock_records_location_sku via stock_repository.list_records (AP2, PI8); how a location exists with no stock stays OD3 (open), so the test seeds the location via a quantity-0 filing, a state S1's upsert already allows (CHECK quantity >= 0).\" && \\\n./scripts/lk consort-response-formatter --role architect-reviewer --feature F1-stock-visibility --story S2-stock-by-location-table"}
- Bash {"command":"cd <PROJECT_ROOT>; python3 - <<'EOF'\nimport json\np='.consort/features/F1-stock-visibility/architecture.json';d=json.load(open(p))\nfor n in d['nfrs']:\n  if n['id']=='NFR1-stock-survives-migration':\n    n['fitness_function']=\"Real-branch migration tests per fitness_functions clause: S1 create_table downgrade/upgrade recreates the schema (PI7); S2 add-index downgrade/upgrade preserves filed rows and recreates ix_stock_records_location_sku (PI8).\"\njson.dump(d,open(p,'w'),indent=2)\nEOF\n./scripts/lk consort-response-formatter --role architect-reviewer --feature F1-stock-visibility --story S2-stock-by-location-table"}

## Final reasoning

I declared the S2 index migration, so T38/T39 now have a real migration to test instead of a made-up one; the self-check passes. The migration is a new revision on S1 that adds `ix_stock_records_location_sku` (the DBA's db-design SC5). It's backed by persistence invariant PI8 and a second NFR1 clause: rolling it back drops only the index and keeps filed rows. I updated `architecture.md` to match, and AC1 and AC3 now carry fresh notes (E2E, endpoint EP4).
