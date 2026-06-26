# Microsoft Fabric — Connection (auth.md)

CLI-first / REST-primary. Az CLI mints the Entra token; the **Fabric REST API is
the primary execution path** (the `fab` CLI is optional and not installed here,
and REST coverage is more predictable). MCP is never required.

The four headings below are the standard connection contract shared by every
skill in this suite: **Interactive · Service principal · Verify · Troubleshoot**.

## Interactive (dev default)

Already-logged-in `az` user. Mint a Fabric-scoped token and call REST.

```bash
az login   # once per machine / when the session expires

TOKEN=$(az account get-access-token \
  --resource https://api.fabric.microsoft.com \
  --query accessToken -o tsv)

curl -s -H "Authorization: Bearer $TOKEN" \
  https://api.fabric.microsoft.com/v1/workspaces | jq -r '.value[].displayName'
```

Verified working user: `fabricdev@slysikgmail.onmicrosoft.com`
tenant `cae2035f-5769-4043-8ccc-caaa469650ba`.

Known workspaces:
- `c9a28b96-8ba0-461a-be73-6c61bc97506b` — **ws-hr-policy-dev** (HR; primary)
- `2e51bf17-c40d-48b8-a6b1-8e363d079b18` — My workspace

## Service principal (headless / cron)

Register an app in Entra ID, enable the tenant setting **"Service principals can
use Fabric APIs"**, and add the SP to the target workspace (Admin/Member/
Contributor). Then use the client-credentials flow against the `.default` scope.

```bash
export AZURE_TENANT_ID=...    AZURE_CLIENT_ID=...    AZURE_CLIENT_SECRET=...

TOKEN=$(curl -s -X POST \
  "https://login.microsoftonline.com/${AZURE_TENANT_ID}/oauth2/v2.0/token" \
  -d "grant_type=client_credentials" \
  -d "client_id=${AZURE_CLIENT_ID}" \
  -d "client_secret=${AZURE_CLIENT_SECRET}" \
  -d "scope=https://api.fabric.microsoft.com/.default" | jq -r .access_token)
```

`scripts/trigger-fabric-data-agent.ts` uses this same SP flow with
`FABRIC_WORKSPACE_ID`. Keep secrets in env / a vault — never commit them.

## Verify (single command)

```bash
TOKEN=$(az account get-access-token --resource https://api.fabric.microsoft.com --query accessToken -o tsv) \
  && curl -s -H "Authorization: Bearer $TOKEN" https://api.fabric.microsoft.com/v1/workspaces \
  | jq -e '.value | length > 0' && echo "FABRIC OK"
```

Prints `FABRIC OK` when the token is valid and at least one workspace is reachable.

List a lakehouse's tables (HR workspace example):

```bash
WS=c9a28b96-8ba0-461a-be73-6c61bc97506b
LH=5f8fb01b-8425-446c-aad1-9541ec1f2f53   # lh_hr_policy_dev
curl -s -H "Authorization: Bearer $TOKEN" \
  "https://api.fabric.microsoft.com/v1/workspaces/$WS/lakehouses/$LH/tables" | jq
```

## Troubleshoot

| Symptom | Cause | Fix |
|---|---|---|
| `401 Unauthorized` | Token expired or wrong resource | Re-mint with `--resource https://api.fabric.microsoft.com` (not the ARM resource). |
| Empty `value: []` | Az identity has no Fabric workspace roles | Add the user/SP to a workspace; check default subscription with `az account show`. |
| SP gets `403` | Tenant setting off, or SP not in workspace | Enable "Service principals can use Fabric APIs"; assign the SP a workspace role. |
| `fab: command not found` | `fab` CLI not installed (expected) | Use REST (primary). Install `fab` only if you want the convenience layer. |
| Lakehouse tables empty | Data in Files section, not promoted to Delta | Promote to a Delta table or query `/files`. As of 2026-06-18 `lh_hr_policy_dev` had 0 promoted tables. |

> MCP note: a Fabric MCP server may be added later as a convenience, but no skill
> in this suite depends on it. REST is the contract.
