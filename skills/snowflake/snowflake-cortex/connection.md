# Snowflake — Connection (connection.md)

CLI-first. The **Snowflake CLI (`snow`) is the single primary path**; `snowsql`
and the Python connector are documented fallbacks only. MCP is never required.

Standard connection contract: **Interactive · Service principal · Verify · Troubleshoot**.
Shared by `snowflake-cortex`, `cortex-code`, and `snowflake-kafka`.

## Interactive (dev default)

Named connections live in `~/.snowflake/connections.toml`. Each top-level entry
MUST be a `[section]` — see Troubleshoot for the one-key gotcha.

```toml
# ~/.snowflake/connections.toml   (chmod 600)
[my_conn]
account = "ORG-ACCOUNT"
user = "slysik"
authenticator = "SNOWFLAKE"          # or EXTERNALBROWSER / PROGRAMMATIC_ACCESS_TOKEN
role = "SYSADMIN"
warehouse = "WH_TRANSFORM"
database = "RAW_DEV"
schema = "PUBLIC"
```

```toml
# ~/.snowflake/config.toml   — default lives HERE, not in connections.toml
default_connection_name = "my_conn"
```

```bash
snow connection list                    # show all configured connections
snow connection test -c my_conn         # auth + simple query
snow sql -c my_conn -q "SELECT CURRENT_USER(), CURRENT_ROLE(), CURRENT_WAREHOUSE()"
```

Browser SSO: set `authenticator = "EXTERNALBROWSER"`.

## Service principal (headless / cron) — key-pair auth

Preferred for automation: RSA key-pair, no interactive prompt.

```bash
openssl genrsa 2048 | openssl pkcs8 -topk8 -inform PEM -out rsa_key.p8 -nocrypt
openssl rsa -in rsa_key.p8 -pubout -out rsa_key.pub
# In Snowflake: ALTER USER svc_user SET RSA_PUBLIC_KEY='<contents of rsa_key.pub>';
```

```toml
[svc]
account = "ORG-ACCOUNT"
user = "SVC_USER"
authenticator = "SNOWFLAKE_JWT"
private_key_file = "/secure/rsa_key.p8"
role = "SVC_ROLE"
warehouse = "WH_AI"
```

Or via env (CI): `SNOWFLAKE_ACCOUNT`, `SNOWFLAKE_USER`,
`SNOWFLAKE_PRIVATE_KEY_PATH`, `SNOWFLAKE_ROLE`, `SNOWFLAKE_WAREHOUSE`.
`PROGRAMMATIC_ACCESS_TOKEN` is also supported (set the token, not a password).

## Verify (single command)

```bash
snow connection test -c my_conn
```

Returns host, user, role, warehouse on success. Deeper check:

```bash
snow sql -c my_conn -q "SELECT CURRENT_USER() u, CURRENT_ROLE() r, CURRENT_WAREHOUSE() w"
```

## Troubleshoot

| Symptom | Cause | Fix |
|---|---|---|
| `'String' object has no attribute 'items'` on `snow connection list` | A bare key (e.g. `default_connection_name = "..."`) at the **top level** of `connections.toml`; the parser expects every top-level entry to be a `[table]`. | Move `default_connection_name` into `~/.snowflake/config.toml`. (Fixed here 2026-06-23.) |
| `250001 … user account has been temporarily locked` | Too many failed logins (often a stale password authenticator). | Wait for the lock to clear or have an admin unlock; switch to key-pair auth to avoid password lockouts. |
| `251006: Password is empty` | `PROGRAMMATIC_ACCESS_TOKEN` / password authenticator with no secret set. | Set the token/password via env or `connections.toml`, or switch to `SNOWFLAKE_JWT` key-pair. |
| `'NoneType' object is not subscriptable` on connect | `authenticator = "PROGRAMMATIC_ACCESS_TOKEN"` with a plain password (connector 3.11 masks the real error in id_token handling). | Use `authenticator = "SNOWFLAKE"` for password auth. **Verified working:** connection `XDOJQZJ-ZSB13251` (user `SLYSIK`, role `ACCOUNTADMIN`, WH `COMPUTE_WH`) with `authenticator = "SNOWFLAKE"` and the password supplied via `SNOWFLAKE_PASSWORD` env (sourced from `~/elite-context-engineering/.env`, **not** stored in the toml). `snow connection test -c XDOJQZJ-ZSB13251` → Status OK. |
| Cortex calls fail with privilege error | Role lacks `SNOWFLAKE.CORTEX_USER`. | `GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE CORTEX_USER;` |
| Wrong warehouse billed | No warehouse in connection / session. | Set `warehouse` per connection; isolate `WH_TRANSFORM/BI/AI` for cost observability. |

> Fallbacks: `snowsql -c my_conn` (legacy) or the Python connector
> (`snowflake.connector.connect(connection_name="my_conn")`) — use only when a
> `snow` subcommand is missing. MCP may be layered on later; nothing depends on it.
