-- Snowflake-side setup for the Kafka Connector demo.
--
-- Usage:  snowq -f setup-snowflake.sql
--
-- Edits required before running:
--   1. Replace <PASTE_PUBLIC_KEY_HERE> with the body of rsa_key.pub
--      (no header, no footer, no whitespace). gen-keypair.sh produces it.
--
-- Idempotent: re-running cleanly recreates objects without breaking key-pair.
--
-- Note: when invoked through `snowq` (Snowflake SQL REST API) the API does NOT
-- support `USE ROLE/DATABASE/SCHEMA`. The role is fixed by the caller, and all
-- object refs below are fully qualified so it works either way.

------------------------------------------------------------------------------
-- 1. Database / schema / warehouse
------------------------------------------------------------------------------
CREATE DATABASE  IF NOT EXISTS kafka_db;
CREATE SCHEMA    IF NOT EXISTS kafka_db.kafka_schema;
CREATE WAREHOUSE IF NOT EXISTS kafka_wh
  WITH WAREHOUSE_SIZE = XSMALL
       AUTO_SUSPEND   = 60
       AUTO_RESUME    = TRUE
       INITIALLY_SUSPENDED = TRUE;

------------------------------------------------------------------------------
-- 2. Service-account user (key-pair auth, no password)
------------------------------------------------------------------------------
CREATE USER IF NOT EXISTS kafka_connector_user
  LOGIN_NAME            = kafka_connector_user
  DISPLAY_NAME          = 'Kafka Connector Service Account'
  MUST_CHANGE_PASSWORD  = FALSE
  COMMENT               = 'Used by the Snowflake Kafka Connector';

-- Attach the public key. Replace the placeholder with the contents of rsa_key.pub
-- minus the BEGIN/END lines and all newlines.
ALTER USER kafka_connector_user SET RSA_PUBLIC_KEY = 'MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAwSoywdaKm1LD063q4KARl6NtTTMQZJJtg3y3rYY+o/u8HaD7Io3j9q/5lXVevVB5E5cFOOBbWul3GdgO2CA3zZjrCLGgEGkWxfyqzfOiYKcRyZvnTI+3AkolHUGgdtyy5KSf8nGofYH0xdobBc0fj3pjasREmkOF9r3Xhc7ecpGekyqz5yDFuJQLjFSoiw1/epkBfl7JHTbKSRs/znkKU5JfavFmK0tP8yk8zRhmSV/mGPFfWHdPMCZ1osHdY9GUMVQLKxSras0axmP5daCR1ZV7iiwkQFagTxHHCZesT9ZaSJ/a+jZEI5aiGaTilzWQYyugPW00/VN4oDky1t0ziwIDAQAB';

------------------------------------------------------------------------------
-- 3. Role with DIRECT grants (v4 ignores role hierarchy)
------------------------------------------------------------------------------
CREATE ROLE IF NOT EXISTS kafka_connector_role;

GRANT USAGE      ON DATABASE  kafka_db                  TO ROLE kafka_connector_role;
GRANT USAGE      ON SCHEMA    kafka_db.kafka_schema     TO ROLE kafka_connector_role;

-- Lets the connector auto-create the target table when it first sees data.
GRANT CREATE TABLE ON SCHEMA  kafka_db.kafka_schema     TO ROLE kafka_connector_role;

-- Only needed for the v3 file-based Snowpipe path. Harmless to grant.
GRANT CREATE STAGE ON SCHEMA  kafka_db.kafka_schema     TO ROLE kafka_connector_role;
GRANT CREATE PIPE  ON SCHEMA  kafka_db.kafka_schema     TO ROLE kafka_connector_role;

GRANT USAGE      ON WAREHOUSE kafka_wh                  TO ROLE kafka_connector_role;

GRANT ROLE kafka_connector_role TO USER kafka_connector_user;
ALTER USER kafka_connector_user SET DEFAULT_ROLE = kafka_connector_role
                                    DEFAULT_WAREHOUSE = kafka_wh;

------------------------------------------------------------------------------
-- 4. Pre-create the target table with the canonical 2-column VARIANT layout.
--    Skip this step if you want to watch the connector auto-create it.
------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS kafka_db.kafka_schema.sensors (
  RECORD_METADATA VARIANT,
  RECORD_CONTENT  VARIANT
);

-- Direct INSERT grant on the pre-created table — REQUIRED for v4.
GRANT INSERT, SELECT ON TABLE kafka_db.kafka_schema.sensors TO ROLE kafka_connector_role;

-- For schematization on a pre-existing table the connector role needs OWNERSHIP:
-- GRANT OWNERSHIP ON TABLE kafka_db.kafka_schema.sensors TO ROLE kafka_connector_role REVOKE CURRENT GRANTS;
-- ALTER TABLE   kafka_db.kafka_schema.sensors SET ENABLE_SCHEMA_EVOLUTION = TRUE;

------------------------------------------------------------------------------
-- 5. Sanity check
------------------------------------------------------------------------------
SHOW USERS LIKE 'kafka_connector_user';
DESC USER kafka_connector_user;          -- look at RSA_PUBLIC_KEY_FP
SHOW GRANTS TO ROLE kafka_connector_role;
