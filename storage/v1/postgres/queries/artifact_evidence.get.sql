SELECT payload
FROM traust_storage.artifact_evidence
WHERE digest = %(digest)s;
