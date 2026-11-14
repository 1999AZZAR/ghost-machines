# Illustration shot list

One 16:9 Blotcat illustration per documentation page. Generated through the
`blotcat-illustrations` skill and written to `docs/site/assets/blotcat/`; the
builder renders the declared figure under each page header.

Style contract for every image: 16:9 horizontal body illustration, pure white
background, black hand-drawn line art, solid black Blotcat (white dot eyes,
thin legs, blank expression) doing the core action, 3–5 sparse red/orange/blue
handwritten English annotations, generous white space, no PPT/flowchart look,
no corner title, no cute style.

| File | Page | Core meaning | Blotcat action | Annotations |
| :--- | :--- | :--- | :--- | :--- |
| `00-overview.png` | home | Disposable sandbox with persistent work | Packing a laptop into a crate; a labelled shelf keeps `mounts/` | `throwaway`, `mounts/`, `4 engines` |
| `01-getting-started.png` | start | Five minutes to a shell | Handing a key through a small door labelled 2223 | `ssh`, `2223`, `5 min` |
| `02-images.png` | images | Prebuilt vs local build | Weighing a sealed parcel against a toolbox on a scale | `pull 1 min`, `build 15 min`, `same image` |
| `03-engines.png` | engines | Four distros, one toolchain | Swapping four labelled shells on one body | `ubuntu`, `debian`, `alpine`, `arch` |
| `04-lifecycle.png` | lifecycle | Container is disposable, work is not | Lifting a workbench out while the crate is crushed | `stop`, `mounts/`, `survives` |
| `05-connecting.png` | connecting | Only port 22 is open | Threading a cable through one narrow labelled hole | `22`, `-L 3000`, `tunnel` |
| `06-configuration.png` | configuration | Knobs that apply at create time | Turning labelled dials on a small panel | `.env`, `G1_PORT`, `rebuild` |
| `07-troubleshooting.png` | troubleshooting | Follow the logs to the broken link | Following footprints with a magnifier to a cut cable | `logs`, `status`, `refused` |
| `08-architecture.png` | architecture | Boot chain | Assembling labelled pipes end to end | `compose`, `entrypoint`, `sshd` |
| `09-tenants.png` | tenants | One isolated workspace per person | Handing separate keys and boxes to four small cats | `port`, `4G`, `isolated` |
| `10-security.png` | security | Dev defaults are not production | Locking a door while scratching out the word ghost | `key only`, `no root`, `expose?` |
| `11-scripts.png` | scripts | Each script is a station in the process | Pulling levers on a small labelled machine | `start`, `snapshot`, `clean` |
| `12-glossary.png` | glossary | Container vs VM, words that matter | Translating between a light box and a heavy crate | `container`, `vm`, `kernel` |
| `13-comparison.png` | comparison | Container weight vs VM weight | Holding a light box and a heavy crate on a scale | `seconds`, `minutes`, `shared kernel` |
| `14-contributing.png` | contributing | Add an engine through the same rails | Slotting a new labelled shell into a rack | `Dockerfile`, `tests`, `docs` |
| `15-cheatsheet.png` | cheatsheet | One page, every command | Taping a single page to a wall, tools hanging from it | `start`, `ssh`, `nuke` |

Implementation: `site.json` → `pages[].figure = {src, alt, caption}`;
`assets/blotcat/` is committed so the gh-pages deploy is self-contained.

## Generation notes

All sixteen plates were generated with `agy` (Antigravity CLI) driven through
herdr, as vector line art: 1600×900, white background, 6px black strokes,
`JetBrains Mono` annotations, no frames. Vector keeps the files small (3–6 KB
each), crisp at any width, and reviewable in a diff.

agy's raster image model returned `429 RESOURCE_EXHAUSTED` after the first two
plates (multi-hour reset), so the set was completed as SVG rather than mixing
raster and vector styles. The home page also embeds the terminal demo
(asciinema `sDNJP7aYOabLz0k6`) above its plate.
