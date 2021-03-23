# My ES sheet 

## Get all alias
```bash
curl --user ${USER}:${PASSWORD} -X GET "${URL}:${PORT}/_cat/aliases?v"
``` 

## Get all indexes
```bash
curl --user ${USER}:${PASSWORD} -X GET "${URL}:${PORT}/_cat/indices?v"
```

## Get settings for one indices
```bash
curl --user ${USER}:${PASSWORD} -X GET "${URL}:${PORT}/my-index/_settings"
```

## Get mapping for one indices
```bash
curl --user ${USER}:${PASSWORD} -X GET "${URL}:${PORT}/my-index/_mappings"
```

## Create index with mapping and setting
```bash
curl --user ${USER}:${PASSWORD} -X PUT "${URL}:${PORT}/INDEX-NAME" -H 'Content-Type: application/json' -d'
{
    "settings" : {
        # your settings
    },
    "mappings" : {
        # your mappings
    }
}
'
```

## Delete Index
```bash
curl --user ${USER}:${PASSWORD} -X DELETE "${URL}:${PORT}/INDEX-NAME"
```

## Re-index 
```bash
curl --user ${USER}:${PASSWORD} -X POST "${URL}:${PORT}/_reindex" -H 'Content-Type: application/json' -d'
{
  "source": {
    "index": "INDEX-NAME"
  },
  "dest": {
    "index": "NEW-INDEX"
  }
}
'
```

## Async re-index
```bash
curl --user ${USER}:${PASSWORD} -X POST "${URL}:${PORT}/_reindex?wait_for_completion=false" -H 'Content-Type: application/json' -d'
{
  "source": {
    "index": "INDEX-NAME"
  },
  "dest": {
    "index": "NEW-INDEX"
  }
}
'
```

## Get task information
```bash
curl --user ${USER}:${PASSWORD} -X POST "${URL}:${PORT}/_tasks/${ID}"
```

## Add alias to index
```bash
curl --user ${USER}:${PASSWORD} -X POST "${URL}:${PORT}/_aliases" -H 'Content-Type: application/json' -d'
{
    "actions" : [
        { "add" : { "index" : "INDEX-NAME", "alias" : "ALIAS-NAME" } }
    ]
}
'
```
