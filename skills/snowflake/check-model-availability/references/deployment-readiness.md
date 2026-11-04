# Snowflake Cortex Deployment Readiness

Assess deployment readiness for Cortex models with comprehensive environment checks.

## Input Required

Ask for:

1. **Model name**: What model needs deployment readiness assessment?
2. **Environment**: Production, staging, or development?
3. **Warehouse context**: Current warehouse and size preferences

## Step 1: Environment Assessment

### Check Warehouse Readiness

```sql
-- Assess current warehouse
SELECT
  NAME,
  SIZE,
  TYPE,
  MAX_CLUSTER_COUNT,
  AUTO_SUSPEND,
  AUTO_RESUME,
  RESOURCE_CONSUMPTION_PER_HOUR_USD
FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSES
WHERE NAME = '<WAREHOUSE_NAME>';
```

### Warehouse Readiness Framework

```
# Warehouse Readiness Matrix

| Warehouse Size | Base Mode | Agentic Mode | Recommendation |
|---|---|---|---|
| Small (XS) | ❌ Insufficient | ❌ Insufficient | UPGRADE REQUIRED |
| Medium (S) | ⚠️ Marginal | ❌ Insufficient | UPGRADE REQUIRED |
| Large (L) | ✅ Suitable | ⚠️ Sufficient | UPGRADE ADVISED |
| XLARGE (XL) | ✅ Suitable | ✅ Suitable | ✅ OPTIMAL |
| 2XLarge (XXL) | ✅ Optimal | ✅ Optimal | ✅ RECOMMENDED |

## Warehouse Performance Baseline

```sql
-- Establish performance baseline
SELECT
  QUERY_ID,
  EXECUTION_TIME,
  BYTES_SCANNED,
  CREDITS_USED_COMPUTE,
  START_TIME
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE START_TIME >= DATEADD(day, -7, CURRENT_DATE())
  AND WAREHOUSE_NAME = '<WAREHOUSE_NAME>'
ORDER BY START_TIME DESC
LIMIT 10;
```

### Warehouse Performance Indicators

```
# Warehouse Performance Benchmark

| Metric | Target | Current | Status |
|---|---|---|---|
| Avg Query Time | < 30 seconds | < MEASUREMENT > | <STATUS> |
| Max Query Time | < 120 seconds | < MEASUREMENT > | <STATUS> |
| Concurrent Queries | 5+ | < COUNT > | <STATUS> |
| Compute Credits/Hour | < $5 | < MEASUREMENT > | <STATUS> |
| Usage Pattern | Predictable | < PATTERN > | <STATUS> |
```

## Step 2: Privilege Assessment

### Required Permissions Check

```sql
-- Check Cortex execution privileges
SELECT DISTINCT PRIVILEGE FROM SNOWFLAKE.ACCOUNT_LEVEL_ACCESS_CONTROL.GRANTS 
WHERE GRANTEE_NAME = CURRENT_ROLE() 
  AND PRIVILEGE LIKE '%CORTEX%';

-- Check agentic mode specific privileges
SELECT DISTINCT PRIVILEGE FROM SNOWFLAKE.ACCOUNT_LEVEL_ACCESS_CONTROL.GRANTS 
WHERE GRANTEE_NAME = CURRENT_ROLE() 
  AND (PRIVILEGE LIKE '%AGENTIC%' OR PRIVILEGE LIKE '%ML%');
```

### Privilege Requirements Framework

```
# Privilege Requirements Matrix

| Permission | Base Mode | Agentic Mode | Risk Level |
|---|---|---|---|
| CORTEX_EXECUTE | ✅ Required | ✅ Required | HIGH |
| CORTEX_MODEL_USAGE | ✅ Required | ✅ Required | HIGH |
| CORTEX_AGENTIC_EXECUTE | ❌ Not Required | ✅ Required | MEDIUM |
| ML_ADMIN | ❌ Not Required | ✅ Required | LOW |
| DATA_ACCESS | ✅ Required (model data) | ✅ Required (extended) | HIGH |

## Privilege Gap Analysis

```sql
-- Identify missing privileges
WITH required_privileges AS (
    SELECT PRIVILEGE, DESCRIPTION FROM (
        VALUES
            ('CORTEX_EXECUTE', 'Execute Cortex models'),
            ('CORTEX_MODEL_USAGE', 'Use Cortex models'),
            ('CORTEX_AGENTIC_EXECUTE', 'Execute agentic models'),
            ('ML_ADMIN', 'Manage ML resources')
    ) AS v(PRIVILEGE, DESCRIPTION)
),

user_privileges AS (
    SELECT DISTINCT PRIVILEGE FROM SNOWFLAKE.ACCOUNT_LEVEL_ACCESS_CONTROL.GRANTS 
    WHERE GRANTEE_NAME = CURRENT_ROLE()
)

SELECT
    rp.PRIVILEGE,
    rp.DESCRIPTION,
    CASE
        WHEN up.PRIVILEGE IS NULL THEN '❌ MISSING'
        ELSE '✅ PRESENT'
    END as STATUS
FROM required_privileges rp
LEFT JOIN user_privileges up ON rp.PRIVILEGE = up.PRIVILEGE
ORDER BY STATUS, rp.PRIVILEGE;
```

## Step 3: Data Access Readiness

### Model Data Access Check

```sql
-- Verify model data access
SELECT
  'MODEL_STORAGE' as ACCESS_POINT,
  CASE
    WHEN EXISTS (SELECT 1 FROM <MODEL_DATABASE>.<MODEL_SCHEMA>.MODELS WHERE TYPE = 'CORTEX_MODEL')
    THEN '✅ MODEL_DATA_AVAILABLE'
    ELSE '❌ MODEL_DATA_UNAVAILABLE'
  END as STATUS,
  'Ensure model files are accessible in the specified location' as NOTES;

UNION ALL

SELECT
  'SAMPLE_DATA' as ACCESS_POINT,
  CASE
    WHEN EXISTS (SELECT 1 FROM <database>.<schema>.SAMPLE_DATA LIMIT 1)
    THEN '✅ SAMPLE_DATA_AVAILABLE'
    ELSE '❌ SAMPLE_DATA_UNAVAILABLE'
  END as STATUS,
  'Verify sample data exists for model testing' as NOTES;
```

### Data Access Framework

```
# Data Access Readiness Matrix

| Data Source | Base Mode | Agentic Mode | Access Method |
|---|---|---|---|
| Model Repository | ✅ Direct | ✅ Direct | Internal storage |
| Training Data | ✅ Required | ✅ Required | Warehouse tables |
| Sample Data | ✅ Recommended | ✅ Recommended | Test queries |
| Validation Data | ✅ Required | ✅ Required | Performance testing |

## Step 4: Monitoring & Alerting Readiness

### Current Monitoring Setup

```sql
-- Check monitoring configuration
SELECT
  NAME,
  TYPE,
  FREQUENCY,
  RECIPIENTS,
  NOTIFICATIONS
FROM SNOWFLAKE.ACCOUNT_LEVEL_ACCESS_CONTROL.MONITORS
WHERE TYPE = 'WAREHOUSE' OR TYPE = 'QUERY';
```

### Alerting Requirements Framework

```
# Alerting Readiness Matrix

| Alert Type | Base Mode | Agentic Mode | Configuration |
|---|---|---|---|
| Query Failures | ✅ Recommended | ✅ Required | Snowflake alerts |
| Cost Thresholds | ✅ Recommended | ✅ Required | Budget alerts |
| Performance Issues | ✅ Recommended | ✅ Required | Query time alerts |
| Model Errors | ✅ Required | ✅ Required | Custom monitors |

## Step 5: Final Readiness Score

### Calculate Readiness Score

```sql
-- Comprehensive readiness assessment
WITH readiness_checks AS (
    SELECT
        'WAREHOUSE_SIZE' as CHECK_NAME,
        CASE
            WHEN (SELECT SIZE FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSES 
                  WHERE NAME = '<WAREHOUSE_NAME>') IN ('XL', 'XXL', 'XXXL') 
            THEN 1 ELSE 0
        END as SCORE,
        'Warehouse must be XLARGE or larger for optimal performance' as NOTES
    UNION ALL
    SELECT
        'PRIVILEGES',
        CASE
            WHEN EXISTS (SELECT 1 FROM SNOWFLAKE.ACCOUNT_LEVEL_ACCESS_CONTROL.GRANTS 
                        WHERE GRANTEE_NAME = CURRENT_ROLE() 
                        AND PRIVILEGE = 'CORTEX_EXECUTE') THEN 1 ELSE 0
        END as SCORE,
        'Role must have CORTEX_EXECUTE privilege' as NOTES
    UNION ALL
    SELECT
        'MONITORING',
        CASE
            WHEN EXISTS (SELECT 1 FROM SNOWFLAKE.ACCOUNT_LEVEL_ACCESS_CONTROL.MONITORS 
                        WHERE NAME IS NOT NULL) THEN 1 ELSE 0
        END as SCORE,
        'Basic monitoring should be configured' as NOTES
)

SELECT
    SUM(SCORE) / COUNT(*) * 100 as READINESS_PERCENTAGE,
    SUM(SCORE) as PASSED_CHECKS,
    COUNT(*) as TOTAL_CHECKS,
    CASE
        WHEN SUM(SCORE) / COUNT(*) >= 80 THEN '✅ READY FOR DEPLOYMENT'
        WHEN SUM(SCORE) / COUNT(*) >= 60 THEN '⚠️ MOSTLY READY'
        ELSE '❌ NOT READY - ADDRESS BLOCKERS'
    END as READINESS_STATUS
FROM readiness_checks;
```

## Readiness Framework

```
# Deployment Readiness Assessment

| Readiness Score | Status | Recommendation |
|---|---|---|
| 90-100% | ✅ OPTIMAL | Deploy immediately |
| 80-89% | ⚠️ MOSTLY READY | Fix warnings before deployment |
| 70-79% | ⚠️ CAUTIONARY | Address critical issues |
| 60-69% | ❌ PREPARATORY | Complete major fixes |
| < 60% | ❌ NOT READY | Complete foundation work |

## Output Templates

### Deployment Readiness Report

```markdown
# Snowflake Cortex Deployment Readiness Report

## Environment Assessment

**Warehouse**: <WAREHOUSE_NAME> (<SIZE>)
**Current Status**: <WAREHOUSE_STATUS>
**Model**: <MODEL_NAME>

## Readiness Score: <PERCENTAGE>%

- **Passed Checks**: <PASSED>/<TOTAL>
- **Overall Status**: <STATUS>

## Detailed Assessment

| Readiness Area | Score | Details |
|---|---|---|
| Warehouse Infrastructure | <WAREHOUSE_SCORE> | <WAREHOUSE_DETAILS> |
| Role & Permissions | <PRIVILEGES_SCORE> | <PRIVILEGES_DETAILS> |
| Data Access | <DATA_SCORE> | <DATA_DETAILS> |
| Monitoring & Alerts | <MONITORING_SCORE> | <MONITORING_DETAILS> |

## Critical Blockers

❌ **BLOCKER 1**: <BLOCKER_1>
- **Impact**: Prevents deployment
- **Fix**: <FIX_1>

❌ **BLOCKER 2**: <BLOCKER_2>
- **Impact**: Prevents deployment
- **Fix**: <FIX_2>

## Recommendations

### Immediate Actions (Next 24 hours)

1. **<ACTION_1>** - Priority: <PRIORITY>
2. **<ACTION_2>** - Priority: <PRIORITY>
3. **<ACTION_3>** - Priority: <PRIORITY>

### Preparation Steps (Next week)

1. **<STEP_1>** - Timeline: <TIMELINE>
2. **<STEP_2>** - Timeline: <TIMELINE>
3. **<STEP_3>** - Timeline: <TIMELINE>

## Deployment Timeline

**Green Light Deployment**: <DATE> - If all blockers resolved
**Yellow Light**: <DATE> - If partial readiness
**Red Light**: <DATE> - If major blockers remain

## Success Metrics

- **Pre-deployment**: <METRICS>
- **Post-deployment**: <METRICS>
- **Monitoring**: <MONITORING_PLAN>

## Rollback Plan

**Trigger Conditions**:
- <CONDITION_1>
- <CONDITION_2>
- <CONDITION_3>

**Rollback Steps**:
1. **<STEP_1>** - <DESCRIPTION>
2. **<STEP_2>** - <DESCRIPTION>
3. **<STEP_3>** - <DESCRIPTION>
```

### Action Plan Generator

```markdown
# Immediate Action Plan

## Priority 1 - Blockers (Next 24 hours)

1. **WAREHOUSE UPGRADE**
   - **Task**: Upgrade warehouse to XLARGE or larger
   - **Owner**: <ROLE>
   - **Deadline**: <TIME>
   - **Resources**: Budget approval, maintenance window

2. **PRIVILEGE GRANTING**
   - **Task**: Add missing Cortex privileges
   - **Owner**: <ROLE>
   - **Deadline**: <TIME>
   - **Resources**: Role management access

3. **MONITORING SETUP**
   - **Task**: Configure basic monitoring alerts
   - **Owner**: <ROLE>
   - **Deadline**: <TIME>
   - **Resources**: Alert system configuration

## Priority 2 - Improvements (Next week)

1. **PERFORMANCE TESTING**
   - **Task**: Establish performance baselines
   - **Owner**: <ROLE>
   - **Deadline**: <TIME>

2. **BACKUP MODEL PREPARATION**
   - **Task**: Identify fallback models
   - **Owner**: <ROLE>
   - **Deadline**: <TIME>

## Success Criteria

- **All blockers resolved**: <YES/NO>
- **Performance targets met**: <YES/NO>
- **Monitoring operational**: <YES/NO>
- **Team trained**: <YES/NO>
```

## Anti-patterns (Never Do)

- Never skip warehouse readiness assessment
- Never assume permissions are sufficient
- Never deploy without monitoring in place
- Never ignore data access verification
- Never deploy with incomplete readiness assessment
- Never rush through readiness checks to meet deadlines
- Never deploy without rollback plan

## Behavior contract

- Always provide comprehensive readiness assessment
- Always identify critical blockers clearly
- Always provide specific action plans with timelines
- Always ask for user confirmation before making changes
- Always prioritize blockers clearly
- Always provide rollback plan when deployment issues arise
- Never deploy without complete readiness assessment