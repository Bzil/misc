Some usefull postgres 9.6 querries
----------------------------------

Get the last vacuum date for specific table

```sql
SELECT
  relname,
  last_vacuum,
  last_autovacuum,
  last_analyze,
  last_autoanalyze
FROM pg_stat_user_tables
WHERE relname = 'NAME';
```

Get lock on table
```sql
SELECT
  clock_timestamp(),
  pg_class.relname,
  pg_locks.locktype,
  pg_locks.database,
  pg_locks.relation,
  pg_locks.page,
  pg_locks.tuple,
  pg_locks.virtualtransaction,
  pg_locks.pid,
  pg_locks.mode,
  pg_locks.granted
FROM pg_locks
  JOIN pg_class ON pg_locks.relation = pg_class.oid
WHERE relname !~ '^pg_' AND relname <> 'active_locks';
```

See real size on disk for specific table
```sql
SELECT
  c.oid,
  nspname                               AS table_schema,
  relname                               AS TABLE_NAME,
  c.reltuples                           AS row_estimate,
  pg_total_relation_size(c.oid)         AS total_bytes,
  pg_indexes_size(c.oid)                AS index_bytes,
  pg_total_relation_size(reltoastrelid) AS toast_bytes
FROM pg_class c
  LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE relkind = 'r' AND relname = 'TABLE_NAME';
```


See all table size
```sql
SELECT
  relname                                                                 AS "Table",
  pg_size_pretty(pg_total_relation_size(relid))                           AS "Size",
  pg_size_pretty(pg_total_relation_size(relid) - pg_relation_size(relid)) AS "External Size"
FROM pg_catalog.pg_statio_user_tables
ORDER BY pg_total_relation_size(relid) DESC;
```

See active request on db 
```sql
SELECT *
FROM pg_stat_activity
WHERE datname = 'NAME'
``