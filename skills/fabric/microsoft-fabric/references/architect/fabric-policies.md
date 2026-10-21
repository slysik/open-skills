# Fabric architect: Fabric policies (admin guardrails)

Last verified: 2026-10-21. Source: Microsoft Learn `fabric/governance/fabric-policies-overview` (2026-09-29), `fabric-policies-item-creation` (2026-09-29), `fabric-policies-rest-api`. Everything here is **Preview** (the tenant setting is "Policies (preview)" and the REST page labels the APIs preview). Policy-set and rule **endpoint paths, verbs, scopes and response JSON were not shown** on the REST page, only operation names: those are `UNVERIFIED`. Linked sub-pages (get started, external data sharing, edit workspace settings) were not read. The existing `onelake-catalog-govern-cli` skill audits labels, domains and tags; it does not create these policies.

## 1. What a policy is
A Fabric policy is stored as a Fabric item in a workspace. **Scope (Tenant or Capacity) is set at creation and cannot change.** A policy must be **activated** before rules take effect; there is one active policy per scope; changes take effect within 15 minutes of activation. Git can manage the definition but cannot activate it. Policies consume no capacity units and have no extra licence charge.

| Policy type | Scope | Default when no rule applies |
|---|---|---|
| Allow item creation | Capacity | Allow all item types |
| Allow external data sharing | Tenant | Block all |
| Allow workspace settings editing | Tenant | Allow editing of all workspace settings |

Only the `Allow` effect exists. Rules form an allow list: if rules exist but none match, the action is denied. Conditions within a rule are ANDed; values inside one condition are ORed (`AnyOf`) or NORed (`NoneOf`); unspecified conditions match everything. Blocked operations are recorded in audit logs; the exact user-facing error text was not found.

## 2. Item-creation policy (the CSA-relevant one)
Modes: Allow all, Blocked, Advanced (allow list). Switching to Advanced with an Allow rule blocks every other item type immediately. Activation must use `ScopeType` `Capacity`; activating with `Workspace` is rejected. Target properties: `principal.groups.id` (transitive Entra group IDs), `item.type` (API identifiers, for example `DataPipeline` for Pipeline), `workspace.id` (GUIDs in the selected capacity). `workspace.name` is rejected (`UnsupportedPropertyValue`).

```json
{
  "displayName": "Allow engineering item creation",
  "policy": "ItemCreation",
  "conditions": [
    { "type": "Dynamic", "targetProperty": "principal.groups.id",
      "predicate": { "operator": "AnyOf", "values": ["<entra-group-object-id>"] } },
    { "type": "Dynamic", "targetProperty": "item.type",
      "predicate": { "operator": "AnyOf", "values": ["Notebook", "DataPipeline", "Lakehouse"] } },
    { "type": "Dynamic", "targetProperty": "workspace.id",
      "predicate": { "operator": "AnyOf", "values": ["<workspace-id>"] } }
  ]
}
```
The Create Policy Rule API has no `effect` property: blocking is implicit for unmatched requests. The external-data-sharing rule shape uses `policy: "ExternalDataShare"` with conditions `Principal.UserAndSecurityGroup`, `Workspace.Id`, `EDS.RecipientEmailDomain` and `then: {"effect": "Allow"}`.

## 3. REST operations (names only)
Create Policy Set, Add / Update / Delete / List Policy Rule, Activate Policy Set (Tenant or Capacity), Deactivate Policy Set, List Policy Sets, Read Active Policy Sets, Policy Evaluation API. Activation needs a Fabric administrator (Tenant scope) or capacity administrator (Capacity scope). Auth: user tokens, service principals, managed identities. Before scripting, open the REST reference for each operation and copy the exact path and scope; do not guess.

## 4. Limits and constraints
Tenant-scoped policy: up to 100 rules; capacity-scoped: up to 50 rules; up to 50 workspaces and 50 security groups per rule; 1 to 50 values per condition; **unsupported regions: West Europe, North Europe, West US**. Tenant setting "Policies (preview)" can be limited to a security group. Admin portal home: OneLake catalog, Govern, Policies.

## 5. When to use it
**Use** for a controlled prod capacity (only engineering groups create Lakehouse, Notebook, Pipeline in approved workspaces), for blocking item types a regulated tenant has not approved (for example preview AI items), and for external-sharing guardrails. **Do not use** as your only control: it does not replace workspace roles, OneLake security, labels or Purview (see [security-governance.md](security-governance.md)), and unsupported regions cannot use it.

## 6. Rollout pattern
1. Inventory item types actually in use on the capacity (audit first).
2. Create the policy in audit-friendly shape: Allow all, then draft the Advanced rules.
3. Name Entra groups per role; keep rule counts under the 50 limit.
4. Activate on a non-prod capacity, wait 15 minutes, test with a user outside the group.
5. Activate on prod with a documented exception process (a break-glass group rule).

## 7. Anti-patterns
- Switching to Advanced on prod without testing: every unlisted item type is blocked immediately.
- Using workspace names in conditions (rejected; use IDs).
- Expecting the policy to change after Git sync without activating it.
- Assuming it works in West Europe, North Europe or West US.

## 8. Talk track
"Policies are the guardrail layer: who can create which item types, where. We start permissive, learn what is used, then switch to an allow list on production with an exception group, and we remember it takes up to 15 minutes to apply and is preview."
