# Some usefull postgres querries


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

```sql
SELECT pid,
    usename AS login,
    application_name AS app,
    to_char(query_start, 'HH24:MI:SS') AS start,
    date_trunc('second', (now() - query_start)) AS duration,
    wait_event_type || '/' || wait_event AS waiting,
    state,
    left(REPLACE(query, E'\n', ''), 2000) AS query
FROM pg_stat_activity
WHERE state != 'idle'
ORDER BY query_start
LIMIT 30;
```

## Kill queries matching app name
```sql
SELECT 
   pid, -- pg_terminate_backend(pid),
   usename as login,
   application_name as app,
   to_char(query_start, 'HH24:MI:SS') as start,
   date_trunc('second', (now()-query_start)) as duration,
   wait_event_type || '/' || wait_event as waiting,
   state,
   left(REPLACE(query, E'\n', ''), 200) as query
FROM pg_stat_activity
WHERE state != 'idle' and application_name LIKE 'NAME%'
ORDER BY query_start
LIMIT 30;
```

## Get bloated tables
```sql
SELECT schemaname, tblname, to_char((((tblpages-est_tblpages_ff)*bs)/(1024::NUMERIC^2))::INT, '9G999G999G999') AS bloat_mb,
     CASE WHEN tblpages - est_tblpages_ff > 0
       THEN round((100 * (tblpages - est_tblpages_ff)/tblpages::float)::NUMERIC,2)
       ELSE 0
     END AS bloat_ratio
   FROM (
     SELECT
       ceil( reltuples / ( (bs-page_hdr)/tpl_size ) ) + ceil( toasttuples / 4 ) AS est_tblpages,
       ceil( reltuples / ( (bs-page_hdr)*fillfactor/(tpl_size*100) ) ) + ceil( toasttuples / 4 ) AS est_tblpages_ff,
       tblpages, fillfactor, bs, schemaname, tblname, heappages, toastpages
     FROM (
       SELECT
         ( 4 + tpl_hdr_size + tpl_data_size + (2*ma)
           - CASE WHEN ceil(tpl_data_size)::int%ma = 0 THEN ma ELSE ceil(tpl_data_size)::int%ma END
         ) AS tpl_size, (heappages + toastpages) AS tblpages, heappages,
         toastpages, reltuples, toasttuples, bs, page_hdr, schemaname, tblname, fillfactor
       FROM (
         SELECT
          ns.nspname AS schemaname, tbl.relname AS tblname, tbl.reltuples,
           tbl.relpages AS heappages, coalesce(toast.relpages, 0) AS toastpages,
           coalesce(toast.reltuples, 0) AS toasttuples,
           coalesce(substring(
             array_to_string(tbl.reloptions, ' ')
             FROM '%fillfactor=#"__#"%' FOR '#')::smallint, 100) AS fillfactor,
           current_setting('block_size')::numeric AS bs,
           CASE WHEN version()~'mingw32' OR version()~'64-bit|x86_64|ppc64|ia64|amd64' THEN 8 ELSE 4 END AS ma,
           24 AS page_hdr,
           23 + CASE WHEN MAX(coalesce(null_frac,0)) > 0 THEN ( 7 + count(*) ) / 8 ELSE 0::int END AS tpl_hdr_size,
           sum( (1-coalesce(s.null_frac, 0)) * coalesce(s.avg_width, 1024) ) AS tpl_data_size
         FROM pg_attribute AS att
           JOIN pg_class AS tbl ON att.attrelid = tbl.oid
           JOIN pg_namespace AS ns ON ns.oid = tbl.relnamespace
           LEFT JOIN pg_stats AS s ON s.schemaname=ns.nspname
             AND s.tablename = tbl.relname AND s.inherited=false AND s.attname=att.attname
           LEFT JOIN pg_class AS toast ON tbl.reltoastrelid = toast.oid
         WHERE att.attnum > 0 AND NOT att.attisdropped
           AND tbl.relkind = 'r'
         GROUP BY 1,2,3,4,5,6,7,8,9
         ORDER BY 2
       ) AS s
     ) AS s2
   ) AS s3
   ORDER BY ((tblpages-est_tblpages_ff)*bs) desc,bloat_ratio desc
   LIMIT 30;
   ```

## Get bloated indexes
```sql
WITH btree_index_atts AS (
    SELECT nspname,
        indexclass.relname as index_name,
        indexclass.reltuples,
        indexclass.relpages,
        indrelid, indexrelid,
        indexclass.relam,
        tableclass.relname as tablename,
        regexp_split_to_table(indkey::text, ' ')::smallint AS attnum,
        indexrelid as index_oid
    FROM pg_index
    JOIN pg_class AS indexclass ON pg_index.indexrelid = indexclass.oid
    JOIN pg_class AS tableclass ON pg_index.indrelid = tableclass.oid
    JOIN pg_namespace ON pg_namespace.oid = indexclass.relnamespace
    JOIN pg_am ON indexclass.relam = pg_am.oid
    WHERE pg_am.amname = 'btree' AND indexclass.relpages > 0
         AND nspname NOT IN ('pg_catalog','information_schema')
    ),
index_item_sizes AS (
    SELECT
    ind_atts.nspname, ind_atts.index_name,
    ind_atts.reltuples, ind_atts.relpages, ind_atts.relam,
    indrelid AS table_oid, index_oid,
    current_setting('block_size')::numeric AS bs,
    8 AS maxalign,
    24 AS pagehdr,
    CASE WHEN max(coalesce(pg_stats.null_frac,0)) = 0
        THEN 2
        ELSE 6
    END AS index_tuple_hdr,
    sum( (1-coalesce(pg_stats.null_frac, 0)) * coalesce(pg_stats.avg_width, 1024) ) AS nulldatawidth
    FROM pg_attribute
    JOIN btree_index_atts AS ind_atts ON pg_attribute.attrelid = ind_atts.indexrelid AND pg_attribute.attnum = ind_atts.attnum
    JOIN pg_stats ON pg_stats.schemaname = ind_atts.nspname
          -- stats for regular index columns
          AND ( (pg_stats.tablename = ind_atts.tablename AND pg_stats.attname = pg_catalog.pg_get_indexdef(pg_attribute.attrelid, pg_attribute.attnum, TRUE))
          -- stats for functional indexes
          OR   (pg_stats.tablename = ind_atts.index_name AND pg_stats.attname = pg_attribute.attname))
    WHERE pg_attribute.attnum > 0
    GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9
),
index_aligned_est AS (
    SELECT maxalign, bs, nspname, index_name, reltuples,
        relpages, relam, table_oid, index_oid,
        coalesce (
            ceil (
                reltuples * ( 6
                    + maxalign
                    - CASE
                        WHEN index_tuple_hdr%maxalign = 0 THEN maxalign
                        ELSE index_tuple_hdr%maxalign
                      END
                    + nulldatawidth
                    + maxalign
                    - CASE /* Add padding to the data to align ON MAXALIGN */
                        WHEN nulldatawidth::integer%maxalign = 0 THEN maxalign
                        ELSE nulldatawidth::integer%maxalign
                      END
                )::numeric
              / ( bs - pagehdr::NUMERIC )
              +1 )
         , 0 )
      as expected
    FROM index_item_sizes
),
raw_bloat AS (
    SELECT current_database() as dbname, nspname, pg_class.relname AS table_name, index_name,
        bs*(index_aligned_est.relpages)::bigint AS totalbytes, expected,
        CASE
            WHEN index_aligned_est.relpages <= expected
                THEN 0
                ELSE bs*(index_aligned_est.relpages-expected)::bigint
            END AS wastedbytes,
        CASE
            WHEN index_aligned_est.relpages <= expected
                THEN 0
                ELSE bs*(index_aligned_est.relpages-expected)::bigint * 100 / (bs*(index_aligned_est.relpages)::bigint)
            END AS realbloat,
        pg_relation_size(index_aligned_est.table_oid) as table_bytes,
        stat.idx_scan as index_scans
    FROM index_aligned_est
    JOIN pg_class ON pg_class.oid=index_aligned_est.table_oid
    JOIN pg_stat_user_indexes AS stat ON index_aligned_est.index_oid = stat.indexrelid
),
format_bloat AS (
SELECT nspname || '.' || table_name as table_name,
       nspname || '.' || index_name as index_name,
       round(realbloat) as bloat_pct,
       round(wastedbytes/(1024^2)::BIGINT) as bloat_mb,
       (totalbytes/(1024^2))::BIGINT as index_mb,
       (table_bytes/(1024^2))::BIGINT as table_mb,
       (index_scans/1000)::BIGINT as K_index_scans
FROM raw_bloat
)
-- final query outputting the bloated indexes
-- change the where AND order by to change
-- what shows up as bloated
SELECT *
FROM format_bloat
WHERE bloat_mb >= 100
  AND bloat_pct >= 70
ORDER BY bloat_mb DESC;
```

##  Get the last vacuum date for specific table

```sql
SELECT
  schemaname,
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
  nspname                                               AS table_schema,
  relname                                               AS TABLE_NAME,
  c.reltuples                                           AS row_estimate,
  pg_size_pretty(pg_total_relation_size(c.oid))         AS total_bytes,
  pg_size_pretty(pg_indexes_size(c.oid))                AS index_bytes,
  pg_size_pretty(pg_total_relation_size(reltoastrelid)) AS toast_bytes
FROM pg_class c
  LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE relkind = 'r' AND relname = 'TABLE_NAME';
```

## See all table size
```sql
SELECT
  schemaname                                                              AS "Schema",
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

## See all related data to table
```sql
 SELECT
 ctid, -- physical location
 xmin, -- insertion transaction
 xmax, -- deletion transaction
 * 
 FROM <table>;
```

## See long running queries 
```sql
SELECT now() - xact_start AS duration,
    pid,
    query_start,
    application_name,
    left(REPLACE(query, E'\n', ''), 2000)
FROM pg_stat_activity
WHERE state <> 'idle'
ORDER BY 1 DESC, 3 ASC
LIMIT 10;
```

# See index usage stat on tabled
```sql 
SELECT indexrelname,
    idx_scan,
    idx_tup_read,
    idx_tup_fetch
FROM pg_stat_user_indexes
WHERE schemaname = 'SCHEMA' and relname = 'TABLE_NAME';
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
