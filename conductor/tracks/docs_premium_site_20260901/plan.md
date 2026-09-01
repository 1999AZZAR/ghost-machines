# Plan — Premium Swiss-Archival Docs Site

## Phase 1 — Hub De-crowd & Uncrowd
- [ ] Rebuild index.html as archival hub (masthead, proof bar, sticky index, teaser cards) with proper whitespace and Swiss grid
- [ ] Ensure beginner/casual toggle (hotel vs Docker) with localStorage, no crowded single-page dumping

## Phase 2 — Multi-page Expansion (Detail)
- [ ] Flesh pages/engines.html, pages/start.html, pages/tenant.html with per-engine copy-paste blocks + sizes
- [ ] Flesh pages/comparison.html, pages/scripts.html, pages/cleanup.html with exhaustive tables and step-by-step
- [ ] Fix all hrefs to point inside site/ (no ../*.md), add missing nav links

## Phase 3 — Quality Gates & Polish
- [ ] Run anti_pattern_check (35/35) and self_critique (avg >=4), fix focus-visible, reduced-motion, overflow-wrap, named easings
- [ ] Wire README to docs/site, verify site serves via npx serve, no regressions

## Phase Verification
- [ ] Manual verification: open docs/site/index.html at 320/768, check toggle, copy-paste, tables, links
