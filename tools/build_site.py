#!/usr/bin/env python3
"""Render docs/*.md into the static site under docs/site/pages/.

Single source of truth: the markdown in docs/. The landing page
(docs/site/index.html) is hand-written marketing; everything under
pages/ is generated and must never be edited by hand.

Usage:
    python3 tools/build_site.py            # regenerate pages + css
    python3 tools/build_site.py --check    # fail if output is stale (CI)

Requires: python3 -m pip install markdown
"""

from __future__ import annotations

import json
import os
import re
import sys
from pathlib import Path

try:
    import markdown
except ImportError:  # pragma: no cover - guidance path
    sys.exit(
        "build_site.py needs the 'markdown' package:\n"
        "  python3 -m pip install --user markdown\n"
        "  # or: nix shell nixpkgs#python3Packages.markdown -c python3 tools/build_site.py"
    )

ROOT = Path(__file__).resolve().parent.parent
DOCS = ROOT / "docs"
SITE = DOCS / "site"
PAGES = SITE / "pages"
ASSETS = SITE / "assets"
MANIFEST = SITE / "site.json"

MD_EXTENSIONS = ["tables", "fenced_code", "sane_lists", "toc", "attr_list"]

CSS = """\
:root{--paper:#f6f5f1;--paper2:#ebebe7;--ink:#111110;--muted:#6b6b68;--border:#dbdbd6;--accent:#0f6f6f;--accent2:#0a5858}
*{box-sizing:border-box;margin:0;padding:0}
html{scroll-behavior:smooth}
body{font-family:'Plus Jakarta Sans',system-ui,sans-serif;background:var(--paper);color:var(--ink);line-height:1.65}
a{color:var(--accent);text-decoration:none}a:hover{text-decoration:underline}
a:focus-visible{outline:2px solid var(--accent);outline-offset:2px}
.mono,code,pre{font-family:'JetBrains Mono',ui-monospace,monospace}
.serif{font-family:'Newsreader',Georgia,serif}
.wrap{display:grid;grid-template-columns:minmax(0,1fr) 260px;gap:40px;max-width:1120px;margin:0 auto;padding:0 32px 64px}
@media(max-width:900px){.wrap{grid-template-columns:1fr}}
header.top{max-width:1120px;margin:0 auto;padding:24px 32px;display:flex;justify-content:space-between;align-items:baseline;gap:16px;border-bottom:1px solid var(--border)}
header.top .crumbs{font-size:11px;letter-spacing:.1em;text-transform:uppercase;color:var(--muted)}
header.top a.home{font-size:12px;letter-spacing:.08em;text-transform:uppercase}
main{padding-top:32px;min-width:0}
main h1.serif{font-size:2rem;line-height:1.2;margin:0 0 12px}
main h2{font-size:1.25rem;margin:36px 0 12px;padding-top:8px;border-top:1px solid var(--border)}
main h3{font-size:.78rem;letter-spacing:.1em;text-transform:uppercase;color:var(--muted);margin:26px 0 10px}
main h4{font-size:.95rem;margin:20px 0 8px}
main p{margin:10px 0}
main ul,main ol{margin:10px 0 10px 22px}
main li{margin:5px 0}
main code{background:var(--paper2);border:1px solid var(--border);padding:1px 5px;font-size:.86em}
main pre{background:#fff;border:1px solid var(--border);padding:14px 44px 14px 14px;overflow:auto;font-size:12px;line-height:1.7;margin:12px 0;position:relative}
main pre code{background:none;border:none;padding:0;font-size:inherit}
main blockquote{border-left:2px solid var(--accent);background:#fff;padding:10px 16px;margin:14px 0;color:var(--muted)}
main blockquote p{margin:4px 0}
main table{border-collapse:collapse;width:100%;margin:14px 0;font-size:13px;background:#fff;display:block;overflow-x:auto}
main th,main td{border:1px solid var(--border);padding:8px 10px;text-align:left;vertical-align:top}
main th{background:var(--paper2);font-size:11px;letter-spacing:.06em;text-transform:uppercase;color:var(--muted);white-space:nowrap}
main hr{border:none;border-top:1px solid var(--border);margin:28px 0}
main img{max-width:100%;height:auto}
aside.toc{position:sticky;top:24px;align-self:start;padding-top:36px;font-size:12px}
aside.toc b{display:block;font-size:10px;letter-spacing:.12em;text-transform:uppercase;color:var(--muted);margin-bottom:10px}
aside.toc ul{list-style:none;margin:0;padding:0}
aside.toc li{margin:6px 0;line-height:1.35}
aside.toc li.sub{padding-left:12px;font-size:11px;color:var(--muted)}
.copy-btn{position:absolute;top:6px;right:6px;padding:3px 7px;font-size:10px;letter-spacing:.06em;text-transform:uppercase;border:1px solid var(--border);background:var(--paper);color:var(--ink);cursor:pointer}
.copy-btn:active{transform:translateY(1px)}
footer.foot{border-top:1px solid var(--border);margin-top:32px;padding:24px 32px;text-align:center;font-size:11px;color:var(--muted)}
footer.foot nav{display:flex;gap:16px;justify-content:center;flex-wrap:wrap;margin-bottom:8px}
"""

COPY_JS = """<script>
document.querySelectorAll("main pre").forEach(function(el){
  var b=document.createElement("button");
  b.className="mono copy-btn";b.textContent="copy";
  b.setAttribute("aria-label","Copy code");
  b.onclick=function(){
    navigator.clipboard.writeText(el.querySelector("code")?el.querySelector("code").innerText:el.innerText)
      .then(function(){b.textContent="copied";setTimeout(function(){b.textContent="copy";},1200);});
  };
  el.appendChild(b);
});
</script>"""


def render_markdown(text: str) -> tuple[str, list[tuple[str, str]]]:
    """Return (html, [ (anchor, title) ] for the sidebar)."""
    md = markdown.Markdown(extensions=MD_EXTENSIONS, output_format="html5")
    html = md.convert(text)
    entries: list[tuple[str, str]] = []
    for token in md.toc_tokens:
        children = token["children"] if token["level"] == 1 else [token]
        for child in children:
            entries.append((child["id"], strip_tags(child["name"])))
    return html, entries


def strip_tags(value: str) -> str:
    return re.sub(r"<[^>]+>", "", value).strip()


def rewrite_links(html: str) -> str:
    """Point intra-docs markdown links at the generated pages."""
    return re.sub(r'href="([^"#]+)\.md(#[^"]*)?"', _to_html_link, html)


def _to_html_link(match: re.Match[str]) -> str:
    target, anchor = match.group(1), match.group(2) or ""
    name = os.path.basename(target)
    slug = NAME_MAP.get(name) or NAME_MAP.get(f"{name}.md")
    if slug:
        return f'href="{slug}.html{anchor}"'
    return match.group(0)


DEFAULT_BASE_URL = "https://1999azzar.github.io/ghost-machines"


def sitemap(pages: list[dict], base_url: str) -> str:
    urls = [f"{base_url}/index.html"] + [f"{base_url}/pages/{entry['slug']}.html" for entry in pages]
    body = "".join(f"  <url><loc>{url}</loc></url>\n" for url in urls)
    return f"""<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
{body}</urlset>
"""


def robots(base_url: str) -> str:
    return f"User-agent: *\nAllow: /\nSitemap: {base_url}/sitemap.xml\n"


def page_html(entry: dict, body: str, toc: list[tuple[str, str]], prev: dict | None, nxt: dict | None) -> str:
    toc_html = "".join(f'<li><a href="#{anchor}">{title}</a></li>' for anchor, title in toc[:24])
    nav_prev = f'<a href="{prev["slug"]}.html">← {prev["title"]}</a>' if prev else ""
    nav_next = f'<a href="{nxt["slug"]}.html">{nxt["title"]} →</a>' if nxt else ""
    return f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>{entry['title']} — Ghost Machines</title>
<meta name="description" content="{entry['description']}">
<link rel="icon" href="../favicon.png" type="image/png">
<link rel="manifest" href="../manifest.json">
<link href="https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;500&family=Plus+Jakarta+Sans:wght@400;500;600;700&family=Newsreader:opsz,wght@6..72,600&display=swap" rel="stylesheet">
<link rel="stylesheet" href="../assets/site.css">
</head>
<body>
<header class="top">
  <span class="crumbs mono">GHOST_MACHINES · {entry['title'].upper()}</span>
  <a class="home mono" href="../index.html">← index</a>
</header>
<div class="wrap">
  <main>
{body}
  </main>
  <aside class="toc mono">
    <b>On this page</b>
    <ul>{toc_html}</ul>
  </aside>
</div>
<footer class="foot mono">
  <nav>{nav_prev}{nav_next}<a href="../index.html">index</a></nav>
  Generated from <code>docs/{entry['source']}</code> · edit the markdown, not this file · MIT
</footer>
{COPY_JS}
</body>
</html>
"""


def main() -> int:
    check = "--check" in sys.argv[1:]
    manifest = json.loads(MANIFEST.read_text())

    global NAME_MAP
    NAME_MAP = {entry["source"]: entry["slug"] for entry in manifest["pages"]}

    ASSETS.mkdir(parents=True, exist_ok=True)
    PAGES.mkdir(parents=True, exist_ok=True)

    pages = manifest["pages"]
    base_url = manifest.get("base_url", DEFAULT_BASE_URL).rstrip("/")
    outputs: dict[Path, str] = {
        ASSETS / "site.css": CSS,
        SITE / "sitemap.xml": sitemap(pages, base_url),
        SITE / "robots.txt": robots(base_url),
    }
    if manifest.get("cname"):
        outputs[SITE / "CNAME"] = f"{manifest['cname']}\n"
    for index, entry in enumerate(pages):
        source = DOCS / entry["source"]
        if not source.exists():
            sys.exit(f"missing source: {source}")
        body, toc = render_markdown(source.read_text())
        body = rewrite_links(body)
        outputs[PAGES / f"{entry['slug']}.html"] = page_html(
            entry,
            body,
            toc,
            pages[index - 1] if index > 0 else None,
            pages[index + 1] if index + 1 < len(pages) else None,
        )

    stale = []
    for path, content in outputs.items():
        current = path.read_text() if path.exists() else ""
        if current != content:
            stale.append(path)
            path.write_text(content)

    relative = [str(p.relative_to(ROOT)) for p in stale]
    if check:
        if relative:
            print("Site is stale; regenerate with `make docs`.\n  " + "\n  ".join(relative))
            return 1
        print(f"[OK] {len(outputs)} generated files are current")
        return 0

    print(f"[OK] wrote {len(outputs)} files ({len(relative)} changed)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
