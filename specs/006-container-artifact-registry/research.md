# Research: Containerization & Artifact Registry

## Technology Choices & Rationale
- **Artifact Registry Repository Format**: `DOCKER` format in Google Artifact Registry provides IAM-controlled access and fast pulls for GCE instances within the same region.
- **Dynamic Secret Injection**: Fetching secrets at entrypoint runtime via ADC avoids storing secrets in images or static files on disk.
- **Signal Handlers**: Trapping `SIGTERM` and `SIGINT` in `entrypoint.sh` allows the application process to perform cleanup, such as closing SQLite database transactions cleanly.
