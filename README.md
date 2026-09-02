
# Docker Compose developer kit for MahoCommerce

This project aims to help developers and aficionados to embrace the power of [MahoCommerce](https://mahocommerce.com/) without the headache of also managing the tech stack.

> [!NOTE]
> This stack follows the official Maho documentation. See [Getting started](https://mahocommerce.com/about/getting-started/) and [Web server configuration](https://mahocommerce.com/hosting/web-server/) for reference.

## Features

- Fully compatible stack aligned with [official Maho docs](https://mahocommerce.com/about/getting-started/)
- Green SSL certs for local development via [mkcert](https://github.com/FiloSottile/mkcert)
- Configurable parameters for great flexibility
- View logs from browser via [Dozzle](https://github.com/amir20/dozzle)
- GUI to manage database via [Adminer](https://github.com/wodby/adminer)
- [Redis](https://mahocommerce.com/hosting/redis/) for cache and sessions
- [Mailpit](https://github.com/axllent/mailpit) for local email testing
- Native integration with [VSCode Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
- [Cron](https://mahocommerce.com/hosting/cron/) management via [Ofelia](https://github.com/mcuadros/ofelia)
- High performance out of the box

## Tech Stack

| Component | Technology | Notes |
|---|---|---|
| **webserver** | Nginx | Configured per [official docs](https://mahocommerce.com/hosting/web-server/) |
| **php** | PHP-FPM 8.3 | Supported: 8.3 / 8.4 / 8.5 |
| **db** | MariaDB 10.11 LTS | [Supported DBs](https://mahocommerce.com/about/getting-started/#system-requirements) |
| **cache/sessions** | Redis 7 | [Redis docs](https://mahocommerce.com/hosting/redis/) |
| **ssl** | [mkcert](https://github.com/FiloSottile/mkcert) | Trusted local certs |
| **logging** | [Dozzle](https://github.com/amir20/dozzle) | Browser-based log viewer |
| **db admin** | [Adminer](https://github.com/wodby/adminer) | Database GUI |
| **mail** | [Mailpit](https://github.com/axllent/mailpit) | Local SMTP testing |
| **cron** | [Ofelia](https://github.com/mcuadros/ofelia) | Cron job scheduler |

## Authors

- [@x86fantini](https://github.com/x86fantini)

---

## Documentation

### Prerequisites

- [mkcert](https://github.com/FiloSottile/mkcert)
- [Docker](https://docs.docker.com/get-started/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/install/)

### What to know

The `php` container runs as the `www-data` user and makes use of Docker's native volume handling, so you do not need to worry about permissions and ownership.
You can use `docker compose exec php` to execute commands just like on your local machine.

When the `startup.sh` script is executed, you will be asked:
- to install the CAROOT of mkcert into your OS trusted store
- the local domain name for SSL certificate creation, nginx `server_name` and Maho `base_url`
- the ports for HTTP and HTTPS for nginx to bind
- the script will populate the `MARIADB` variables for creating db, user and password
- the command `composer create-project mahocommerce/maho-starter .` is issued so you will have the project ready to run

### Remember to edit your `/etc/hosts` with the chosen domain

### Run locally

After you clone the repo, just execute `startup.sh` to generate the SSL trusted by your system, and populate the DOMAIN environment in `.env`

```bash
git clone git@github.com:x86fantini/mahocommerce-docker-starter.git
cd mahocommerce-docker-starter
bash startup.sh
```

### Redis (cache & sessions)

Maho supports Redis for both cache and session storage out of the box. The Redis container is included in the stack.

To enable Redis, add the following to your `app/etc/local.xml`:

**Cache:**
```xml
<global>
    <cache>
        <lifetime>86400</lifetime>
        <backend>redis</backend>
        <backend_options>
            <dsn>redis://redis:6379/0</dsn>
        </backend_options>
    </cache>
</global>
```

**Sessions:**
```xml
<global>
    <session_save>redis</session_save>
    <redis_session>
        <dsn>redis://redis:6379/1</dsn>
        <key_prefix>maho_session:</key_prefix>
    </redis_session>
</global>
```

See the [official Redis documentation](https://mahocommerce.com/hosting/redis/) for all options.

> [!IMPORTANT]
> Redis `maxmemory-policy` must be `noeviction` or a `volatile-*` policy (e.g. `volatile-lfu`). Policies like `allkeys-lfu` cause the cache to silently fail.

### Cron management

The `php` container has the labels necessary to run the Maho [cron](https://mahocommerce.com/hosting/cron/) system via [Ofelia](https://github.com/mcuadros/ofelia/blob/master/docs/jobs.md):

```yaml
labels:
  ofelia.enabled: "true"
  ofelia.job-exec.cron-default.schedule: "@every 5m"
  ofelia.job-exec.cron-default.command: "php maho cron:run default"
  ofelia.job-exec.cron-always.schedule: "@every 5m"
  ofelia.job-exec.cron-always.command: "php maho cron:run always"
```

### Logs management

The `logviewer` container (Dozzle) provides a browser-based log viewer. Access it at `https://yourdomain:port/logz/`.

### DB Management

The `adminer` container provides a database GUI. Access it at `https://yourdomain:port/adminer/`.

### Mail testing

The `mailpit` container provides local SMTP testing. Access it at `https://yourdomain:port/mailpit/`.

Configure Maho to use it by setting in `System > Configuration > Advanced > System > SMTP`:
- Host: `mailpit`
- Port: `1025`

### API configuration

The nginx configuration follows the [official Maho API routing map](https://mahocommerce.com/hosting/web-server/#api-routing-map-v267). The four API paths are properly routed:

| Path | Entry point | Handler |
|---|---|---|
| `/api/rest/v2/*` | `rest.php` | REST v2 (Symfony API Platform) |
| `/api/rest` | `api.php?type=rest` | Legacy REST |
| `/api/(soap\|v2_soap\|xmlrpc\|jsonrpc)` | `index.php` | SOAP/RPC controllers |
| `/api/*` (catch-all) | `rest.php` | REST v2 fallback |

> [!NOTE]
> API protocols default to **off**. Enable them in **System → Configuration → Services → API → API Protocols**.

### VSCode Dev Containers

If you use the [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) plugin you can easily browse code from inside the running `php` container.
The `php` container comes with `git` and `composer` on board, so you can log into the container with `docker compose exec php bash` and then execute commands.

