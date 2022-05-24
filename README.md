# mongo

## How to use

Run MongoDB and Elasticsearch with Docker:

```
cd scripts
./runstack.sh
```

Make sure you populate it with the sample data:
```
cd scripts
./loadsample.sh
```

The use the Makefile to run the service:
```
make install
make run
```

And start a sync with `http://0.0.0.0:9292/start`

  Install note:

  In case of an error when compiling Puma on macOS Catalina
  try https://github.com/puma/puma/issues/2544#issuecomment-771345173
  Use OpenSSL 1.1, not OpenSSL 3.x


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
