-- Revision 3 adds report.review_surface_coverage (traust-contracts 0.56.0).
-- Existing reports predate the field: the column stays NULL for them.
ALTER TABLE traust_storage.report ADD COLUMN IF NOT EXISTS review_surface_coverage JSONB;
