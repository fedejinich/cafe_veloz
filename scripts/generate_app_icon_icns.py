#!/usr/bin/env python3

from pathlib import Path
import sys

try:
    from PIL import Image
except ImportError as exc:
    raise SystemExit(
        "Pillow is required to regenerate AppIcon.icns. Install it with 'python3 -m pip install pillow'."
    ) from exc


def main() -> int:
    root_dir = Path(__file__).resolve().parents[1]
    source_png = root_dir / "Sources/CafeVeloz/Resources/Assets.xcassets/AppIcon.appiconset/icon_1024.png"
    output_icns = root_dir / "Sources/CafeVeloz/Resources/AppIcon.icns"

    if not source_png.is_file():
        raise SystemExit(f"Source icon not found: {source_png}")

    with Image.open(source_png) as image:
        width, height = image.size
        if (width, height) != (1024, 1024):
            raise SystemExit(
                f"Expected a 1024x1024 source icon, got {width}x{height}: {source_png}"
            )
        image.save(output_icns, format="ICNS")

    print(f"Wrote {output_icns}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
