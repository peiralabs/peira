import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/ask_api.dart';
import '../../core/providers/settings_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/phosphor.dart';
import '../../core/widgets/ai_status_strip.dart';
import '../../core/widgets/screen_header.dart';
import '../../core/widgets/status_light.dart';
import '../chat_scaffold.dart';

/// One transcript entry. User/system entries carry only text; assistant
/// entries also carry the reply's citations + revision label.
class AskEntry {
  const AskEntry({
    required this.role,
    required this.text,
    this.sources = const [],
    this.revision = '',
    this.stale = false,
    this.model = '',
  });

  final String role;
  final String text;
  final List<AskSource> sources;
  final String revision;
  final bool stale;
  final String model;
}

/// Native "Ask Your Homelab" chat (RAG over the canonical vault): verdigris
/// assistant bubbles with numbered source chips + the vault revision each
/// answer was generated from, sapphire user bubbles, recessed input bar.
/// Talks to the ask-homelab endpoint on CT 106 (retrieve-then-generate over
/// the embeddings index). Transcript is in-memory per session — the shell's
/// IndexedStack keeps it alive across tab switches.
class AskScreen extends ConsumerStatefulWidget {
  const AskScreen({super.key, this.testTranscript});

  /// Seeds the transcript (goldens / tests).
  final List<AskEntry>? testTranscript;

  @override
  ConsumerState<AskScreen> createState() => _AskScreenState();
}

class _AskScreenState extends ConsumerState<AskScreen> {
  final List<AskEntry> _entries = [];
  bool _waiting = false;

  /// Verdigris inner field for the header badge (the vault's patina accent).
  static const _verdigrisField = RadialGradient(
    center: Alignment(-0.2, -0.36),
    colors: [Color(0xFF2E7258), Color(0xFF0F281F)],
  );

  @override
  void initState() {
    super.initState();
    if (widget.testTranscript != null) _entries.addAll(widget.testTranscript!);
  }

  Future<void> _send(String text) async {
    final settings = ref.read(settingsControllerProvider).value;
    final endpoint = settings?.askEndpoint ?? '';
    setState(() => _entries.add(AskEntry(role: 'user', text: text)));

    if (endpoint.isEmpty) {
      setState(() {
        _entries.add(
          const AskEntry(
            role: 'system',
            text:
                'Ask is not configured yet — set the Wiki URL (or a '
                'dedicated Ask URL) in Settings.',
          ),
        );
      });
      return;
    }

    setState(() => _waiting = true);
    try {
      final api = AskApi.fromBase(endpoint);
      final reply = await api.ask(
        text,
        history: [
          // Prior turns only — the endpoint appends the question itself.
          for (final e in _entries)
            if (e.role != 'system' && !(e.role == 'user' && e.text == text))
              (role: e.role, content: e.text),
        ],
      );
      if (!mounted) return;
      setState(() {
        _entries.add(
          AskEntry(
            role: 'assistant',
            text: reply.answer,
            sources: reply.sources,
            revision: reply.revision,
            stale: reply.stale,
            model: reply.model,
          ),
        );
      });
    } on AskException catch (e) {
      if (!mounted) return;
      setState(() => _entries.add(AskEntry(role: 'system', text: e.message)));
    } catch (e) {
      if (!mounted) return;
      setState(
        () => _entries.add(
          AskEntry(role: 'system', text: 'Ask call failed: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _waiting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pal = _AskPalette.of(context);
    final endpoint =
        ref.watch(settingsControllerProvider).value?.askEndpoint ?? '';
    return ChatScaffold(
      header: Padding(
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 16),
        child: ScreenHeader(
          icon: Ph.chatCircleText,
          badgeField: _verdigrisField,
          title: 'Ask',
          subtitle: 'YOUR HOMELAB · CITED FROM THE VAULT',
          subtitleColor: pal.subtitle,
          trailing: [
            if (endpoint.isNotEmpty) ...[
              const SizedBox(width: 12),
              _ReachabilityPill(url: '$endpoint/health'),
            ],
          ],
        ),
      ),
      entries: [
        for (final entry in _entries)
          (
            role: entry.role,
            text: entry.text,
            footer: _AskBubbleFooter(entry: entry),
          ),
      ],
      onSend: _send,
      waiting: _waiting,
      emptyState: const _EmptyTranscript(),
      thinkingLabel: 'Consulting the vault',
      inputHint: 'Ask your homelab — "what\'s the NAS double-hop again?"',
      style: pal.chatStyle,
    );
  }
}

/// Breathing endpoint-reachability light probing the ask-homelab /health
/// route, mirroring the Hermes pill idiom.
class _ReachabilityPill extends ConsumerWidget {
  const _ReachabilityPill({required this.url});

  final String url;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pal = _AskPalette.of(context);
    final state = ref.watch(serviceReachableProvider(url));
    final failed = state.hasError || state.value == false;
    final up = !failed && state.hasValue;
    final health = failed
        ? Health.crit
        : up
        ? Health.ok
        : Health.offline;
    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: failed ? pal.pillBorderFail : pal.pillBorderUp,
        ),
        color: pal.pillBg,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          StatusLight(health: health, size: 8),
          const SizedBox(width: 8),
          Text(
            failed
                ? 'Retry'
                : up
                ? 'Vault up'
                : 'Checking…',
            style: TextStyle(
              fontSize: 12,
              color: failed ? pal.pillTextFail : pal.pillTextUp,
            ),
          ),
        ],
      ),
    );
    if (!failed) return pill;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => ref.invalidate(serviceReachableProvider(url)),
        child: pill,
      ),
    );
  }
}

class _EmptyTranscript extends StatelessWidget {
  const _EmptyTranscript();

  @override
  Widget build(BuildContext context) {
    final pal = _AskPalette.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Ph.chatCircleText, size: 40, color: pal.emptyIcon),
          const SizedBox(height: 12),
          Text(
            'Ask anything your vault knows — answers cite their sources.',
            style: TextStyle(color: context.brass.textMuted),
          ),
        ],
      ),
    );
  }
}

/// Ask-specific content appended to the shared record-based chat bubble.
class _AskBubbleFooter extends StatelessWidget {
  const _AskBubbleFooter({required this.entry});

  final AskEntry entry;

  @override
  Widget build(BuildContext context) {
    final pal = _AskPalette.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (entry.sources.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final source in entry.sources) _SourceChip(source: source),
            ],
          ),
        ],
        if (entry.revision.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'vault @ ${entry.revision.length >= 8 ? entry.revision.substring(0, 8) : entry.revision}'
                '${entry.model.isNotEmpty ? ' · ${entry.model}' : ''}',
                style: TextStyle(fontSize: 11.5, color: pal.metaText),
              ),
              if (entry.stale) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: pal.staleBg,
                    border: Border.all(color: pal.staleBorder),
                  ),
                  child: Text(
                    'index stale',
                    style: TextStyle(fontSize: 10.5, color: pal.staleText),
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

/// Numbered citation chip — tap for the source's full reference + snippet.
class _SourceChip extends StatelessWidget {
  const _SourceChip({required this.source});

  final AskSource source;

  @override
  Widget build(BuildContext context) {
    final pal = _AskPalette.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _showDetails(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: pal.chipBg,
            border: Border.all(color: pal.chipBorder),
          ),
          child: Text(
            '[${source.n}] ${source.wikiPath}',
            style: TextStyle(fontSize: 12, color: pal.chipText),
          ),
        ),
      ),
    );
  }

  void _showDetails(BuildContext context) {
    final pal = _AskPalette.of(context);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(source.title, style: const TextStyle(fontSize: 18)),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (source.heading.isNotEmpty &&
                  source.heading != source.title) ...[
                Text(
                  source.heading,
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: pal.metaText,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              SelectableText(
                source.ref,
                style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
              ),
              const SizedBox(height: 10),
              Flexible(
                child: SingleChildScrollView(
                  child: SelectableText(
                    source.snippet.isEmpty ? '(no snippet)' : source.snippet,
                    style: const TextStyle(fontSize: 14, height: 1.4),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Ph.copy, size: 16),
            label: const Text('Copy reference'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: source.ref));
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

/// Ask-local chat palette, brightness-resolved. Assistant bubbles wear the
/// vault's verdigris patina (distinct from Hermes's garnet); user bubbles
/// share the sapphire idiom; errors share the oxblood idiom.
class _AskPalette {
  const _AskPalette({
    required this.subtitle,
    required this.pillBorderFail,
    required this.pillBorderUp,
    required this.pillBg,
    required this.pillTextFail,
    required this.pillTextUp,
    required this.emptyIcon,
    required this.userBubbleTop,
    required this.userBubbleBottom,
    required this.userBorder,
    required this.userInk,
    required this.assistantTop,
    required this.assistantBottom,
    required this.assistantBorder,
    required this.assistantInk,
    required this.errorTop,
    required this.errorBottom,
    required this.errorBorder,
    required this.errorInk,
    required this.bubbleShadow,
    required this.thinkingText,
    required this.inputBg,
    required this.inputBorder,
    required this.inputInk,
    required this.inputHint,
    required this.chipBg,
    required this.chipBorder,
    required this.chipText,
    required this.metaText,
    required this.staleBg,
    required this.staleBorder,
    required this.staleText,
  });

  final Color subtitle;
  final Color pillBorderFail;
  final Color pillBorderUp;
  final Color pillBg;
  final Color pillTextFail;
  final Color pillTextUp;
  final Color emptyIcon;
  final Color userBubbleTop;
  final Color userBubbleBottom;
  final Color userBorder;
  final Color userInk;
  final Color assistantTop;
  final Color assistantBottom;
  final Color assistantBorder;
  final Color assistantInk;
  final Color errorTop;
  final Color errorBottom;
  final Color errorBorder;
  final Color errorInk;
  final Color bubbleShadow;
  final Color thinkingText;
  final Color inputBg;
  final Color inputBorder;
  final Color inputInk;
  final Color inputHint;
  final Color chipBg;
  final Color chipBorder;
  final Color chipText;
  final Color metaText;
  final Color staleBg;
  final Color staleBorder;
  final Color staleText;

  /// Ambient-theme resolution (registers a Theme dependency, like Brass.of).
  static _AskPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;

  ChatScaffoldStyle get chatStyle => ChatScaffoldStyle(
    userBubbleTop: userBubbleTop,
    userBubbleBottom: userBubbleBottom,
    userBorder: userBorder,
    userInk: userInk,
    assistantTop: assistantTop,
    assistantBottom: assistantBottom,
    assistantBorder: assistantBorder,
    assistantInk: assistantInk,
    errorTop: errorTop,
    errorBottom: errorBottom,
    errorBorder: errorBorder,
    errorInk: errorInk,
    bubbleShadow: bubbleShadow,
    thinkingText: thinkingText,
    inputBg: inputBg,
    inputBorder: inputBorder,
    inputInk: inputInk,
    inputHint: inputHint,
    sendTop: const Color(0xFF3E8E76),
    sendBottom: const Color(0xFF1E5946),
    sendBorder: const Color(0x8078C8AE),
    sendIcon: const Color(0xFFDCF2E8),
    sendIconDisabled: const Color(0x80DCF2E8),
  );

  static const dark = _AskPalette(
    subtitle: Color(0xFF8FC8B4),
    pillBorderFail: Color(0x80C8564A),
    pillBorderUp: Color(0x5750806E),
    pillBg: Color(0x66142018),
    pillTextFail: Color(0xFFECAF9F),
    pillTextUp: Color(0xFF94C0AC),
    emptyIcon: Color(0xFF5E8A7A),
    userBubbleTop: Color(0x575A86C0),
    userBubbleBottom: Color(0x522D5A9A),
    userBorder: Color(0x738CAFE0),
    userInk: Color(0xFFE7EEFA),
    assistantTop: Color(0xC71E2E2A),
    assistantBottom: Color(0xD1121D19),
    assistantBorder: Color(0x5778C8AE),
    assistantInk: Color(0xFFD8EEE4),
    errorTop: Color(0x66502020),
    errorBottom: Color(0x662A1212),
    errorBorder: Color(0x80C8564A),
    errorInk: Color(0xFFECC5BC),
    bubbleShadow: Color(0x59000000),
    thinkingText: Color(0xFF8FC0AE),
    inputBg: Color(0xA6131C19),
    inputBorder: Color(0x5C78C8AE),
    inputInk: Color(0xFFD8EEE4),
    inputHint: Color(0xFF7E9A8E),
    chipBg: Color(0x66142420),
    chipBorder: Color(0x4D78C8AE),
    chipText: Color(0xFFA8D8C4),
    metaText: Color(0xFF7FA89A),
    staleBg: Color(0x66403010),
    staleBorder: Color(0x80D8A038),
    staleText: Color(0xFFE8C878),
  );

  static const light = _AskPalette(
    subtitle: Color(0xFF2E6E56),
    pillBorderFail: Color(0x8C9E362C),
    pillBorderUp: Color(0x662E6E56),
    pillBg: Color(0x66E8F2EA),
    pillTextFail: Color(0xFF9E362C),
    pillTextUp: Color(0xFF3A5C4C),
    emptyIcon: Color(0xFF5E7A6A),
    userBubbleTop: Color(0xE8D6E2F4),
    userBubbleBottom: Color(0xE0C6D6EC),
    userBorder: Color(0x8C3A5E96),
    userInk: Color(0xFF24365A),
    assistantTop: Color(0xE8DCEEE2),
    assistantBottom: Color(0xECCBE0D4),
    assistantBorder: Color(0x662E6E56),
    assistantInk: Color(0xFF22382E),
    errorTop: Color(0x8CF2D8D0),
    errorBottom: Color(0x8CEBC8BE),
    errorBorder: Color(0x8C9E362C),
    errorInk: Color(0xFF7A241A),
    bubbleShadow: Color(0x2E38462F),
    thinkingText: Color(0xFF3E6350),
    inputBg: Color(0xA6E2EEE4),
    inputBorder: Color(0x662E6E56),
    inputInk: Color(0xFF243830),
    inputHint: Color(0xFF5A7264),
    chipBg: Color(0x66DFF0E6),
    chipBorder: Color(0x8C2E6E56),
    chipText: Color(0xFF275444),
    metaText: Color(0xFF57705F),
    staleBg: Color(0x66F2E2B8),
    staleBorder: Color(0x8C9A7018),
    staleText: Color(0xFF6E5010),
  );
}
