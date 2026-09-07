# Feature Specification: Vector Context Search & Semantic Memory Engine

## Feature Overview & Objectives
The goal of this feature is to equip OpenClaw with persistent semantic search capabilities using vector embeddings generated via the Gemini Embeddings API and stored in SQLite on the persistent disk (`/mnt/disks/openclaw-data/vector_memory.db`). 

This enables OpenClaw to perform long-term recall across multi-session conversations beyond short-term memory buffers, exposing `/remember` and `/search` commands while automatically retrieving relevant historical facts during prompt execution.

---

## User Stories & Acceptance Scenarios

### User Story 1: Semantic Embedding Indexing & Storage
* **As an** Authorized Telegram User,
* **I want** important conversation facts and explicit memories stored in a persistent vector index,
* **So that** OpenClaw remembers key context across days and weeks without losing information when sessions reset.

#### Scenario 1.1: Explicit Memory Creation (`/remember`)
* **Given** an authorized user session,
* **When** the user sends `/remember User prefers concise summaries and Python over Bash`,
* **Then** OpenClaw generates text embeddings via Gemini Embeddings API, stores the text and vector in SQLite persistent storage, and confirms *"Memory stored successfully."*

#### Scenario 1.2: Context Search (`/search`)
* **Given** stored vector memories on `/mnt/disks/openclaw-data/vector_memory.db`,
* **When** the user issues `/search user coding preferences`,
* **Then** OpenClaw computes query embeddings, performs cosine similarity search, and returns top matching semantic memory records.

---

### User Story 2: Automatic Retrieval Augmentation (RAG) in Prompt Turns
* **As an** End-User,
* **I want** relevant historical memories automatically injected into LLM prompt contexts,
* **So that** OpenClaw maintains coherent context awareness without manual reminder inputs.

#### Scenario 2.1: Automatic Relevant Context Retrieval
* **Given** stored memories related to a user project,
* **When** the user asks a question referencing that project,
* **Then** the semantic memory engine retrieves top relevant vector chunks and injects them into the prompt system instructions prior to LLM generation.

---

## Success Criteria & Validation
- SQLite vector storage schema initialized on persistent disk volume (`/mnt/disks/openclaw-data/vector_memory.db`).
- Gemini embedding generation integrated into message ingestion pipeline.
- Commands `/remember` and `/search` implemented in channel interface.
- Automatic RAG injection active for multi-turn conversations.
- Validation script `scripts/test_vector_memory.sh` created and asserting embedding storage, query search accuracy, and persistent disk state survival.
