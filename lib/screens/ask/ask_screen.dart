import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/ask_api.dart';
import '../../core/providers/settings_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/mol_motion.dart';
import '../../core/theme/phosphor.dart';
import '../../core/widgets/ai_status_strip.dart';
import '../../core/widgets/brass_ornament.dart';
import '../../core/widgets/screen_header.dart';
import '../../core/widgets/status_light.dart';

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

  final String role; // 'user' | 'assistant' | 'system'
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
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _inputFocus = FocusNode();
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

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: MolMotion.base,
        curve: MolMotion.standard,
      );
    });
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _waiting) return;

    final settings = ref.read(settingsControllerProvider).value;
    final endpoint = settings?.askEndpoint ?? '';
    setState(() {
      _entries.add(AskEntry(role: 'user', text: text));
      _input.clear();
    });
    _scrollToBottom();

    if (endpoint.isEmpty) {
      setState(() {
        _entries.add(
          const AskEntry(
            role: 'system',
            text: 'Ask is not configured yet — set the Wiki URL (or a '
                'dedicated Ask URL) in Settings.',
          ),
        );
      });
      _scrollToBottom();
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
        () =>
            _entries.add(AskEntry(role: 'system', text: 'Ask call failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _waiting = false);
        _inputFocus.requestFocus();
      }
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pal = _AskPalette.of(context);
    final endpoint =
        ref.watch(settingsControllerProvider).value?.askEndpoint ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
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
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: SectionDivider.garnet(),
        ),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: Column(
                children: [
                  Expanded(
                    child: _entries.isEmpty && !_waiting
                        ? const _EmptyTranscript()
                        : ListView(
                            controller: _scroll,
                            padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                            children: [
                              for (final e in _entries) _Bubble(entry: e),
                              if (_waiting) const _ThinkingBubble(),
                            ],
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 6, 24, 22),
                    child: _InputBar(
                      controller: _input,
                      focusNode: _inputFocus,
                      enabled: !_waiting,
                      onSend: _send,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
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

/// One chat bubble: verdigris assistant (left, with source chips + revision
/// footer) / sapphire user (right) / oxblood system-error (left).
class _Bubble extends StatelessWidget {
  const _Bubble({required this.entry});

  final AskEntry entry;

  @override
  Widget build(BuildContext context) {
    final pal = _AskPalette.of(context);
    final user = entry.role == 'user';
    final system = entry.role == 'system';
    final gradient = user
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [pal.userBubbleTop, pal.userBubbleBottom],
          )
        : system
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [pal.errorTop, pal.errorBottom],
          )
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [pal.assistantTop, pal.assistantBottom],
          );
    final border = user
        ? pal.userBorder
        : system
        ? pal.errorBorder
        : pal.assistantBorder;
    final textColor = user
        ? pal.userInk
        : system
        ? pal.errorInk
        : pal.assistantInk;

    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: gradient,
            border: Border.all(color: border),
            boxShadow: [
              BoxShadow(
                color: pal.bubbleShadow,
                offset: const Offset(0, 3),
                blurRadius: 8,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectableText(
                entry.text,
                style: TextStyle(fontSize: 16, height: 1.45, color: textColor),
              ),
              if (entry.sources.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final s in entry.sources) _SourceChip(source: s),
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
                          style: TextStyle(
                            fontSize: 10.5,
                            color: pal.staleText,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
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

/// "Consulting the vault…" placeholder while retrieval + generation run.
/// The ellipsis pulse is gated off under FLUTTER_TEST so tests settle.
class _ThinkingBubble extends StatefulWidget {
  const _ThinkingBubble();

  @override
  State<_ThinkingBubble> createState() => _ThinkingBubbleState();
}

class _ThinkingBubbleState extends State<_ThinkingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void initState() {
    super.initState();
    if (kMolAnimationsEnabled) _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pal = _AskPalette.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [pal.assistantTop, pal.assistantBottom],
          ),
          border: Border.all(color: pal.assistantBorder),
        ),
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final dots = '.' * (1 + ((_c.value * 3).floor() % 3));
            return Text(
              'Consulting the vault$dots',
              style: TextStyle(
                fontSize: 15,
                fontStyle: FontStyle.italic,
                color: pal.thinkingText,
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Recessed input field + 42px verdigris send stud. Enter sends, Shift+Enter
/// inserts a newline.
class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final pal = _AskPalette.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: pal.inputBg,
              border: Border.all(color: pal.inputBorder),
            ),
            child: Focus(
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent &&
                    event.logicalKey == LogicalKeyboardKey.enter &&
                    !HardwareKeyboard.instance.isShiftPressed) {
                  onSend();
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                enabled: enabled,
                minLines: 1,
                maxLines: 5,
                style: TextStyle(fontSize: 15.5, color: pal.inputInk),
                decoration: InputDecoration(
                  hintText: 'Ask your homelab — "what\'s the NAS double-hop '
                      'again?"',
                  hintStyle: TextStyle(color: pal.inputHint),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        MouseRegion(
          cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
          child: GestureDetector(
            onTap: enabled ? onSend : null,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(13),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF3E8E76), Color(0xFF1E5946)],
                ),
                border: Border.all(color: const Color(0x8078C8AE)),
                boxShadow: context.brass.cardShadow,
              ),
              child: Icon(
                PhBold.paperPlaneTilt,
                size: 18,
                color: enabled
                    ? const Color(0xFFDCF2E8)
                    : const Color(0x80DCF2E8),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Ask-local chat palette, brightness-resolved. Assistant bubbles wear the
/// vault's verdigris patina (distinct from Hermes's garnet); user bubbles
/// share the sapphire idiom; errors share the oxblood idiom. The verdigris
/// send stud (gradient, patina rim, mint icon) is a shared physical object
/// and keeps its literals in [_InputBar].
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
