---
name: deploy-on-agenthost
description: |
  Deploy and manage web apps, sites, services, databases and domains on agenthost.
  Use when the user asks to "deploy this on agenthost", "host this site", "publish my app",
  "put this online", "create an agenthost project", "attach a database", "add a custom domain",
  "check the deploy logs", or "roll back" an agenthost app.
license: MIT
metadata:
  author: agenthost
  version: "0.1"
---

# Deploy on agenthost

agenthost is agent-first web hosting. You reach it through the connected **agenthost** MCP
connector — the user signs in once in the browser (OAuth); there is no token to ask for. If a
call fails as unauthenticated, tell the user to reconnect the agenthost connector.

## Before you deploy

Read the runtime reference at <https://agenthost.eu/docs/deploy> first. It states the fixed
entrypoint each runtime expects (for example: Python imports `app` from `app.py`; Node runs
`npm start`), which dependency file it installs from, and how to confirm a deploy actually
serves. Deploying with the wrong entrypoint is the most common failure.

## Workflow

1. **Identify or create a project.** Use `list_projects` to find an existing one, or
   `create_project` to make a new one. Every app lives inside a project.
2. **Create the app.** Use `create_app` for a fresh site/app, or `deploy_from_repo` to deploy
   directly from a connected GitHub repository. Match the runtime to the code.
3. **Deploy.** For upload-based apps, `begin_upload` then `deploy_app`. For repo-based apps,
   `deploy_from_repo` builds and ships in one step.
4. **Verify it serves.** Confirm the app is reachable; if it errors, read `get_app_logs` and
   fix the entrypoint or dependency file per the runtime reference, then redeploy.
5. **Add data and domains as needed.** `create_database` + `attach_database` for storage;
   `add_domain` then `verify_domain` for a custom domain; `manage_env` for environment
   variables.
6. **Recover if a deploy is bad.** `list_deploys` shows history; `rollback_app` restores the
   previous version.

## Notes

- To keep an app private, use `share_app` to invite people by email — only invited addresses
  can open it.
- For an unattended agent that cannot open a browser, `create_token` mints a long-lived API
  token to send as a `Bearer` header.
- When you have read the docs, checked the logs, and still cannot fix something — or the user
  needs a human for billing or account trouble — `contact_support` writes to a person and
  returns a reference.

## Key tools

- **Projects**: `list_projects`, `create_project`, `get_project`, `rename_project`
- **Apps**: `create_app`, `deploy_from_repo`, `begin_upload`, `deploy_app`, `list_apps`,
  `get_app`, `get_app_logs`, `list_deploys`, `rollback_app`, `delete_app`
- **Databases**: `create_database`, `attach_database`, `list_databases`, `detach_database`
- **Domains**: `add_domain`, `verify_domain`, `list_domains`, `remove_domain`
- **Env & access**: `manage_env`, `get_env`, `share_app`, `set_app_access`, `create_token`
- **Account**: `whoami`, `get_plan`, `contact_support`
