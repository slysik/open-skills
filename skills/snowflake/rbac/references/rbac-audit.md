# Snowflake RBAC Audit

Audit Snowflake RBAC implementation for compliance, security, and operational efficiency.

## Input Required

Ask for:

1. **Audit Scope**: What do you want to audit? (roles, permissions, access patterns, compliance)
2. **Time Period**: When was the RBAC implemented? (e.g., "3 months ago")
3. **Compliance Standards**: Any specific standards to check against? (SOC2, HIPAA, GDPR)

## Step 1: Current RBAC State Assessment

### Query All Roles and Permissions

```sql
-- Get all roles in the account
SELECT NAME, COMMENT, CREATED, OWNER, IS_DEFAULT FROM SNOWFLAKE.ACCOUNT_LEVEL_ACCESS_CONTROL.ROLES;

-- Get role hierarchy
SELECT CHILD_ROLE_NAME, PARENT_ROLE_NAME FROM SNOWFLAKE.ACCOUNT_LEVEL_ACCESS_CONTROL.ROLE_HIERARCHY ORDER BY PARENT_ROLE_NAME, CHILD_ROLE_NAME;

-- Get all permissions
SELECT GRANTEE_NAME, PRIVILEGE, TABLE_SCHEMA, TABLE_NAME, CREATED_BY, CREATED_ON FROM SNOWFLAKE.ACCOUNT_LEVEL_ACCESS_CONTROL.GRANTS WHERE TABLE_SCHEMA IS NOT NULL;
```

### Analysis of Current State

**Role Complexity Analysis**:

```sql
-- Count roles per schema (identify over-permissioning)
SELECT TABLE_SCHEMA, COUNT(DISTINCT GRANTEE_NAME) as ROLE_COUNT, COUNT(*) as PERMISSION_COUNT
FROM SNOWFLAKE.ACCOUNT_LEVEL_ACCESS_CONTROL.GRANTS 
WHERE TABLE_SCHEMA IS NOT NULL
GROUP BY TABLE_SCHEMA
ORDER BY ROLE_COUNT DESC;
```

**Access Pattern Analysis**:

```sql
-- Identify roles with excessive privileges (admin-level permissions without admin role)
SELECT DISTINCT GRANTEE_NAME as ROLE_NAME, TABLE_SCHEMA, PRIVILEGE_COUNT
FROM (
    SELECT GRANTEE_NAME, TABLE_SCHEMA, COUNT(*) as PRIVILEGE_COUNT
    FROM SNOWFLAKE.ACCOUNT_LEVEL_ACCESS_CONTROL.GRANTS 
    WHERE TABLE_SCHEMA IS NOT NULL
    GROUP BY GRANTEE_NAME, TABLE_SCHEMA
) analysis
WHERE PRIVILEGE_COUNT > 10 AND GRANTEE_NAME NOT LIKE '%_ADMIN%';
```

## Step 2: Security Audit Checks

### 1. Principle of Least Privilege Audit

**Check for over-permissive roles**:

```sql
-- Find roles with SELECT on ALL TABLES (should be limited)
SELECT GRANTEE_NAME, COUNT(*) as GLOBAL_ACCESS_COUNT FROM SNOWFLAKE.ACCOUNT_LEVEL_ACCESS_CONTROL.GRANTS 
WHERE PRIVILEGE = 'SELECT' AND TABLE_SCHEMA IS NULL
GROUP BY GRANTEE_NAME
HAVING COUNT(*) > 5;
```

**Check for schema-level over-permissioning**:

```sql
-- Identify roles with access to more than 3 schemas
SELECT GRANTEE_NAME, COUNT(DISTINCT TABLE_SCHEMA) as SCHEMA_COUNT FROM SNOWFLAKE.ACCOUNT_LEVEL_ACCESS_CONTROL.GRANTS 
WHERE TABLE_SCHEMA IS NOT NULL
GROUP BY GRANTEE_NAME
HAVING COUNT(DISTINCT TABLE_SCHEMA) > 3;
```

### 2. Compliance Audit

**Role Lifecycle Compliance**:

```sql
-- Find roles without owners
SELECT NAME FROM SNOWFLAKE.ACCOUNT_LEVEL_ACCESS_CONTROL.ROLES 
WHERE OWNER IS NULL;

-- Find roles not used in last 90 days
SELECT NAME FROM SNOWFLAKE.ACCOUNT_LEVEL_ACCESS_CONTROL.ROLE_USAGE_HISTORY 
WHERE LAST_USED < DATEADD(day, -90, CURRENT_DATE());
```

**Access Pattern Compliance**:

```sql
-- Find inactive privileged accounts
SELECT NAME, CREATED, COMMENT FROM SNOWFLAKE.ACCOUNT_LEVEL_ACCESS_CONTROL.ROLES 
WHERE NAME IN ('[ADMIN]', '[SUPERUSER]') AND CREATED < DATEADD(day, -180, CURRENT_DATE());
```

### 3. Operational Efficiency Audit

**Duplicate Role Detection**:

```sql
-- Find duplicate permission patterns
WITH role_permissions AS (
    SELECT GRANTEE_NAME, STRING_AGG(CONCAT(PRIVILEGE, ':', TABLE_SCHEMA), ', ') as PERMISSIONS
    FROM SNOWFLAKE.ACCOUNT_LEVEL_ACCESS_CONTROL.GRANTS 
    WHERE TABLE_SCHEMA IS NOT NULL
    GROUP BY GRANTEE_NAME
)
SELECT RP1.GRANTEE_NAME as ROLE_A, RP2.GRANTEE_NAME as ROLE_B, RP1.PERMISSIONS
FROM role_permissions RP1
JOIN role_permissions RP2 ON RP1.GRANTEE_NAME <> RP2.GRANTEE_NAME
WHERE RP1.PERMISSIONS LIKE CONCAT('%', SUBSTRING(RP2.PERMISSIONS, 1, 50), '%')
AND RP1.PERMISSIONS <> RP2.PERMISSIONS;
```

**Access Review Gaps**:

```sql
-- Find resources without explicit access control
SELECT TABLE_SCHEMA, TABLE_NAME, COUNT(*) as ACCESS_GRANT_COUNT
FROM SNOWFLAKE.ACCOUNT_LEVEL_ACCESS_CONTROL.GRANTS 
WHERE TABLE_SCHEMA IS NOT NULL
GROUP BY TABLE_SCHEMA, TABLE_NAME
HAVING COUNT(*) = 0;  -- Should never happen, indicates missing controls
```

## Step 3: Audit Report Generation

### Pass/Fail Matrix

```markdown
# Snowflake RBAC Audit Report

## 🎯 Audit Overview

| Audit Area | Status | Issues Found | Recommendation |
|---|---|---|---|
| Role Hierarchy | ✅ PASS | 0 | Maintain current structure |
| Principle of Least Privilege | ❌ FAIL | 3 | Fix over-permissive roles |
| Compliance | ✅ PASS | 0 | Good compliance posture |
| Operational Efficiency | ⚠️ WARNING | 2 | Optimize role structure |

## 📊 Summary Statistics

- **Total Roles Audited**: 15
- **Roles with Issues**: 8 (53%)
- **Critical Issues**: 3
- **Medium Issues**: 5
- **Compliance Score**: 78%
```

### Detailed Findings

#### 🚨 Critical Issues - Immediate Action Required

**Issue 1: Excessive Schema Access**

```
Role: [BUSINESS_ANALYST]
Problem: Has access to 5 schemas (prod_staging, prod_analytics, dev_test, marketing, finance)
Risk: Unauthorized access to sensitive data
Fix: Restrict to only production analytics schemas

SQL to Fix:
REVOKE USAGE ON SCHEMA <database>.dev_test FROM ROLE [BUSINESS_ANALYST];
REVOKE USAGE ON SCHEMA <database>.marketing FROM ROLE [BUSINESS_ANALYST];
REVOKE USAGE ON SCHEMA <database>.finance FROM ROLE [BUSINESS_ANALYST];
```

**Issue 2: Orphaned Roles**

```
Roles Found Without Owners:
- [TEMP_ROLE_123]
- [LEGACY_SERVICE_ACCOUNT]
- [DEPRECATED_TOOL]

Risk: Unmanaged access, compliance violation
Fix: Remove or assign owners

SQL to Fix:
DROP ROLE IF EXISTS [TEMP_ROLE_123];
DROP ROLE IF EXISTS [LEGACY_SERVICE_ACCOUNT];
DROP ROLE IF EXISTS [DEPRECATED_TOOL];
```

**Issue 3: Privileged Access Without Oversight**

```
Role: [DATA_SCIENTIST_ADMIN]
Problem: Has admin-level privileges but is not in admin group
Risk: Data breach potential
Fix: Reassign to proper admin role hierarchy

SQL to Fix:
REVOKE ALL PRIVILEGES FROM ROLE [DATA_SCIENTIST_ADMIN];
GRANT ROLE [DATA_SCIENTIST] TO ROLE [DATA_SCIENTIST_ADMIN];  -- Proper assignment
```

#### ⚠️ Medium Issues - Optimize Soon

**Issue 1: Role Duplication**

```
Duplicate Permission Patterns Found:
- [READ_ONLY_USER] vs [VIEWER_USER] (identical permissions)
- [ETL_OPERATOR] vs [PIPELINE_RUNNER] (identical permissions)

Fix: Consolidate roles, remove duplicates
```

**Issue 2: Unused Roles**

```
Roles Not Used in 90+ Days:
- [OLD_DEVELOPER]
- [FORMER_ANALYST]
- [LEGACY_REPORTER]

Fix: Deactivate or remove unused roles
```

### ✅ Positive Findings

**Well-Designed Roles**:

```
Roles With Optimal Design:
- [DATA_ENGINEER]: 2 schemas, appropriate permissions
- [BUSINESS_USER]: 1 schema, read-only only
- [DEVELOPER]: 1 schema, development-only permissions

These roles follow principle of least privilege well.
```

## Step 4: Remediation Plan

### Immediate Actions (Next 48 hours)

1. **Remove Orphaned Roles** (Critical)
2. **Fix Excessive Schema Access** (Critical)
3. **Reassign Privileged Access** (Critical)

### Short-term Actions (Next 2 weeks)

1. **Consolidate Duplicate Roles** (Medium)
2. **Deactivate Unused Roles** (Medium)
3. **Update Role Documentation** (Low)

### Long-term Actions (Next month)

1. **Implement Automated RBAC Governance** (Low)
2. **Set up RBAC Monitoring** (Low)
3. **Review Access Patterns** (Low)

## Anti-patterns (Never Do)

- Never audit without involving the actual role owners
- Never fix issues without testing each change
- Never skip compliance checks for privileged roles
- Never audit roles that have been recently modified without re-validation
- Never accept "admin" roles without proper oversight

## Behavior contract

- Always provide detailed findings with SQL to fix issues
- Always include a clear remediation plan with timelines
- Always ask for confirmation before making destructive changes
- Always provide both technical and business impact of issues
- Never report audit findings without actionable recommendations
- Always include a compliance score and overall assessment