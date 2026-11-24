[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/opentodo-1?utm_medium=integration&utm_source=button&utm_campaign=opentodo)

# OpenTodo on Railway

One-click [Railway](https://railway.com) template for [OpenTodo](https://github.com/OpenTodoApp/OpenTodo), the open-source, local-first task manager you host yourself (AGPL-3.0).

## What it deploys

| Service | What it does | Source |
| --- | --- | --- |
| **OpenTodo** | Web app, sync API and the embedded SQLite database | This repo: `ghcr.io/opentodoapp/opentodo:1.7.0@sha256:c156bc53b3629934760b15505f404954fdbec65b890c1f3b1438d78f851a9840` plus a small start script |

- A Railway volume on `/data` holds the database, attachments and OpenTodo's own backups.
- An HTTPS Railway domain on port 8080, health check `/healthz`, restart on failure.
- Fits Railway's Free plan: about 35 MB of RAM at idle (tested with a 0.5 GB / 1 vCPU limit).

The start script (`start.sh`):

- refuses to start without `OPENTODO_SETUP_TOKEN`, so the owner account can't be claimed by the first stranger who opens the URL;
- keeps sign-up closed (`OPENTODO_ALLOW_SIGNUP=false`): other people join by invitation;
- trusts Railway's edge proxy ranges (`100.64.0.0/10`, `152.233.0.0/16`) for client addresses and HTTPS detection;
- starts without `OPENTODO_BASE_URL` (instead of crash-looping) if the service has no public domain yet;
- sets Go's memory limit to 80% of the service's limit;
- gives the root-owned volume to OpenTodo's non-root user and runs OpenTodo as that user (no `RAILWAY_RUN_UID=0`).

## Variables

| Variable | Default | What it does |
| --- | --- | --- |
| `OPENTODO_SETUP_TOKEN` | `${{secret(32)}}` | Asked once, when you create the owner account. Copy it from the service's Variables tab. |
| `OPENTODO_BASE_URL` | `https://${{RAILWAY_PUBLIC_DOMAIN}}` | The address people open. Passkeys and secure cookies are bound to it. Change it if you add a custom domain. |
| `PORT` | `8080` | The port OpenTodo listens on and Railway health-checks. |

Everything else (mail, single sign-on, CalDAV, the MCP endpoint, S3 or WebDAV backups) is optional: set it in OpenTodo's Settings or with the `OPENTODO_*` variables from the [upstream configuration table](https://github.com/OpenTodoApp/OpenTodo/blob/v1.7.0/docs/self-hosting/configuration.md).

## After deploy

1. Copy `OPENTODO_SETUP_TOKEN` from the OpenTodo service's **Variables** tab.
2. Open the service's `https://….up.railway.app` address and create the owner account (name, email, a password of 10+ characters and the token).
3. Invite other people from Settings.

## Updates

The service builds from this repo, which pins one OpenTodo release by version and digest. When `main` moves to a new release, Railway shows an "update available" notice on every project deployed from the template, and you choose when to apply it. Read [CHANGELOG.md](CHANGELOG.md) first, breaking changes are listed at the top of each entry, and back up the volume: OpenTodo migrates its database on start and has no down-migrations.
