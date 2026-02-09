enum HTMLTemplate {
    static let html: String = """
    <!DOCTYPE html>
    <html>
    <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
    /* ── Reset & Base ─────────────────────────────────────────── */
    *, *::before, *::after { box-sizing: border-box; }

    :root { color-scheme: light dark; }

    html, body {
        margin: 0;
        padding: 0;
        height: 100%;
    }

    body {
        font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif;
        font-size: 15px;
        line-height: 1.7;
        color: #24292f;
        background: #ffffff;
        -webkit-font-smoothing: antialiased;
    }

    #content {
        max-width: 1560px;
        margin: 0 auto;
        padding: 28px 32px 80px;
    }

    /* ── Headings ─────────────────────────────────────────────── */
    h1, h2, h3, h4, h5, h6 {
        margin-top: 24px;
        margin-bottom: 16px;
        font-weight: 600;
        line-height: 1.25;
    }
    h1 { font-size: 2em;   padding-bottom: .3em; border-bottom: 1px solid #d1d9e0; }
    h2 { font-size: 1.5em; padding-bottom: .3em; border-bottom: 1px solid #d1d9e0; }
    h3 { font-size: 1.25em; }
    h4 { font-size: 1em; }

    /* ── Paragraphs & Text ────────────────────────────────────── */
    p, ul, ol, blockquote, table, pre, details {
        margin-top: 0;
        margin-bottom: 16px;
    }
    a { color: #0969da; text-decoration: none; }
    a:hover { text-decoration: underline; }

    strong { font-weight: 600; }

    hr {
        height: 2px;
        padding: 0;
        margin: 24px 0;
        background-color: #d1d9e0;
        border: 0;
    }

    /* ── Lists ────────────────────────────────────────────────── */
    ul, ol { padding-left: 2em; }
    li + li { margin-top: .25em; }
    li > p { margin-top: 16px; }

    /* ── Blockquote ───────────────────────────────────────────── */
    blockquote {
        margin-left: 0;
        padding: 0 1em;
        color: #59636e;
        border-left: 3px solid #d1d9e0;
    }

    /* ── Code ─────────────────────────────────────────────────── */
    code {
        font-family: "SF Mono", "Menlo", "Monaco", "Courier New", monospace;
        font-size: 0.9em;
        padding: 0.2em 0.4em;
        margin: 0;
        background-color: rgba(175, 184, 193, 0.2);
        border-radius: 4px;
    }

    pre {
        padding: 16px;
        overflow: auto;
        font-size: 0.88em;
        line-height: 1.5;
        background-color: #f6f8fa;
        border-radius: 6px;
    }

    pre code {
        padding: 0;
        margin: 0;
        background: transparent;
        border: 0;
        font-size: 100%;
    }

    /* ── Table ────────────────────────────────────────────────── */
    table {
        border-spacing: 0;
        border-collapse: collapse;
        width: auto;
        max-width: 100%;
        overflow: auto;

    }
    th, td {
        padding: 6px 13px;
        border: 1px solid #d1d9e0;
    }
    th {
        font-weight: 600;
        background-color: #f6f8fa;
    }
    tr:nth-child(2n) { background-color: #f6f8fa; }

    /* ── Images ───────────────────────────────────────────────── */
    img {
        max-width: 100%;
        height: auto;
        border-radius: 4px;
    }

    /* ── Task List ────────────────────────────────────────────── */
    .task-list-item {
        list-style: none;
        margin-left: -1.5em;
    }
    .task-list-item input[type="checkbox"] {
        margin-right: 0.5em;
        vertical-align: middle;
    }

    /* ── Loading state ────────────────────────────────────────── */
    #loading {
        display: flex;
        align-items: center;
        justify-content: center;
        height: 100vh;
        color: #59636e;
        font-size: 14px;
    }

    /* ── Dark Mode ────────────────────────────────────────────── */
    @media (prefers-color-scheme: dark) {
        body {
            color: #e6edf3;
            background: #0d1117;
        }
        a { color: #58a6ff; }
        h1, h2 { border-bottom-color: #30363d; }
        hr { background-color: #30363d; }
        blockquote { color: #8b949e; border-left-color: #30363d; }
        code { background-color: rgba(110, 118, 129, 0.3); }
        pre { background-color: #161b22; }
        th { background-color: #161b22; }
        th, td { border-color: #30363d; }
        tr:nth-child(2n) { background-color: #161b22; }
        #loading { color: #8b949e; }
    }
    </style>
    <!-- highlight.js themes (loaded before scripts) -->
    <link rel="stylesheet"
          href="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/styles/github.min.css"
          media="(prefers-color-scheme: light)">
    <link rel="stylesheet"
          href="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/styles/github-dark.min.css"
          media="(prefers-color-scheme: dark)">
    </head>
    <body>
    <div id="loading">Loading renderer…</div>
    <div id="content" style="display:none;"></div>

    <script src="https://cdnjs.cloudflare.com/ajax/libs/marked/14.1.4/marked.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/highlight.min.js"></script>
    <script>
    (function() {
        // Configure marked
        marked.setOptions({ gfm: true, breaks: false });

        const content = document.getElementById('content');
        const loading = document.getElementById('loading');

        function show() {
            loading.style.display = 'none';
            content.style.display = 'block';
        }

        // Main render function called from Swift via evaluateJavaScript
        window.renderBase64 = function(b64) {
            const bytes = Uint8Array.from(atob(b64), c => c.charCodeAt(0));
            const text  = new TextDecoder('utf-8').decode(bytes);

            const scrollY = window.scrollY;
            content.innerHTML = marked.parse(text);

            // Syntax-highlight code blocks
            content.querySelectorAll('pre code').forEach(function(block) {
                hljs.highlightElement(block);
            });

            // Make task-list checkboxes disabled (read-only viewer)
            content.querySelectorAll('input[type="checkbox"]').forEach(function(cb) {
                cb.disabled = true;
            });

            show();
            window.scrollTo(0, scrollY);
        };
    })();
    </script>
    </body>
    </html>
    """
}
