# Snowflake RBAC Role Design

Design Snowflake RBAC roles and hierarchies for optimal data access governance.

## Input Required

Ask the user for:

1. **Business entities** (people roles, not technical roles): `['Data Engineers', 'Data Scientists', 'Business Users', 'Administrators']`
2. **Data access patterns**: `['read-only access to production tables', 'write access to staging tables', 'admin access to warehouse', 'data lake access']`
3. **Workload separation**: Any separation requirements (prod/staging/dev, sensitive PII, etc.)

## Step 1: Core Role Template

**Template Application**:

```
## Core Role Hierarchy (Standard Template)

PRIMARY ROLES:
├── [Entity_A] (Owner) - All privileges on all objects
├── [Entity_B] (Admin) - Warehouse + Schema + Object management
└── [Entity_C] (User) - Select privileges only

SEMI-PRIVILEGED ROLES:
├── [Entity_D] (ETL) - Access to staging schema
├── [Entity_E] (Analyst) - Access to specific tables/views
└── [Entity_F] (Copilot) - Limited data access

TECHNICAL ROLES:
├── [Entity_G] (Dev) - Schema creation only
└── [Entity_H] (Ops) - Monitor + troubleshooting
```

## Step 2: Component Roles

**Technical Component Roles** (replace [Entity_X] with user role names):

```sql
-- Replace [ENTITY_NAME] with user's actual role names
-- Example: [DATA_ENGINEER], [DATA_SCIENTIST], etc.

-- For staging environments
CREATE ROLE IF NOT EXISTS [DATA_ENGINEER]_STAGING;
GRANT USAGE ON SCHEMA <database>.STAGING TO ROLE [DATA_ENGINEER]_STAGING;
GRANT SELECT ON ALL TABLES IN SCHEMA <database>.STAGING TO ROLE [DATA_ENGINEER]_STAGING;

-- For production environments
CREATE ROLE IF NOT EXISTS [DATA_ENGINEER]_PROD;
GRANT USAGE ON SCHEMA <database>.PROD TO ROLE [DATA_ENGINEER]_PROD;
GRANT SELECT ON ALL TABLES IN SCHEMA <database>.PROD TO ROLE [DATA_ENGINEER]_PROD;
```

**Semi-Privileged Component Roles**:

```sql
-- User access roles
CREATE ROLE IF NOT EXISTS [BUSINESS_USER];
GRANT USAGE ON SCHEMA <database>.PROD TO ROLE [BUSINESS_USER];
GRANT SELECT ON ALL TABLES IN SCHEMA <database>.PROD TO ROLE [BUSINESS_USER];

-- Copilot access roles
CREATE ROLE IF NOT EXISTS [COPILOT];
GRANT USAGE ON SCHEMA <database>.PROD TO ROLE [COPILOT];
GRANT SELECT ON TABLE <database>.PROD.CUSTOMERS TO ROLE [COPILOT];
```

**Technical Component Roles**:

```sql
-- Developer role (schema creation)
CREATE ROLE IF NOT EXISTS [DEVELOPER];
GRANT USAGE ON SCHEMA <database>.DEV TO ROLE [DEVELOPER];
GRANT CREATE TABLE ON SCHEMA <database>.DEV TO ROLE [DEVELOPER];

-- Operations role (monitoring)
CREATE ROLE IF NOT EXISTS [OPERATIONS];
GRANT MONITORING ON WAREHOUSE <warehouse_name> TO ROLE [OPERATIONS];
```

## Step 3: Permission Mapping

**User-Level Permissions**:

| Permission Level | Who Gets It | Why |
|---|---|---|
| **Full Access** | [Owner] | Owns and manages everything |
| **Read-Only** | [Business User], [Analyst] | Need to view data but not modify |
| **Write-Only** | [ETL] | Can modify staging but not production |
| **Admin** | [Admin] | Manages infrastructure, not data |

**Technical Permissions**:

| Permission | Role | Scope |
|---|---|---|
| Warehouse Management | [ADMIN] | USAGE on warehouse, all object privileges |
| Schema Management | [DEVELOPER] | CREATE on development schema |
| Monitoring | [OPERATIONS] | MONITORING on warehouse |

## Step 4: Role Assignment

```sql
-- Example assignments (replace with user roles)
GRANT ROLE [DATA_ENGINEER]_PROD TO ROLE [DATA_ENGINEER];
GRANT ROLE [DATA_SCIENTIST]_PROD TO ROLE [DATA_SCIENTIST];
GRANT ROLE [BUSINESS_USER] TO ROLE [DATA_SCIENTIST];
GRANT ROLE [COPILOT] TO ROLE [DATA_SCIENTIST];
```

## Final Output

Deliver:

1. **Role Design Document** (Markdown):

```markdown
# Snowflake RBAC Role Design

## Roles Created

| Role Name | Permission Set | Business Justification |
|---|---|---|
| [DATA_ENGINEER]_PROD | SELECT on prod schemas + USAGE on warehouse | Builds and maintains production data pipelines |
| [DATA_SCIENTIST] | SELECT on prod + admin staging access | Analyzes production data, develops models |
| [BUSINESS_USER] | Read-only access to key business tables | Views dashboards and reports |
| [DEVELOPER] | CREATE on dev schema only | Develops new features and test |
| [OPERATIONS] | Monitoring only | Troubleshoots and monitors systems |

## Access Matrix

| Entity | Database | Schema | Permissions |
|---|---|---|
| [DATA_ENGINEER] | <database> | PROD | SELECT |
| [DATA_SCIENTIST] | <database> | PROD | SELECT |
| [BUSINESS_USER] | <database> | PROD | SELECT |
| [DEVELOPER] | <database> | DEV | CREATE |
| [OPERATIONS] | <database> | ALL | USAGE |

## Next Steps

1. Create roles in Snowflake
2. Grant permissions as shown above
3. Test each role's access
4. Document final role assignments
```

2. **SQL Scripts** (separate files for role creation and permission grants)

## Anti-patterns (Never Do)

- Never grant object-level permissions directly; use schema-level grants.
- Never create overlapping roles; maintain clear separation of concerns.
- Never assign production access to development roles.
- Never create overly permissive "superuser" roles; use principle of least privilege.

## Code Examples (Copy-Paste)

```bash
# Create all roles
for role in [DATA_ENGINEER]_PROD [DATA_SCIENTIST]_PROD [BUSINESS_USER] [DEVELOPER] [OPERATIONS]; do
  echo "Creating role: $role"
  snowflake execute "CREATE ROLE IF NOT EXISTS $role"
done

# Grant schema usage
for role in [DATA_ENGINEER]_PROD [DATA_SCIENTIST]_PROD [BUSINESS_USER] [DEVELOPER]; do
  snowflake execute "GRANT USAGE ON SCHEMA <database>.PROD TO ROLE $role"
done

# Grant select permissions
for role in [DATA_ENGINEER]_PROD [DATA_SCIENTIST]_PROD [BUSINESS_USER]; do
  snowflake execute "GRANT SELECT ON ALL TABLES IN SCHEMA <database>.PROD TO ROLE $role"
done
```

## Behavior contract

- Always ask for user role names before generating scripts
- Always provide both Markdown design and SQL scripts
- Never skip testing phase - verify permissions work as expected
- Always document business justification for each role
- Never create more than 3-4 core roles - keep it simple and maintainable