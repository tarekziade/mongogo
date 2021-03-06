# mongo POC

The MongoDB connector is a full ingestion event-based, async service that keeps a MongoDB database
and an Elasticsearch index in sync.


## Connector Service

The **Connector** service is a standalone service. Once started, it registers
itself in ES with its public key and waits for Sync Job.

When a job is added in ES, it picks it and executes it and update its status in ES.

The service has two types of sync jobs:

- **Bulk sync** the MongoDB database is scanned and mirrored in an Elasticsearch index-- that may include additions, updates, deletions
- **Stream sync** The service uses the MongoDB changes API to get notified on changes and propagates them into Elasticsearch in real time

The index is created with a dynamic mapping.

## Kibanana

Front end that displays registered connectors, adds sync jobs and display their status.
Kibanana has no prior knowledge of connectors. Connectors are providing their own settings
to get triggered.


## Adding a Sync Job

Sync Jobs are JSON payload that are added to ES and may be encrypted when they contain secrets
like auth tokens or passwords.

Once they are pushed by Kibanana in ES, the connector service can pick them if it
knows how to run them.

## How to start and use the service

Use the Makefile for everything.

Install rbenv and all deps:
```
make install
```

Install note:

  In case of an error when compiling Puma on macOS Catalina
  try https://github.com/puma/puma/issues/2544#issuecomment-771345173
  Use OpenSSL 1.1, not OpenSSL 3.x


Run MongoDB and Elasticsearch with Docker:
```
make run-stack
```

Make sure you populate MongoDB with the sample data:
```
make populate-mongo
```

Generate a pair of pub/priv keys for the service (optional, you can use the defaults):
```
make gen-certs
```

Then, use the Makefile to run the Kibanana service:
```
make run-kibanana
```

And visit Kibanana `http://0.0.0.0:9292`

Now run the connector service in another terminal:
```
make run-connector
```

And the connector will register itself and appear in Kibanana.
Now you can use it to sync data.

Once the sync ends, a "permanent" sync job starts.

You can write data in MongoDB with:
```
make mongo-writes
```

This will add the data and should trigger an update to Elasticsearch in realtime,
and you should see it live in http://0.0.0.0:9292/status.html.


## How the code is organized

- **app.rb** The Kibanana Sinatra front-end
- **connector_app.rb** The connector service
- **html/** The HTML templates and files (based on Bootstrap)
- **certs/** The pem keys and a key generator
- **scripts/** The Docker Compose definition and some scripts to boostrap the stacks
- **elasticconfig.rb** The key/value storage for storing configuration (with encryption)
- **elasticdb.rb** The class that creates the ES index and sends bulk queries
- **events.rb** Events class definitions
- **job.rb** A jobs manager used to start/list/manage jobs + Jobs class (async)
- **mongodb.rb** MongoDB backend. Fetches a full collection or watches its changes and emit events

