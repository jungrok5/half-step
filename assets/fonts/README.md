# Bundled UI fonts

The web prototype renders its HUD with the system `monospace` family at
`font-weight:1000` and leans on the browser's Korean fallback for the in-game
hint and the result card buttons. Godot has neither, so the port ships two
subsets built by `tools/build_fonts.py`:

| File | Source | Covers |
| --- | --- | --- |
| `HalfStepMono.ttf` | DejaVu Sans Mono Bold | Latin, digits, punctuation |
| `HalfStepKR.ttf` | GNU Unifont | the Hangul syllables used in the UI |

Both are subset to only the characters the game draws, which is why they are a
few kilobytes each. `CssText` loads the mono face and registers the Korean face
as its fallback.

Regenerate them after adding new UI copy — add the strings to `KOREAN_STRINGS`
in `tools/build_fonts.py` first, otherwise new Hangul renders as blank boxes:

```bash
pip install fonttools
python3 tools/build_fonts.py
```

## Licences

- DejaVu fonts: Bitstream Vera / DejaVu licence (permissive, redistribution and
  modification allowed). See <https://dejavu-fonts.github.io/License.html>.
- GNU Unifont: dual licensed under GPLv2+ with the GNU font embedding exception
  and SIL OFL 1.1. See <https://unifoundry.com/LICENSE.txt>.

Both licences permit redistributing subsets inside a game.
