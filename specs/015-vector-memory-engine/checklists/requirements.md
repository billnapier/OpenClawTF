# Quality Checklist: Vector Context Search & Semantic Memory Requirements

- [ ] **Persistent Vector Database**: SQLite vector memory database configured on persistent disk path (`/mnt/disks/openclaw-data/vector_memory.db`).
- [ ] **Embedding API Integration**: Text embeddings generated using Gemini embedding endpoints with backoff handling.
- [ ] **Slash Commands (`/remember`, `/search`)**: Slash commands implemented for storing explicit memories and searching memory index.
- [ ] **RAG Context Injection**: Semantic memory retrieval automatically injects relevant context into LLM system prompts.
- [ ] **Verification Script (`scripts/test_vector_memory.sh`)**: Executable validation script testing embedding generation, index storage, search retrieval, and disk persistence.
