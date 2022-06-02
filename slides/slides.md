---
theme: gaia
size: 4:3
---

# Goals

Build a MongoDB connector from scratch that:

- runs as a standalone service
- can be discovered without prior setup
- pushes document to ES directly
- grab sync jobs
- grab configuration info in a safe way

---

# Constraints

- Elasticsearch is the sole database for everyone
- The whole process can be converted into cURLs calls to ES
- The data pushed to ES can be used by App Search

---

# What I built 1/2

- A fully automated environment with ES, MongoDB replicas with sample data

- A Connectors service that
  - registers itself into ES and wait for work
  - creates an index with dynamic mapping
  - ingests data from MongoDB in bulk and stream modes
  - reports status in real-time in ES

---

# What I built 2/2

- A Javascript app that
  - discovers connectors and displays them
  - let a user trigger syncs, safely send secrets
  - display sync progression in real-time


---

# Demo!

---

# Lessons learned 1/2

- Assymetric encryption offers zero-config discovery
- Continuous, event-based syncs is a cool idea
- MongoDB != MySQL != GDrive

---

# Lessons learned 2/2

- A connector is a series of ES HTTP calls
- ES HTTP API Definitions > Framework
- Current things to define:
  - Register a Connector, List connectors
  - Get configuration data
  - Trigger a Sync
  - Show progress in real-time
  - Create indices, Index data

---

# Deliverables, what's next

- The POC is a fully working Connectors framework.
- We can use it for experimenting on ideas, or trying to build new backends
- We can cherry-pick stuff for the RoR app

=> code: https://github.com/tarekziade/mongogo


