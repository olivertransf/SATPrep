import { repairInlineMathTex } from './repairInlineMathTex'

export type HtmlProfile = 'standard' | 'passage' | 'quizFigures'

/**
 * TypeScript port of the native Swift buildHTMLString().
 * Generates a self-contained HTML document suitable for srcdoc rendering in an iframe.
 * Uses MathJax 3 CDN for LaTeX, DPR-aware scaling for bitmap PNGs, and dark-mode white plates.
 */
export function buildHtml(
  content: string,
  isDark: boolean,
  fontSize: number = 16,
  compact: boolean = false,
  profile: HtmlProfile = 'standard',
  frameId: string = '',
  fillViewport: boolean = false,
): string {
  const bg       = isDark ? '#111111' : '#FFFFFF'
  const fg       = isDark ? '#EBEBF5' : '#000000'
  const border   = isDark ? '#48484A' : '#D1D1D6'
  const headerBg = isDark ? '#2C2C2E' : '#F2F2F7'
  const rowAlt   = isDark ? '#252528' : '#FAFAFA'
  const bodyClass = isDark ? 'studysat-dark' : 'studysat-light'
  const profileClass = profile === 'passage'
    ? 'studium-profile-passage'
    : profile === 'quizFigures'
      ? 'studium-profile-quizfig'
      : 'studium-profile-standard'
  const densityClass = compact ? 'studium-html-compact' : 'studium-html-comfortable'
  const padding = compact ? '2px 4px 4px' : '4px 2px 14px'
  const fillRootClass = fillViewport ? 'studium-fill-root' : ''
  const fillBodyClass = fillViewport ? 'studium-fill-viewport' : ''

  // Blank replacement — mirrors the Swift replacingOccurrences chain
  const processed = repairInlineMathTex(
    content
    .replace(/<span class="sr-only">blank<\/span>/gi, '______')
    .replace(/<span class="sr-only">Blank<\/span>/g, '______')
    .replace(/<span class="sr-only">BLANK<\/span>/g, '______')
    .replace(/>blank</gi, '>______<')
    .replace(/ blank /gi, ' ______ ')
    .replace(/ blank\./gi, ' ______.')
    .replace(/ blank,/gi, ' ______,')
    .replace(/ blank:/gi, ' ______:')
    .replace(/ blank;/gi, ' ______;'),
  )

  // postH helper string used in both MathJax startup and inline script
  const postH = `function postH() {
                    window.parent.postMessage({ type: 'studium-height', id: '${frameId}', value: document.body.scrollHeight }, '*');
                }`

  return `<!DOCTYPE html>
<html class="${fillRootClass}">
<head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <meta name="color-scheme" content="${isDark ? 'dark' : 'light'}">
    <script>
    window.MathJax = {
        tex: {
            inlineMath: [['\\\\(', '\\\\)']],
            displayMath: [['\\\\[', '\\\\]']],
            tags: 'none',
            packages: {'[+]': ['ams', 'newcommand', 'configmacros', 'noerrors']}
        },
        chtml: {
            scale: 1,
            displayAlign: 'center',
            matchFontHeight: false
        },
        options: {
            skipHtmlTags: ['script','noscript','style','textarea','pre','code'],
            ignoreHtmlClass: 'tex2jax_ignore',
            processHtmlClass: 'tex2jax_process'
        },
        startup: {
            typeset: true,
            ready() {
                MathJax.startup.defaultReady();
                ${postH}
                MathJax.startup.promise.then(function() {
                    postH();
                    requestAnimationFrame(function() { requestAnimationFrame(postH); });
                    [40, 120, 280, 600].forEach(function(ms) { setTimeout(postH, ms); });
                }).catch(function() { postH(); });
            }
        }
    };
    </script>
    <script id="MathJax-script" async src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js"></script>
    <style>
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
    html, body { width: 100%; }
    html.studium-fill-root {
        height: 100%;
        overflow: hidden;
    }
    body.studium-fill-viewport {
        min-height: 100%;
        height: 100%;
        overflow-y: auto;
        overflow-x: hidden;
        -webkit-overflow-scrolling: touch;
    }
    body {
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Helvetica Neue', sans-serif;
        font-size: ${fontSize}px;
        line-height: 1.7;
        color: ${fg};
        background-color: ${bg};
        padding: ${padding};
        word-wrap: break-word;
        overflow-x: hidden;
        -webkit-text-size-adjust: 100%;
        text-rendering: optimizeLegibility;
        -webkit-font-smoothing: antialiased;
    }
    body.studium-profile-quizfig {
        overflow-x: visible !important;
    }
    html:has(body.studium-profile-quizfig) {
        overflow-x: visible;
    }
    body.studium-html-comfortable.studium-profile-quizfig {
        padding: 18px 22px 22px !important;
        line-height: 1.74 !important;
    }
    /* Force question bank color overrides — CB HTML often hardcodes #000000 */
    * { color: ${fg} !important; }
    body { background-color: ${bg}; }
    math { color: inherit; }
    mjx-container { color: ${fg} !important; filter: none !important; opacity: 1 !important; }
    mjx-container[jax="CHTML"] { font-size: 1em !important; }
    mjx-container mjx-math { font-kerning: normal; }
    img:not(.math-img):not([role="math"]) {
        max-width: 100%; height: auto; object-fit: contain;
        display: block; margin: 10px auto; border-radius: 6px;
    }
    img[src^="data:image/png"] {
        image-rendering: -webkit-optimize-contrast;
    }
    /* Inline math images: keep inline, override block layout */
    .math-container .math-img,
    .math-container img[role="math"],
    .math_expression img[role="math"],
    img.math-img[role="math"] {
        display: inline-block !important;
        vertical-align: middle !important;
        margin: 0 0.08em !important;
        max-width: none !important;
        width: auto !important;
        height: auto !important;
        border-radius: 0 !important;
        object-fit: contain;
        image-rendering: -webkit-optimize-contrast;
        image-rendering: crisp-edges;
    }
    /* Block diagrams */
    figure > img:not(.math-img):not([role="math"]),
    p > img:only-child:not(.math-img):not([role="math"]) {
        max-width: min(100%, 760px) !important;
        width: auto !important;
        margin: 16px auto !important;
    }
    figure { max-width: min(100%, 800px); margin-inline: auto; }
    /* Dark mode white plate for block images */
    body.studysat-dark figure > img:not(.math-img):not([role="math"]),
    body.studysat-dark p > img:only-child:not(.math-img):not([role="math"]),
    body.studysat-dark .standalone_image img,
    body.studysat-dark .choice_paragraph img[src^="data:image"] {
        background-color: rgba(255,255,255,0.97) !important;
        padding: 14px 16px !important;
        border-radius: 12px !important;
        box-sizing: border-box !important;
        box-shadow: inset 0 0 0 1px rgba(0,0,0,0.06) !important;
    }
    body.studysat-dark figure > svg,
    body.studysat-dark p > svg:only-child {
        background-color: rgba(255,255,255,0.97) !important;
        padding: 14px 16px !important;
        border-radius: 12px !important;
        box-sizing: border-box !important;
        max-width: min(100%, 760px) !important;
        width: auto !important;
        height: auto !important;
        display: block !important;
        margin: 16px auto !important;
        box-shadow: inset 0 0 0 1px rgba(0,0,0,0.08) !important;
    }
    body.studysat-dark mjx-container svg {
        background: none !important;
        padding: 0 !important;
        margin: 0 !important;
        box-shadow: none !important;
        border-radius: 0 !important;
        max-width: none !important;
        width: auto !important;
        height: auto !important;
        shape-rendering: geometricPrecision;
    }
    body.studysat-light figure > svg,
    body.studysat-light p > svg:only-child {
        max-width: min(100%, 760px) !important;
        display: block !important;
        margin: 16px auto !important;
    }
    h1, h2, h3, h4, h5, h6 {
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Helvetica Neue', sans-serif;
        font-weight: 600;
        line-height: 1.3;
        margin: 16px 0 8px;
        letter-spacing: -0.01em;
    }
    h1 { font-size: 1.5em; }
    h2 { font-size: 1.3em; }
    h3 { font-size: 1.15em; }
    h4, h5, h6 { font-size: 1em; }
    p { margin: 0 0 ${compact ? '6px' : '12px'}; }
    p:last-child { margin-bottom: 0; }
    ul, ol { padding-left: 22px; margin: 0 0 12px; }
    li { margin: 5px 0; line-height: 1.6; }
    li:last-child { margin-bottom: 0; }
    ul ul, ol ol, ul ol, ol ul { margin: 4px 0; }
    strong, b { font-weight: 600; }
    em, i { font-style: italic; }
    blockquote {
        border-left: 3px solid ${isDark ? '#636366' : '#C7C7CC'};
        padding: 4px 0 4px 14px;
        margin: 12px 0;
        opacity: 0.85;
    }
    code {
        font-family: 'SF Mono', 'Consolas', 'Menlo', monospace;
        font-size: 0.875em;
        background-color: ${isDark ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.06)'};
        padding: 2px 5px;
        border-radius: 4px;
    }
    pre {
        font-family: 'SF Mono', 'Consolas', 'Menlo', monospace;
        font-size: 0.875em;
        background-color: ${isDark ? 'rgba(255,255,255,0.07)' : 'rgba(0,0,0,0.04)'};
        border: 1px solid ${border};
        padding: 12px 14px;
        border-radius: 8px;
        overflow-x: auto;
        margin: 12px 0;
        line-height: 1.5;
    }
    pre code { background: none; padding: 0; border-radius: 0; font-size: inherit; }
    sup, sub { font-size: 0.75em; line-height: 0; }
    figure { margin: 0; max-width: 100%; }
    figure.table { display: block; overflow-x: auto; }
    table {
        width: 100%; border-collapse: collapse;
        margin: 4px 0; font-size: 14.5px;
        border-radius: 8px; overflow: hidden;
    }
    table, th, td { border: 1px solid ${border}; }
    table.table_Borderless,
    table.table_Borderless th,
    table.table_Borderless td { border: none !important; }
    th, td { padding: 9px 12px; text-align: left; vertical-align: middle; }
    th {
        background-color: ${headerBg};
        font-weight: 600;
        font-size: 13px;
        letter-spacing: 0.01em;
    }
    tr:nth-child(even) { background-color: ${rowAlt}; }
    tr:nth-child(odd)  { background-color: transparent; }
    .table-scroll-wrapper {
        overflow-x: auto;
        margin: 12px 0; max-width: 100%; scrollbar-width: thin;
        border-radius: 8px;
    }
    .sr-only {
        position: absolute; width: 1px; height: 1px; padding: 0;
        margin: -1px; overflow: hidden; clip: rect(0,0,0,0);
        white-space: nowrap; border-width: 0;
    }
    mjx-container[jax="CHTML"][display="true"] {
        margin: 14px 0 !important;
        overflow: visible !important;
        max-width: 100% !important;
    }
    mjx-container[jax="CHTML"][display="false"] {
        overflow: visible !important;
    }
    body.studium-profile-passage {
        padding: 22px 28px 28px !important;
        line-height: 1.82 !important;
    }
    body.studium-profile-passage p { margin-bottom: 14px !important; }
    body.studium-profile-quizfig figure > img:not(.math-img):not([role="math"]),
    body.studium-profile-quizfig p > img:only-child:not(.math-img):not([role="math"]) {
        max-width: min(100%, 940px) !important;
        margin: 22px auto !important;
    }
    body.studium-profile-quizfig figure { max-width: min(100%, 980px); }
    body.studium-profile-quizfig figure > svg,
    body.studium-profile-quizfig p > svg:only-child {
        max-width: min(100%, 940px) !important;
        margin: 22px auto !important;
    }
    body.studysat-dark.studium-profile-quizfig figure > img:not(.math-img):not([role="math"]),
    body.studysat-dark.studium-profile-quizfig p > img:only-child:not(.math-img):not([role="math"]) {
        padding: 16px 18px !important;
    }
    body.studysat-dark.studium-profile-quizfig figure > svg,
    body.studysat-dark.studium-profile-quizfig p > svg:only-child {
        padding: 16px 18px !important;
    }
    </style>
</head>
<body class="${bodyClass} ${profileClass} ${densityClass} ${fillBodyClass}">
    ${processed}
    <script>
    (function() {
        ${postH}
        var resizeRaf = null;
        function schedulePostH() {
            if (resizeRaf !== null) return;
            resizeRaf = requestAnimationFrame(function() {
                resizeRaf = null;
                postH();
            });
        }

        // DPR-aware scaling for CB bitmap PNGs (1x assets shown on 2x/3x screens)
        function scaleRasterImages() {
            var dpr = window.devicePixelRatio || 1;
            document.querySelectorAll('img[src^="data:image"]').forEach(function(img) {
                var apply = function() {
                    if (!img.naturalWidth) return;
                    img.style.maxWidth = Math.round(img.naturalWidth / dpr) + 'px';
                    img.style.width = '100%';
                    img.style.height = 'auto';
                };
                if (img.complete && img.naturalWidth) apply();
                else img.addEventListener('load', apply, { once: true });
            });
        }
        scaleRasterImages();
        setTimeout(scaleRasterImages, 80);
        setTimeout(scaleRasterImages, 220);

        // Keep iframe height in sync when parent width changes (e.g. split-pane drag)
        window.addEventListener('resize', schedulePostH);
        if ('ResizeObserver' in window) {
            var ro = new ResizeObserver(function() { schedulePostH(); });
            ro.observe(document.documentElement);
            ro.observe(document.body);
        }
        setTimeout(schedulePostH, 0);

        // Wrap bare tables in a scroll container
        document.querySelectorAll('table').forEach(function(t) {
            var p = t.parentElement;
            if (p && p.classList.contains('table-scroll-wrapper')) return;
            var w = document.createElement('div');
            w.className = 'table-scroll-wrapper';
            t.parentNode.insertBefore(w, t);
            w.appendChild(t);
        });

        // Report height after images finish loading
        var imgs = document.querySelectorAll('img');
        var pending = imgs.length;
        if (pending === 0) { postH(); return; }
        imgs.forEach(function(img) {
            if (img.complete) { pending--; }
            else {
                img.addEventListener('load',  function() { if (--pending <= 0) postH(); });
                img.addEventListener('error', function() { if (--pending <= 0) postH(); });
            }
        });
        if (pending <= 0) postH();
    })();
    </script>
</body>
</html>`
}
