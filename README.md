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

And set the "config" used by the connector with:
```
ruby ./scripts/initialize.rb
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


Once the sync ends, a "permanent" sync job starts.

You can write data in MongoDB with:
```
rbenv exec ruby scripts/mongo_writer.rb
```

This will add the data and should trigger an update to Elasticsearch in realtime.


## Actors

- `SyncService` -- front end to trigger jobs
- `Jobs` -- Handles jobs
- `BulkSync` and `StreamSync` -- Sync jobs that drives a sync
- `MongoBackend` -- the mongo class that grabs documents and sends them back
- `ElasticDB` -- the documents DB we are pushing into
- `ElasticConfig` -- the configuration DB that provides info, like auth tokensm indexing rules etc

## How the service works

- `SyncService` gets triggered on `GET /start`
- `SyncService` creates a bulk sync job via `Jobs` and returns immediatly its id
- `BulkSync` can pick running info from `ElasticConfig` to know how to run
- `BulkSync` uses `MongoBackend` to get documents
- `BulkSync` fills a queue
- `ElasticDB` sends docs to Elasticsearch as bulk request by picking docs in the queue
- `SyncService` starts a `StreamSync` when the `BulkSync` has finished working
- `StreamSync` connects to the MongoDB changes API and streams documents to the queue
- `ElasticDB` sends docs continuously to Elasticsearch
