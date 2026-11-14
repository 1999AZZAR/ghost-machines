#!/usr/bin/env python3
"""Render docs/*.md into the static site under docs/site/.

Layout and navigation follow the hela.my.id documentation shell; colours and
content are Ghost Machines'. Single source of truth: markdown in docs/.
Everything under docs/site/ except assets/site.css is generated — do not edit
by hand.

Usage:
    python3 tools/build_site.py            # regenerate the site
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
MANIFEST = SITE / "site.json"

MD_EXTENSIONS = ["tables", "fenced_code", "sane_lists", "toc", "attr_list"]
DEFAULT_BASE_URL = "https://1999azzar.github.io/ghost-machines"

APP_JS = """<script>
(function () {
  var dataEl = document.getElementById("search-index");
  var index = dataEl ? JSON.parse(dataEl.textContent) : [];
  var palette = document.getElementById("cmdPalette");
  var input = document.getElementById("cmdInput");
  var results = document.getElementById("cmdResults");
  var active = -1;

  function esc(value) {
    return String(value).replace(/[&<>"]/g, function (c) {
      return { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[c];
    });
  }

  function render(items) {
    active = -1;
    if (!items.length) {
      results.innerHTML = '<div class="cmd-empty">no matches</div>';
      return;
    }
    results.innerHTML = items.map(function (item) {
      return '<a class="cmd-item" href="' + item.u + '">' +
        '<span>' + esc(item.t) + (item.p ? ' <span class="cmd-item-tag">' + esc(item.p) + '</span>' : '') + '</span>' +
        '<span class="cmd-item-tag">' + item.k + '</span></a>';
    }).join("");
  }

  function filter() {
    var q = input.value.trim().toLowerCase();
    var hits = !q ? index.filter(function (i) { return i.k === "page"; })
      : index.filter(function (i) { return i.t.toLowerCase().indexOf(q) !== -1; });
    render(hits.slice(0, 24));
  }

  function openPalette() {
    palette.style.display = "flex";
    input.value = "";
    filter();
    input.focus();
  }

  function closePalette() {
    palette.style.display = "none";
  }

  function move(delta) {
    var items = results.querySelectorAll(".cmd-item");
    if (!items.length) return;
    active = (active + delta + items.length) % items.length;
    items.forEach(function (el, i) { el.classList.toggle("is-active", i === active); });
    items[active].scrollIntoView({ block: "nearest" });
  }

  document.querySelectorAll(".open-cmd-palette").forEach(function (btn) {
    btn.addEventListener("click", openPalette);
  });
  palette.addEventListener("click", function (event) {
    if (event.target === palette) closePalette();
  });
  input.addEventListener("input", filter);
  input.addEventListener("keydown", function (event) {
    if (event.key === "ArrowDown") { event.preventDefault(); move(1); }
    else if (event.key === "ArrowUp") { event.preventDefault(); move(-1); }
    else if (event.key === "Enter") {
      var current = results.querySelectorAll(".cmd-item")[active] ||
        results.querySelector(".cmd-item");
      if (current) window.location.href = current.getAttribute("href");
    } else if (event.key === "Escape") closePalette();
  });
  document.addEventListener("keydown", function (event) {
    if ((event.metaKey || event.ctrlKey) && event.key.toLowerCase() === "k") {
      event.preventDefault();
      palette.style.display === "flex" ? closePalette() : openPalette();
    } else if (event.key === "Escape") {
      closePalette();
    }
  });

  document.querySelectorAll(".doc-nav a").forEach(function (link) {
    link.addEventListener("click", function () {
      var drawer = document.querySelector(".doc-mobile-nav");
      if (drawer) drawer.open = false;
    });
  });

  document.querySelectorAll(".doc-content pre").forEach(function (el) {
    var b = document.createElement("button");
    b.className = "copy-btn";
    b.textContent = "copy";
    b.setAttribute("aria-label", "Copy code");
    b.addEventListener("click", function () {
      var code = el.querySelector("code");
      navigator.clipboard.writeText(code ? code.innerText : el.innerText).then(function () {
        b.textContent = "copied";
        setTimeout(function () { b.textContent = "copy"; }, 1200);
      });
    });
    el.appendChild(b);
  });

  var tocLinks = Array.prototype.slice.call(document.querySelectorAll('#tocList a[href^="#"]'));
  var heads = tocLinks.map(function (a) {
    return document.getElementById(a.getAttribute("href").slice(1));
  }).filter(Boolean);
  if ("IntersectionObserver" in window && heads.length) {
    var observer = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        if (!entry.isIntersecting) return;
        tocLinks.forEach(function (a) {
          a.classList.toggle("is-active", a.getAttribute("href") === "#" + entry.target.id);
        });
      });
    }, { rootMargin: "-20% 0px -70% 0px" });
    heads.forEach(function (h) { observer.observe(h); });
  }
})();
</script>"""


def strip_tags(value: str) -> str:
    return re.sub(r"<[^>]+>", "", value).strip()


def render_markdown(text: str) -> tuple[str, list[tuple[str, str, int]]]:
    """Return (html without the leading H1, [(anchor, title, level)])."""
    md = markdown.Markdown(extensions=MD_EXTENSIONS, output_format="html5")
    html = md.convert(text)
    html = re.sub(r"<h1[^>]*>.*?</h1>\s*", "", html, count=1, flags=re.S)

    entries: list[tuple[str, str, int]] = []
    for token in md.toc_tokens:
        children = token["children"] if token["level"] == 1 else [token]
        for child in children:
            if child["level"] > 3:
                continue
            entries.append((child["id"], strip_tags(child["name"]), child["level"]))
            for grandchild in child["children"]:
                if grandchild["level"] <= 3:
                    entries.append((grandchild["id"], strip_tags(grandchild["name"]), grandchild["level"]))
    return html, entries


def rewrite_links(html: str, prefix: str = "") -> str:
    def to_html(match: re.Match[str]) -> str:
        target, anchor = match.group(1), match.group(2) or ""
        name = os.path.basename(target)
        slug = NAME_MAP.get(name) or NAME_MAP.get(f"{name}.md")
        return f'href="{prefix}{slug}.html{anchor}"' if slug else match.group(0)

    return re.sub(r'href="([^"#]+)\.md(#[^"]*)?"', to_html, html)


def toc_html(entries: list[tuple[str, str, int]]) -> str:
    out, h2 = [], 0
    for anchor, title, level in entries:
        if level == 2:
            h2 += 1
            out.append(f'<li><a href="#{anchor}">'
                       f'<span class="doc-nav-num">{h2:02d}</span> {title}</a></li>')
        else:
            out.append(f'<li class="toc-sub"><a href="#{anchor}">{h2}.{len(out)} {title}</a></li>')
    return "".join(out)


def nav_html(active: str, rel_pages: str, rel_root: str, is_home: bool) -> str:
    groups: list[tuple[str, list[dict]]] = []
    for entry in PAGE_LIST:
        if not groups or groups[-1][0] != entry["group"]:
            groups.append((entry["group"], []))
        groups[-1][1].append(entry)

    home_current = ' aria-current="page"' if is_home else ""
    chunks = [
        '<div class="doc-nav-section">OVERVIEW</div>',
        '<ol class="doc-nav" start="0">',
        f'<li><a href="{rel_root}index.html"{home_current}>'
        '<span class="doc-nav-num">00</span> <span>Overview</span></a></li>',
        "</ol>",
    ]
    number = 1
    for title, entries in groups:
        chunks.append(f'<div class="doc-nav-section">{title}</div>')
        chunks.append(f'<ol class="doc-nav" start="{number}">')
        for entry in entries:
            current = ' aria-current="page"' if entry["slug"] == active else ""
            chunks.append(
                f'<li><a href="{rel_pages}{entry["slug"]}.html"{current}>'
                f'<span class="doc-nav-num">{number:02d}</span> '
                f'<span>{entry["nav_title"]}</span></a></li>'
            )
            number += 1
        chunks.append("</ol>")
    return "".join(chunks)


def search_index(rel_pages: str) -> str:
    items = [{"t": HOME["title"], "u": f"{rel_pages}index.html", "k": "page"}]
    for entry in PAGE_LIST:
        items.append({"t": entry["title"], "u": f"{rel_pages}{entry['slug']}.html", "k": "page"})
    for entry in PAGE_LIST:
        source = (DOCS / entry["source"]).read_text()
        _, entries = render_markdown(source)
        for anchor, title, _level in entries:
            items.append({
                "t": title,
                "u": f"{rel_pages}{entry['slug']}.html#{anchor}",
                "k": "section",
                "p": entry["nav_title"],
            })
    payload = json.dumps(items, separators=(",", ":")).replace("<", "\\u003c")
    return f'<script type="application/json" id="search-index">{payload}</script>'


def page_html(entry: dict, body: str, toc: list[tuple[str, str, int]], is_home: bool) -> str:
    rel_root = "" if is_home else "../"
    rel_pages = "pages/" if is_home else ""
    number = 0 if is_home else next((i for i, p in enumerate(PAGE_LIST, 1) if p["slug"] == entry["slug"]), 0)
    spec = "SPEC_00 // GHOST-MACHINES" if is_home else f"DOC_{number:02d} // GHOST-MACHINES"
    dossier = "OVERVIEW" if is_home else entry["slug"].upper().replace("-", "_")
    html = rewrite_links(body, "pages/" if is_home else "")

    return f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>{entry['title']} — {BRAND}</title>
<meta name="description" content="{entry['description']}">
<link rel="icon" href="{rel_root}favicon.png" type="image/png">
<link rel="manifest" href="{rel_root}manifest.json">
<link href="https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;500;700&family=Plus+Jakarta+Sans:wght@400;500;700;800&display=swap" rel="stylesheet">
<link rel="stylesheet" href="{rel_root}assets/site.css">
</head>
<body>
<a href="#main-content" class="skip-link">Skip to main content</a>
<div class="doc-shell">
  <aside class="doc-sidebar" aria-label="Documentation sections">
    <div class="doc-brand">
      <a href="{rel_root}index.html" class="doc-brand-title">{BRAND}</a>
      <div class="doc-brand-meta">{META}</div>
    </div>
    <nav aria-label="Documentation">
      <details class="doc-mobile-nav" open>
        <summary>Browse documentation</summary>
        {nav_html(entry['slug'], rel_pages, rel_root, is_home)}
      </details>
    </nav>
  </aside>
  <div class="doc-main">
    <div class="doc-topbar">
      <span class="doc-topbar-title">{spec}</span>
      <div class="topbar-actions">
        <button class="btn open-cmd-palette" type="button">Search ⌘K</button>
        <a class="btn" href="{REPO}" target="_blank" rel="noopener noreferrer">GitHub</a>
      </div>
    </div>
    <main id="main-content" class="doc-content">
      <header class="specimen-plate">
        <div class="specimen-ref"><span>{spec}</span><span>DOSSIER: {dossier}</span></div>
        <h1 class="doc-title">{entry['title']}</h1>
        <p class="doc-lead">{entry['description']}</p>
      </header>
{html}
      <footer class="doc-footer">
        <span>MIT LICENSE · AZZAR</span>
        <span>ARCHIVAL_RECORD_SEALED // GHOST_MACHINES</span>
      </footer>
    </main>
    <nav class="doc-toc" aria-label="On this page">
      <div class="doc-toc-title">ON THIS PAGE</div>
      <ol id="tocList">{toc_html(toc)}</ol>
    </nav>
  </div>
</div>

<div class="cmd-backdrop" id="cmdPalette" role="dialog" aria-label="Search documentation">
  <div class="cmd-modal">
    <div class="cmd-input-row">
      <span aria-hidden="true">§</span>
      <input type="text" class="cmd-input" id="cmdInput" aria-label="Search pages and sections" placeholder="Search pages and sections…">
      <span class="cmd-item-tag">ESC</span>
    </div>
    <div class="cmd-results" id="cmdResults"></div>
  </div>
</div>
{search_index(rel_pages)}
{APP_JS}
</body>
</html>
"""


def sitemap(pages: list[dict], base_url: str) -> str:
    urls = [f"{base_url}/index.html"] + [f"{base_url}/pages/{entry['slug']}.html" for entry in pages]
    body = "".join(f"  <url><loc>{url}</loc></url>\n" for url in urls)
    return f"""<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
{body}</urlset>
"""


def robots(base_url: str) -> str:
    return f"User-agent: *\nAllow: /\nSitemap: {base_url}/sitemap.xml\n"


def main() -> int:
    check = "--check" in sys.argv[1:]
    manifest = json.loads(MANIFEST.read_text())

    global NAME_MAP, PAGE_LIST, HOME, BRAND, META, REPO
    BRAND = manifest.get("brand", "Ghost Machines")
    META = manifest.get("meta", "")
    REPO = manifest.get("repo", "https://github.com/1999AZZAR/ghost-machines")
    HOME = manifest["home"]
    PAGE_LIST = manifest["pages"]
    NAME_MAP = {entry["source"]: entry["slug"] for entry in PAGE_LIST}

    pages = PAGE_LIST
    base_url = manifest.get("base_url", DEFAULT_BASE_URL).rstrip("/")
    outputs: dict[Path, str] = {
        SITE / "sitemap.xml": sitemap(pages, base_url),
        SITE / "robots.txt": robots(base_url),
    }
    if manifest.get("cname"):
        outputs[SITE / "CNAME"] = f"{manifest['cname']}\n"

    PAGES.mkdir(parents=True, exist_ok=True)
    for entry in pages:
        source = DOCS / entry["source"]
        if not source.exists():
            sys.exit(f"missing source: {source}")
        body, toc = render_markdown(source.read_text())
        outputs[PAGES / f"{entry['slug']}.html"] = page_html(entry, body, toc, False)

    home_source = DOCS / HOME["source"]
    if not home_source.exists():
        sys.exit(f"missing source: {home_source}")
    home_body, home_toc = render_markdown(home_source.read_text())
    home_entry = {
        "slug": "index",
        "source": HOME["source"],
        "title": HOME["title"],
        "description": HOME["description"],
    }
    outputs[SITE / "index.html"] = page_html(home_entry, home_body, home_toc, True)

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
