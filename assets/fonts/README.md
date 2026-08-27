# Bundled UI fonts

The web prototype renders its HUD with the system `monospace` family at
`font-weight:1000` and leans on the browser's Korean fallback for the in-game
hint and the result card buttons. Godot has neither, so the port ships two
subsets built by `tools/build_fonts.py`, each containing only the characters the
UI actually draws:

| File | Source | Licence | Covers |
| --- | --- | --- | --- |
| `HalfStepMono.ttf` | DejaVu Sans Mono Bold | Bitstream Vera | Latin, digits, punctuation |
| `HalfStepKR.ttf` | Noto Sans KR Bold | SIL OFL 1.1 | the Hangul syllables used in the UI |

`CssText` loads the mono face and registers the Korean face as its fallback.

Regenerate them after adding new UI copy — add the strings to `KOREAN_STRINGS`
in `tools/build_fonts.py` first, otherwise new Hangul renders as blank boxes:

```bash
pip install fonttools brotli
python3 tools/build_fonts.py
```

## Licences

Full texts are in `licenses/`, and both licences require them to travel with the
font — including inside the exported `.pck`, which is why they are committed
here rather than only linked.

- **DejaVu Sans Mono Bold** — Bitstream Vera Fonts License, a permissive licence
  that allows redistribution, modification and sale. Modified copies may not be
  named with "Bitstream" or "Vera"; the subset keeps the DejaVu name, so that
  condition is met.
- **Noto Sans KR Bold** — SIL Open Font License 1.1. Permits embedding in a
  closed-source product, including a paid or ad-supported one.

### Do not use GNU Unifont here

An earlier revision subset GNU Unifont for the Hangul. The Debian
`fonts-unifont` package it came from is **plain GPL-2+ with no font-embedding
exception**, so shipping it inside the exported `.pck` would extend the GPL's
copyleft to the whole distributed game — incompatible with the closed-source
ad-supported release `AGENTS.md` section 12 targets. Any replacement font must
be OFL, Apache, or similarly permissive.
