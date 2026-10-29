# Setup file

A setup file configures every service in one step: fill in the template,
then import it. It is a single JSON object whose keys are the app's
settings keys.

Template: [`setup/setup.example.json`](../setup/setup.example.json). It
lists every key, with blanks and the defaults.

## Importing

- **Settings › Import setup file…** (any platform): paste the file's
  contents. It is saved straight away.
- **Desktop drop-in:** save the file as `~/.config/homelab/seed.json`
  (or `$XDG_CONFIG_HOME/homelab/seed.json`). The app imports it at its
  next launch and then **deletes it**, so credentials do not stay in a
  plain file. A malformed file is deleted too, and nothing is imported.

## Rules

- A key the file sets **replaces** the saved value. A key the file leaves
  out, or sets to `""` or `null`, keeps the saved value, so a half-filled
  template never clears a field that is already set.
- Keys beginning with `_` (such as `_comment`) are ignored. Any other key
  the app does not recognise is skipped, and Settings names the skipped
  keys after an import.
- Booleans and numbers may be written as JSON values (`true`, `0.12`) or as
  strings (`"true"`, `"0.12"`).
- The file sets the **active** connection profile. To set up a second
  cluster, switch profile first, then import.

## Which tabs appear

The sidebar lists a service tab once at least one of its services has a
URL. A tab whose URL is set but whose API key is missing still appears and
shows what it needs. **Settings › Show tabs for services not set up** lists
every tab regardless.

## Where each key comes from

| Service | Keys | Where to get the credential |
|---|---|---|
| Proxmox VE | `proxmox_url`, `proxmox_token_id`, `proxmox_token_secret` | Datacenter › Permissions › API Tokens |
| Home Assistant | `home_assistant_url`, `home_assistant_token` | Your profile › Security › Long-lived access tokens |
| Paperless-ngx | `paperless_url`, `paperless_token` | My Profile › API Auth Token |
| Immich | `immich_url`, `immich_api_key` | Account Settings › API Keys |
| Karakeep | `karakeep_url`, `karakeep_api_key` | User Settings › API Keys |
| Seerr / Jellyseerr | `jellyseerr_url`, `jellyseerr_api_key` | Settings › General › API Key |
| Open WebUI | `ollama_url`, `open_webui_api_key` | Settings › Account › API keys (an admin must first turn on API keys in Admin Panel › Settings › General) |
| changedetection.io | `changedetection_url`, `changedetection_api_key` | Settings › API |
| Wiki.js | `wiki_url`, `wiki_api_key` | Administration › API Access (turn on the API, then create a key) |
| SearXNG | `searxng_url` | No key. `search.formats` in the instance's `settings.yml` must include `json` |

Each credential reaches only its own service. A credential with more rights
lets the app do more, and the app does nothing its credential does not
allow.
