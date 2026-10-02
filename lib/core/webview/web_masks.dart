/// Per-service "masks": JavaScript injected into each embedded web view so it
/// blends into the app instead of looking like a website. Every service gets a
/// base field matching the app background and themed scrollbars, resolved for
/// the brightness passed to [WebMasks.scriptFor]. The script is injected on
/// every page load and re-run into live pages when the effective brightness
/// flips, so each run must fully replace the previous mask (style node,
/// observers, pollers) rather than append to it.
///
/// Selectors were verified against the live pages via CEF DevTools.
class WebMasks {
  WebMasks._();

  // Shared base field + themed scrollbars.
  static String _baseCss(_MaskPalette p) =>
      '''
    :root { color-scheme: ${p.scheme}; }
    html, body { background: ${p.base} !important; }
    ::-webkit-scrollbar { width: 10px; height: 10px; }
    ::-webkit-scrollbar-thumb { background: ${p.scrollThumb}; border-radius: 8px; }
    ::-webkit-scrollbar-thumb:hover { background: ${p.scrollThumbHover}; }
    ::-webkit-scrollbar-track { background: transparent; }
  ''';

  // Wiki.js (Vue 2 + Vuetify) reskinned into the Brass Edition language to
  // match the design render: bottle-green field (parchment in light mode),
  // Playfair headings, EB Garamond body with a gilt drop-cap, gilt links, and a
  // green-header gilt table. The brand fonts are referenced by name (installed
  // alongside the app) with a Georgia/serif fallback, so it degrades gracefully
  // if they're absent.
  //
  // Content is scoped under `.v-main` (Vuetify's main region) so the nav drawer
  // and TOC keep their own styling; `.nav-header` (verified live) is the app's
  // own toolbar, hidden here since the shell already provides browser chrome.
  static String _wikiCss(_MaskPalette p) =>
      '''
    :root { color-scheme: ${p.scheme}; }
    html, body,
    .v-application, .${p.themeClass}.v-application,
    .v-main, .v-main__wrap { background: ${p.base} !important; }
    .v-application {
      background:
        radial-gradient(120% 90% at 50% -10%, ${p.radialTop} 0%, ${p.base} 55%, ${p.radialEdge} 100%)
        !important;
    }
    /* The shell provides the browser chrome, so drop Wiki's own top toolbar. */
    .nav-header { display: none !important; }

    /* Body copy — antique serif on a warm parchment-ink colour. */
    .v-main, .v-main .contents, .v-main .page {
      font-family: 'EB Garamond', Georgia, 'Times New Roman', serif !important;
      color: ${p.bodyInk} !important;
      font-size: 17px !important;
      line-height: 1.72 !important;
    }

    /* Headings — Playfair, cream, with the first (page title) larger. */
    .v-main h1, .v-main h2, .v-main h3, .v-main h4,
    .v-main .page-header, .v-main .page-header * {
      font-family: 'Playfair Display', Georgia, serif !important;
      color: ${p.headingInk} !important;
      font-weight: 800 !important;
      letter-spacing: .2px !important;
    }
    .v-main h1, .v-main .page-header-title { font-size: 2.35em !important; }
    /* Section headers ("Start here") lean gilt. */
    .v-main h2 { color: ${p.h2Gilt} !important; font-weight: 700 !important; }
    .v-main h3 { color: ${p.h3Gilt} !important; }

    /* Gilt links, underline on hover only. */
    .v-main a, .v-main .contents a {
      color: ${p.link} !important;
      text-decoration: none !important;
    }
    .v-main a:hover { color: ${p.linkHover} !important; text-decoration: underline !important; }

    /* Gilt drop-cap on the article's first paragraph (content is wrapped in a
       <div>, so match the first <p> anywhere under .contents, not a child). */
    .v-main .contents p:first-of-type::first-letter,
    .v-main .page p:first-of-type::first-letter {
      font-family: 'Playfair Display', Georgia, serif;
      font-size: 3.1em;
      line-height: .78;
      float: left;
      margin: 4px 10px 0 0;
      color: ${p.h2Gilt};
    }

    /* Sidebar/meta cards + list panels → blend into the base field instead
       of reading as flat boxes (Vuetify keeps its own surface colour). */
    .v-main .v-card, .v-main .v-sheet, .v-main .v-list,
    .v-main .${p.themeClass}.v-card, .v-main .${p.themeClass}.v-sheet,
    .v-main .${p.themeClass}.v-list, .v-main .v-navigation-drawer__content {
      background: ${p.cardBg} !important;
      border-color: ${p.cardBorder} !important;
      color: ${p.cardInk} !important;
    }
    .v-main .v-toolbar, .v-main .v-app-bar { background: transparent !important; }
    /* Small-caps labels on the meta cards (PAGE CONTENTS / TAGS / …). */
    .v-main .v-card .caption, .v-main .v-subheader { color: ${p.captionSage} !important; }

    /* Tag chips → muted green pills. Vuetify paints `.teal.darken-1` with
       !important at (0,2,0), so use an element+class selector (a.v-chip) to
       out-specify it. */
    .v-application a.v-chip, .v-main a.v-chip {
      background-color: ${p.tagChipBg} !important;
      border: 1px solid ${p.tagChipBorder} !important;
    }
    .v-application a.v-chip .v-chip__content { color: ${p.tagChipInk} !important; }

    /* Tables — gilt small-caps header on deep green, hairline gilt rules. */
    .v-main table { border-collapse: collapse !important; width: 100% !important; }
    .v-main th {
      background: ${p.tableHeadBg} !important;
      color: ${p.tableHeadInk} !important;
      font-family: 'Playfair Display', Georgia, serif !important;
      font-weight: 700 !important;
      text-transform: uppercase !important;
      letter-spacing: .12em !important;
      font-size: 12px !important;
      text-align: left !important;
    }
    .v-main th, .v-main td {
      border: 1px solid ${p.cellBorder} !important;
      padding: 10px 16px !important;
    }
    .v-main tbody tr:nth-child(even) td { background: ${p.zebra} !important; }

    /* Blockquotes in the brass palette. */
    .v-main blockquote {
      border-left: 3px solid ${p.quoteRule} !important;
      color: ${p.quoteInk} !important;
      background: ${p.quoteBg} !important;
    }

    /* Code + fenced blocks → a small, recessed mono panel. */
    .v-main code, .v-main kbd {
      font-family: 'JetBrains Mono', ui-monospace, monospace !important;
      font-size: 13px !important;
      background: ${p.codeBg} !important;
      color: ${p.codeInk} !important;
      border-radius: 5px !important;
      padding: 1px 5px !important;
    }
    .v-main pre, .v-main pre[class*="language-"],
    .v-main .hljs, .v-main .highlight, .v-main .code-toolbar {
      background: ${p.fencedCodeBg} !important;
      border: 1px solid ${p.codeBorder} !important;
      border-radius: 8px !important;
      padding: 14px 16px !important;
      overflow-x: auto !important;
      line-height: 1.55 !important;
    }
    /* Flatten every syntax-highlight token span to a quiet, uniform
       monospace so code blocks don't inherit the loud heading/link colours. */
    .v-main pre, .v-main pre *, .v-main pre code, .v-main pre span,
    .v-main .hljs, .v-main .hljs *,
    .v-main code[class*="language-"], .v-main code[class*="language-"] * {
      font-family: 'JetBrains Mono', ui-monospace, monospace !important;
      font-size: 13px !important;
      color: ${p.codeInk} !important;
      background: transparent !important;
      text-shadow: none !important;
      font-weight: 400 !important;
      font-style: normal !important;
    }

    /* ---- Single-column reading view (matches the design render) ---- */
    /* The page's `--- … ---` YAML is mis-parsed as ONE multi-line heading (an
       <h*> containing <br>s); real headings are single-line, so :has(br) hides
       only that artifact, plus the stray leading <hr> from the fence. */
    .contents :is(h1,h2,h3,h4,h5,h6):has(br) { display: none !important; }
    .contents > div > hr:first-child { display: none !important; }
    /* Drop Wiki's right meta sidebar; widen the article to full width. */
    .page-col-sd { display: none !important; }
    .page-col-content { max-width: 100% !important; flex: 0 0 100% !important; }
    /* Page-header title → brass Playfair (was Roboto grey); subtitle → sage.
       The duplicate content <h1> is hidden in JS, so this is the one title. */
    .v-application .page-header-headings .headline {
      font-family: 'Playfair Display', Georgia, serif !important;
      color: ${p.headingInk} !important;
      font-weight: 800 !important;
      font-size: 2.3em !important;
      letter-spacing: .2px !important;
    }
    .v-application .page-header-headings .caption {
      font-family: 'EB Garamond', Georgia, serif !important;
      color: ${p.captionSage} !important;
      font-size: 15px !important;
    }
    /* Card meta labels (PAGE CONTENTS / TAGS / …) → sage, not blue. */
    .v-main .v-card .overline { color: ${p.captionSage} !important; }

    /* Folder nav tree → garnet-red icons + gilt-gold lettering (was white). */
    .v-application .v-navigation-drawer .v-list-item .v-icon {
      color: ${p.navIcon} !important;
    }
    .v-application .v-navigation-drawer .v-list-item__title,
    .v-application .v-navigation-drawer .v-list-item__content {
      color: ${p.drawerInk} !important;
      font-family: 'EB Garamond', Georgia, serif !important;
      font-size: 15px !important;
      letter-spacing: .2px !important;
    }
    .v-application .v-navigation-drawer .v-toolbar__content,
    .v-application .v-navigation-drawer .v-btn { color: ${p.drawerInk} !important; }
  ''';

  // Align Vuetify's own theme flag with the app brightness (`__MOL_DARK__` is
  // substituted from the palette in [scriptFor]) so Wiki's surfaces don't fight
  // the mask — in light mode Wiki keeps its native light theme instead of
  // being forced dark.
  static const _wikiTheme = r'''
(function () {
  // Generation token: a re-injection (brightness flip) bumps it, which stops
  // any still-polling loop from an earlier run racing its stale value in.
  var gen = (window.__molThemeGen || 0) + 1;
  window.__molThemeGen = gen;
  var tries = 0;
  function goTheme() {
    if (gen !== window.__molThemeGen) return;
    tries++;
    var el = document.querySelector('.v-application');
    var vue = el && el.__vue__;
    if (!vue) {
      var all = document.querySelectorAll('*');
      for (var i = 0; i < all.length; i++) {
        if (all[i].__vue__) { vue = all[i].__vue__; break; }
      }
    }
    if (vue && vue.$root && vue.$root.$vuetify && vue.$root.$vuetify.theme) {
      vue.$root.$vuetify.theme.dark = __MOL_DARK__;
      return;
    }
    if (tries < 40) setTimeout(goTheme, 250);
  }
  goTheme();
})();
''';

  // A few surfaces can't be won with CSS: Vuetify paints the nav drawer and the
  // page-header band with `!important` colour utilities (`grey darken-4-*`) that
  // tie our specificity, and the mangled-frontmatter duplicate title must be
  // matched by text. Set those inline (inline !important beats any stylesheet)
  // and re-apply on SPA navigation, which recreates the content nodes.
  static String _wikiBrass(_MaskPalette p) =>
      '''
(function () {
  function apply() {
    var d = document.querySelector('.v-navigation-drawer');
    if (d) {
      d.style.setProperty('background', '${p.drawerBg}', 'important');
      var c = d.querySelector('.v-navigation-drawer__content');
      if (c) c.style.setProperty('background', '${p.drawerBg}', 'important');
      var greys = d.querySelectorAll('.v-list, .v-sheet, .grey');
      for (var i = 0; i < greys.length; i++)
        greys[i].style.setProperty('background-color', 'transparent', 'important');
    }
    var bands = document.querySelectorAll('[class*="darken-4-l3"]');
    for (var j = 0; j < bands.length; j++)
      bands[j].style.setProperty('background', 'transparent', 'important');
    var t = document.querySelector('.page-header-headings .headline');
    var title = t ? t.textContent.trim() : null;
    if (title) {
      var hs = document.querySelectorAll('.contents h1');
      for (var k = 0; k < hs.length; k++)
        if (hs[k].textContent.replace(/¶/g, '').trim() === title)
          hs[k].style.display = 'none';
    }
  }
  // A previous injection's observer closed over its own palette and would
  // keep re-applying it; replace it so exactly one observer is live.
  if (window.__molBrassMo) { window.__molBrassMo.disconnect(); }
  apply();
  // Re-apply as the SPA renders/navigates, debounced to one call per frame.
  var queued = false;
  var mo = new MutationObserver(function () {
    if (queued) return;
    queued = true;
    requestAnimationFrame(function () { queued = false; apply(); });
  });
  window.__molBrassMo = mo;
  if (document.body) mo.observe(document.body, {childList: true, subtree: true});
})();
''';

  // Every Wiki selector above is Wiki.js v2 (Vue 2 + Vuetify) specific. On any
  // other wiki — BookStack, Outline, Confluence… — they would half-apply: a
  // repainted background with the page's own chrome fighting it. So the whole
  // Wiki mask is gated on the Vuetify application root actually appearing;
  // unrecognised DOM means no-op, and the page renders exactly as itself.
  // The generation token stops a superseded run's poller (same pattern as the
  // theme script), so a re-injection replaces the previous gate.
  static String _wikiGate(String masked) =>
      '''
(function () {
  var gen = (window.__molWikiGateGen || 0) + 1;
  window.__molWikiGateGen = gen;
  var tries = 0;
  function arm() {
    if (gen !== window.__molWikiGateGen) return;
    if (document.querySelector('.v-application')) {
      $masked
      return;
    }
    if (++tries < 40) setTimeout(arm, 250);
  }
  arm();
})();
''';

  // The CSS lives in a single <style id="__mol_mask"> node whose content is
  // overwritten on every run, so re-injecting (LOAD_END after LOAD_START, or a
  // live brightness flip) replaces the previous palette instead of stacking a
  // second stylesheet under it.
  static String _styleInjector(String css) =>
      '''
(function () {
  try {
    var s = document.getElementById('__mol_mask');
    if (!s) {
      s = document.createElement('style');
      s.id = '__mol_mask';
      (document.head || document.documentElement).appendChild(s);
    }
    s.textContent = ${_dartToJsString(css)};
  } catch (e) {}
})();
''';

  /// The JS mask for a service, or null if none applies. [isDark] selects the
  /// palette. The script is safe to re-run into a live page — it replaces the
  /// prior style node, observer, and theme poller — which the platform
  /// webviews do when the effective brightness changes (didUpdateWidget →
  /// executeJavaScript / runJavaScript).
  static String? scriptFor(String service, {required bool isDark}) {
    final p = isDark ? _MaskPalette.dark : _MaskPalette.light;
    switch (service) {
      case 'Wiki':
        return _wikiGate(
          _styleInjector(_baseCss(p) + _wikiCss(p)) +
              _wikiTheme.replaceFirst('__MOL_DARK__', p.vuetifyDark) +
              _wikiBrass(p),
        );
      case 'Open WebUI':
      case 'Jellyseerr':
      // Home Assistant themes itself (its own dark/light setting); the base
      // mask only aligns the page field + scrollbars with the app chrome.
      case 'Home Assistant':
      // SearXNG (simple theme), Karakeep, Paperless-ngx, and Immich all
      // theme themselves (auto / user setting) — same base-only treatment.
      case 'SearXNG':
      case 'Karakeep':
      case 'Paperless':
      case 'Immich':
        return _styleInjector(_baseCss(p));
      // changedetection.io deliberately gets NO mask: it is server-rendered
      // with text that can sit directly on the page field, so forcing the
      // field dark risks unreadable text. Revisit with the CDP kit if its
      // light field grates in dark mode.
      default:
        return null;
    }
  }

  /// Encodes a Dart string as a JS backtick template literal safely.
  static String _dartToJsString(String s) {
    final escaped = s
        .replaceAll(r'\', r'\\')
        .replaceAll('`', r'\`')
        .replaceAll(r'$', r'\$');
    return '`$escaped`';
  }
}

/// One brightness mode's CSS color strings for the injected masks (the
/// `mask.*` token family). [dark] is verbatim from the dark-only era so dark
/// renders stay identical; [light] is the parchment variant — paper base,
/// engraved-ink text, sepia washes instead of black overlays, and Wiki.js left
/// on its native light Vuetify theme.
class _MaskPalette {
  const _MaskPalette({
    required this.scheme,
    required this.vuetifyDark,
    required this.themeClass,
    required this.base,
    required this.scrollThumb,
    required this.scrollThumbHover,
    required this.radialTop,
    required this.radialEdge,
    required this.bodyInk,
    required this.headingInk,
    required this.h2Gilt,
    required this.h3Gilt,
    required this.link,
    required this.linkHover,
    required this.cardBg,
    required this.cardBorder,
    required this.cardInk,
    required this.captionSage,
    required this.tagChipBg,
    required this.tagChipBorder,
    required this.tagChipInk,
    required this.tableHeadBg,
    required this.tableHeadInk,
    required this.cellBorder,
    required this.zebra,
    required this.quoteRule,
    required this.quoteInk,
    required this.quoteBg,
    required this.codeBg,
    required this.fencedCodeBg,
    required this.codeInk,
    required this.codeBorder,
    required this.navIcon,
    required this.drawerInk,
    required this.drawerBg,
  });

  /// CSS `color-scheme` (native form controls, UA scrollbars).
  final String scheme;

  /// Value substituted into the Wiki theme script's `theme.dark = …;`.
  final String vuetifyDark;

  /// Vuetify's brightness class on themed surfaces.
  final String themeClass;

  final String base;
  final String scrollThumb;
  final String scrollThumbHover;
  final String radialTop;
  final String radialEdge;
  final String bodyInk;
  final String headingInk;
  final String h2Gilt;
  final String h3Gilt;
  final String link;
  final String linkHover;
  final String cardBg;
  final String cardBorder;
  final String cardInk;
  final String captionSage;
  final String tagChipBg;
  final String tagChipBorder;
  final String tagChipInk;
  final String tableHeadBg;
  final String tableHeadInk;
  final String cellBorder;
  final String zebra;
  final String quoteRule;
  final String quoteInk;
  final String quoteBg;
  final String codeBg;
  final String fencedCodeBg;
  final String codeInk;
  final String codeBorder;
  final String navIcon;
  final String drawerInk;
  final String drawerBg;

  static const dark = _MaskPalette(
    scheme: 'dark',
    vuetifyDark: 'true',
    themeClass: 'theme--dark',
    base: '#0E1810',
    scrollThumb: 'rgba(212,169,79,.35)',
    scrollThumbHover: 'rgba(212,169,79,.6)',
    radialTop: '#17281C',
    radialEdge: '#0A120D',
    bodyInk: '#D9D3BF',
    headingInk: '#F4EEDA',
    h2Gilt: '#E8CD78',
    h3Gilt: '#EAD79A',
    link: '#E4C877',
    linkHover: '#F6E4A2',
    cardBg: 'rgba(20,34,24,.66)',
    cardBorder: 'rgba(212,169,79,.14)',
    cardInk: '#C7C2AE',
    captionSage: '#9DB089',
    tagChipBg: 'rgba(46,74,48,.55)',
    tagChipBorder: 'rgba(123,178,106,.42)',
    tagChipInk: '#B7D69B',
    tableHeadBg: '#16281A',
    tableHeadInk: '#E8CD78',
    cellBorder: 'rgba(212,169,79,.18)',
    zebra: 'rgba(255,255,255,.02)',
    quoteRule: 'rgba(212,169,79,.55)',
    quoteInk: '#C7BF9F',
    quoteBg: 'rgba(0,0,0,.16)',
    codeBg: 'rgba(0,0,0,.32)',
    fencedCodeBg: 'rgba(0,0,0,.34)',
    codeInk: '#C9C2A6',
    codeBorder: 'rgba(212,169,79,.16)',
    navIcon: '#C4574B',
    drawerInk: '#E8CD78',
    drawerBg: '#152619',
  );

  static const light = _MaskPalette(
    scheme: 'light',
    vuetifyDark: 'false',
    themeClass: 'theme--light',
    base: '#EDE4CF',
    scrollThumb: 'rgba(110,82,32,.35)',
    scrollThumbHover: 'rgba(110,82,32,.6)',
    radialTop: '#F6F0E0',
    radialEdge: '#E0D4BC',
    bodyInk: '#3A4433',
    headingInk: '#26331F',
    h2Gilt: '#7A5F1E',
    h3Gilt: '#9C7B33',
    link: '#7A5A1A',
    linkHover: '#5C451A',
    cardBg: 'rgba(230,218,192,.62)',
    cardBorder: 'rgba(110,82,32,.25)',
    cardInk: '#474A3C',
    captionSage: '#5C6B4A',
    tagChipBg: 'rgba(78,122,66,.14)',
    tagChipBorder: 'rgba(56,112,46,.45)',
    tagChipInk: '#2C511F',
    tableHeadBg: '#E2D6B8',
    tableHeadInk: '#6E5620',
    cellBorder: 'rgba(110,82,32,.22)',
    zebra: 'rgba(59,46,22,.03)',
    quoteRule: 'rgba(138,106,42,.6)',
    quoteInk: '#4A4433',
    quoteBg: 'rgba(59,46,22,.05)',
    codeBg: 'rgba(59,46,22,.08)',
    fencedCodeBg: 'rgba(59,46,22,.08)',
    codeInk: '#4A4030',
    codeBorder: 'rgba(110,82,32,.16)',
    navIcon: '#9C4136',
    drawerInk: '#6E5620',
    drawerBg: '#E8DEC6',
  );
}
