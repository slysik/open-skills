# Snowflake Semantic View Pattern Tutorials

Interactive, end-to-end tutorials for 25 Snowflake Semantic View (SV) modeling patterns. Each pattern ships with annotated DDL and YAML, seed data, and live `SEMANTIC_VIEW()` queries.

## Tutorial Mode Overview

### Pattern Categories

The Semantic View pattern library is organized into logical categories:

| Category | Patterns | Focus Area |
|---|---|---|
| **Time Intelligence** | 3 patterns | Date/time dimensions and metrics |
| **Joins** | 4 patterns | Data combination and relationship building |
| **Metrics** | 5 patterns | Aggregation and business calculations |
| **Dimensions** | 5 patterns | Lookups and reference data |
| **Advanced** | 8 patterns | Complex modeling scenarios |

### Getting Started with Tutorial Mode

1. **Choose Your First Pattern** - Start with a pattern that matches your current data challenge:
   - Time Intelligence: For business reporting with time-based metrics
   - Joins: For combining multiple data sources
   - Metrics: For building KPIs and business calculations

2. **Understand the Pattern Structure** - Each tutorial includes:
   - Problem statement and business context
   - SQL DDL for the Semantic View
   - YAML configuration for column mapping
   - Sample data and expected results
   - Live `SEMANTIC_VIEW()` queries you can run

3. **Deploy and Explore** - Follow the step-by-step deployment instructions to:
   - Create the Semantic View in your account
   - Load the sample data
   - Run live queries to verify functionality

4. **Extend and Customize** - Modify the pattern to match your specific requirements:
   - Adjust column mappings
   - Customize business logic
   - Add additional constraints or business rules

### Pattern Learning Path

**Beginner Path (Recommended for first-time SV users):**
1. Start with Time Intelligence patterns
2. Learn basic pattern application
3. Progress to Join patterns
4. Master Metrics patterns

**Intermediate Path (For experienced data modelers):**
1. Start with advanced Join patterns
2. Learn Semi-Additive patterns
3. Explore Fan Trap patterns
4. Master Window Metrics patterns

**Advanced Path (For SV experts):**
1. Study Accumulating Snapshot patterns
2. Learn Role Playing Dimensions patterns
3. Master Range Join and Asof Join patterns
4. Explore complex Application patterns

### Pattern Application Examples

#### Example 1: Time Intelligence Pattern

```sql
-- Create a Time Intelligence Semantic View
CREATE SEMANTIC VIEW sales_by_month AS
SELECT 
  date_trunc('month', order_date) AS month,
  customer_id,
  product_category,
  sales_amount,
  quantity_sold
FROM sales_data;
```

**Key Components:**
- **TIME_DIMENSION:** month (derived from order_date)
- **MEASURING:** sales_amount, quantity_sold
- **HIERARCHY:** customer_id, product_category

#### Example 2: Join Pattern

```sql
-- Create a Join-based Semantic View
CREATE SEMANTIC VIEW customer_order_summary AS
SELECT 
  c.customer_id,
  c.customer_name,
  o.order_date,
  p.product_name,
  o.amount,
  o.quantity
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN products p ON o.product_id = p.product_id;
```

**Key Components:**
- **LOOKUP_1:** customers (dimension)
- **LOOKUP_2:** products (dimension)  
- **MEASURING:** amount, quantity
- **MEASURING:** order_date

### Pattern Benefits

1. **Standardized Patterns** - 25 battle-tested patterns for common use cases
2. **Interactive Learning** - Deploy, explore, and customize patterns live
3. **Business Context** - Patterns include real-world business scenarios
4. **Hands-on Practice** - Live queries and sample data for immediate learning
5. **Progressive Complexity** - Patterns build on each other for skill development

### Getting Help

- **Pattern-specific questions:** Ask about individual patterns
- **Implementation guidance:** Request help applying patterns to your data
- **Customization:** Request pattern modifications for your specific needs
- **Troubleshooting:** Get help with pattern deployment or queries

### Pattern Library Access

To access the full pattern library:

1. Choose your learning mode (tutorial or apply)
2. Select a pattern category
3. Choose a specific pattern
4. Follow the deployment and customization instructions

Each pattern includes comprehensive documentation, SQL examples, and YAML configurations to guide you through the implementation process.