# Security policy

## Reporting

Email **security@peiralabs.com**. You'll get an acknowledgment within a week
(this is a solo, best-effort project — see the maintenance policy). Please
don't open public issues for undisclosed vulnerabilities.

Only the latest release is supported with fixes.

## What this app holds, and where

- Proxmox API tokens, media-service API keys, and other credentials are
  stored **only** in the system Secret Service (GNOME Keyring / KWallet)
  via `flutter_secure_storage`. Nothing is written to plain files, and
  nothing leaves your machine except the API calls you configured.
- There is **no telemetry**. The only outbound call not aimed at your own
  services is the explicit, operator-triggered update check against the
  GitHub Releases API (public builds).
- Self-signed TLS trust applies to the **Proxmox host only**, behind a
  visible settings toggle.

## Known accepted risk: SSH targets are trusted input

The terminal's quick-connect targets (Settings › Terminal) are passed
**directly to `ssh`'s argv** with no validation. A hostile "target" string
like `-oProxyCommand=...` would execute a command when you open that
terminal entry.

Today this is operator-controlled input — you typed it into your own
settings, so it is equivalent to editing your own `~/.ssh/config`. It
becomes a real attack path only if settings import from untrusted sources
ever ships (see KNOWN_ISSUES: planned export/import); that feature will not
land without hardening this path. Disclosed here so nobody has to discover
it.

## Threat-model boundaries worth knowing

- The app talks to whatever endpoints you configure with the credentials
  you gave it — a compromised endpoint sees those credentials by design.
  Scope your Proxmox token (`PVEAuditor` unless you want management
  actions).
- Embedded webviews render remote web apps inside CEF (Chromium). They get
  the same trust you'd give those apps in a browser tab.
- The AppImage runs unsandboxed, like any AppImage. Verify downloads:
  `sha256sum -c SHA256SUMS && gpg --verify SHA256SUMS.asc SHA256SUMS`.
