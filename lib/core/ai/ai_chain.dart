/// Single source of truth for the lab's AI model chain, as configured on
/// Hermes (CT 107) and verified against the canonical vault (services/
/// hermes-agent.md 2026-07-19 chain verification + the 2026-07-22 node1
/// relocation; services/ollama.md + open-webui.md 2026-08-18 bake-off):
/// primary Claude Haiku 4.5 via the Anthropic-compatible provider, then
/// hosted and local fallbacks. The Ollama nodes serve embeddings, the small
/// local fallback, and — since the 2026-08-18 bake-off — Open WebUI's own
/// chat models (gemma3:4b default, qwen2.5:3b for title/tag tasks).
library;

/// One link in the AI provider chain.
typedef AiModel = ({String name, String provider, String role});

abstract final class AiChain {
  /// The model that runs Hermes.
  static const primary = (
    name: 'claude-haiku-4-5',
    provider: 'Anthropic',
    role: 'primary',
  );

  static const fallbacks = <AiModel>[
    (name: 'gpt-oss-120b', provider: 'OpenRouter', role: 'fallback'),
    // Relocated node2 → node1 on 2026-07-22 (the 4.7 GB model belongs on
    // the 14 GB node).
    (name: 'qwen2.5-coder:7b', provider: 'Ollama node1', role: 'fallback'),
  ];

  /// Embeddings model served by all three Ollama nodes.
  static const embeddings = (
    name: 'nomic-embed-text',
    provider: 'Ollama cluster',
    role: 'embeddings',
  );

  /// What answers directly in Open WebUI (no Hermes in that path): the
  /// 2026-08-18 four-model bake-off winner as default chat, with the 3B
  /// task model doing titles/tags. Both carry `function_calling: legacy`
  /// server-side or OWUI's web search silently no-ops.
  static const owuiModels = <AiModel>[
    (name: 'gemma3:4b', provider: 'Ollama node1', role: 'OWUI chat'),
    (name: 'qwen2.5:3b', provider: 'Ollama node1', role: 'OWUI tasks'),
  ];

  static const all = <AiModel>[primary, ...fallbacks, embeddings];
}
