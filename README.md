# mongo POC

## How it works


The MongoDB connector is a full ingestion event-based, async service that keeps a MongoDB database
and an Elasticsearch index in sync.

It has two modes:

- **Bulk sync** the MongoDB database is scanned and mirrored in an Elasticsearch index-- that may include additions, updates, deletions
- **Stream sync** The service uses the MongoDB changes API to get notified on changes and propagates them into Elasticsearch in real time

The index is created with a dynamic mapping.

Configuration data is picked by the connector in Elasticsearch on a specific index.
Some values can be encrypted. The service has a public/private key pair and publishes its public key at `http://localhost:9292/public_key`.
That key can be used to encrypt data that only the service can read (things like Elasticsearch API keys or OAuht tokens).

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

Then, use the Makefile to run the service:
```
make run
```

And visit `http://0.0.0.0:9292`

Once the sync ends, a "permanent" sync job starts.

You can write data in MongoDB with:
```
make mongo-writes
```

This will add the data and should trigger an update to Elasticsearch in realtime,
and you should see it live in http://0.0.0.0:9292/status.html.

