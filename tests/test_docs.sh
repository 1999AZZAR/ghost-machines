#!/bin/bash
# Test Suite: Documentation integrity (links, examples, facts, generated site)

set -e

echo "=================================================="
echo "RUNNING DOCUMENTATION INTEGRITY CHECKS"
echo "=================================================="

# Test 1: Relative links and in-page anchors resolve
echo -n "[DOCS 1] Markdown links and anchors... "
python3 - <<'PY'
import pathlib, re, sys

def slug(heading: str) -> str:
    text = heading.strip().lower()
    text = re.sub(r"[^\w\s-]", "", text)
    return text.replace(" ", "-")

root = pathlib.Path(".")
files = [pathlib.Path("README.md")] + sorted(pathlib.Path("docs").glob("*.md"))
problems = []

for path in files:
    body = path.read_text()
    heads = {slug(m.group(2)) for m in re.finditer(r"^(#{1,6})\s+(.*)$", body, re.M)}
    for match in re.finditer(r"\[[^\]]+\]\(([^)]+)\)", body):
        target = match.group(1).strip()
        if target.startswith(("http://", "https://", "mailto:")):
            continue
        file_part, _, anchor = target.partition("#")
        if file_part:
            if not (path.parent / file_part).resolve().exists():
                problems.append(f"{path}: missing file {target}")
        elif anchor and anchor not in heads:
            problems.append(f"{path}: dead anchor {target}")

if problems:
    print("\n".join(problems))
    sys.exit(1)
PY
echo "PASSED"

# Test 2: Bash examples in the docs parse
echo -n "[DOCS 2] Fenced bash examples parse (bash -n)... "
python3 - <<'PY'
import pathlib, re, subprocess, sys, tempfile

blocks, checked = [], 0
files = [pathlib.Path("README.md")] + sorted(pathlib.Path("docs").glob("*.md"))
for path in files:
    text = path.read_text()
    for match in re.finditer(r"```bash\n(.*?)```", text, re.S):
        blocks.append((path, match.group(1)))

for path, code in blocks:
    if "…" in code or "<container>" in code:
        continue  # illustrative excerpt, not a runnable block
    with tempfile.NamedTemporaryFile("w", suffix=".sh", delete=False) as handle:
        handle.write(code)
        name = handle.name
    result = subprocess.run(["bash", "-n", name], capture_output=True, text=True)
    if result.returncode != 0:
        print(f"\n{path}: invalid bash example:\n{result.stderr}")
        sys.exit(1)
    checked += 1

print(f"({checked} blocks)", end=" ")
PY
echo "PASSED"

# Test 3: Every .env.example variable is documented
echo -n "[DOCS 3] Env vars in .env.example documented in docs/configuration.md... "
MISSING=""
while IFS= read -r KEY; do
    [ -n "$KEY" ] || continue
    grep -q "$KEY" docs/configuration.md || MISSING="$MISSING $KEY"
done < <(grep -E '^[A-Z0-9_]+=' .env.example | cut -d= -f1)
if [ -n "$MISSING" ]; then
    echo "FAILED: undocumented vars:$MISSING"
    exit 1
fi
echo "PASSED"

# Test 4: Documentation facts match the code
echo -n "[DOCS 4] Doc claims vs code (ports, engines, suites, harnesses)... "
for ENGINE in ubuntu debian alpine arch; do
    grep -q "$ENGINE" docs/engines.md || { echo "FAILED: engines.md missing $ENGINE"; exit 1; }
    grep -q "    $ENGINE)" start.sh || { echo "FAILED: start.sh has no $ENGINE case"; exit 1; }
done
for DOCKERFILE in $(grep -oE 'Dockerfile(\.[a-z]+)?' docs/engines.md | sort -u); do
    [ -f "$DOCKERFILE" ] || { echo "FAILED: docs reference missing $DOCKERFILE"; exit 1; }
done
grep -q "G1_PORT:-2223" docker-compose.yml
grep -q "2223" docs/connecting.md || { echo "FAILED: docs lose the default port"; exit 1; }
grep -q "2224" docs/connecting.md || { echo "FAILED: docs lose the dual port"; exit 1; }
for SUITE in $(grep -oE 'test_[a-z0-9_]+\.sh' tests/run_all.sh | sort -u); do
    grep -q "$SUITE" docs/contributing.md || { echo "FAILED: contributing.md omits $SUITE"; exit 1; }
done
for FLAG in --nuke --hard --dry-run --keep-cache; do
    grep -q -- "$FLAG" clean.sh || { echo "FAILED: clean.sh lacks $FLAG"; exit 1; }
    grep -q -- "$FLAG" docs/lifecycle.md || { echo "FAILED: lifecycle.md does not document $FLAG"; exit 1; }
done
for URL in https://opencode.ai/v2/install https://antigravity.google/cli/install.sh https://github.com/rtk-ai/rtk/releases/latest/download; do
    grep -q "$URL" harness-update.sh
    grep -q "$URL" docs/images.md || { echo "FAILED: images.md omits $URL"; exit 1; }
done
echo "PASSED"

# Test 5: No known stale claims
echo -n "[DOCS 5] Stale claim guard... "
if grep -rq "aarch64 runner" README.md docs/*.md; then
    echo "FAILED: docs claim a multi-arch CI matrix that does not exist"
    exit 1
fi
if grep -rq "Node.js 22" README.md docs/*.md; then
    echo "FAILED: docs pin Node.js 22 while the image uses the current channel"
    exit 1
fi
echo "PASSED"

# Test 6: Generated site is current and its landing links resolve
echo -n "[DOCS 6] Generated site freshness and landing links... "
if python3 -c "import markdown" >/dev/null 2>&1; then
    python3 tools/build_site.py --check > /dev/null || {
        echo "FAILED: docs/site is stale — run 'make docs'"
        exit 1
    }
    python3 - <<'PY'
import pathlib, re, sys

broken = []
pages = [pathlib.Path("docs/site/index.html")] + sorted(pathlib.Path("docs/site/pages").glob("*.html"))
for page in pages:
    for href in re.findall(r'href="([^"]+)"', page.read_text()):
        if href.startswith(("http", "mailto:", "#")):
            continue
        target_part, _, anchor = href.partition("#")
        target = (page.parent / target_part).resolve() if target_part else page
        if not target.exists():
            broken.append(f"{page.name}: {href}")
        elif anchor and f'id="{anchor}"' not in target.read_text():
            broken.append(f"{page.name}: dead anchor {href}")
if broken:
    print("\nbroken links: " + ", ".join(broken))
    sys.exit(1)
PY
else
    echo -n "(markdown module missing, freshness skipped) "
fi
echo "PASSED"

# Test 7: Pages deployment wiring and generated metadata
echo -n "[DOCS 7] Pages workflow and generated metadata... "
[ -f .github/workflows/pages.yml ] || { echo "FAILED: no pages workflow"; exit 1; }
grep -q "tools/build_site.py" .github/workflows/pages.yml || { echo "FAILED: workflow does not render the site"; exit 1; }
grep -q "gh-pages" .github/workflows/pages.yml || { echo "FAILED: workflow does not publish to gh-pages"; exit 1; }
grep -q "tests/test_docs.sh" .github/workflows/pages.yml || { echo "FAILED: workflow publishes without verification"; exit 1; }
python3 - <<'CHECK'
import json, pathlib, sys
manifest = json.loads(pathlib.Path("docs/site/site.json").read_text())
base = manifest.get("base_url", "").rstrip("/")
cname = manifest.get("cname", "")
problems = []
if not base:
    problems.append("site.json has no base_url")
if cname and pathlib.Path("docs/site/CNAME").read_text().strip() != cname:
    problems.append("docs/site/CNAME does not match site.json cname")
if base and f"Sitemap: {base}/sitemap.xml" not in pathlib.Path("docs/site/robots.txt").read_text():
    problems.append("robots.txt Sitemap does not use base_url")
sitemap = pathlib.Path("docs/site/sitemap.xml").read_text()
if base and f"<loc>{base}/index.html</loc>" not in sitemap:
    problems.append("sitemap.xml does not use base_url")
if problems:
    print("\n".join(problems))
    sys.exit(1)
CHECK
echo "PASSED"

# Test 8: Site builder is syntactically valid
echo -n "[DOCS 8] Site builder compiles... "
PYTHONPYCACHEPREFIX="$(mktemp -d)" python3 -m py_compile tools/build_site.py || { echo "FAILED: tools/build_site.py"; exit 1; }
echo "PASSED"

echo "=================================================="
echo "ALL DOCUMENTATION CHECKS PASSED!"
echo "=================================================="
