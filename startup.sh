#!/bin/bash

# Function to perform a simple math challenge
function math_challenge {
    NUM1=$((RANDOM % 10 + 1))
    NUM2=$((RANDOM % 10 + 1))
    RESULT=$((NUM1 + NUM2))
    
    read -p "To confirm, please solve this: $NUM1 + $NUM2 = " ANSWER
    
    if [ "$ANSWER" -eq "$RESULT" ]; then
        return 0
    else
        return 1
    fi
}

# 1. Check if .env file exists. If it does, offer to reset everything.
if [ -f .env ]; then
    echo "Sorry, another installation has been found."
    echo "First, delete the .env file and remove the codebase volume to generate a new Maho project."
    
    read -p "If you like me to reset ALL project (code, db), I can do it, but it will destroy ALL. Confirm? (yes/no) " RESET_CONFIRM
    echo

    if [[ "$RESET_CONFIRM" == "yes" || "$RESET_CONFIRM" == "y" ]]; then
        if math_challenge; then
            echo "Math challenge passed. Proceeding with reset..."
            
            # 1. Stop and remove all Docker Compose services and their orphans
            docker compose down --remove-orphans
            
            # 2. Retrieve the project name used by Docker Compose
            PROJECT_NAME=$(basename "$(pwd)")

            # 3. Fetch all volume names from the docker-compose.yml file under the current directory
            VOLUMES=$(docker compose config --volumes)
            
            # 4. Remove only the volumes in the current directory context
            for volume in $VOLUMES; do
                FULL_VOLUME_NAME="${PROJECT_NAME}_${volume}"
                echo "Removing volume: $FULL_VOLUME_NAME"
                docker volume rm "$FULL_VOLUME_NAME"
                if [ $? -eq 0 ]; then
                    echo "Successfully removed volume: $FULL_VOLUME_NAME"
                else
                    echo "Failed to remove volume: $FULL_VOLUME_NAME"
                fi
            done
            
            # 5. Remove the .env file
            rm .env
            
            # Finish script and ask user to relaunch manually
            echo "Project reset complete."
            echo "Please relaunch the script manually to start over."
            exit 0
        else
            echo "Math challenge failed. Exiting without making any changes."
            exit 1
        fi
    else
        echo "Operation canceled. Exiting."
        exit 1
    fi
fi


# 0. check .env
#if [ -f .env ]; then
#    echo "Sorry, another installation has been found."
#    echo "First, delete the .env file and remove the codebase volume to generate a new Maho project."
#    exit 1
#fi

cp .env.example .env

# 1. Check if mkcert is installed
if ! command -v mkcert &> /dev/null
then
    echo "mkcert is not installed. It's a prerequisite for this script."
    echo "Please install it from: https://github.com/FiloSottile/mkcert"
    exit 1
fi

# 2. Check if openssl is installed
if ! command -v openssl &> /dev/null
then
    echo "openssl is not installed. It's a prerequisite for this script."
    echo "Please install it from: https://www.openssl.org/"
    exit 1
fi

# 3. Check for or create the folder ./conf/ssl
mkdir -p ./conf/ssl

# 4. Execute mkcert -install and generate certificates
mkcert -install

# 5. Get the local domain name from the user with validation
while true; do
    echo
    read -p "Please type the domain to assign to this new project (e.g., maho.dev.local or maho.dev) " DOMAIN
    echo
    echo

    # Validate the domain name format using regex
    if [[ ! "$DOMAIN" =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        echo "Invalid domain format. Please enter a valid domain name, such as 'maho.dev.local' or 'maho.dev'."
    elif [ -z "$DOMAIN" ]; then
        echo "You did not enter a domain name. Please enter a valid domain name."
    else
        break
    fi
done

mkcert -key-file conf/ssl/nginx.key -cert-file conf/ssl/nginx.crt "$DOMAIN" localhost 127.0.0.1 ::1

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

LOGZ=$(openssl rand -base64 10 | tr -d '/+=' | cut -c1-20)
# Update the .env file with the random name for the Dazzle filter using sed
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS (BSD `sed`)
    sed -i "" "s/^LOGZ_LABEL=.*/LOGZ_LABEL=$LOGZ/" .env
else
    # Linux and WSL (GNU `sed`)
    sed -i "s/^LOGZ_LABEL=.*/LOGZ_LABEL=$LOGZ/" .env
fi

# Echo the chosen domain name
echo
echo "The domain name chosen is: $DOMAIN"
echo

# 7. Ask the user for nginx exposed ports with validation
echo "Note: If the ports you choose are already in use, Docker Compose will fail to start."
echo

# Validate NGINX HTTP port input
while true; do
    read -p "Which port should be exposed for HTTP (default 28282)? " NGINX_HTTP_PORT
    echo
    NGINX_HTTP_PORT=${NGINX_HTTP_PORT:-28282}  # Set default if empty

    # Check if the input is a valid number
    if [[ "$NGINX_HTTP_PORT" =~ ^[0-9]+$ ]]; then
        break
    else
        echo "Please enter a valid number for the HTTP port."
        echo
    fi
done

# Validate NGINX HTTPS port input
while true; do
    read -p "Which port should be exposed for HTTPS (default 28383)? " NGINX_HTTPS_PORT
    echo
    NGINX_HTTPS_PORT=${NGINX_HTTPS_PORT:-28383}  # Set default if empty

    # Check if the input is a valid number
    if [[ "$NGINX_HTTPS_PORT" =~ ^[0-9]+$ ]]; then
        break
    else
        echo "Please enter a valid number for the HTTPS port."
        echo
    fi
done

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
echo

# 8. Ask to create the MariaDB variables
read -p "Can I create the MariaDB variables? Attention, current ones will be overwritten (yes/no or enter for "yes" as default) " CREATE_DB_VARS
echo

CREATE_DB_VARS=${CREATE_DB_VARS:-yes}

if [[ $CREATE_DB_VARS == "yes" || $CREATE_DB_VARS == "y" ]]; then
    # Generate a 20-character password for MARIADB_PASSWORD using openssl
    MARIADB_PASSWORD=$(openssl rand -base64 20 | tr -d '/+=' | cut -c1-20)

    # Generate a 10-character name for MARIADB_DATABASE and MARIADB_USER (same value) using openssl
    MARIADB_DB_USER=$(openssl rand -base64 10 | tr -d '/+=' | cut -c1-10)

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
    echo
else
    echo "Skipping MariaDB variable creation."
    echo
fi

# 9. Check if Maho Commerce project should be created
read -p "Do you want to create the Maho Commerce project into volume? (yes/no or enter for "yes" as default) " CONFIRM
echo

CONFIRM=${CONFIRM:-yes}

if [[ $CONFIRM == "yes" || $CONFIRM == "y" ]]; then
    # Run a check inside the PHP container to see if /var/www/html exists and is not empty
    docker compose run --rm php sh -c '
        if [ -d "/var/www/html" ] && [ "$(ls -A /var/www/html)" ]; then
            echo
            echo "Maho Commerce project has already been initialized. Skipping creation."
            echo
        else
            echo
            echo "/var/www/html is empty or does not exist. Initializing Maho Commerce project..."
            echo
            composer create-project -s dev mahocommerce/maho-starter /var/www/html
        fi
    '
else
    echo "Skipping Maho Commerce project creation."
    echo
fi

echo "========================================"
echo "Recap of the configuration:"
echo "========================================"
echo "The Maho HTTP base URL is: http://$DOMAIN:$NGINX_HTTP_PORT"
echo "The Maho HTTPS base URL is: https://$DOMAIN:$NGINX_HTTPS_PORT"
echo "Database connection info is located in the .env file."
echo "Adminer DB Gui can be accessed at: https://$DOMAIN:$NGINX_HTTPS_PORT/adminer"
echo "Logs can be viewed at: https://$DOMAIN:$NGINX_HTTPS_PORT/logz"
echo "========================================"
echo "Remember to add the following line to your computer's hosts file to map the domain:"
echo "127.0.0.1 $DOMAIN"
echo "========================================"

read -p "Would you like to start the project now? (yes/no or enter for "yes" as default) " START_CONFIRM
START_CONFIRM=${START_CONFIRM:-yes}
if [[ "$START_CONFIRM" == "yes" || "$START_CONFIRM" == "y" ]]; then
    echo "Starting the project with Docker Compose..."
    docker compose up -d
    echo "Project started successfully. You can now access the application at https://$DOMAIN:$NGINX_HTTPS_PORT"
else
    echo "Thank you! You can start the project later by running 'docker compose up -d'."
    echo "Goodbye!"
fi

echo "Script completed."

exit 0