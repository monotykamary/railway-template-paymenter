# Deploy and Host Paymenter on Railway

## About Hosting Paymenter

Paymenter is open-source billing, invoicing, client-management, and service-automation software built for hosting providers. This template deploys stable release `v1.5.7` with private MariaDB and Redis services and durable application storage.

## Common Use Cases

- Bill customers for hosting products and subscriptions
- Automate provisioning through Paymenter extensions
- Manage invoices, services, support tickets, and customers
- Integrate payment gateways and hosting control panels

## Dependencies for Paymenter Hosting

### Deployment Dependencies

The template creates a public `paymenter` service plus private `mariadb` and `redis` services. Paymenter and both dependencies receive persistent volumes and backup schedules.

### Implementation Details

The Paymenter service owns the public HTTPS domain. Its container runs nginx, PHP-FPM, the Redis queue worker, and the Laravel scheduler together, matching the upstream shared-filesystem design. A narrow adapter maps generated configuration, private uploads, themes, and extensions into one Railway volume.

On an empty database, the adapter creates the first administrator from `PAYMENTER_ADMIN_EMAIL` and the generated `PAYMENTER_ADMIN_PASSWORD`. Read those values in the Paymenter service variables, sign in at `/login`, and rotate the password. Do not change database or Redis references independently.

Payment gateways, mail, registrars, and hosting-panel integrations require external credentials and post-deploy configuration.

### Why Deploy Paymenter on Railway?

Railway provides HTTPS, private database/cache networking, persistent storage, backup schedules, generated credentials, and an intentionally pinned upgrade path for a complete Paymenter installation.
