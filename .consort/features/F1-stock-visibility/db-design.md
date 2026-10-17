# F1 DB design

**stock_records** (mirrors `app/models/stock_record.py`): id identity PK; sku, location text NOT NULL; quantity integer NOT NULL; tracking_code text NULL; created_at/updated_at timestamptz default now().

## Migration plan
- S1-file-stock (single reversible revision): SC1 create table, SC2 UNIQUE(sku, location), SC3 CHECK(quantity >= 0), SC4 index on location. Downgrade drops the table.

## Invariants
- PI1: `uq_stock_records_sku_location`.
- PI2/PI3/PI4: NOT NULL on sku/location/quantity.
- PI5: `ck_stock_records_quantity_non_negative`.
- PI6: repository runs a single `INSERT ... ON CONFLICT (sku, location) DO UPDATE SET quantity, tracking_code, updated_at` against PI1's constraint.
- PI7: initial revision downgrade drops / upgrade recreates the table with constraints.

## Access patterns
- AP1: btree `ix_stock_records_location` serves DISTINCT location ORDER BY location via index scan.
- AP2: btree `ix_stock_records_location_sku (location, sku)` serves the location filter plus ORDER BY location, sku. UNIQUE(sku, location) leads on sku, so it can't serve this. The S1 `ix_stock_records_location` is kept as-is. The composite index would also serve it, but dropping it isn't needed in this increment.

## Migration plan (S2)
- S2-stock-by-location-table: SC5 add `ix_stock_records_location_sku`; downgrade drops it.
- PI8: SC5 is its own additive revision (down_revision = S1 create). Downgrade runs DROP INDEX only, so the rows survive. Upgrade recreates the index.
