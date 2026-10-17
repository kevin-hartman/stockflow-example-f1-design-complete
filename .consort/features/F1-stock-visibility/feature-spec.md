# Record and view stock by SKU and location

## Summary
Lets the warehouse team file the stock level of a SKU at a physical location and read it back later. It is the foundation for the warehouse app. Each (sku, location) pair is one uniquely addressable record that carries a combined tracking code.

## Stories
- S1-file-stock — file and retrieve stock for a (sku, location), reusing known locations or entering a new one. Re-filing the same pair updates it in place.
- S2-stock-by-location-table — home-screen stock-by-location table, with an empty-location state.
- S3-sku-detail-view — SKU detail across locations, with tracking code and a par level shown as not tracked.

## Out of scope
- Adjusting quantities and receiving inbound goods (separate features).
- Splitting tracking_code into location/batch/serial (later iteration).
- App chrome (navbar, brand icon, favicon) is delivered by the design system / IA, not as a story.

## Open questions
- S1: When a (sku, location) is re-filed, does it update in place or get rejected? Recommended: update in place (last write wins), with no duplicate and no error page, as written in S1 AC3.
- S1: Is a tracking code required when filing? Recommended: optional. When it is absent, views show "not tracked".
- S1: Is a quantity of zero allowed, and are negative quantities rejected? Recommended: zero is allowed and negatives are rejected inline.
- S2: Does the home table offer a per-location filter or grouping, and is that how a single location's empty state is reached? Recommended: a location filter/grouping on the home table. When the selected location has no rows it shows "No stock at this location" (S2 AC3). The designer decides how it is presented.
- S2: If no stock exists anywhere, does the home screen use the same empty-state treatment? Recommended: yes, an explicit empty state and never a blank page.
- S3: How is a SKU with no stock reached when SKUs exist only through stock records? Recommended: by navigating directly to that SKU's detail (for example a typed or linked SKU) and getting the S3 AC4 empty state, not a not-found error page.
- S3: Can the par level be recorded in F1? Recommended: no. In F1 it is always shown as "not tracked" (S3 AC3), and capturing it is deferred to a later feature.
