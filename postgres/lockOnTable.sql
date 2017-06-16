SELECT clock_timestamp(), pg_class.relname, pg_locks.locktype, pg_locks.database,
       pg_locks.relation, pg_locks.page, pg_locks.tuple, pg_locks.virtualtransaction,
       pg_locks.pid, pg_locks.mode, pg_locks.granted
FROM pg_locks JOIN pg_class ON pg_locks.relation = pg_class.oid
WHERE relname !~ '^pg_' and relname <> 'active_locks';
