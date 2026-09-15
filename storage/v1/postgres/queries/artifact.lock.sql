-- Serialize a digest: first eight SHA-256 bytes interpreted as signed big-endian int64.
SELECT pg_advisory_xact_lock(%(lock_key)s);
