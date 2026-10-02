# Maintenance policy

Written before launch, on purpose — solo OSS projects die at month 3 from
unbounded triage, not from code. This is the contract; it's honest rather
than ambitious.

## Status: **maintained, best-effort**

This is a personal project. There is no SLA, no roadmap commitments, and no
guarantee any issue gets fixed. What you can rely on: releases are signed
and checksummed, `main` stays green (CI: analyze + tests + marker scan),
and this file tells the truth about the project's state.

## Triage budget

- **One 45-minute triage window per week.** Issues are read in that window,
  not continuously.
- An issue with no reproduction after **21 days** from a maintainer request
  gets closed with `no-repro` (reopenable with the repro).
- "Does it happen in `--demo`?" is the first triage question — it separates
  app bugs from setup bugs in one step.
- Security reports (SECURITY.md) jump the queue.

## Canned answers to the two predicted top issues

**"The app won't start / forgot my settings" →** KNOWN_ISSUES.md, keyring
section. It is an upstream `flutter_secure_storage_linux` bug (schema name
from a dangling pointer + phantom-item corruption). Unlock your login
keyring or log out and back in; your data is on disk. Not fixable in this
app; export/import is the planned mitigation.

**"Which Prometheus exporter do I need?" →** `node_exporter` on every node
for the Metrics tab. The Top-guests panel additionally needs
`prometheus-pve-exporter` — a separate, optional install; everything else
works without it. README › Metrics has the link.

## Scope boundary — things this app will never do

- **Windows or macOS.** Never; the desktop target is Linux.
- **iOS** until a paid Apple Developer account exists (it currently does
  not; the target compiles but is unsupported).
- **Non-Proxmox hypervisors** (ESXi, XCP-ng, Incus…). The whole design
  assumes the Proxmox API.
- **Auto-update or telemetry.** Structural (AppImage) and philosophical
  respectively.
- **Wayland-native rendering** while CEF requires X11 — XWayland is the
  supported path.

## Degradation plan (agreed in advance)

Adoption is read from release download counts, stars, and issue volume —
the only instruments a no-telemetry project has, accepted as such. If the
weekly window goes unused for **three consecutive months**, the README
badge flips to **maintenance-only** (security + build fixes, no features).
If it goes unused for **a year**, the repo gets archived with a final
release and a note — degrading gracefully beats looking abandoned.
