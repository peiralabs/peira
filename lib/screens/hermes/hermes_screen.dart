import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ai/ai_chain.dart';
import '../../core/api/hermes_api.dart';
import '../../core/build_config.dart';
import '../../core/providers/settings_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/phosphor.dart';
import '../../core/widgets/ai_status_strip.dart';
import '../../core/widgets/brass_icon_badge.dart';
import '../../core/widgets/screen_header.dart';
import '../../core/widgets/status_light.dart';
import '../chat_scaffold.dart';

/// One transcript entry. Role is 'user', 'assistant', or 'system' (errors).
typedef HermesTurn = ({String role, String text});

/// Native chat (design §5): garnet header, centered 920px transcript
/// of garnet assistant / sapphire user bubbles, and a recessed input bar
/// with a garnet send stud. Talks to an OpenAI-compatible endpoint
/// non-streaming — a thinking bubble covers the agent's 10–60s turnaround.
/// The transcript is in-memory per session (the shell's IndexedStack keeps
/// this state alive across tab switches).
///
/// Personal build: the Hermes agent, fixed model route, key required.
/// Public build ("AI Chat"): any OpenAI-compatible server (Ollama /v1,
/// LiteLLM, OpenRouter, vLLM) with an operator-configured model and an
/// optional key. All branding differences are const on [kPublicBuild], so
/// each build tree-shakes the other's strings.
class HermesScreen extends ConsumerStatefulWidget {
  const HermesScreen({super.key, this.testTranscript});

  /// Seeds the transcript (goldens / tests).
  final List<HermesTurn>? testTranscript;

  @override
  ConsumerState<HermesScreen> createState() => _HermesScreenState();
}

class _HermesScreenState extends ConsumerState<HermesScreen> {
  final List<HermesTurn> _turns = [];
  bool _waiting = false;

  @override
  void initState() {
    super.initState();
    if (widget.testTranscript != null) _turns.addAll(widget.testTranscript!);
  }

  Future<void> _send(String text) async {
    final settings = ref.read(settingsControllerProvider).value;
    final endpoint = settings?.hermesApiEndpoint ?? '';
    setState(() => _turns.add((role: 'user', text: text)));

    if (endpoint.isEmpty) {
      setState(() {
        _turns.add((
          role: 'system',
          text: kPublicBuild
              ? 'AI Chat is not configured yet. Enter an OpenAI-compatible '
                    'endpoint URL in Settings.'
              : 'Hermes is not configured yet. Enter the Hermes URL '
                    '(or API URL) and API key in Settings.',
        ));
      });
      return;
    }

    // Personal build: the Hermes agent always wants its key. Public build:
    // the key is optional (local daemons run open) but the model is not —
    // an OpenAI-compatible server rejects a request without one.
    if (!kPublicBuild && (settings?.hermesApiKey ?? '').isEmpty) {
      setState(() {
        _turns.add((
          role: 'system',
          text: 'Hermes API key is not set — add it in Settings.',
        ));
      });
      return;
    }

    if (kPublicBuild && (settings?.chatModel ?? '').isEmpty) {
      setState(() {
        _turns.add((
          role: 'system',
          text:
              'No model is set — enter the model name in Settings '
              '(e.g. llama3.2 for Ollama).',
        ));
      });
      return;
    }

    setState(() => _waiting = true);
    try {
      final api = HermesApi(
        endpoint,
        settings?.hermesApiKey ?? '',
        model: settings?.chatModel ?? 'hermes-agent',
      );
      final reply = await api.chat([
        for (final t in _turns)
          if (t.role != 'system') (role: t.role, content: t.text),
      ]);
      if (!mounted) return;
      setState(() => _turns.add((role: 'assistant', text: reply)));
    } on HermesException catch (e) {
      if (!mounted) return;
      setState(() => _turns.add((role: 'system', text: e.message)));
    } catch (e) {
      if (!mounted) return;
      setState(
        () => _turns.add((
          role: 'system',
          text: kPublicBuild
              ? 'AI request failed: $e'
              : 'Hermes call failed: $e',
        )),
      );
    } finally {
      if (mounted) {
        setState(() => _waiting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pal = _HermesPalette.of(context);
    final settings = ref.watch(settingsControllerProvider).value;
    // Personal: the pill probes the Hermes dashboard root. Public: there is
    // no dashboard — probe the chat endpoint itself (any HTTP response = up).
    final pillUrl = kPublicBuild
        ? (settings?.hermesApiEndpoint ?? '')
        : (settings?.hermesUrl ?? '');
    final model = settings?.chatModel ?? '';
    return ChatScaffold(
      header: Padding(
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 16),
        child: ScreenHeader(
          icon: Ph.brain,
          badgeField: BrassIconBadge.garnetField,
          title: kPublicBuild ? 'AI Chat' : 'Hermes',
          subtitle: kPublicBuild
              ? (model.isEmpty
                    ? 'AI ASSISTANT · OPENAI-COMPATIBLE'
                    : 'AI ASSISTANT · ${model.toUpperCase()}')
              : 'AI ASSISTANT · ${AiChain.primary.name.toUpperCase()}',
          subtitleColor: pal.subtitle,
          trailing: [
            if (pillUrl.isNotEmpty) ...[
              const SizedBox(width: 12),
              _ReachabilityPill(url: pillUrl),
            ],
          ],
        ),
      ),
      entries: [
        for (final turn in _turns)
          (role: turn.role, text: turn.text, footer: null),
      ],
      onSend: _send,
      waiting: _waiting,
      emptyState: const _EmptyTranscript(),
      thinkingLabel: kPublicBuild ? 'Thinking' : 'Hermes is thinking',
      inputHint: kPublicBuild
          ? 'Send a message…'
          : 'Ask Hermes anything about your homelab…',
      style: pal.chatStyle,
    );
  }
}

/// Breathing reachability light mirroring the Ollama pill idiom: green when
/// the last probe of [url] (the Hermes dashboard root, or the chat endpoint
/// in the public build) succeeded, red with a Retry affordance when it
/// failed. Holds the previous ok/fail state while a re-probe is in flight so
/// the pill doesn't flicker through "Checking…".
class _ReachabilityPill extends ConsumerWidget {
  const _ReachabilityPill({required this.url});

  final String url;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pal = _HermesPalette.of(context);
    final state = ref.watch(serviceReachableProvider(url));
    // hasValue survives a refresh (loading with a previous result), so only
    // a genuine first probe shows "Checking…".
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
                ? (kPublicBuild ? 'Endpoint up' : 'Hermes up')
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
    final pal = _HermesPalette.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Ph.brain, size: 40, color: pal.emptyIcon),
          const SizedBox(height: 12),
          Text(
            kPublicBuild
                ? 'Chat with your own AI endpoint — Ollama, LiteLLM, '
                      'OpenRouter, vLLM.'
                : 'Ask Hermes about the lab — it can see the cluster.',
            style: TextStyle(color: context.brass.textMuted),
          ),
        ],
      ),
    );
  }
}

/// Hermes-local chat palette, brightness-resolved. [dark] is verbatim from
/// the dark-only era (translucent maroons over the green field, cream inks);
/// [light] turns the bubbles into sapphire/garnet-tinted papers with dark
/// inks and the black bubble shadow into an umber wash.
class _HermesPalette {
  const _HermesPalette({
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

  /// Ambient-theme resolution (registers a Theme dependency, like Brass.of).
  static _HermesPalette of(BuildContext context) =>
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
    sendTop: const Color(0xFFC05A4E),
    sendBottom: const Color(0xFF7A2B2C),
    sendBorder: const Color(0x80E09678),
    sendIcon: const Color(0xFFFBE9DC),
    sendIconDisabled: const Color(0x80FBE9DC),
  );

  static const dark = _HermesPalette(
    subtitle: Color(0xFFD79F92),
    pillBorderFail: Color(0x80C8564A),
    pillBorderUp: Color(0x578C5048),
    pillBg: Color(0x66231414),
    pillTextFail: Color(0xFFECAF9F),
    pillTextUp: Color(0xFFC8A294),
    emptyIcon: Color(0xFF8A6A5E),
    userBubbleTop: Color(0x575A86C0),
    userBubbleBottom: Color(0x522D5A9A),
    userBorder: Color(0x738CAFE0),
    userInk: Color(0xFFE7EEFA),
    assistantTop: Color(0xC7302121),
    assistantBottom: Color(0xD11C1414),
    assistantBorder: Color(0x57E09678),
    assistantInk: Color(0xFFEEDCD0),
    errorTop: Color(0x66502020),
    errorBottom: Color(0x662A1212),
    errorBorder: Color(0x80C8564A),
    errorInk: Color(0xFFECC5BC),
    bubbleShadow: Color(0x59000000),
    thinkingText: Color(0xFFC8A294),
    inputBg: Color(0xA61C1313),
    inputBorder: Color(0x5CE09678),
    inputInk: Color(0xFFEEDCD0),
    inputHint: Color(0xFF9A8378),
  );

  static const light = _HermesPalette(
    subtitle: Color(0xFF8F4A3C),
    pillBorderFail: Color(0x8C9E362C),
    pillBorderUp: Color(0x668F4A3C),
    pillBg: Color(0x66F2E3DA),
    pillTextFail: Color(0xFF9E362C),
    pillTextUp: Color(0xFF6E4A3E),
    emptyIcon: Color(0xFF7A6558),
    userBubbleTop: Color(0xE8D6E2F4),
    userBubbleBottom: Color(0xE0C6D6EC),
    userBorder: Color(0x8C3A5E96),
    userInk: Color(0xFF24365A),
    // Pulled off salmon (was 0xE8F0DED2 / 0xECE4CDBE — read pink): warm
    // parchment-tan carries the bubble; the cognac border keeps the identity.
    assistantTop: Color(0xE8EFE4D2),
    assistantBottom: Color(0xECE7D8C2),
    assistantBorder: Color(0x668F4A3C),
    assistantInk: Color(0xFF3E2A22),
    errorTop: Color(0x8CF2D8D0),
    errorBottom: Color(0x8CEBC8BE),
    errorBorder: Color(0x8C9E362C),
    errorInk: Color(0xFF7A241A),
    bubbleShadow: Color(0x2E46381F),
    thinkingText: Color(0xFF6E4A3E),
    inputBg: Color(0xA6ECE3D2),
    inputBorder: Color(0x668F4A3C),
    inputInk: Color(0xFF3A2C24),
    inputHint: Color(0xFF6E5A4E),
  );
}
