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

read -p "What is the local domain name? " DOMAIN

mkcert -key-file conf/ssl/nginx.key -cert-file conf/ssl/nginx.crt "$DOMAIN" localhost 127.0.0.1 ::1

# Save the domain to .env file
sed -i '' "s/^DOMAIN=.*/DOMAIN=$DOMAIN/" .env

# 4. Ask for confirmation to create Maho Commerce project
read -p "Do you want to create the Maho Commerce project into volume? (yes/no) " CONFIRM

if [[ $CONFIRM == "yes" || $CONFIRM == "y" ]]; then
    docker compose run php composer create-project -s dev mahocommerce/maho-starter .
else
    echo "Skipping Maho Commerce project creation."
fi

echo "Script completed."