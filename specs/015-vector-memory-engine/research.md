# Research: Vector Memory & SQLite Embedding Storage

## Technical Decisions
- **Database Engine**: SQLite 3 with json/blob storage for vector embeddings on persistent disk `/mnt/disks/openclaw-data/vector_memory.db`.
- **Vector Operations**: Exact dot-product / cosine similarity computed in Python over stored embedding arrays.
- **Embedding Model**: Gemini `text-embedding-004` (768 dimensions) or standard normalized word vector representations.
