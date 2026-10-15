-- Revision 4 adds verification.review_surface_coverage and threat.review_surfaces
-- (traust-contracts 0.57.0). Existing rows predate the fields: the columns stay NULL.
ALTER TABLE traust_storage.verification ADD COLUMN IF NOT EXISTS review_surface_coverage JSONB;
ALTER TABLE traust_storage.threat ADD COLUMN IF NOT EXISTS review_surfaces JSONB;
