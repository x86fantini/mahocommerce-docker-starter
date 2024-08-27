#!/bin/bash

# 1. Check if mkcert is installed
if ! command -v mkcert &> /dev/null
then
    echo "mkcert is not installed. It's a prerequisite for this script."
    echo "Please install it from: https://github.com/FiloSottile/mkcert"
    exit 1
fi

# 2. Check for or create the folder ./conf/ssl
mkdir -p ./conf/ssl

# 3. Execute mkcert -install and generate certificates
mkcert -install

# 4. Get the local domain name from the user
read -p "What is the local domain name? (e.g., maho.dev.local) " DOMAIN

mkcert -key-file conf/ssl/nginx.key -cert-file conf/ssl/nginx.crt "$DOMAIN" localhost 127.0.0.1 ::1

# 5. Create or update the .env file with the DOMAIN value
if [ ! -f .env ]; then
    # If .env doesn't exist, copy from .env.example
    cp .env.example .env
fi

# Determine the operating system and apply the appropriate `sed` command
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS (BSD `sed`)
    sed -i "" "s/^DOMAIN=.*/DOMAIN=$DOMAIN/" .env
    sed -i "" "s/^DOZZLE_HOSTNAME=.*/DOZZLE_HOSTNAME=$DOMAIN/" .env
else
    # Linux and WSL (GNU `sed`)
    sed -i "s/^DOMAIN=.*/DOMAIN=$DOMAIN/" .env
    sed -i "s/^DOZZLE_HOSTNAME=.*/DOZZLE_HOSTNAME=$DOMAIN/" .env
fi

# Echo the chosen domain name
echo "The domain name chosen is: $DOMAIN"

# 6. Ask the user for nginx exposed ports
read -p "Which port should be exposed for HTTP (default 8080)? " NGINX_HTTP_PORT
read -p "Which port should be exposed for HTTPS (default 8443)? " NGINX_HTTPS_PORT

# Set default ports if the user leaves them blank
NGINX_HTTP_PORT=${NGINX_HTTP_PORT:-8080}
NGINX_HTTPS_PORT=${NGINX_HTTPS_PORT:-8443}

# Update the .env file with the chosen ports using sed
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS (BSD `sed`)
    sed -i "" "s/^NGINX_HTTP_PORT=.*/NGINX_HTTP_PORT=$NGINX_HTTP_PORT/" .env
    sed -i "" "s/^NGINX_HTTPS_PORT=.*/NGINX_HTTPS_PORT=$NGINX_HTTPS_PORT/" .env
else
    # Linux and WSL (GNU `sed`)
    sed -i "s/^NGINX_HTTP_PORT=.*/NGINX_HTTP_PORT=$NGINX_HTTP_PORT/" .env
    sed -i "s/^NGINX_HTTPS_PORT=.*/NGINX_HTTPS_PORT=$NGINX_HTTPS_PORT/" .env
fi

# Echo the chosen nginx ports
echo "The exposed ports for nginx are: HTTP=$NGINX_HTTP_PORT, HTTPS=$NGINX_HTTPS_PORT"

# 7. Ask to create the MariaDB variables
read -p "Can I create the MariaDB variables? Attention, current ones will be overwritten (yes/no) " CREATE_DB_VARS

if [[ $CREATE_DB_VARS == "yes" || $CREATE_DB_VARS == "y" ]]; then
    # Generate a 20-character password for MARIADB_PASSWORD
    MARIADB_PASSWORD=$(< /dev/urandom tr -dc 'A-Za-z0-9' | head -c20)

    # Generate a 10-character name for MARIADB_DATABASE and MARIADB_USER (same value)
    MARIADB_DB_USER=$(< /dev/urandom tr -dc 'a-z0-9' | head -c10)

    # Update the .env file with the generated values using sed
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS (BSD `sed`)
        sed -i "" "s/^MARIADB_PASSWORD=.*/MARIADB_PASSWORD=$MARIADB_PASSWORD/" .env
        sed -i "" "s/^MARIADB_DATABASE=.*/MARIADB_DATABASE=$MARIADB_DB_USER/" .env
        sed -i "" "s/^MARIADB_USER=.*/MARIADB_USER=$MARIADB_DB_USER/" .env
    else
        # Linux and WSL (GNU `sed`)
        sed -i "s/^MARIADB_PASSWORD=.*/MARIADB_PASSWORD=$MARIADB_PASSWORD/" .env
        sed -i "s/^MARIADB_DATABASE=.*/MARIADB_DATABASE=$MARIADB_DB_USER/" .env
        sed -i "s/^MARIADB_USER=.*/MARIADB_USER=$MARIADB_DB_USER/" .env
    fi

    # Echo the MariaDB variables recap
    echo "MariaDB variables have been created:"
    echo "MARIADB_PASSWORD=$MARIADB_PASSWORD"
    echo "MARIADB_DATABASE=$MARIADB_DB_USER"
    echo "MARIADB_USER=$MARIADB_DB_USER"
else
    echo "Skipping MariaDB variable creation."
fi

# 8. Ask for confirmation to create Maho Commerce project
read -p "Do you want to create the Maho Commerce project into volume? (yes/no) " CONFIRM

if [[ $CONFIRM == "yes" || $CONFIRM == "y" ]]; then
    docker compose run php composer create-project -s dev mahocommerce/maho-starter .
else
    echo "Skipping Maho Commerce project creation."
fi

echo "Script completed."
