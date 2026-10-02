import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ai/ai_chain.dart';
import '../theme/app_theme.dart';
import '../theme/mol_motion.dart';
import 'brass_panel.dart';
import 'status_light.dart';

/// Reachability of a service URL (the tab's configured endpoint). Kept as a
/// plain family provider — one tiny GET, no codegen needed.
final serviceReachableProvider = FutureProvider.autoDispose
    .family<bool, String>((ref, url) async {
      if (url.isEmpty) return false;
      try {
        final dio = Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 4),
            receiveTimeout: const Duration(seconds: 4),
            // Any HTTP response means the service is up.
            validateStatus: (_) => true,
          ),
        );
        await dio.get<void>(url);
        return true;
      } on DioException {
        return false;
      }
    });

/// Slim glass header shown above the AI web views (Ollama, Hermes): the live
/// model chain — Haiku primary, hosted + local fallbacks, embeddings — plus a
/// breathing reachability light for the tab's own service.
class AiStatusStrip extends ConsumerWidget {
  const AiStatusStrip({
    super.key,
    required this.serviceName,
    required this.serviceUrl,
    this.accent,
  });

  final String serviceName;
  final String serviceUrl;

  /// Accent for the primary model chip. Defaults to the gilt bronze token.
  final Color? accent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accent = this.accent ?? context.brass.bronze;
    final reachable = ref.watch(serviceReachableProvider(serviceUrl));
    final health = switch (reachable) {
      AsyncData(:final value) => value ? Health.ok : Health.crit,
      AsyncError() => Health.crit,
      _ => Health.offline,
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        MolSpace.lg,
        MolSpace.md,
        MolSpace.lg,
        0,
      ),
      child: BrassPanel(
        padding: const EdgeInsets.symmetric(
          horizontal: MolSpace.lg,
          vertical: MolSpace.sm,
        ),
        child: Row(
          children: [
            StatusLight(health: health),
            const SizedBox(width: MolSpace.md),
            Text(
              serviceName,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: MolSpace.lg),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _ModelChip(model: AiChain.primary, accent: accent),
                    for (final m in AiChain.fallbacks) ...[
                      _ChainArrow(),
                      _ModelChip(model: m),
                    ],
                    const SizedBox(width: MolSpace.lg),
                    const _ModelChip(model: AiChain.embeddings),
                    // What answers in Open WebUI itself — the local chat
                    // pair from the 2026-08-18 bake-off, no Hermes in that
                    // path.
                    for (final m in AiChain.owuiModels) ...[
                      const SizedBox(width: MolSpace.sm),
                      _ModelChip(model: m),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChainArrow extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: MolSpace.xs),
    child: Icon(
      Icons.chevron_right,
      size: 14,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
  );
}

class _ModelChip extends StatelessWidget {
  const _ModelChip({required this.model, this.accent});

  final AiModel model;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPrimary = accent != null;
    final tint = accent ?? theme.colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MolSpace.sm,
        vertical: MolSpace.xs,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(MolRadius.pill),
        border: Border.all(
          color: tint.withValues(alpha: isPrimary ? 0.55 : 0.25),
        ),
        color: isPrimary ? tint.withValues(alpha: 0.10) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            model.name,
            style: theme.textTheme.labelSmall?.copyWith(
              color: isPrimary ? tint : theme.colorScheme.onSurface,
              fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          const SizedBox(width: MolSpace.xs),
          Text(
            model.role == 'primary'
                ? '${model.provider} · runs Hermes'
                : '${model.provider} · ${model.role}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
