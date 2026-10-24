See CHANGELOG.md.

**Verify before running.** Releases are signed with the Peira Labs release key, fingerprint `659A D4F9 BD11 8838 ECBA  D6DB 587E C679 3F57 6180` ([docs/release-signing-key.asc](https://github.com/peiralabs/peira/blob/main/docs/release-signing-key.asc)). Import it once and check the fingerprint:

```bash
curl -fsSL https://raw.githubusercontent.com/peiralabs/peira/main/docs/release-signing-key.asc | gpg --import
gpg --fingerprint 659AD4F9BD118838ECBAD6DB587EC6793F576180
```

Then, in the folder with the downloads:

```bash
sha256sum -c SHA256SUMS
gpg --verify SHA256SUMS.asc SHA256SUMS
```
