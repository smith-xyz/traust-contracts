-- Revision 4 adds verification.review_surface_coverage and threat.review_surfaces
-- (traust-contracts 0.57.0). Existing rows predate the fields: the columns stay NULL.
ALTER TABLE verification ADD COLUMN review_surface_coverage TEXT
    CHECK (review_surface_coverage IS NULL OR json_valid(review_surface_coverage));
ALTER TABLE threat ADD COLUMN review_surfaces JSONB;
