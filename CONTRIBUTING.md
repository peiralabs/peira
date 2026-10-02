# Contributing

Thanks for considering it. This is a solo-maintained project with a written
triage budget — small, well-scoped PRs with a clear problem statement have
the best odds. Open an issue before building anything large.

## Dev setup

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # after any @riverpod/@freezed change
flutter analyze
flutter test
```

The Flutter version is pinned in `.tool-versions` — CI builds with exactly
that version. `flutter run -d linux` for a dev build; the first Linux build
downloads CEF (one time, a few hundred MB).

## What CI enforces on every PR

- `flutter analyze` clean.
- `flutter test --exclude-tags golden` green.
- `dart tool/check_public_markers.dart` green — this repo fails closed on
  private markers (real IPs, hostnames, credential shapes, unattested
  binaries). Use documentation address space (`10.0.0.x`, `192.168.1.x`)
  and placeholder identities (`user@pve!token`) in fixtures and docs.

Golden tests (`@Tags(['golden'])`) are exact-pixel inspection artifacts
rendered on the maintainer's machine — they do not run in CI and you don't
need to regenerate them; note UI changes in the PR instead.

## Ground rules

- Match the surrounding code: Riverpod v3 + freezed, small focused
  providers, the existing theme token system (no hardcoded colors).
- No new runtime dependencies without discussion — every dependency is a
  supply-chain and licensing commitment (see THIRD_PARTY_NOTICES.md).
- Behavior changes need a test; bug fixes need a test that fails before the
  fix.
- No telemetry, ever. Nothing phones home beyond what the operator
  explicitly configured.
