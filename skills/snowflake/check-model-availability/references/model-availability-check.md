# Snowflake Cortex Model Availability Checker

Check Cortex model availability in base vs agentic mode with deployment readiness analysis.

## Input Required

Ask for:

1. **Model name**: What Cortex model do you want to check? (e.g., "claude-3-7-sonnet", "mixtral-8x7b", etc.)
2. **Context**: Do you need base mode availability, agentic mode availability, or both?
3. **Account**: Which Snowflake account/workspace?

## Step 1: Check Base Mode Availability

### Query Base Model Status

```sql
-- Check if model exists in base mode
try (
  SELECT CURRENT_CORTEX_MODEL('MODEL_NAME') as BASE_MODEL
  FROM TABLE(<database>.CORTEX.INFERENCE_SERVICES('/models/claude-3-7-sonnet'))
) CATCH (e) {
  -- Model not found in base mode
  SELECT 'BASE_MODEL_NOT_AVAILABLE' as STATUS, e as ERROR
}
```

**Alternative Base Mode Check**:

```sql
-- Use system function to check base mode
SELECT SNOWFLAKE.CORTEX.MODEL_INFO('MODEL_NAME') as MODEL_INFO;
```

### Base Mode Availability Framework

```
# Base Mode Availability Status

| Status | Conditions | Action |
|---|---|---|
| ✅ AVAILABLE | Model found via MODEL_INFO or INFERENCE_SERVICES | Proceed with usage |
| ❌ NOT_FOUND | Model not found in any service catalog | Check model name | Model name typos |
| ⚠️ DEPRECATED | Model found but marked deprecated | Verify alternatives |
| 🚫 ACCESS_DENIED | Model exists but access restricted | Request access |
| ❓ UNKNOWN | Error querying model status | Contact Snowflake Support |

## Step 2: Check Agentic Mode Availability

### Query Agentic Model Status

```sql
-- Check if model exists in agentic mode
try (
  SELECT SNOWFLAKE.AGENTIC_MODELS('MODEL_NAME') as AGENTIC_MODEL
  FROM <database>.CORTEX.AGENTIC_MODELS_TABLE
) CATCH (e) {
  SELECT 'AGENTIC_MODEL_NOT_AVAILABLE' as STATUS, e as ERROR
}
```

**Alternative Agentic Mode Check**:

```sql
-- Check agentic mode via catalog
SELECT MODEL_NAME, VERSION, STATUS, FEATURES FROM <database>.CORTEX.AGENTIC_MODEL_CATALOG WHERE MODEL_NAME = 'MODEL_NAME';
```

### Agentic Mode Availability Framework

```
# Agentic Mode Availability Status

| Status | Conditions | Action |
|---|---|---|
| ✅ AVAILABLE | Model found in agentic catalog | Proceed with agentic usage |
| ❌ NOT_FOUND | Model not in agentic catalog | Consider base mode alternative |
| ⚠️ PARTIAL | Model available but features limited | Verify required capabilities |
| 🚫 ACCESS_DENIED | Model exists but access restricted | Request agentic access |
| ❓ UNKNOWN | Error querying agentic status | Contact Snowflake Support |

## Step 3: Compare Base vs Agentic

### Side-by-Side Comparison

```sql
-- Compare model availability across modes
SELECT 
  'BASE_MODE' as MODE,
  MODEL_NAME,
  VERSION,
  STATUS,
  FEATURES
FROM <database>.CORTEX.BASE_MODEL_CATALOG
WHERE MODEL_NAME = 'MODEL_NAME'

UNION ALL

SELECT
  'AGENTIC_MODE' as MODE,
  MODEL_NAME,
  VERSION,
  STATUS,
  FEATURES
FROM <database>.CORTEX.AGENTIC_MODEL_CATALOG
WHERE MODEL_NAME = 'MODEL_NAME';
```

### Key Differences Analysis

| Feature | Base Mode | Agentic Mode | Decision |
|---|---|---|---|
| **Agent Capability** | ❌ Limited | ✅ Full | Choose agentic for complex tasks |
| **Memory Management** | ❌ Stateless | ✅ Persistent sessions | Choose agentic for multi-turn tasks |
| **Tool Integration** | ❌ None | ✅ Full | Choose agentic when tools needed |
| **Task Orchestration** | ❌ Manual | ✅ Automated | Choose agentic for workflow automation |
| **Resource Management** | ✅ Basic | ✅ Advanced | Both suitable |
| **Latency** | ✅ Low | ⚠️ Higher | Choose based on use case |

## Step 4: Deployment Readiness Assessment

### Pre-Deployment Checks

```sql
-- Check deployment prerequisites
SELECT 
  'WAREHOUSE_SIZE' as REQUIREMENT,
  CASE 
    WHEN WAREHOUSE_SIZE >= 'XLARGE' THEN '✅ READY'
    ELSE '❌ UPGRADE REQUIRED'
  END as STATUS,
  'Ensure warehouse size is at least XLARGE for model execution' as NOTES
FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSES
WHERE NAME = '<WAREHOUSE_NAME>'

UNION ALL

SELECT
  'ROLE_PERMISSIONS' as REQUIREMENT,
  CASE
    WHEN GRANTED_PRIVILEGES LIKE '%CORTEX%' THEN '✅ READY'
    ELSE '❌ INSUFFICIENT PRIVILEGES'
  END as STATUS,
  'Ensure role has Cortex execution privileges' as NOTES
FROM SNOWFLAKE.ACCOUNT_LEVEL_ACCESS_CONTROL.GRANTS
WHERE GRANTEE_NAME = CURRENT_ROLE();
```

### Deployment Readiness Framework

```
# Deployment Readiness Matrix

| Requirement | Base Mode | Agentic Mode | Priority |
|---|---|---|---|
| Warehouse Size | XLARGE minimum | 2X XLARGE recommended | HIGH |
| Role Privileges | CORTEX_EXECUTE | CORTEX_AGENTIC_EXECUTE | HIGH |
| Network Connectivity | Standard | Enhanced required | MEDIUM |
| Monitoring Tools | Basic | Advanced required | MEDIUM |

## Decision Tree

```
                         MODEL AVAILABILITY
                             ↓
                ┌───────────────────────┐
                │  Is model available?   │
                └─────────┬─────────────┘
                          │ YES
                ┌─────────▼─────────────┐
                │   BASE MODE ONLY?    │
                └─────┬───────┬───────┘
                      │       │
                ┌─────▼─────┐ ┌─▼─────┐
                │  Agentic  │ │Agentic │
                │   READY   │ │ ONLY   │
                └─────┬─────┘ └───┬───┘
                      │           │
                ┌─────▼─────┐ ┌───▼─────┐
                │DEPLOY NOW│ │NOT READY│
                └──────────┘ └─────────┘
```

## Output Templates

### Model Availability Report

```markdown
# Snowflake Cortex Model Availability Report

## Model Status Summary

**Model**: <MODEL_NAME>
**Check Date**: <DATE>

| Mode | Status | Version | Features | Readiness |
|---|---|---|---|---|
| Base Mode | <STATUS> | <VERSION> | <FEATURES> | <READY_STATUS> |
| Agentic Mode | <STATUS> | <VERSION> | <FEATURES> | <READY_STATUS> |

## Deployment Recommendation

**Primary Recommendation**: <CHOICE>

**Reasoning**:
- Base mode provides <BASE_REASON>
- Agentic mode offers <AGENTIC_REASON>
- <FINAL_DECISION>

## Alternative Options

If primary option not available:
- **Alternative 1**: <OPTION_1>
- **Alternative 2**: <OPTION_2>
- **Alternative 3**: <OPTION_3>

## Next Steps

1. **Immediate Actions**: <ACTIONS>
2. **Pre-Deployment**: <PREPARATION>
3. **Monitoring**: <MONITORING>

## Notes

- Availability subject to change without notice
- Contact Snowflake Support for model-specific questions
- Consider licensing costs for agentic mode
```

### Deployment Readiness Checklist

```markdown
# Deployment Readiness Checklist

## ✅ Required Items

- [ ] Model availability confirmed
- [ ] Warehouse size verified (XLARGE+)
- [ ] Role privileges granted
- [ ] Network connectivity tested
- [ ] Monitoring configured

## 📋 Optional Items

- [ ] Backup model identified
- [ ] Performance baseline established
- [ ] Error handling implemented
- [ ] Rollback plan prepared

## 🚨 Blockers

Any ❌ items above must be resolved before deployment:
1. Model availability: <STATUS>
2. Warehouse size: <STATUS>
3. Role privileges: <STATUS>
```

## Anti-patterns (Never Do)

- Never assume model availability without checking
- Never skip deployment readiness assessment
- Never deploy without proper permissions
- Never ignore base vs agentic differences
- Never assume model status without current verification
- Never deploy without testing in non-production environment first

## Behavior contract

- Always check both base and agentic mode if user asks for availability
- Always provide deployment readiness assessment
- Always recommend the best mode based on use case
- Always include alternative options if primary unavailable
- Always verify current availability before making recommendations
- Never make assumptions about model availability or features