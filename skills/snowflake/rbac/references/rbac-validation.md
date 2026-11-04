# Snowflake RBAC Architecture Validation

Validate Snowflake RBAC implementation against the documented architecture.

## Input Required

Ask for:

1. **Account/Session Context**: Which Snowflake account/workspace?
2. **Roles to Validate**: List of roles you want to validate (e.g., `[DATA_ENGINEER]_PROD`, `[BUSINESS_USER]`, etc.)
3. **Current State**: Do you have existing RBAC in place, or are you starting fresh?

## Step 1: Current State Assessment

### Query Existing Roles

```sql
SELECT ROLE_NAME, IS_DEFAULT, IS_CURRENT, GRANTED_TO FROM SNOWFLAKE ACCOUNT_USAGE.WAREHOUSE_LOAD_HISTORY WHERE ROLE_NAME IN ('[DATA_ENGINEER]_PROD', '[BUSINESS_USER]', '[DEVELOPER]', '[OPERATIONS]')
```

Or use more direct approach:

```sql
SELECT NAME FROM SNOWFLAKE.ACCOUNT_LEVEL_ACCESS_CONTROL.ROLES WHERE NAME LIKE '%_PROD' OR NAME LIKE '%_USER' OR NAME LIKE '%_DEV' OR NAME LIKE '%_OPS';
```

### Check Role Hierarchies

```sql
SELECT * FROM SNOWFLAKE.ACCOUNT_LEVEL_ACCESS_CONTROL.ROLE_HIERARCHY ORDER BY PARENT_ROLE_NAME, CHILD_ROLE_NAME;
```

### Validate Permissions

```sql
-- Check schema access
SELECT ROLE_NAME, GRANTEE_NAME, PRIVILEGE FROM SNOWFLAKE.ACCOUNT_LEVEL_ACCESS_CONTROL.GRANTS WHERE PRIVILEGE IN ('USAGE', 'SELECT', 'CREATE')
ORDER BY ROLE_NAME, GRANTEE_NAME;

-- Check object-level access
SELECT ROLE_NAME, GRANTEE_NAME, PRIVILEGE, TABLE_SCHEMA, TABLE_NAME FROM SNOWFLAKE.ACCOUNT_LEVEL_ACCESS_CONTROL.GRANTS WHERE TABLE_SCHEMA IS NOT NULL
ORDER BY ROLE_NAME, TABLE_SCHEMA, TABLE_NAME;
```

## Step 2: Validation Rules

### ✅ Valid Patterns

**Role Hierarchy Validation**:

```sql
SELECT CHILD_ROLE_NAME, PARENT_ROLE_NAME FROM SNOWFLAKE.ACCOUNT_LEVEL_ACCESS_CONTROL.ROLE_HIERARCHY
WHERE CHILD_ROLE_NAME NOT IN (
    SELECT NAME FROM SNOWFLAKE.ACCOUNT_LEVEL_ACCESS_CONTROL.ROLES
    WHERE NAME LIKE '%_PROD'
);
```

**Permission Validation**:

```sql
-- Check for excessive permissions
SELECT ROLE_NAME, COUNT(*) as PRIVILEGE_COUNT FROM SNOWFLAKE.ACCOUNT_LEVEL_ACCESS_CONTROL.GRANTS 
WHERE ROLE_NAME IN ('[DATA_ENGINEER]_PROD', '[BUSINESS_USER]', '[DEVELOPER]', '[OPERATIONS]')
GROUP BY ROLE_NAME
HAVING COUNT(*) > 20;  -- Threshold for excessive permissions
```

**Principle of Least Privilege Check**:

```sql
-- Identify roles with overly broad access
SELECT DISTINCT ROLE_NAME FROM SNOWFLAKE.ACCOUNT_LEVEL_ACCESS_CONTROL.GRANTS 
WHERE (PRIVILEGE = 'ALL' OR PRIVILEGE = 'GLOBAL') 
AND ROLE_NAME NOT LIKE '%_ADMIN%';
```

### ❌ Invalid Patterns (Must Fix)

**Problematic Hierarchies**:

```sql
-- Cycles in role hierarchy
WITH RECURSIVE role_hierarchy AS (
    SELECT CHILD_ROLE_NAME, PARENT_ROLE_NAME, 1 as level
    FROM SNOWFLAKE.ACCOUNT_LEVEL_ACCESS_CONTROL.ROLE_HIERARCHY
    UNION ALL
    SELECT rh.CHILD_ROLE_NAME, rh.PARENT_ROLE_NAME, rh.level + 1
    FROM SNOWFLAKE.ACCOUNT_LEVEL_ACCESS_CONTROL.ROLE_HIERARCHY rh
    JOIN role_hierarchy rh2 ON rh.CHILD_ROLE_NAME = rh2.PARENT_ROLE_NAME
)
SELECT CHILD_ROLE_NAME FROM role_hierarchy WHERE level > 1;
```

**Excessive Permissions**:

```sql
-- Roles with more than 3 different database access levels
SELECT ROLE_NAME, COUNT(DISTINCT TABLE_SCHEMA) as SCHEMA_COUNT FROM SNOWFLAKE.ACCOUNT_LEVEL_ACCESS_CONTROL.GRANTS 
WHERE ROLE_NAME IN ('[BUSINESS_USER]', '[DATA_SCIENTIST]')
GROUP BY ROLE_NAME
HAVING COUNT(DISTINCT TABLE_SCHEMA) > 3;
```

## Step 3: Validation Results

### Valid Role Structure

```markdown
# RBAC Validation Results

## ✅ PASS - Core Structure Valid

| Validation Check | Status | Details |
|---|---|---|
| Role Existence | ✅ PASS | All expected roles found |
| Role Hierarchy | ✅ PASS | No cycles detected |
| Schema Isolation | ✅ PASS | Roles have appropriate schema scope |
| Permission Level | ✅ PASS | Roles have appropriate privilege levels |

## 📊 Summary

- **Total Roles Validated**: 4
- **Valid Roles**: 4 (100%)
- **Issues Found**: 0
- **Recommendations**: None
```

### Issues Found - Fix Required

```markdown
# RBAC Validation Results

## ❌ FAIL - Architecture Issues Detected

### Issue 1: Excessive Permissions
**Role**: [BUSINESS_USER]
**Problem**: Has access to 5 schemas (should be 1-2 max)
**Fix**: Reduce schema access to only business-critical schemas

**SQL to Fix**:
```sql
REVOKE ALL PRIVILEGES ON SCHEMA <database>.STAGING FROM ROLE [BUSINESS_USER];
REVOKE ALL PRIVILEGES ON SCHEMA <database>.DEVELOPMENT FROM ROLE [BUSINESS_USER];
```

### Issue 2: Missing Role Hierarchy
**Role**: [OPERATIONS]
**Problem**: No parent role for proper inheritance
**Fix**: Add [OPERATIONS] to proper hierarchy (e.g., under [ADMIN])

**SQL to Fix**:
```sql
ALTER ROLE [OPERATIONS] SET PARENT_ROLE = [ADMIN];
```

### Issue 3: Privilege Creep
**Role**: [DATA_ENGINEER]_PROD
**Problem**: Has CREATE privilege on production schema
**Fix**: Remove CREATE privilege from production environment

**SQL to Fix**:
```sql
REVOKE CREATE ON SCHEMA <database>.PROD FROM ROLE [DATA_ENGINEER]_PROD;
```

## 📊 Summary

- **Total Roles Validated**: 4
- **Valid Roles**: 1 (25%)
- **Issues Found**: 3
- **Critical Issues**: 2
- **Recommended Actions**: 3
```

## Step 4: Recommended Fixes

Generate specific SQL to fix validation issues:

```sql
-- Rollback to clean state (if needed)
DROP ROLE IF EXISTS [BUSINESS_USER];
DROP ROLE IF EXISTS [OPERATIONS];
DROP ROLE IF EXISTS [DATA_ENGINEER]_PROD;

-- Recreate with proper permissions
CREATE ROLE IF NOT EXISTS [BUSINESS_USER];
GRANT USAGE ON SCHEMA <database>.PROD TO ROLE [BUSINESS_USER];
GRANT SELECT ON ALL TABLES IN SCHEMA <database>.PROD TO ROLE [BUSINESS_USER];

-- Add proper hierarchy
CREATE ROLE IF NOT EXISTS [OPERATIONS];
ALTER ROLE [OPERATIONS] SET PARENT_ROLE = [ADMIN];
```

## Anti-patterns (Never Do)

- Never validate only a subset of roles
- Never ignore permission creep over time
- Never accept complex hierarchies without documentation
- Never validate without testing actual access

## Behavior contract

- Always ask for specific roles to validate
- Always provide both validation report and fix recommendations
- Always include actual SQL to fix issues found
- Never skip validation of critical security controls
- Always provide a clear pass/fail status
- If issues found, provide specific remediation steps