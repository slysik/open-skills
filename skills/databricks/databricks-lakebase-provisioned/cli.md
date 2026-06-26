# Lakebase Provisioned — CLI Quick Reference

> Router: SKILL.md

## CLI Quick Reference

```bash
# Create instance
databricks database create-database-instance \
    --name my-lakebase-instance \
    --capacity CU_1

# Get instance details
databricks database get-database-instance --name my-lakebase-instance

# Generate credentials
databricks database generate-database-credential \
    --request-id $(uuidgen) \
    --json '{"instance_names": ["my-lakebase-instance"]}'

# List instances
databricks database list-database-instances

# Stop instance (saves cost)
databricks database stop-database-instance --name my-lakebase-instance

# Start instance
databricks database start-database-instance --name my-lakebase-instance
```

