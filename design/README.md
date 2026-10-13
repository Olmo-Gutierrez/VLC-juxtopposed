# Design assets

Reference material taken from the Figma file (`B7ifd32zHbliiZs9q00JG3`). Nothing here is compiled into VLC; the
folders are a library to pick from when a screen is built.

## `figma-icons/`
All 206 variants of the Figma `Icon` component set (node `42:356`), exported as SVG.

- Open `index.html` (or look at `index.png`) to see every icon on the Figma bar colour.
- `index.json` lists each file with its Figma node id, name and variant.
- File names: `name[-direction][-state][-value][-EQ][-two-tone].svg`. Parts that are `default` are left out, so
  `arrow-left.svg` is `name=arrow, direction=left`, and `volume-high.svg` is `name=volume, value=high`.
- Two icons exist twice in Figma with the same name (`album`, `subtitle`); the second copy carries its node id in the
  file name.
- Colours are literal, as in Figma: strokes `#8F8F8F`, two-tone accent `#AB6314`, `-active` and `-selected` states use
  `#D37918`. Qt's SVG renderer draws `currentColor` black, so the files keep literals.
- To use an icon in the app, copy it to `modules/gui/qt/pixmaps/icons/` and add it to `assets.qrc`, `Makefile.am` and
  `meson.build`, like the existing `bar_*.svg`.
