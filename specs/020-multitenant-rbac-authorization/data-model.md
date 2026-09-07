# Data Model: RBAC Config Schema (`roles.json`)

```json
{
  "roles": {
    "1001": "Admin",
    "2002": "StandardUser",
    "3003": "ReadOnly"
  },
  "permissions": {
    "Admin": ["*"],
    "StandardUser": ["chat", "remember", "search", "model_status"],
    "ReadOnly": ["model_status", "rbac_status"]
  }
}
```
