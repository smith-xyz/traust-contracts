-- The MITRE CWE catalog: reference data, loaded read-only. Never written by
-- assessments.
--
-- Mutable table (catalog releases change it). identifier is the catalog id
-- (CWE-306); abstraction and mapping_usage classify (closed catalog values,
-- checked at intake); catalog_version pins the load.
CREATE TABLE IF NOT EXISTS traust.cwe (
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    identifier TEXT NOT NULL CHECK (identifier <> ''),
    abstraction TEXT,
    mapping_usage TEXT,
    catalog_version TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (id),
    UNIQUE (identifier)
);

DROP TRIGGER IF EXISTS cwe_touch ON traust.cwe;
CREATE TRIGGER cwe_touch
BEFORE UPDATE ON traust.cwe
FOR EACH ROW EXECUTE FUNCTION traust.touch_updated_at();
