-- Snowflake-side setup for the Kafka Connector (v4 Snowpipe Streaming).
-- GENERATED from blueprint kafka-to-snowflake — values resolved from live sensed state.
--
-- Before running: replace {{PUBLIC_KEY}} with the body of rsa_key.pub
-- (no BEGIN/END, no newlines). gen-keypair.sh produces it.
-- Idempotent; all object refs fully qualified (works via snowq REST too).

------------------------------------------------------------------------------
-- 1. Database / schema / warehouse
------------------------------------------------------------------------------
CREATE DATABASE  IF NOT EXISTS {{DB}};
CREATE SCHEMA    IF NOT EXISTS {{DB}}.{{SCHEMA}};
CREATE WAREHOUSE IF NOT EXISTS {{WAREHOUSE}}
  WITH WAREHOUSE_SIZE = XSMALL
       AUTO_SUSPEND   = 60
       AUTO_RESUME    = TRUE
       INITIALLY_SUSPENDED = TRUE;

------------------------------------------------------------------------------
-- 2. Service-account user (key-pair auth, no password)
------------------------------------------------------------------------------
CREATE USER IF NOT EXISTS {{CONN_USER}}
  LOGIN_NAME            = {{CONN_USER}}
  DISPLAY_NAME          = 'Kafka Connector Service Account'
  MUST_CHANGE_PASSWORD  = FALSE
  COMMENT               = 'Used by the Snowflake Kafka Connector';

ALTER USER {{CONN_USER}} SET RSA_PUBLIC_KEY = '{{PUBLIC_KEY}}';

------------------------------------------------------------------------------
-- 3. Role with DIRECT grants (v4 ignores role hierarchy)
------------------------------------------------------------------------------
CREATE ROLE IF NOT EXISTS {{CONN_ROLE}};

GRANT USAGE        ON DATABASE  {{DB}}                TO ROLE {{CONN_ROLE}};
GRANT USAGE        ON SCHEMA    {{DB}}.{{SCHEMA}}     TO ROLE {{CONN_ROLE}};
GRANT CREATE TABLE ON SCHEMA    {{DB}}.{{SCHEMA}}     TO ROLE {{CONN_ROLE}};
GRANT CREATE STAGE ON SCHEMA    {{DB}}.{{SCHEMA}}     TO ROLE {{CONN_ROLE}};
GRANT CREATE PIPE  ON SCHEMA    {{DB}}.{{SCHEMA}}     TO ROLE {{CONN_ROLE}};
GRANT USAGE        ON WAREHOUSE {{WAREHOUSE}}         TO ROLE {{CONN_ROLE}};

GRANT ROLE {{CONN_ROLE}} TO USER {{CONN_USER}};
ALTER USER {{CONN_USER}} SET DEFAULT_ROLE = {{CONN_ROLE}}
                             DEFAULT_WAREHOUSE = {{WAREHOUSE}};

------------------------------------------------------------------------------
-- 4. Pre-create the target table (canonical 2-column VARIANT layout)
------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS {{DB}}.{{SCHEMA}}.{{TABLE}} (
  RECORD_METADATA VARIANT,
  RECORD_CONTENT  VARIANT
);
GRANT INSERT, SELECT ON TABLE {{DB}}.{{SCHEMA}}.{{TABLE}} TO ROLE {{CONN_ROLE}};

------------------------------------------------------------------------------
-- 5. Sanity check
------------------------------------------------------------------------------
SHOW USERS LIKE '{{CONN_USER}}';
SHOW GRANTS TO ROLE {{CONN_ROLE}};
