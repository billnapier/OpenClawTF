# Quality Checklist: OpenTelemetry APM & Distributed Tracing Requirements

- [ ] **OpenTelemetry Provider**: OTel SDK initialized with GCP Trace exporter and memory batch processor.
- [ ] **Component Span Instrumentation**: Spans configured for channel ingress, RBAC, Gemini API, vector DB queries, and tool execution.
- [ ] **Secret & Prompt Sanitization**: Automatic masking of sensitive data (API keys, tokens, personal identifiers) in trace attributes.
- [ ] **Metrics Assert Utility (`scripts/export_otel_metrics.sh`)**: Script querying exported trace statistics and latency quantiles.
- [ ] **Verification Script (`scripts/test_opentelemetry_tracing.sh`)**: Executable test validating span context propagation and exporter pipeline health.
