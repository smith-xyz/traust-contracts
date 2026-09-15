-- Reserved bootstrap lock shared by storage hosts; the stable key is arbitrary, not a hash.
SELECT pg_advisory_xact_lock(741829301);
