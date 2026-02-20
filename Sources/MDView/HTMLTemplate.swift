enum HTMLTemplate {
    static let html: String = """
    <!DOCTYPE html>
    <html>
    <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <link rel="stylesheet" href="github-light.css" media="(prefers-color-scheme: light)">
    <link rel="stylesheet" href="github-dark.css" media="(prefers-color-scheme: dark)">
    <style>
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

    ul, ol { padding-left: 2em; }
    li + li { margin-top: .25em; }
    li > p { margin-top: 16px; }

    blockquote {
        margin-left: 0;
        padding: 0 1em;
        color: #59636e;
        border-left: 3px solid #d1d9e0;
    }

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

    img {
        max-width: 100%;
        height: auto;
        border-radius: 4px;
    }

    .task-list-item {
        list-style: none;
        margin-left: -1.5em;
    }
    .task-list-item input[type="checkbox"] {
        margin-right: 0.5em;
        vertical-align: middle;
    }

    .find-highlight {
        background-color: #fff3a8;
        border-radius: 2px;
        padding: 0 1px;
    }
    .find-highlight.find-current {
        background-color: #ff9632;
        color: #fff;
    }

    .mermaid-container {
        display: flex;
        justify-content: center;
        margin-bottom: 16px;
        overflow: auto;
    }
    .mermaid-container svg {
        max-width: 100%;
        height: auto;
    }

    #loading {
        display: flex;
        align-items: center;
        justify-content: center;
        height: 100vh;
        color: #59636e;
        font-size: 14px;
    }

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
        .find-highlight { background-color: #625a2e; color: #e6edf3; }
        .find-highlight.find-current { background-color: #c47616; color: #fff; }
    }
    </style>
    </head>
    <body>
    <div id="loading">Loading renderer…</div>
    <div id="content" style="display:none;"></div>

    <script src="marked.min.js"></script>
    <script src="highlight.min.js"></script>
    <script src="mermaid.min.js"></script>
    <script>
    (function() {
        marked.setOptions({ gfm: true, breaks: false });

        var isDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
        mermaid.initialize({
            startOnLoad: false,
            theme: isDark ? 'dark' : 'default',
            securityLevel: 'strict'
        });

        window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', function(e) {
            isDark = e.matches;
            mermaid.initialize({
                startOnLoad: false,
                theme: isDark ? 'dark' : 'default',
                securityLevel: 'strict'
            });
        });

        var _mermaidId = 0;
        const content = document.getElementById('content');
        const loading = document.getElementById('loading');

        function show() {
            loading.style.display = 'none';
            content.style.display = 'block';
        }

        var _baseDir = '';

        window.setBaseDir = function(dir) {
            _baseDir = dir;
        };

        // Mermaid strict mode doesn't support backslash-n for line breaks
        // in labels. Replace them with <br/> tags on each source line,
        // preserving real newlines that separate diagram statements.
        function mermaidNewlines(src) {
            var lines = src.split('\\n');
            for (var i = 0; i < lines.length; i++) {
                lines[i] = lines[i].replace(/\\\\n/g, '<br/>');
            }
            return lines.join('\\n');
        }

        async function renderMermaidBlocks() {
            var blocks = content.querySelectorAll('pre code.language-mermaid');
            for (var i = 0; i < blocks.length; i++) {
                var block = blocks[i];
                var pre = block.parentElement;
                var source = mermaidNewlines(block.textContent);
                try {
                    var id = 'mermaid-' + (++_mermaidId);
                    var result = await mermaid.render(id, source);
                    var container = document.createElement('div');
                    container.className = 'mermaid-container';
                    container.innerHTML = result.svg;
                    pre.replaceWith(container);
                } catch (e) {
                    pre.classList.add('mermaid-error');
                }
            }
        }

        window.renderBase64 = function(b64) {
            const bytes = Uint8Array.from(atob(b64), c => c.charCodeAt(0));
            const text  = new TextDecoder('utf-8').decode(bytes);

            const scrollY = window.scrollY;
            content.innerHTML = marked.parse(text);

            if (_baseDir) {
                content.querySelectorAll('img').forEach(function(img) {
                    var src = img.getAttribute('src');
                    if (src && !src.match(/^(https?:|data:|file:)/i) && !src.startsWith('//')) {
                        img.src = _baseDir + '/' + src;
                    }
                });
            }

            content.querySelectorAll('pre code').forEach(function(block) {
                if (!block.classList.contains('language-mermaid')) {
                    hljs.highlightElement(block);
                }
            });

            renderMermaidBlocks();

            content.querySelectorAll('input[type="checkbox"]').forEach(function(cb) {
                cb.disabled = true;
            });

            show();
            window.scrollTo(0, scrollY);

            if (_findQuery) findInPage(_findQuery);
        };

        /* ---- Find-in-page ---- */
        var _findMarks = [];
        var _findIndex = -1;
        var _findQuery = '';

        function clearFindMarks() {
            for (var i = 0; i < _findMarks.length; i++) {
                var mark = _findMarks[i];
                var parent = mark.parentNode;
                if (parent) {
                    parent.replaceChild(document.createTextNode(mark.textContent), mark);
                    parent.normalize();
                }
            }
            _findMarks = [];
            _findIndex = -1;
        }

        function updateCurrentHighlight() {
            for (var i = 0; i < _findMarks.length; i++) {
                _findMarks[i].className = (i === _findIndex) ? 'find-highlight find-current' : 'find-highlight';
            }
            if (_findIndex >= 0 && _findIndex < _findMarks.length) {
                _findMarks[_findIndex].scrollIntoView({ behavior: 'smooth', block: 'center' });
            }
        }

        function result() {
            return JSON.stringify({ total: _findMarks.length, current: _findIndex });
        }

        window.findInPage = function(query) {
            clearFindMarks();
            _findQuery = query || '';
            if (!_findQuery) return result();

            var walker = document.createTreeWalker(content, NodeFilter.SHOW_TEXT, null);
            var nodes = [];
            while (walker.nextNode()) nodes.push(walker.currentNode);

            var lower = _findQuery.toLowerCase();
            for (var i = 0; i < nodes.length; i++) {
                var node = nodes[i];
                var text = node.textContent;
                var lt = text.toLowerCase();
                var pos = 0, frags = [], last = 0;
                while ((pos = lt.indexOf(lower, pos)) !== -1) {
                    if (pos > last) frags.push(document.createTextNode(text.substring(last, pos)));
                    var mark = document.createElement('mark');
                    mark.className = 'find-highlight';
                    mark.textContent = text.substring(pos, pos + _findQuery.length);
                    frags.push(mark);
                    _findMarks.push(mark);
                    last = pos + _findQuery.length;
                    pos = last;
                }
                if (frags.length > 0) {
                    if (last < text.length) frags.push(document.createTextNode(text.substring(last)));
                    var parent = node.parentNode;
                    for (var j = 0; j < frags.length; j++) parent.insertBefore(frags[j], node);
                    parent.removeChild(node);
                }
            }
            _findIndex = _findMarks.length > 0 ? 0 : -1;
            updateCurrentHighlight();
            return result();
        };

        window.findNext = function() {
            if (_findMarks.length === 0) return result();
            _findIndex = (_findIndex + 1) % _findMarks.length;
            updateCurrentHighlight();
            return result();
        };

        window.findPrev = function() {
            if (_findMarks.length === 0) return result();
            _findIndex = (_findIndex - 1 + _findMarks.length) % _findMarks.length;
            updateCurrentHighlight();
            return result();
        };

        window.clearFind = function() {
            _findQuery = '';
            clearFindMarks();
            return result();
        };
    })();
    </script>
    </body>
    </html>
    """
}
