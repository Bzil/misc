# Some usefull parameters

### Unlock JMC for profiling
```
-XX:+UnlockCommercialFeatures
-XX:+FlightRecorder
```

###Generate heap dump on OOM error
```
-XX:+HeapDumpOnOutOfMemoryError
```

# Some usefull cmd

### List all java process
```bash
jps
```

### Generate a heap dump
```bash
jmap -dump:format=b,file=heapdump.hprof <JAVA_PID>
```

### Generate a thread dump
```bash
jstack -l <JAVA_PID> > threaddump
```

### Analyze heapdump on MAT, on `org.hibernate.internal.SessionFactoryImpl` problem 
```sql
SELECT l.query.toString() FROM INSTANCEOF org.hibernate.engine.query.spi.QueryPlanCache$HQLQueryPlanKey l 
``` 

### List cache per size on MAT
```sql
SELECT toString(c.name) AS cacheName, c.@retainedHeapSize AS retained, c
FROM org.springframework.cache.caffeine.CaffeineCache c
```

```sql
SELECT toString(c.name) AS cacheName, c.cache.cache.data.baseCount AS entries, c.cache.cache.weightedSize AS weightedSize, c.@retainedHeapSize AS retained, c FROM org.springframework.cache.caffeine.CaffeineCache c
```

### Clean SNAPSHOT
```bash
function cleanSnapshot() {
    DATE=${1:-1}
    find $HOME -type f -mtime +$DATE -iname "*SNAPSHOT*" -exec rm -fr {} \;
}
```

### Add [logback](log/logback.xml) option
```
-Dlogging.config=$LOG_PATH/log/logback.xml
```


### Use [async-profiler](https://github.com/async-profiler/async-profiler)


```bash
# wall
/async-profiler/bin/asprof -d 30 -e wall -f $PATH/flamegraph-wall.html $PID

# wall / thread
/async-profiler/bin/asprof -d 30 -e wall -t -f $PATH/flamegraph-wall-thread.html $PID
```
