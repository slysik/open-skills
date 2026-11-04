---
name: rbac
title: Snowflake RBAC Architecture Router
title: Snowflake RBAC Router
summary: Design Snowflake RBAC roles, hierarchies, and governance for data access. Handles role design, inheritance, and permission optimization.
description: "Use for Snowflake RBAC architecture, role design, hierarchy planning, and governance. Triggers: role hierarchy, RBAC design, permission architect, data access, security, role isolation, role grants, governance, role engineering."
license: MIT
metadata:
  author: SnowFlake Security Solutions
  version: "1.0.0"
  updated: "2026-06-28"
---

# Snowflake RBAC Router

Design and validate Snowflake Role-Based Access Control (RBAC) architectures. Includes role hierarchy design, permission analysis, and governance.

## Route the task

| User intent | Load |
|---|---|
| Design RBAC roles and hierarchies | [references/role-design.md](references/role-design.md) |
| Validate RBAC architecture | [references/rbac-validation.md](references/rbac-validation.md) |
| Audit RBAC implementation | [references/rbac-audit.md](references/rbac-audit.md) |

## Default behavior

1. If user asks about role hierarchy, role design, or RBAC architecture, load role-design.md first
2. If user asks about RBAC validation, audit, or permission issues, load rbac-validation.md
3. If user asks about existing RBAC implementation review, load rbac-audit.md
4. If no specific intent is clear, default to role-design.md