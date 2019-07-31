Some usefull parameters
-----------------------

Unlock JMC for profiling
```
-XX:+UnlockCommercialFeatures
-XX:+FlightRecorder
```

Generate heap dump on OOM error
```
-XX:+HeapDumpOnOutOfMemoryError
```

Some usefull cmd
----------------

List all java process
```bash
jps
```

Generate a heap dump
```bash
jmap -dump:format=b,file=heapdump.hprof <JAVA_PID>
```

Generate a thread dump
```bash
jstack -l <JAVA_PID> > threaddump
```

Analyze heapdump on MAT, on `org.hibernate.internal.SessionFactoryImpl` problem 
```sql
SELECT l.query.toString() FROM INSTANCEOF org.hibernate.engine.query.spi.QueryPlanCache$HQLQueryPlanKey l 
``` 