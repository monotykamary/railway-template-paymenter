# Paymenter on Railway

A pinned and Railway-adapted deployment for [Paymenter](https://github.com/Paymenter/Paymenter), open-source billing software for hosting providers.

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/paymenter-v157-railway?referralCode=ZqgrJ0)

## What this deploys

- Paymenter `v1.5.8`
- MariaDB `11.8.3`
- Redis `7.4.5`
- One persistent Paymenter data volume

The small adapter preserves Paymenter's generated key, Passport encryption keys, private uploads, themes, and extensions under `/data`, runs upstream migrations, and creates the first administrator only when the user table is empty.

## First login

Read `PAYMENTER_ADMIN_EMAIL` and the generated `PAYMENTER_ADMIN_PASSWORD` from the Paymenter service variables. Sign in at `/login`, open the administrator area, and rotate the password.

## Important limits

- Payment gateways, mail delivery, domain registrars, and hosting-panel integrations require their own credentials.
- Installed custom extensions and themes are persisted, but rebuilding their frontend assets still follows Paymenter's Node-based asset workflow.
- The application, queue worker, scheduler, PHP-FPM, and nginx intentionally run in one service because they share the application filesystem.
- Use Railway volume/database backups before upgrades.

## Version pins

- Paymenter source: commit `e9ff5c5e480abdacee3ee156245b2a8945236fd1` (`v1.5.8`), archive SHA-256 `ab6e40ab9ae69aacf6e138f12b882edc42bd39533d057f8cd69b7c724a584b54`
- MariaDB: `mariadb:11.8.3@sha256:ae6119716edac6998ae85508431b3d2e666530ddf4e94c61a10710caec9b0f71`
- Redis: `redis:7.4.5-alpine@sha256:bb186d083732f669da90be8b0f975a37812b15e913465bb14d845db72a4e3e08`

No production service uses `latest`.

## Updating

1. Back up MariaDB and the Paymenter volume.
2. Review the upstream release and security notes.
3. Update the Paymenter image tag and digest deliberately.
4. Validate migrations, admin login, queue work, scheduler heartbeat, uploads, persistence, and logs on a disposable Railway project.

## Upstream and license

- Source: https://github.com/Paymenter/Paymenter
- Release: https://github.com/Paymenter/Paymenter/releases/tag/v1.5.8
- Documentation: https://paymenter.org/docs
- License: MIT; see [`LICENSE`](LICENSE) and [`NOTICE`](NOTICE)
