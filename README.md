# mongo

## How to use

Use the Makefile:

```
make install
make run
```


## Actors

- `SyncService` -- front end to trigger jobs
- `SyncJob` -- Sync job that drives a sync
- `MongoBackend` -- the mongo class that grabs documents and sends them back
- `ElasticDB` -- the documents DB we are pushing into
- `ElasticConfig` -- the configuration DB that provides info, like auth tokensm indexing rules etc


## How the service works

- `SyncService` gets triggered on `GET /start`
- `SyncService` creates a sync job and return immediatly an id
- `SyncJob` can pick running info from `ElasticConfig` to know how to run
- `SyncJob` uses `MongoBackend` to get documents
- `SyncJob` updates its status on a regulare basis
- `SyncJob` sends documents to `ElasticDB`
