# Some usefull postgres querries

##  Get the last vacuum date for specific table

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

## Get lock on table
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

## See real size on disk for specific table
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

## See all table size
```sql
SELECT
  relname                                                                 AS "Table",
  pg_size_pretty(pg_total_relation_size(relid))                           AS "Size",
  pg_size_pretty(pg_total_relation_size(relid) - pg_relation_size(relid)) AS "External Size"
FROM pg_catalog.pg_statio_user_tables
ORDER BY pg_total_relation_size(relid) DESC;
```

## See all active request on db 
```sql
SELECT *
FROM pg_stat_activity
WHERE datname = 'NAME'
```

## See all running querries
```sql
SELECT 
  pid,
  age(query_start, clock_timestamp()),
  usename,
  query 
FROM pg_stat_activity 
WHERE query != '<IDLE>' AND query NOT ILIKE '%pg_stat_activity%' 
ORDER BY query_start desc;

```

## See all related data to table
```sql
 SELECT
 ctid, -- physical location
 xmin, -- insertion transaction
 xmax, -- deletion transaction
 * 
 FROM <table>;

```

## See combinaison of blocked and blocking activity
```sql
SELECT
  blocked_locks.pid         AS blocked_pid,
  blocked_activity.usename  AS blocked_user,
  blocking_locks.pid        AS blocking_pid,
  blocking_activity.usename AS blocking_user,
  blocked_activity.query    AS blocked_statement,
  blocking_activity.query   AS current_statement_in_blocking_process
FROM pg_catalog.pg_locks blocked_locks
  JOIN pg_catalog.pg_stat_activity blocked_activity ON blocked_activity.pid = blocked_locks.pid
  JOIN pg_catalog.pg_locks blocking_locks
    ON blocking_locks.locktype = blocked_locks.locktype
       AND blocking_locks.database IS NOT DISTINCT FROM blocked_locks.database
       AND blocking_locks.relation IS NOT DISTINCT FROM blocked_locks.relation
       AND blocking_locks.page IS NOT DISTINCT FROM blocked_locks.page
       AND blocking_locks.tuple IS NOT DISTINCT FROM blocked_locks.tuple
       AND blocking_locks.virtualxid IS NOT DISTINCT FROM blocked_locks.virtualxid
       AND blocking_locks.transactionid IS NOT DISTINCT FROM blocked_locks.transactionid
       AND blocking_locks.classid IS NOT DISTINCT FROM blocked_locks.classid
       AND blocking_locks.objid IS NOT DISTINCT FROM blocked_locks.objid
       AND blocking_locks.objsubid IS NOT DISTINCT FROM blocked_locks.objsubid
       AND blocking_locks.pid != blocked_locks.pid

  JOIN pg_catalog.pg_stat_activity blocking_activity ON blocking_activity.pid = blocking_locks.pid
WHERE NOT blocked_locks.granted;
```

## Export data to csv file 
```sql

SET client_encoding TO 'UTF8';

\COPY (SELECT * FROM <TABLE_NAME> ) to 'export.csv' WITH CSV HEADER DELIMITER ';'

```

## Change template for db creation
```sql
-- remove template flag to allow deletion 
ALTER database template1 is_template=false;

DROP database template1;

-- define your own custom config
CREATE DATABASE template1
WITH OWNER = postgres
   ENCODING = 'UTF8'
   TABLESPACE = pg_default
   LC_COLLATE = 'en_US.UTF-8'
   LC_CTYPE = 'en_US.UTF-8'
   CONNECTION LIMIT = -1
   TEMPLATE template0;

-- define database as template
ALTER database template1 is_template=true;
```

# Some configuration and tip to analyze queries

## Custom postgres console
 add in `$HOME/.psqlrc`  
```bash
\timing on
\pset linestyle unicode 
\pset border 2
\setenv PAGER 'pspg --no-mouse -bX --no-commandbar --no-topbar'
\set HISTSIZE 100000
```

### Configure postgres to log every query
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

### Increase query size in activity table
```
track_activity_query_size = 16384
```

### Clean log on postgres install with brew (OSx)
```bash
echo "" > /usr/local/var/log/postgres.log
```

### Run pgbadger, more information see : https://github.com/dalibo/pgbadger
```bash
pgbadger /path/to/my/postgres-log-file.log
```
