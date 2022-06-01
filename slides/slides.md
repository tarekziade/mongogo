---
theme: gaia
size: 4:3
---

# Goals

Build a MongoDB connector that:

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
  - ingest data from MongoDB in bulk and stream modes
  - report status in real-time in ES

---

# What I built 2/2

- A Javascript app that
 - discovers connectors and displays them
 - let a use trigger syncs, safely send secrets
 - display sync progression in real-time


---

# Demo!

---

# Lessons learned

- Assymetric encryption solves the key exchange issue
- Enforcing a framework for connectors is overkill
- Continuous, event-based syncs is a cool idea 

- Writing a MongoDB backend is very different from a MYSQL backend
- It's all about the read/write contracts
 - How does a connector registers to get discovered
 - How does a connector picks configuration
 - How does Kibana triggers and display syncs

- We don't have any scaling issue

---

# Deliverables, what's next

The POC is a fully working Connectors framework.
We can use it for experimenting on ideas, or trying to build a new backend.

=> code: https://github.com/tarekziade/mongogo


