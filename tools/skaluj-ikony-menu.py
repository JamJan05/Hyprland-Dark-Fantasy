#!/usr/bin/env python3
# -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
#  MENU TILE ICONS - 256 px versions from the originals.
#
#  assets/ikony-menu/ holds the originals: six tiles of 512 x 512 px,
#  each with its own frame and bas-relief. The shell draws a tile at 76 px,
#  so loading 512 px would mean ~1 MB of texture per tile and scaling
#  with a ~7x reduction on every start - with visible aliasing
#  on the fine relief. This script does it once, properly:
#
#      assets/ikony-menu/<nazwa>.png  ->  assets/ikony-menu/256/<nazwa>.png
#
#  256 px, Lanczos filter. QML loads ONLY these files (sourceSize
#  256, smooth, mipmap) and further shrinks them to 76 px on the GPU, with a mipmap -
#  from 256 px that is already more than threefold, without aliasing.
#
#  WHY 256 AND NOT 76 x 2 = 152
#
#  Headroom for screen scale 2 and for a possible larger tile. A 256 px file
#  weighs approx. 100 kB, so the headroom is cheap.
#
#  The 256/ directory is in .gitignore - it is output, not source; it is recreated by
#  install.sh. The script is idempotent: it skips files whose 256 px
#  version is newer than the original.
#
#  Run from the repository root:
#      python3 tools/skaluj-ikony-menu.py
#
#  Requires Pillow (dev-python/pillow). Exit code 1 = one of the
#  six originals is missing (the tile will then show an empty dark square with its name).
# -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

import sys
from pathlib import Path

from PIL import Image

ZRODLO = Path("assets/ikony-menu")
CEL = ZRODLO / "256"
ROZMIAR = 256

# Order of tiles in the row - the same as in kafle/RzadKafli.qml.
KAFLE = ["uzbrojenie", "sakwa", "status", "wiesci", "zebatka", "ognisko"]


def main() -> int:
    CEL.mkdir(parents=True, exist_ok=True)
    brakuje = []

    for nazwa in KAFLE:
        oryginal = ZRODLO / f"{nazwa}.png"
        wynik = CEL / f"{nazwa}.png"

        if not oryginal.exists():
            brakuje.append(oryginal)
            continue

        if wynik.exists() and wynik.stat().st_mtime >= oryginal.stat().st_mtime:
            print(f"aktualny  {wynik}")
            continue

        obraz = Image.open(oryginal)
        # RGBA, because some originals may have a transparent background outside the frame -
        # converting to RGB would turn it into a black square.
        obraz = obraz.convert("RGBA")
        obraz.thumbnail((ROZMIAR, ROZMIAR), Image.LANCZOS)
        obraz.save(wynik, optimize=True)
        print(f"saved  {wynik}  ({obraz.width} x {obraz.height})")

    for plik in brakuje:
        print(f"WARNING: original {plik} is missing - its tile will show an empty square with the name",
              file=sys.stderr)
    return 1 if brakuje else 0


if __name__ == "__main__":
    sys.exit(main())
