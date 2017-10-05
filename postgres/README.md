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

See all active request on db 
```sql
SELECT *
FROM pg_stat_activity
WHERE datname = 'NAME'
```

Some configuration and tip to analyze querries
----------------------------------------------

Configure postgres to log every query in order to avoid pollution
```
log_min_duration_statement = 0
log_line_prefix = '%t [%p]: [%l-1] '
log_checkpoints = on
log_connections = on
log_disconnections = on
log_lock_waits = on
log_temp_files = 0
log_autovacuum_min_duration = 0
log_error_verbosity = default
log_statement = 'none'

# if psql is not in english
# lc_messages='C'
```

Clean log on mac os
```bash
echo "" > /usr/local/var/log/postgres.log
```

Run pgbadger
```bash
pgbadger /path/to/my/postgres-log-file.log
```