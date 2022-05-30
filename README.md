# mongo

## How it works


The MongoDB connector is a full ingestion event-based service that runs a
couple of threads to keep a MongoDB and Elasticsearch collection in sync.

It has two modes:
- **Bulk sync** the MongoDB collection is scanned and mirrored in Elasticsearch -- that may include additions, updates, deletions
- **Stream sync** The service uses the MongoDB changes API to get notified on changes and propagates them into Elasticsearch in real time

The data is indexed in an index that uses a dynamic mapping.


## Configuration with encryption

This demo also features a way to use Elasticsearch to safely store service
configuration and session data. Some keys be encrypted and
encryption is based on a pub/priv key so anyone with Elasticsearch access can
**write** encrypted data for the service to read by picking the public key at
`http://localhost:9292/public_key`. This makes the assumption that the
indentity of the service is trusted.

To write a key for the service from anywhere:

```
require_relative 'elasticdb'

config = ExternalElasticConfig.new('http://localhost:9292')
config.write_key('auth_token', 'modified_secret', encrypted: true)
```


## How to use the app

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

Generate a pair of pub/priv keys:
```
ruby ./certs/generate_keys.rb
```

Set the "config" used by the connector with:
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
