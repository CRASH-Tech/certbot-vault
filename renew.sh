#!/bin/bash

set -e

# === CREATE DIRS ===
mkdir .config
mkdir .logs
mkdir .work

# === CREATE CONFIG ===
cat <<EOF >.config.ini
dns_rfc2136_server = $RFC2136_SERVER
dns_rfc2136_port = $RFC2136_PORT
dns_rfc2136_name = $RFC2136_NAME
dns_rfc2136_secret = $RFC2136_SECRET
dns_rfc2136_algorithm = $RFC2136_ALGORITHM
dns_rfc2136_sign_query = $RFC2136_SIGN_QUERY
EOF

# === Convert comma-separated domains to array ===
IFS=',' read -ra DOMAIN_ARRAY <<<"$DOMAINS"
PRIMARY_DOMAIN="${DOMAIN_ARRAY[0]}"

while true; do
    # === Loop through each domain ===
    for DOMAIN in "${DOMAIN_ARRAY[@]}"; do
        echo "🔧 Processing domain: $DOMAIN"
        DOMAIN=$(echo "$DOMAIN" | xargs)
        CERT_DIR=".config/live/$DOMAIN"

        # === Obtain certificate ===
        certbot certonly \
            --non-interactive \
            --agree-tos \
            --email "$EMAIL" \
            --dns-rfc2136 \
            --dns-rfc2136-credentials .config.ini \
            --dns-rfc2136-propagation-seconds $PROPAGATION_SECONDS \
            --logs-dir .logs \
            --work-dir .work \
            --config-dir .config \
            $CERTBOT_ARGS \
            -d "$DOMAIN" \
            -d "*.$DOMAIN"

        if [ $? -eq 0 ]; then
            echo "✅ Get certificate for $DOMAIN"
        else
            echo "❌ Cannot get certificate for $DOMAIN"
            continue
        fi

        # === Upload to Vault ===
        if [ -f "$CERT_DIR/fullchain.pem" ] && [ -f "$CERT_DIR/privkey.pem" ]; then
            vault kv put "$VAULT_PATH/$DOMAIN" \
                tls.crt=@"$CERT_DIR/fullchain.pem" \
                tls.key=@"$CERT_DIR/privkey.pem"
            echo "✅ Uploaded cecertificate for $DOMAIN to Vault at $VAULT_PATH/$DOMAIN"
        else
            echo "❌ Certificate files not found for $DOMAIN"
            continue
        fi
    done

    sleep $RENEW_PERIOD
done
