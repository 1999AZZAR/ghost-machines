# Spec — Premium Swiss-Archival Docs Site

## Overview
Build a premium multi-page Swiss-Archival documentation website at `docs/site/` that markets Ghost Machines and serves as the source of truth. Must fix crowdedness, provide beginner/casual two-level reading, and exhaustively detail what it is / contains / built for.

## Functional Requirements
- Hub `index.html` with archival masthead (specimen 001), proof bar (idle/active/engines/GHCR), why 2 cards, engines table, sticky index nav
- 6 dedicated pages: `pages/engines.html`, `pages/start.html`, `pages/tenant.html`, `pages/comparison.html`, `pages/scripts.html`, `pages/cleanup.html` (or similar)
- Two-level toggle (beginner: hotel analogy, plain; casual: Docker/IaC, flags) persisted via localStorage
- Per-engine GHCR copy-paste blocks (4 separate, with sizes 1.38/1.21, 1.36/1.20, 1.59/1.32, 1.63/1.63)
- Tenant WaaS per-engine blocks (prebuilt vs --build), cleanup L1-4, comparison table
- All internal links point inside site (no raw .md links), no missing pages
- Swiss-Archival mono + Newsreader, OKLCH tokens, focus-visible, prefers-reduced-motion, overflow-wrap

## Non-Functional
- No horizontal scroll at 320px, 44px touch targets, WCAG AA contrast
- 29/35 → 35/35 anti-pattern gates, self-critique avg 4+
- Static HTML, no build step, works via `npx serve docs/site`

## Acceptance Criteria
- `index.html` + 5-6 pages exist, all links resolve, no .md hrefs in site/
- Beginner/casual toggle works, tables show correct sizes, copy-paste blocks are per-engine
- `anti_pattern_check` 35/35, `self_critique` avg >=4
- README links to site, no regression on publish workflow

## Out of Scope
- GitHub Pages deploy, language servers, WaaS backend changes
