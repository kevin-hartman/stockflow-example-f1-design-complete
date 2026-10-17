# StockFlow Information Architecture

## Screens
| Screen | Route | Purpose | Stories | Key seams |
|---|---|---|---|---|
| Home: stock by location | `/` | warehouse picker (F7) + `stock-table` of SKU x location with qty + status badge; scan zone. S2: one row per (sku, location) with columns SKU, Location, Quantity (right-aligned, `--font-mono`, tabular-nums — AC2), Tracking code (value, or explicit "Not tracked" badge, never blank — AC1); location filter = `warehouse-select` (see Controls); empty location → `stock-empty` "No stock at this location" + Receive CTA (AC3) | F1 (S2 AC1–AC3), F7, F8 | `stock-table`, `stock-col-sku`, `stock-col-location`, `stock-col-quantity`, `stock-col-tracking`, `stock-qty-<sku>-<loc>`, `stock-tracking-<sku>-<loc>`, `stock-not-tracked`, `stock-row-<sku>-<loc>`, `stock-empty`, `stock-loading`, `stock-error`, `warehouse-select`, `scan-zone`, `scan-input` |
| SKU detail | `/sku/:sku` | narrow page: per-location qty, batch/serial (tracking code parts, F6) or "Not tracked". S3: `sku-locations` lists one entry per (sku, location) record for THIS SKU only, with location + qty (right-aligned, mono) + combined tracking code or "Not tracked" badge, never blank (AC1, AC2); par-level region shows value or explicit "Not tracked" (AC3); a SKU with no stock anywhere → `sku-empty` "This SKU has no stock at any location" + Receive CTA to `/receive?sku=<sku>`, no error page (AC4). No interactive filter (read-only) | F1 (S3 AC1–AC4), F6 | `sku-detail`, `sku-locations`, `sku-location-<loc>`, `sku-qty-<loc>`, `sku-tracking-<loc>`, `sku-tracking`, `sku-not-tracked`, `sku-par-level`, `sku-par-not-tracked`, `sku-empty`, `sku-error` |
| Adjust stock | `/adjust` (prefill `?sku=&location=`) | set/adjust qty for one SKU at one location | F2 | `adjust-form`, `field-sku`, `field-location`, `field-quantity`, `form-error`, `adjust-success` |
| Receive | `/receive` (`?sku=&location=`) | inbound receipt: supplier, SKU, qty, location | F3 | `receive-form`, `field-supplier`, `form-error`, `receive-confirmation` |
| Pick | `/pick` | outbound pick for an order; refuses overcommit | F4 | `pick-form`, `field-order`, `field-quantity-error`, `pick-confirmation` |
| Cycle count | `/count` | count a location, show the variance, reconcile | F5 | `count-form`, `count-variance`, `count-confirmation` |
| Search | `/search?q=` | find SKUs or tracking codes | F9 | `search-input`, `search-results`, `search-empty` |
| File stock | `/file` | file a SKU's stock (sku, location, qty, tracking code) at a known or new location; upsert per (sku, location); confirmation card shows the filed record; retrieve a filed record by (sku, location) | F1 S1 (AC1, AC2, AC3) | `file-stock-form`, `field-sku`, `field-location`, `field-quantity`, `field-tracking-code`, `file-stock-submit`, `form-error`, `file-stock-confirmation`, `confirm-sku`, `confirm-location`, `confirm-quantity`, `confirm-tracking-code`, `file-stock-updated`, `retrieve-form`, `retrieve-submit`, `retrieve-result`, `retrieve-empty` |
| About | `/about` | product tagline | — | `about-page` |

Global seams: `navbar`, `toast-region`, `toast-success`, `toast-error`.

## Controls
Each interactive control declares its TYPE, its OPTION SOURCE, and the states a user must be able to reach THROUGH the control — so the surface is usable by construction and an e2e drives the real control, never a URL/query-param bypass. A named-but-unusable control (e.g. a native `<datalist>` whose options are only the filtered rows and whose empty option cannot be selected) is an IA defect.
| Control | Screen | Type | Option source | Reachable states |
|---|---|---|---|---|
| `warehouse-select` | Home `/` | accessible combobox (listbox popup anchored under the input, keyboard-navigable) | ALL distinct locations (not only those currently holding stock), plus an "All locations" option | pick a location with stock → table; pick an EMPTY location → `stock-empty` reachable through the control; clear → all locations |
| `field-location` | File stock `/file` | accessible creatable combobox (listbox popup anchored under the input, keyboard-navigable; free text allowed) | ALL distinct locations on record (server-queried, refreshed after each filing) | choose a known location; type a NEW location → accepted, not blocked; after filing, the new location appears as an option (AC2) |
| `retrieve-location` | File stock `/file` (retrieve panel) | accessible combobox, same option source as `field-location` | ALL distinct locations on record | pick a filed location → `retrieve-result`; no record → `retrieve-empty` |
| `search-input` | Search `/search` | text search box | free-text, server-queried | results; no match → `search-empty` |

## Navigation
- **Navbar** (`App.tsx`):
  - brand (icon + "StockFlow") links to `/`
  - links: Stock `/`, Receive `/receive`, Pick `/pick`, Adjust `/adjust`, Count `/count`, File stock `/file`, Search `/search`, About `/about`
  - the active link is brand red
- **Contextual links:**
  - a stock row or a search result opens `/sku/:sku`
  - the SKU detail page has Adjust / Receive / Pick buttons that open the form prefilled
  - the empty-state CTA opens `/receive?location=<loc>`
  - the file-stock confirmation links to `/sku/:sku` and "File another" (resets `/file`)
  - a confirmation view links back to `/sku/:sku` and `/`
- **Routing:** every screen above is a `<Route>` in `App.tsx`. Unknown routes show an inline not-found alert with a link home.

## User flows
1. **See stock (F1/F7):** open `/` → pick a warehouse → the table shows qty + status pill. Empty location → empty state → CTA to Receive.
2. **Drill down (F1/F6):** click a row → `/sku/:sku` → see locations and tracking detail, or "Not tracked".
3. **Adjust (F2):** detail → Adjust → submit. Success: green toast + the row updates. Invalid input: inline field error.
4. **Receive (F3):** `/receive` → supplier, SKU, qty, location → confirmation view. Unknown SKU: inline field error.
5. **Pick (F4):** `/pick` → order, SKU, qty, location → confirmation. Overcommit: inline error on the quantity field, stating what is available.
6. **Cycle count (F5):** `/count` → enter the counted qty → variance shown → reconcile → confirmation.
7. **Scan (F8):** focus the scan zone on `/` → scan. Success: green flash + row flash + qty update. Unknown barcode or locked SKU: red flash + persistent error toast.
8. **Search (F9):** `/search` → type → results. No match: empty state.
9. **File stock (S1/AC1–AC3):** `/file` → enter SKU, choose a known location or type a new one in `field-location`, qty, tracking code → submit → `file-stock-confirmation` shows sku, location, qty, tracking code (success toast). Re-filing the same (sku, location) updates in place → normal confirmation with `file-stock-updated` note, no error. Retrieve: pick sku + `retrieve-location` → `retrieve-result` shows the same values; the location is now offered in `field-location`.
10. **Stock-by-location table (S2/AC1–AC3):** open `/` → `stock-table` lists one row per (sku, location) with SKU, location, right-aligned qty, tracking code or "Not tracked". Open `warehouse-select` → choose a location with no stock → `stock-empty` "No stock at this location" (not a blank table) → CTA to `/receive?location=<loc>`.
11. **SKU detail (S3/AC1–AC4):** click a `stock-table` row (or a search result) → `/sku/:sku` → each location holding the SKU with qty + tracking code or "Not tracked"; par level shows "Not tracked" when none. SKU with no stock → `sku-empty` → CTA to `/receive?sku=<sku>`.
