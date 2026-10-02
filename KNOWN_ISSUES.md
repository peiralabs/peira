# Known issues

## The keyring bug (read this before filing a startup issue)

**Symptom:** first launch lands on a "Keyring locked" screen, or the app
suddenly forgets all settings and shows the setup wizard even though you
configured it before.

**Cause — upstream, and not fixable here:** settings are stored as a single
item in your Secret Service (GNOME Keyring / KWallet) via
`flutter_secure_storage`. Its Linux backend has two long-standing problems:

1. It builds the libsecret **schema name from a dangling C++ pointer**, so
   the runtime schema name is per-build non-reproducible. Lookups match on
   attributes, which usually masks this — until it combines with (2).
2. A **phantom-item corruption**: a malformed item in the keyring breaks
   libsecret's attribute search for every app, which reads as "my settings
   vanished".

**Recovery:**

- "Keyring locked" at launch: unlock your login keyring (log out and back
  in, or `seahorse` → unlock), then hit *Retry* on the gate. On distros
  where the login keyring has a password different from your login
  password, GNOME will not auto-unlock it — that is a distro configuration
  choice, not an app bug.
- Vanished settings / phantom item: log out and back in (reloads the
  keyring daemon from disk); in stubborn cases reboot. Your data is on disk
  in `~/.local/share/keyrings/` the whole time.

**Planned mitigation:** a settings export/import so a corrupted keyring
doesn't mean retyping every field. Not built yet.

## Other known limitations

- **Wayland-native sessions are unsupported** — CEF renders via X11;
  XWayland is required. Pure-Wayland compositors without XWayland will not
  show webview tabs.
- **CEF's sandbox needs unprivileged user namespaces** (an AppImage cannot
  ship a setuid helper). Most distros enable them; hardened kernels with
  `kernel.unprivileged_userns_clone=0` will crash webview tabs.
- **Window minimum is 1100×700** — laptops below that resolution clip; small
  screens and phones are out of scope for the desktop target.
- **A brief dashboard flash can appear before the first-run wizard** while
  settings load. Cosmetic.
- **Software rendering fallback**: without working GL, Flutter and CEF fall
  back to software paths (`libEGL warning: DRI3 error` in logs is harmless
  in VMs/containers).
