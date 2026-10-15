-- Revision 3 adds report.review_surface_coverage (traust-contracts 0.56.0).
-- Existing reports predate the field: the column stays NULL for them.
ALTER TABLE report ADD COLUMN review_surface_coverage TEXT
    CHECK (review_surface_coverage IS NULL OR json_valid(review_surface_coverage));
