# Snowflake-side setup for the Kafka Connector

Source: https://docs.snowflake.com/en/user-guide/kafka-connector/setup-snowflake

## Privilege matrix

| Snowflake object | Required privilege          | When needed                                    |
|------------------|-----------------------------|------------------------------------------------|
| Database         | USAGE                       | Always                                         |
| Schema           | USAGE                       | Always                                         |
| Schema           | CREATE TABLE                | Connector auto-creates target tables           |
| Schema           | CREATE STAGE                | Classic v3 only (Snowpipe path)                |
| Schema           | CREATE PIPE                 | Classic v3 only (Snowpipe path)                |
| Existing table   | INSERT (v4) / OWNERSHIP (v3) | If table is pre-created                       |
| Existing stage   | READ, WRITE                 | Only if using a pre-created stage              |
| Existing pipe    | OPERATE                     | Only if using a user-defined pipe (v4)         |
| Warehouse        | USAGE                       | Always                                         |

**v4 critical rule:** privileges must be granted **directly** to the connector role. Inheritance through nested roles is NOT honored.

```sql
-- v4 honours this:
GRANT INSERT ON TABLE kafka_db.kafka_schema.sensors TO ROLE kafka_connector_role;

-- v4 IGNORES this even though every other Snowflake feature respects it:
GRANT ROLE data_loader TO ROLE kafka_connector_role;     -- where data_loader has INSERT
```

## End-to-end provisioning script

Lives in `scripts/setup-snowflake.sql`. Summary of what it does:

1. Create `KAFKA_DB` and `KAFKA_DB.KAFKA_SCHEMA`.
2. Create warehouse `KAFKA_WH` (XS, auto-suspend 60s).
3. Create user `KAFKA_CONNECTOR_USER` with no password — key-pair only.
4. Create role `KAFKA_CONNECTOR_ROLE` and **direct** grants for all privileges above.
5. Assign role to user, set as default, grant warehouse usage.
6. Create target table `SENSORS` with the default two-column VARIANT layout.

## Key-pair authentication, from scratch

Both v3 and v4 require key-pair auth. v4 also accepts OAuth for Snowpipe Streaming, but key-pair is simpler.

```bash
# Step 1: Generate encrypted PKCS#8 private key (AES-256)
openssl genrsa 2048 \
  | openssl pkcs8 -topk8 -v2 aes256 -inform PEM -out rsa_key.p8
# Prompts for a passphrase. Save it — goes into snowflake.private.key.passphrase.

# Step 2: Extract public key
openssl rsa -in rsa_key.p8 -pubout -out rsa_key.pub

# Step 3: View the public key
cat rsa_key.pub
```

```sql
-- Step 4: Assign public key to the user (no header/footer, no whitespace)
ALTER USER kafka_connector_user
  SET RSA_PUBLIC_KEY='MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA...';

-- Step 5: Verify
DESC USER kafka_connector_user;
-- Look at the RSA_PUBLIC_KEY_FP row — that fingerprint is what Snowflake will check.
```

### What goes into the connector config

The connector's `snowflake.private.key` value is the body of `rsa_key.p8` with PEM headers and newlines stripped:

```bash
# Helper: produces the single-line base64 string the connector wants
grep -v "BEGIN\|END" rsa_key.p8 | tr -d '\n'
```

If your private key is encrypted (recommended), also set `snowflake.private.key.passphrase` to the passphrase you typed in Step 1.

## Common auth failures

| Symptom in connector log                                  | Likely cause                                                            |
|-----------------------------------------------------------|-------------------------------------------------------------------------|
| `JWT token is invalid`                                    | Public key fingerprint mismatch — re-run step 3, re-paste in step 4.    |
| `Invalid private key` / parsing error                     | PEM headers or newlines in `snowflake.private.key`. Strip them.         |
| `Cannot open PEM` / passphrase failure                    | Forgot `snowflake.private.key.passphrase`, or wrong passphrase.         |
| `User does not have privileges on table SENSORS`          | Grants made to a parent role; v4 needs direct grants. See top of file.  |
| `403 Forbidden` from Snowpipe REST                        | v3 only — `CREATE PIPE` privilege missing on schema.                    |
| `Authentication failed` after working previously          | Account-level network policy added; whitelist your Connect worker IP.   |

## URL format

```
v3:  snowflake.url.name=<account_locator>.<region>.snowflakecomputing.com:443
v4:  snowflake.url.name=https://<org>-<account>.snowflakecomputing.com
```

For account `XDOJQZJ-ZSB13251` (memory), the v4-style URL is:
`https://XDOJQZJ-ZSB13251.snowflakecomputing.com`

The user's locator is `WVB61235.us-west-2`, so v3 form would be `WVB61235.us-west-2.aws.snowflakecomputing.com:443`.

## Tear-down

```sql
USE ROLE accountadmin;
DROP USER IF EXISTS kafka_connector_user;
DROP ROLE IF EXISTS kafka_connector_role;
DROP WAREHOUSE IF EXISTS kafka_wh;
DROP DATABASE IF EXISTS kafka_db;     -- cascades the schema, table, and any auto-created stages/pipes
```
