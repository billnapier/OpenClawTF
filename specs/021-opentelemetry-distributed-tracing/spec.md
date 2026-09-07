# Feature Specification: OpenTelemetry APM & Distributed Tracing

## Feature Overview & Objectives
The goal of this feature is to integrate OpenTelemetry (OTel) APM instrumentation into OpenClaw to enable distributed tracing, latency profiling, and bottleneck analysis across all core request flows (Gemini API calls, vector search queries, tool runtime executions, and channel polling).

Traces and metrics are formatted for export to GCP Cloud Trace and GCP Cloud Monitoring, ensuring full visibility into sub-second target response latencies (`< 1.0s` prompt response feedback target).

---

## User Stories & Acceptance Scenarios

### User Story 1: End-to-End Request Tracing & Latency Insights
* **As a** Cloud Administrator / DevOps Engineer,
* **I want** end-to-end trace spans for every incoming Telegram message and internal component processing step,
* **So that** I can identify bottlenecks (e.g., Gemini API latency vs SQLite vector search latency) and troubleshoot slow responses.

#### Scenario 1.1: Tracing Message Lifecycle
* **Given** an incoming message from Telegram/Discord,
* **When** processed through OpenClaw,
* **Then** an OTel trace is created containing child spans: `channel.receive`, `rbac.authorize`, `vector.search`, `gemini.generate_content`, and `channel.reply`.

#### Scenario 1.2: GCP Cloud Trace Integration
* **Given** active tracing enabled via environment variable `OTEL_EXPORTER_GCP=true`,
* **When** traces are produced during runtime,
* **Then** trace payloads are exported asynchronously using Application Default Credentials (ADC) to GCP Cloud Trace without degrading agent response performance.

---

## Technical Constraints & Safety Bounds
- **Zero Performance Impact**: Span creation and export run asynchronously; trace batch exporter uses non-blocking memory buffers.
- **Data Privacy**: Prompt text and sensitive API key secrets are redacted from span attributes before trace export.

---

## Success Criteria & Validation
- OpenTelemetry tracer provider initialized with GCP Trace Exporter.
- Core execution paths (`GeminiClient`, `VectorEngine`, `ToolGateway`, `ChannelAdapter`) instrumented with context-propagating spans.
- Helper script `scripts/export_otel_metrics.sh` created to query and assert trace export health.
- Executable verification test `scripts/test_opentelemetry_tracing.sh` validating span creation and secret sanitization.
