import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/searxng_api.dart';
import '../../core/providers/searxng_providers.dart';
import '../../core/providers/settings_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/phosphor.dart';
import '../../core/widgets/brass_panel.dart';
import '../../core/widgets/service_frame.dart';

/// Native SearXNG: the private metasearch's JSON API with its categories,
/// time range, safe search, language, engine choice, autocomplete, answers,
/// infoboxes and paging. Results open in the system browser.
class SearxngScreen extends ConsumerWidget {
  const SearxngScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsControllerProvider).value;
    final url = s?.searxngUrl ?? '';
    return ServiceFrame(
      service: 'SearXNG',
      icon: Ph.magnifyingGlass,
      subtitle: 'PRIVATE METASEARCH',
      url: url,
      configured: s?.searxngConfigured ?? false,
      credentialName: 'URL',
      child: const _SearchView(),
    );
  }
}

class _SearchView extends ConsumerStatefulWidget {
  const _SearchView();

  @override
  ConsumerState<_SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends ConsumerState<_SearchView> {
  final _query = TextEditingController();
  String _category = 'general';
  String? _timeRange;
  int? _safe;
  String? _language;
  Set<String> _engines = {};
  int _page = 1;
  String _lastQuery = '';
  Future<SearxPage>? _results;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _search({int page = 1, String? query}) {
    final q = (query ?? _query.text).trim();
    if (q.isEmpty) return;
    if (query != null) _query.text = query;
    setState(() {
      _page = page;
      _lastQuery = q;
      _results = ref
          .read(searxngApiProvider.future)
          .then(
            (api) => api.search(
              q,
              category: _category,
              page: page,
              timeRange: _timeRange,
              safeSearch: _safe,
              language: _language,
              engines: _engines.toList(),
            ),
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(searxConfigProvider).value;
    final brass = context.brass;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
          child: _QueryField(
            controller: _query,
            onSubmit: (q) => _search(query: q),
            autocomplete: (config?.autocomplete.isNotEmpty ?? false)
                ? (q) async => (await ref.read(
                    searxngApiProvider.future,
                  )).autocomplete(q)
                : null,
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            children: [
              for (final c in config?.categories ?? const ['general']) ...[
                ChoiceChip(
                  label: Text(c),
                  selected: _category == c,
                  onSelected: (_) {
                    setState(() {
                      _category = c;
                      _engines = {};
                    });
                    _search();
                  },
                ),
                const SizedBox(width: 6),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 6, 24, 6),
          child: Wrap(
            spacing: 10,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _menu<String?>('Any time', _timeRange, const {
                null: 'Any time',
                'day': 'Past day',
                'week': 'Past week',
                'month': 'Past month',
                'year': 'Past year',
              }, (v) => _timeRange = v),
              _menu<int?>('Safe search', _safe, {
                null: 'Safe search: default',
                0: 'Safe search: off',
                1: 'Safe search: moderate',
                2: 'Safe search: strict',
              }, (v) => _safe = v),
              if (config != null && config.locales.isNotEmpty)
                _menu<String?>('Language', _language, {
                  null: 'Any language',
                  for (final e in config.locales.entries) e.key: e.value,
                }, (v) => _language = v),
              if (config != null)
                ActionChip(
                  avatar: const Icon(Icons.tune, size: 16),
                  label: Text(
                    _engines.isEmpty
                        ? 'All engines'
                        : '${_engines.length} engines',
                  ),
                  onPressed: () => _pickEngines(config),
                ),
            ],
          ),
        ),
        Expanded(
          child: _results == null
              ? Center(
                  child: Text(
                    config == null
                        ? 'Connecting…'
                        : 'SearXNG ${config.version} · '
                              '${config.engines.where((e) => e.enabled).length} '
                              'engines enabled',
                    style: TextStyle(color: brass.textMuted),
                  ),
                )
              : FutureBuilder<SearxPage>(
                  future: _results,
                  builder: (context, snap) {
                    if (snap.hasError) {
                      return ServiceError(
                        error: snap.error!,
                        onRetry: () => _search(page: _page),
                      );
                    }
                    if (!snap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return _ResultsList(
                      page: snap.data!,
                      pageNo: _page,
                      images: _category == 'images',
                      onSearch: (q) => _search(query: q),
                      onPage: (p) => _search(page: p, query: _lastQuery),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _menu<T>(
    String tooltip,
    T value,
    Map<T, String> options,
    void Function(T) set,
  ) => PopupMenuButton<T>(
    tooltip: tooltip,
    initialValue: value,
    onSelected: (v) {
      setState(() => set(v));
      _search();
    },
    itemBuilder: (_) => [
      for (final e in options.entries)
        PopupMenuItem(value: e.key, child: Text(e.value)),
    ],
    child: Chip(
      label: Text(options[value] ?? tooltip),
      avatar: const Icon(Icons.arrow_drop_down, size: 18),
    ),
  );

  Future<void> _pickEngines(SearxConfig config) async {
    final candidates = [
      for (final e in config.engines)
        if (e.enabled && e.categories.contains(_category)) e.name,
    ];
    final picked = Set<String>.of(_engines);
    final result = await showDialog<Set<String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: Text('Engines for $_category'),
          content: SizedBox(
            width: 420,
            height: 460,
            child: candidates.isEmpty
                ? const Center(child: Text('No enabled engines here.'))
                : ListView(
                    children: [
                      for (final name in candidates)
                        CheckboxListTile(
                          dense: true,
                          value: picked.contains(name),
                          title: Text(name),
                          onChanged: (v) => setLocal(
                            () => v == true
                                ? picked.add(name)
                                : picked.remove(name),
                          ),
                        ),
                    ],
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, <String>{}),
              child: const Text('Use all'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, picked),
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
    if (result == null) return;
    setState(() => _engines = result);
    _search();
  }
}

/// The query box, with the instance's autocomplete when it has one.
class _QueryField extends StatefulWidget {
  const _QueryField({
    required this.controller,
    required this.onSubmit,
    required this.autocomplete,
  });
  final TextEditingController controller;
  final void Function(String) onSubmit;
  final Future<List<String>> Function(String)? autocomplete;

  @override
  State<_QueryField> createState() => _QueryFieldState();
}

class _QueryFieldState extends State<_QueryField> {
  final _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final onSubmit = widget.onSubmit;
    InputDecoration deco() => InputDecoration(
      prefixIcon: const Icon(Icons.search),
      hintText: 'Search the web privately',
      border: const OutlineInputBorder(),
      isDense: true,
      suffixIcon: IconButton(
        tooltip: 'Search',
        icon: const Icon(Icons.arrow_forward),
        onPressed: () => onSubmit(controller.text),
      ),
    );
    final complete = widget.autocomplete;
    if (complete == null) {
      return TextField(
        controller: controller,
        decoration: deco(),
        textInputAction: TextInputAction.search,
        onSubmitted: onSubmit,
      );
    }
    return RawAutocomplete<String>(
      textEditingController: controller,
      focusNode: _focus,
      optionsBuilder: (value) async {
        final q = value.text.trim();
        if (q.length < 2) return const [];
        try {
          return await complete(q);
        } on Object {
          return const [];
        }
      },
      onSelected: onSubmit,
      fieldViewBuilder: (context, c, focus, submit) => TextField(
        controller: c,
        focusNode: focus,
        decoration: deco(),
        textInputAction: TextInputAction.search,
        onSubmitted: onSubmit,
      ),
      optionsViewBuilder: (context, select, options) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 4,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280, maxWidth: 640),
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final o in options)
                  ListTile(dense: true, title: Text(o), onTap: () => select(o)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultsList extends StatelessWidget {
  const _ResultsList({
    required this.page,
    required this.pageNo,
    required this.images,
    required this.onSearch,
    required this.onPage,
  });
  final SearxPage page;
  final int pageNo;
  final bool images;
  final void Function(String) onSearch;
  final void Function(int) onPage;

  @override
  Widget build(BuildContext context) {
    final brass = context.brass;
    final p = page;
    final header = <Widget>[
      for (final c in p.corrections)
        _LinkLine(label: 'Did you mean: $c', onTap: () => onSearch(c)),
      for (final a in p.answers) BrassPanel(child: SelectableText(a)),
      for (final b in p.infoboxes) _Infobox(box: b),
      if (p.suggestions.isNotEmpty)
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final s in p.suggestions)
              ActionChip(label: Text(s), onPressed: () => onSearch(s)),
          ],
        ),
      if (p.results.isEmpty)
        const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text('No results.')),
        ),
    ];
    final footer = <Widget>[
      if (p.unresponsive.isNotEmpty)
        Text(
          'Did not answer: '
          '${p.unresponsive.map((u) => '${u.$1} (${u.$2})').join(', ')}',
          style: TextStyle(color: brass.textMuted, fontSize: 12),
        ),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          OutlinedButton(
            onPressed: pageNo > 1 ? () => onPage(pageNo - 1) : null,
            child: const Text('Previous'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Page $pageNo'),
          ),
          OutlinedButton(
            onPressed: p.results.isEmpty ? null : () => onPage(pageNo + 1),
            child: const Text('Next'),
          ),
        ],
      ),
    ];
    final spaced = [
      for (final w in header) ...[w, const SizedBox(height: 10)],
    ];
    if (images) {
      return CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 6, 24, 0),
            sliver: SliverList.list(children: spaced),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              itemCount: p.results.length,
              itemBuilder: (context, i) => _ImageTile(result: p.results[i]),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
            sliver: SliverList.list(children: footer),
          ),
        ],
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 6, 24, 28),
      children: [
        ...spaced,
        for (final r in p.results) _ResultTile(result: r),
        const SizedBox(height: 12),
        ...footer,
      ],
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({required this.result});
  final SearxResult result;

  @override
  Widget build(BuildContext context) {
    final brass = context.brass;
    final r = result;
    final host = Uri.tryParse(r.url)?.host ?? r.url;
    return InkWell(
      onTap: () => openInBrowser(context, r.url),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(host, style: TextStyle(color: brass.textMuted, fontSize: 12)),
            Text(
              r.title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: brass.giltBright),
            ),
            if (r.content.isNotEmpty)
              Text(r.content, maxLines: 3, overflow: TextOverflow.ellipsis),
            Text(
              [
                r.engines.join(', '),
                if (r.published != null)
                  r.published!.toLocal().toString().substring(0, 10),
              ].join('  ·  '),
              style: TextStyle(color: brass.textMuted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageTile extends StatelessWidget {
  const _ImageTile({required this.result});
  final SearxResult result;

  @override
  Widget build(BuildContext context) {
    final src = result.thumbnail ?? result.imgSrc;
    return InkWell(
      onTap: () => openInBrowser(context, result.url),
      child: Tooltip(
        message: result.title,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: src == null
              ? const ColoredBox(color: Colors.black26)
              : Image.network(
                  src,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      const Center(child: Icon(Icons.broken_image_outlined)),
                ),
        ),
      ),
    );
  }
}

class _Infobox extends StatelessWidget {
  const _Infobox({required this.box});
  final SearxInfobox box;

  @override
  Widget build(BuildContext context) {
    final brass = context.brass;
    return BrassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(box.title, style: Theme.of(context).textTheme.titleLarge),
          if (box.content.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(box.content, maxLines: 6, overflow: TextOverflow.ellipsis),
          ],
          for (final a in box.attributes.take(8))
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${a.label}: ',
                    style: TextStyle(color: brass.textMuted),
                  ),
                  TextSpan(text: a.value),
                ],
              ),
            ),
          if (box.links.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: [
                for (final l in box.links.take(6))
                  ActionChip(
                    label: Text(l.title),
                    onPressed: () => openInBrowser(context, l.url),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _LinkLine extends StatelessWidget {
  const _LinkLine({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Text(label, style: TextStyle(color: context.brass.giltBright)),
  );
}
