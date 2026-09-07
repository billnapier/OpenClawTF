# Data Model: Tool Definition & Call Response Schemas

## Tool Call Result Schema

```json
{
  "tool_name": "execute_python",
  "status": "success | error | timeout",
  "stdout": "string (max 2KB)",
  "stderr": "string",
  "execution_time_ms": 120
}
```
