#!/usr/bin/env bash
# gen-keypair.sh — Generate a key-pair for the Snowflake Kafka Connector user.
#
# Outputs three artifacts in the current directory:
#   rsa_key.p8           encrypted PKCS#8 private key
#   rsa_key.pub          public key (PEM)
#   rsa_key.connector    private key as a SINGLE-LINE base64 string,
#                        ready to paste into snowflake.private.key
#
# It also prints the public-key body (no headers/newlines) so you can paste
# it into setup-snowflake.sql in place of <PASTE_PUBLIC_KEY_HERE>.
#
# Usage:  ./gen-keypair.sh [passphrase]
#         If you don't pass a passphrase, openssl will prompt for one.

set -euo pipefail

PASSPHRASE="${1:-}"

if [[ -f rsa_key.p8 ]]; then
  echo "rsa_key.p8 already exists in $(pwd) — refusing to overwrite." >&2
  echo "Move or delete it first." >&2
  exit 1
fi

if [[ -n "$PASSPHRASE" ]]; then
  openssl genrsa 2048 \
    | openssl pkcs8 -topk8 -v2 aes256 \
        -inform PEM \
        -out rsa_key.p8 \
        -passout "pass:$PASSPHRASE"
else
  openssl genrsa 2048 | openssl pkcs8 -topk8 -v2 aes256 -inform PEM -out rsa_key.p8
fi

# Extract public key. Needs the passphrase to read the encrypted private key.
if [[ -n "$PASSPHRASE" ]]; then
  openssl rsa -in rsa_key.p8 -pubout -out rsa_key.pub -passin "pass:$PASSPHRASE"
else
  openssl rsa -in rsa_key.p8 -pubout -out rsa_key.pub
fi

# Connector wants the private key body, single line, no PEM markers.
grep -v "BEGIN\|END" rsa_key.p8 | tr -d '\n' > rsa_key.connector
echo >> rsa_key.connector       # add trailing newline for sanity

# The public key body — paste this into ALTER USER ... SET RSA_PUBLIC_KEY=...
PUB_BODY=$(grep -v "BEGIN\|END" rsa_key.pub | tr -d '\n')

cat <<EOF

✓ Generated rsa_key.p8, rsa_key.pub, and rsa_key.connector

──────────────────────────────────────────────────────────────────────────
1. Paste the line below into setup-snowflake.sql for RSA_PUBLIC_KEY:
──────────────────────────────────────────────────────────────────────────
${PUB_BODY}

──────────────────────────────────────────────────────────────────────────
2. Use the contents of rsa_key.connector for snowflake.private.key
   (it's already a single line with PEM markers stripped).

3. If you set a passphrase, also set snowflake.private.key.passphrase in
   the connector config to that same value.
──────────────────────────────────────────────────────────────────────────
EOF

chmod 600 rsa_key.p8 rsa_key.connector
