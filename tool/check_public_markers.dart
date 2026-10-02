// Public-marker scanner. Run: dart run tool/check_public_markers.dart
//
// The public repo must never carry two classes of thing:
//
//   1. Credentials — keys, tokens, passwords.
//   2. Real infrastructure — the addresses, hostnames, certificate
//      fingerprints, and hardware identity of the lab this app was built
//      against.
//
// Modelled on the blog's scripts/check-public-markers.mjs, with the gap that
// scanner left closed here: it skipped every binary file, and this repo's
// contamination is partly *rendered into pixels* — golden PNGs drawn from
// fixtures that carried real hostnames. So binaries are gated by attestation:
// every tracked binary's SHA-256 must appear in tool/binary_allowlist.txt or
// the scan fails. There is no way for an unreviewed binary to pass.
//
// Where a value class has legitimate documentation-safe members (private IP
// examples), those are enumerated as an ALLOWLIST and everything else in the
// class is flagged — real addresses are caught without this file ever
// recording what they are. The lab's hostnames have no safe members, so they
// are matched literally; the literals are assembled from fragments at runtime
// so this file neither trips its own scan nor hands the names to a grep of
// the public tree.
//
// Modes:
//   (default)                   scan all git-tracked files; exit 1 on findings
//   --self-test                 prove the scanner catches what it must and
//                               stays quiet on documented conventions
//   --update-binary-allowlist   re-attest tracked binaries; refuses while any
//                               text finding exists, so goldens rendered from
//                               contaminated fixtures can never be attested

import 'dart:io';

import 'package:crypto/crypto.dart';

const binaryAllowlistPath = 'tool/binary_allowlist.txt';

// Extensions always treated as binary, even if their bytes happen to contain
// no NUL; anything else is binary when a NUL byte appears.
const binaryExtensions = {
  '.png', '.jpg', '.jpeg', '.gif', '.webp', '.ico', '.icns',
  '.ttf', '.otf', '.woff', '.woff2',
  '.jar', '.zip', '.so', '.dylib', '.bin', '.pdf',
};

// ---------------------------------------------------------------- class 1

class _Check {
  const _Check(this.name, this.pattern);
  final String name;
  final RegExp pattern;
}

final credentialChecks = [
  _Check('private key',
      RegExp('-----BEGIN (?:RSA |OPENSSH |EC |DSA |ENCRYPTED )?PRIVATE KEY-----')),
  _Check('age secret key', RegExp('AGE-SECRET-KEY-1[A-Z0-9]{20,}')),
  _Check('GitHub token', RegExp('(?:gh[pousr]|github_pat)_[A-Za-z0-9_]{20,}')),
  _Check('OpenAI-style key', RegExp(r'\bsk-[A-Za-z0-9_-]{20,}')),
  _Check('OpenRouter key', RegExp(r'\brpa_[A-Za-z0-9_-]{20,}')),
  _Check('AWS access key', RegExp(r'\bAKIA[0-9A-Z]{16}\b')),
  _Check('Slack token', RegExp(r'\bxox[baprs]-[A-Za-z0-9-]{20,}')),
  // The tail must be value-shaped (a real secret is a 36-char UUID) so the
  // header-building interpolations in lib/ and short fake secrets in tests
  // don't fire.
  _Check('PVE token header with secret',
      RegExp(r'PVEAPIToken=\S+=[A-Za-z0-9-]{16,}')),
  _Check('secret bearer token',
      RegExp(r'\bBearer\s+[A-Za-z0-9._~-]{24,}', caseSensitive: false)),
];

// A long random-looking run mixing cases and digits is secret-shaped. The
// repo's legitimate long tokens (pubspec.lock hashes, identifiers) are
// single-case or digit-free, so this fires on nothing today — keep it that
// way rather than adding exemptions.
final highEntropyToken = RegExp('[A-Za-z0-9+/=_-]{40,}');

bool looksHighEntropy(String token) =>
    token.contains(RegExp('[A-Z]')) &&
    token.contains(RegExp('[a-z]')) &&
    token.contains(RegExp('[0-9]'));

// Reviewed public strings that read as one [A-Za-z0-9+/=_-]{40,} run because
// '/' is in the base64 alphabet — URL paths to public release assets qualify.
// Each entry is the exact matched run (scheme/host dots break the run), added
// deliberately after the gate flagged it.
const allowedEntropyTokens = {
  // appimagetool download in tool/build_appimage.sh
  'com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64',
};

// ---------------------------------------------------------------- class 2

// Private (RFC1918) and CGNAT (RFC6598, the tailnet range) addresses. Public
// addresses are not flagged — documentation may legitimately cite one.
final privateIpPattern = RegExp(
    r'\b(?:10\.\d{1,3}\.\d{1,3}\.\d{1,3}'
    r'|172\.(?:1[6-9]|2\d|3[01])\.\d{1,3}\.\d{1,3}'
    r'|192\.168\.\d{1,3}\.\d{1,3}'
    r'|100\.(?:6[4-9]|[7-9]\d|1[01]\d|12[0-7])\.\d{1,3}\.\d{1,3})\b');

// Documentation-safe address space, mirroring the blog's house convention:
// 10.0.0.0/16 is example space, plus the generic defaults readers already
// have at home.
final allowedIps = [
  RegExp(r'^10\.0\.\d{1,3}\.\d{1,3}$'),
  RegExp(r'^192\.168\.1\.\d{1,3}$'),
  RegExp(r'^192\.168\.0\.1$'),
  RegExp(r'^172\.16\.0\.1$'),
  RegExp(r'^127\.\d{1,3}\.\d{1,3}\.\d{1,3}$'),
  RegExp(r'^0\.0\.0\.0$'),
  // The first /24 of the CGNAT block is example space (the fixtures' fake
  // tailnet addresses live there), mirroring the 10.0.0.0/16 convention.
  // Real tailnet assignments (100.68+) stay flagged.
  RegExp(r'^100\.64\.0\.\d{1,3}$'),
];

// Proxmox API token identity: user@realm!tokenid. The shape itself is the
// marker — a real one names a real account. Documentation and fixtures use
// the placeholder identities below (the blog's convention).
final pveTokenIdPattern = RegExp(r'[A-Za-z0-9_-]+@(?:pve|pam)![A-Za-z0-9_-]+');
// app@pve!homelab is what the setup wizard's own pveum example creates.
const allowedTokenIds = {
  'user@pve!token',
  'root@pam!token',
  'app@pve!homelab',
  'user@pam!tokenname', // settings_screen.dart PDM token-id input hint
  'user@pam!pdmtoken', // settings_repository_test.dart fixture
};

// Certificate fingerprints (11+ colon-separated hex pairs — SHA-1 and up;
// MAC addresses are 6 pairs and don't reach this).
final certFingerprintPattern =
    RegExp('(?:[0-9A-Fa-f]{2}:){10,}[0-9A-Fa-f]{2}');

// Hardware / version identity that fingerprints the real cluster. The CPU
// pattern is assembled from fragments like the hostname markers: written as
// one literal, the pattern matches its own definition line (the character
// class is 11 perfectly ordinary non-newline characters) — which is exactly
// what happened at c9b0ad8, unnoticed until the file became git-tracked.
final hardwareChecks = [
  _Check('CPU model fingerprint',
      RegExp(['Ryz', 'en[^\n]{0,60}Rad', 'eon'].join())),
];

// A real pve-manager version fingerprints the cluster's patch level; the
// documentation placeholder version is 8.0.x.
final pveVersionPattern = RegExp(r'pve-manager/\d+\.\d+');
const allowedPveVersion = 'pve-manager/8.0';

// The lab's own names. Assembled from fragments so this file passes its own
// scan and the public tree greps clean for them (see file header).
final labNameMarkers = [
  ['pve', 'lab'].join(),
  ['ren', 'nas'].join(),
  ['elite', 'book'].join(),
  ['myoffice', 'lab'].join(),
  ['AS', '70', '04T'].join(),
].map((m) => m.toLowerCase()).toList();

List<String> scanText(String text) {
  final findings = <String>[];

  for (final check in credentialChecks) {
    if (check.pattern.hasMatch(text)) {
      findings.add('possible ${check.name}');
    }
  }

  final seen = <String>{};
  for (final match in highEntropyToken.allMatches(text)) {
    final token = match.group(0)!;
    if (!looksHighEntropy(token) ||
        allowedEntropyTokens.contains(token) ||
        !seen.add('e:$token')) {
      continue;
    }
    findings.add('high-entropy token ${token.substring(0, 12)}…');
  }
  for (final match in privateIpPattern.allMatches(text)) {
    final ip = match.group(0)!;
    if (allowedIps.any((a) => a.hasMatch(ip)) || !seen.add(ip)) continue;
    findings.add('non-documentation private/CGNAT IP $ip');
  }
  for (final match in pveTokenIdPattern.allMatches(text)) {
    final id = match.group(0)!;
    if (allowedTokenIds.contains(id) || !seen.add('t:$id')) continue;
    findings.add('PVE token identity $id');
  }
  for (final match in certFingerprintPattern.allMatches(text)) {
    if (!seen.add('f:${match.group(0)}')) continue;
    findings.add('certificate fingerprint ${match.group(0)!.substring(0, 11)}…');
  }
  for (final check in hardwareChecks) {
    if (check.pattern.hasMatch(text)) {
      findings.add(check.name);
    }
  }
  for (final match in pveVersionPattern.allMatches(text)) {
    final version = match.group(0)!;
    if (version == allowedPveVersion || !seen.add('v:$version')) continue;
    findings.add('pve-manager version fingerprint $version');
  }
  final lower = text.toLowerCase();
  for (final marker in labNameMarkers) {
    if (lower.contains(marker)) {
      findings.add('lab hostname/model marker "$marker"');
    }
  }

  return findings;
}

// ---------------------------------------------------------------- binaries

bool isBinary(String path, List<int> bytes) {
  final dot = path.lastIndexOf('.');
  if (dot != -1 && binaryExtensions.contains(path.substring(dot).toLowerCase())) {
    return true;
  }
  return bytes.contains(0);
}

Set<String> readBinaryAllowlist() {
  final file = File(binaryAllowlistPath);
  if (!file.existsSync()) return {};
  return file
      .readAsLinesSync()
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty && !l.startsWith('#'))
      .map((l) => l.split(RegExp(r'\s+')).first.toLowerCase())
      .toSet();
}

String? checkBinary(String path, List<int> bytes, Set<String> allowedHashes) {
  final hash = sha256.convert(bytes).toString();
  if (allowedHashes.contains(hash)) return null;
  return 'binary not in $binaryAllowlistPath (sha256 $hash)';
}

// ------------------------------------------------------------------- scan

final forbiddenFilePattern =
    RegExp(r'(^|/)\.env(\.|$)|\.(pem|key|p12|pfx|jks|keystore)$');

List<String> trackedFiles() {
  final result = Process.runSync('git', ['ls-files', '-z']);
  if (result.exitCode != 0) {
    stderr.writeln('git ls-files failed — refusing to scan blind:');
    stderr.writeln(result.stderr);
    exit(2); // fail closed: no file list, no pass
  }
  return (result.stdout as String)
      .split('\x00')
      .where((f) => f.isNotEmpty)
      .toList();
}

({List<String> text, List<String> binary}) scanTree() {
  final allowedHashes = readBinaryAllowlist();
  final textFindings = <String>[];
  final binaryFindings = <String>[];

  for (final path in trackedFiles()) {
    if (forbiddenFilePattern.hasMatch(path)) {
      textFindings.add('$path: forbidden credential file');
      continue;
    }

    final List<int> bytes;
    try {
      bytes = File(path).readAsBytesSync();
    } catch (_) {
      textFindings.add('$path: unreadable tracked file — refusing to pass it');
      continue;
    }

    if (isBinary(path, bytes)) {
      final finding = checkBinary(path, bytes, allowedHashes);
      if (finding != null) binaryFindings.add('$path: $finding');
    } else {
      for (final finding in scanText(String.fromCharCodes(bytes))) {
        textFindings.add('$path: $finding');
      }
    }
  }

  return (text: textFindings, binary: binaryFindings);
}

void runScan() {
  final findings = scanTree();
  final all = [...findings.text, ...findings.binary];
  if (all.isNotEmpty) {
    stderr.writeln('Public-marker scan FAILED '
        '(${findings.text.length} text finding(s), '
        '${findings.binary.length} unattested binary file(s)):');
    for (final finding in all) {
      stderr.writeln('- $finding');
    }
    exit(1);
  }
  stdout.writeln(
      'Public-marker scan passed (${trackedFiles().length} tracked files).');
}

// ------------------------------------------------------ allowlist update

void updateBinaryAllowlist() {
  // Attestation is only meaningful from an otherwise-clean tree: goldens are
  // rendered from fixtures, and contaminated fixtures are text findings.
  final findings = scanTree();
  if (findings.text.isNotEmpty) {
    stderr.writeln('REFUSING to attest binaries: ${findings.text.length} text '
        'finding(s) remain. Clean the tree first; a golden rendered from a '
        'contaminated fixture must never be allowlisted.');
    for (final finding in findings.text) {
      stderr.writeln('- $finding');
    }
    exit(1);
  }

  final lines = <String>[
    '# SHA-256 attestations for every git-tracked binary file.',
    '# Regenerate with: dart run tool/check_public_markers.dart --update-binary-allowlist',
    '# The update refuses to run while any text finding exists, so entries',
    '# here imply the binaries were produced from a marker-free tree.',
  ];
  var count = 0;
  for (final path in trackedFiles()) {
    final List<int> bytes;
    try {
      bytes = File(path).readAsBytesSync();
    } catch (_) {
      continue;
    }
    if (!isBinary(path, bytes)) continue;
    lines.add('${sha256.convert(bytes)}  $path');
    count++;
  }
  File(binaryAllowlistPath).writeAsStringSync('${lines.join('\n')}\n');
  stdout.writeln('Attested $count binaries into $binaryAllowlistPath.');
}

// -------------------------------------------------------------- self-test
//
// A gate nobody has tested is indistinguishable from a gate that passes
// everything. Every fixture is assembled from fragments at runtime: written
// as literals, this file would trip its own scan.

String j(List<String> parts) => parts.join();

final mustCatch = [
  ('github token', j(['token: gh', 'p_AbCdEfGhIjKlMnOpQrStUvWxYz012345'])),
  ('private key', j(['-----BEGIN OPEN', 'SSH PRIVATE KEY-----'])),
  ('openai-style key', j(['key: sk-', 'Abc123Abc123Abc123Abc123'])),
  ('openrouter key', j(['key: rpa_', 'Abc123Abc123Abc123Abc123'])),
  ('age secret key', j(['AGE-SECRET-', 'KEY-1QQPZRY9X8GF2TVDW0S3JN54'])),
  ('pve token header with secret',
      j(['PVEAPIToken=ops@p', 've!ci=12345678-abcd-ef01-2345-6789abcdef01'])),
  ('bearer token',
      j(['Authorization: Bear', 'er abcdefghijklmnopqrstuvwxyz123456'])),
  ('high-entropy token',
      j(['seed: aB3', 'dE6gH9jK2mN5pQ8sT1vW4', 'yZ7aB3dE6gH9jK2mN5pQ8'])),
  ('private IP outside doc range', j(['ssh root@10.', '99.42.7'])),
  ('second private range', j(['the NAS answers on 192.', '168.7.210'])),
  ('third private range', j(['gateway is 172.', '20.5.1'])),
  ('CGNAT / tailnet IP', j(['reachable at 100.', '88.12.34 over the tailnet'])),
  ('pve token identity', j(['auth as monitor@p', 've!readonly'])),
  ('certificate fingerprint',
      j(['fp: AA:BB:CC:DD:EE:FF:00:11:22:', '33:44:55:66:77:88:99'])),
  ('cpu fingerprint', j(['AMD Ryz', 'en 7 5700U with Rad', 'eon Graphics'])),
  ('pve-manager version', j(['pve-mana', 'ger/8.2.4'])),
  for (final (i, marker) in [
    ['pve', 'lab', '01'],
    ['ren', 'nas'],
    ['elite', 'book'],
    ['myoffice', 'lab'],
    ['as', '70', '04t'],
  ].indexed)
    ('lab name marker #$i', j(['host is ', j(marker)])),
];

final mustIgnore = [
  ('documented dummy range', 'the monitoring host 10.0.0.5 and agent 10.0.0.7'),
  ('VLAN example subnet', 'addresses:\n  - 10.0.10.5/24'),
  ('generic default LAN', 'router at 192.168.1.1, host 192.168.1.100/24'),
  ('gateway defaults', 'use 192.168.0.1 or 172.16.0.1'),
  ('loopback', 'binds to 127.0.0.1 and 0.0.0.0'),
  ('CGNAT range cited as example', 'the 100.64.0.0/10 CGNAT space'),
  ('placeholder token id shape in prose', 'create one with: pveum user token add'),
  ('pub content hash (single-case hex)',
      'sha256: c8ea0233063ba03258fbcf2ca4d6dadfefe14f02fab57702265467a19f27fadf'),
  ('long identifier without digits',
      'dart run build_runner build --delete-conflicting-outputs'),
  ('interpolated bearer header', r"'Authorization': 'Bearer $apiKey'"),
  ('interpolated pve header', r"'PVEAPIToken=${s.tokenId}=${s.tokenSecret}'"),
  ('placeholder token identity with short fake secret',
      'PVEAPIToken=user@pve!token=abc12345'),
  ('wizard example token identity', 'the token ID is then app@pve!homelab'),
  ('mac address (6 pairs)', 'link/ether aa:bb:cc:dd:ee:ff brd ff:ff:ff:ff:ff:ff'),
  ('CGNAT doc space', 'the fixture peer sits at 100.64.0.42'),
  ('doc pve-manager version', 'shows pve-manager/8.0.0/abcdef0123456789'),
  ('appimagetool release URL',
      'https://github.com/AppImage/appimagetool/releases/download/'
          'continuous/appimagetool-x86_64.AppImage'),
];

void selfTest() {
  var failed = 0;
  for (final (label, sample) in mustCatch) {
    if (scanText(sample).isEmpty) {
      stderr.writeln('self-test FAIL: should have been caught — $label');
      failed++;
    }
  }
  for (final (label, sample) in mustIgnore) {
    final hits = scanText(sample);
    if (hits.isNotEmpty) {
      stderr.writeln(
          'self-test FAIL: false positive — $label: ${hits.join(', ')}');
      failed++;
    }
  }

  // Binary gate: an unattested binary must fail, an attested one must pass,
  // and attestation is by content — not by name or location.
  final fakePng = [0x89, 0x50, 0x4E, 0x47, 0, 1, 2, 3];
  final hash = sha256.convert(fakePng).toString();
  if (checkBinary('test/goldens/reintroduced.png', fakePng, {}) == null) {
    stderr.writeln('self-test FAIL: unattested binary passed');
    failed++;
  }
  if (checkBinary('test/goldens/reintroduced.png', fakePng, {hash}) != null) {
    stderr.writeln('self-test FAIL: attested binary flagged');
    failed++;
  }
  if (checkBinary('renamed.png', [...fakePng, 0xFF], {hash}) == null) {
    stderr.writeln('self-test FAIL: modified binary passed on a stale hash');
    failed++;
  }
  if (!isBinary('x.png', [1, 2, 3]) || !isBinary('x.dat', [1, 0, 3])) {
    stderr.writeln('self-test FAIL: binary detection');
    failed++;
  }

  if (failed > 0) {
    stderr.writeln('\nPublic-marker self-test failed ($failed case(s)).');
    exit(1);
  }
  stdout.writeln('Public-marker self-test passed '
      '(${mustCatch.length} caught, ${mustIgnore.length} correctly ignored, '
      'binary gate verified).');
}

// ------------------------------------------------------------------- main

void main(List<String> args) {
  if (args.contains('--self-test')) {
    selfTest();
  } else if (args.contains('--update-binary-allowlist')) {
    updateBinaryAllowlist();
  } else {
    runScan();
  }
}
