# Implementation Plan: OpenTelemetry APM & Distributed Tracing

## Architecture & Design
This feature provides OpenTelemetry (OTel) instrumentation for distributed tracing across Gemini API, SQLite Vector search, tool execution, and channel adapters.

### Core Components
1. **OTel Tracing Utility (`scripts/otel_tracing.py`)**:
   - Manages tracer initialization, span generation (`channel.receive`, `rbac.authorize`, `vector.search`, `gemini.generate_content`).
   - Redacts sensitive secrets and prompts from span attributes.
   - Exports JSON span events locally or to GCP Cloud Trace.

2. **Validation Suite (`scripts/test_opentelemetry_tracing.sh`)**:
   - Verifies span creation, context propagation, and secret sanitization.
