---
theme: gaia
size: 4:3
---

# Spacetime Goals

Build a MongoDB connector from scratch that:

- runs as a standalone service
- can be discovered without prior setup
- securely grabs configuration data
- grabs sync jobs
- pushes document to ES directly
- makes them available in App Search

---

# Constraints

- Elasticsearch is the sole database for everyone
- Everything is done through ES HTTP calls\*
- The data pushed to ES can be used by App Search

*\*Except for the AS engine creation*

---

# What was built 1/2

- Docker compose with ent-search, Kibana, ES, MongoDB replicas with sample data

- A **Connector Service** that
  - registers itself into ES and waits for work
  - creates an index with dynamic mapping
  - ingests data from MongoDB in *bulk* and *stream* modes
  - displays sync progress in real-time in ES

---

# What was built 2/2

- A **Javascript App** that
  - replaces Kibana for the POC
  - discovers connectors and displays them
  - let a user trigger syncs, safely send secrets
  - displays sync progression in real-time

---

# Demo!

---

# Lessons learned 1/2

- Assymetric encryption offers safe zero-config discovery and setup
- Continuous, event-based syncs is a cool idea
- MongoDB != MySQL != GDrive

---

# Lessons learned 2/2

- Connector == series of ES HTTP calls (could be cURL)
- Documented ES HTTP API calls > Framework | It's all about standards
- Current things to define:
  - Register a Connector, list connectors
  - Get configuration data
  - Trigger Sync Jobs, show progress
  - Create indices, index data

---

# Deliverables, what's next

- The POC is a fully working Connectors framework
- Can be used for experiments, build new backends
- The MongoDB connector can be refactored/recycled in the RoR app
- Registration, Status info etc is ad-hoc data in ES, needs structure (ECS?)

=> code: https://github.com/tarekziade/mongogo

