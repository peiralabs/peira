import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/mol_motion.dart';
import '../core/theme/phosphor.dart';
import '../core/widgets/brass_ornament.dart';

/// The common data needed to render one chat bubble. Screens can supply an
/// optional [footer] for metadata such as Ask's citations and vault revision.
typedef ChatBubbleEntry = ({String role, String text, Widget? footer});

/// Screen-specific colors and copy for the shared chat transcript and composer.
class ChatScaffoldStyle {
  const ChatScaffoldStyle({
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
    required this.sendTop,
    required this.sendBottom,
    required this.sendBorder,
    required this.sendIcon,
    required this.sendIconDisabled,
  });

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
  final Color sendTop;
  final Color sendBottom;
  final Color sendBorder;
  final Color sendIcon;
  final Color sendIconDisabled;
}

/// Shared transcript, auto-scroll, thinking indicator, and compose box used by
/// the Hermes and Ask screens.
class ChatScaffold extends StatefulWidget {
  const ChatScaffold({
    super.key,
    required this.header,
    required this.entries,
    required this.onSend,
    required this.waiting,
    required this.emptyState,
    required this.thinkingLabel,
    required this.inputHint,
    required this.style,
  });

  final Widget header;
  final List<ChatBubbleEntry> entries;
  final FutureOr<void> Function(String text) onSend;
  final bool waiting;
  final Widget emptyState;
  final String thinkingLabel;
  final String inputHint;
  final ChatScaffoldStyle style;

  @override
  State<ChatScaffold> createState() => _ChatScaffoldState();
}

class _ChatScaffoldState extends State<ChatScaffold> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _inputFocus = FocusNode();

  @override
  void didUpdateWidget(ChatScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entries.length != widget.entries.length ||
        oldWidget.waiting != widget.waiting) {
      _scrollToBottom();
    }
    if (oldWidget.waiting && !widget.waiting) {
      _inputFocus.requestFocus();
    }
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

  void _send() {
    final text = _input.text.trim();
    if (text.isEmpty || widget.waiting) return;
    _input.clear();
    unawaited(Future.sync(() => widget.onSend(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        widget.header,
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
                    child: widget.entries.isEmpty && !widget.waiting
                        ? widget.emptyState
                        : ListView(
                            controller: _scroll,
                            padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                            children: [
                              for (final entry in widget.entries)
                                _ChatBubble(entry: entry, style: widget.style),
                              if (widget.waiting)
                                _ThinkingBubble(
                                  label: widget.thinkingLabel,
                                  style: widget.style,
                                ),
                            ],
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 6, 24, 22),
                    child: _InputBar(
                      controller: _input,
                      focusNode: _inputFocus,
                      enabled: !widget.waiting,
                      onSend: _send,
                      hintText: widget.inputHint,
                      style: widget.style,
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

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.entry, required this.style});

  final ChatBubbleEntry entry;
  final ChatScaffoldStyle style;

  @override
  Widget build(BuildContext context) {
    final user = entry.role == 'user';
    final system = entry.role == 'system';
    final gradient = user
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [style.userBubbleTop, style.userBubbleBottom],
          )
        : system
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [style.errorTop, style.errorBottom],
          )
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [style.assistantTop, style.assistantBottom],
          );
    final border = user
        ? style.userBorder
        : system
        ? style.errorBorder
        : style.assistantBorder;
    final textColor = user
        ? style.userInk
        : system
        ? style.errorInk
        : style.assistantInk;

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
                color: style.bubbleShadow,
                offset: const Offset(0, 3),
                blurRadius: 8,
              ),
            ],
          ),
          child: entry.footer == null
              ? SelectableText(
                  entry.text,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.45,
                    color: textColor,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(
                      entry.text,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.45,
                        color: textColor,
                      ),
                    ),
                    entry.footer!,
                  ],
                ),
        ),
      ),
    );
  }
}

class _ThinkingBubble extends StatefulWidget {
  const _ThinkingBubble({required this.label, required this.style});

  final String label;
  final ChatScaffoldStyle style;

  @override
  State<_ThinkingBubble> createState() => _ThinkingBubbleState();
}

class _ThinkingBubbleState extends State<_ThinkingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void initState() {
    super.initState();
    if (kMolAnimationsEnabled) _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            colors: [widget.style.assistantTop, widget.style.assistantBottom],
          ),
          border: Border.all(color: widget.style.assistantBorder),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final dots = '.' * (1 + ((_controller.value * 3).floor() % 3));
            return Text(
              '${widget.label}$dots',
              style: TextStyle(
                fontSize: 15,
                fontStyle: FontStyle.italic,
                color: widget.style.thinkingText,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.onSend,
    required this.hintText,
    required this.style,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final VoidCallback onSend;
  final String hintText;
  final ChatScaffoldStyle style;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: style.inputBg,
              border: Border.all(color: style.inputBorder),
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
                style: TextStyle(fontSize: 15.5, color: style.inputInk),
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: TextStyle(color: style.inputHint),
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
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [style.sendTop, style.sendBottom],
                ),
                border: Border.all(color: style.sendBorder),
                boxShadow: context.brass.cardShadow,
              ),
              child: Icon(
                PhBold.paperPlaneTilt,
                size: 18,
                color: enabled ? style.sendIcon : style.sendIconDisabled,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
