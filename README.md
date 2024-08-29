
# Docker Compose developer kit for MahoCommerce

This project aims to help developers and aficionados to embrace the power of MahoCommerce without the headache of also managing the tech stack

As of now this project is still under development, but i am activitly working on it

## Features

- Fully compatible stack
- Green SSL certs for local development
- Different parameters for great flexibility
- View logs from browser
- Gui to managed database
- Native integration with [VSCode](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
- High performance out of the box
## Tech Stack

**webserver:** Nginx

**php:** php-fpm

**db:** MariaDB

**cache/sessions:** tbd

**ssl:** [mkcert](https://github.com/FiloSottile/mkcert)

**logging:** [dozzle](https://github.com/amir20/dozzle)

**db admin:** [adminer](https://github.com/wodby/adminer)

**mail:** tbd

**cron:** [ofelia](https://github.com/mcuadros/ofelia)

**backup:** tbd
## Authors

- [@x86fantini](https://github.com/x86fantini)


## Documentation

#### Prerequisites
- [mkcert](https://github.com/FiloSottile/mkcert)
- [docker](https://docs.docker.com/get-started/get-docker/)
- [docker-compose](https://docs.docker.com/compose/install/)

#### What to know

The ```php``` container runs as the ```www-data``` user and makes use of Docker's native volume handling, so you do not need to worry about permissions and ownership. \
In this way you can use ```docker compose exec php``` in order to execute commands just like on your local machine

When the ```startup.sh``` script is executed, you will be asked:
- to install the CAROOT of mkcert into OS (macOS on my current system) trusted store
- the local domain name for ssl certificate creation , nginx ```server_name``` and MaHo ```base_url```
- the port for HTTP and HTTPS ports for nginx to bind
- the script will populate the ```MARIADB``` variables for creating db, user and password
- the command ```docker compose run php composer create-project -s dev mahocommerce/maho-starter .``` is issued so you will have the project ready to run, you can then follow the installation via browser

#### Remember to edit your ```/etc/hosts``` with the chosen domain in order to be able to browse the domain

#### Run locally

After you clone the repo, you just need to execute ```startup.sh``` to generate the SSL trusted by your system, and populate the DOMAIN environment in ```.env```

```bash
  git clone git@github.com:x86fantini/mahocommerce-docker-starter.git
  cd mahocommerce-docker-starter
  bash startup.sh
```

#### Cron management

On the ```php``` container i have already added the lables necessary to run the Maho [cron](https://mahocommerce.com/cron/) system , but you can add/edit them as per the [ofelia](https://github.com/mcuadros/ofelia/blob/master/docs/jobs.md) documentation

```bash
    labels:
      ofelia.enabled: "true"
      ofelia.job-exec.cron-default.schedule: "@every 5m"
      ofelia.job-exec.cron-default.command: "php maho cron:run default"
      ofelia.job-exec.cron-always.schedule: "@every 5m"
      ofelia.job-exec.cron-always.command: "php maho cron:run always"
```

#### Logs management

The ```logviewer``` container will be your entrypoint for logs management of all containers in the compose stack. The nginx config will catch the ```/logz/``` path and route traffic to the gui, based on chosen domain name and port. \
Eg if domain id ```maho.dev.local``` and https port ```8443```, the logviewer will be available at ```https://maho.dev.local:8443/logz``` .

#### DB Management

The ```adminer``` container will run in the background and will read the ```.env``` for the DB vars. The nginx config will catch the ```/adminer/``` path and route traffic to the gui, based on chosen domain name and port. \
Eg if domain id ```maho.dev.local``` and https port ```8443```, the logviewer will be available at ```https://maho.dev.local:8443/adminer/``` .

#### VScode plugin
If you use the [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) plugin you can easilly browse code from inside the running ```php``` container. \
The ```php``` container is equipped on board with
- git
- composer
so you can log into container ```docker compose exec php bash``` and then execute commands (git, composer, etc)