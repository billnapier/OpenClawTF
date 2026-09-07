# Quickstart: Guardian CI/CD Automation

```bash
# Validate workflow YAML files
python3 -c "import yaml; yaml.safe_load(open('.github/workflows/terraform-plan.yml'))"
python3 -c "import yaml; yaml.safe_load(open('.github/workflows/deploy.yml'))"

# Verify path structures
ls -la .github/workflows/
```
