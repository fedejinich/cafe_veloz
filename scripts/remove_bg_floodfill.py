#!/usr/bin/env python3
"""Remove black background using flood fill from edges + handle hole detection.

Pass 1: Flood fill from border through dark pixels → exterior background.
Pass 2: Find enclosed very-dark components, filter by avg brightness and size
         to identify the handle hole → make transparent.
"""

from PIL import Image
from collections import deque

SRC = "/Users/void_rsk/Downloads/diegohabano.png"
DST_1X = "Sources/CafeVeloz/Resources/coffee_cup.png"
DST_2X = "Sources/CafeVeloz/Resources/coffee_cup@2x.png"

BORDER_THRESH = 40   # for exterior flood fill
INNER_THRESH = 25    # for enclosed dark regions
HOLE_MIN_SIZE = 5000 # minimum pixels to be considered a hole (not noise)
HOLE_MAX_AVG = 5.0   # max average brightness for background-black


def is_dark(r, g, b, thresh):
    return r < thresh and g < thresh and b < thresh


def main():
    print(f"Loading {SRC}...")
    img = Image.open(SRC).convert("RGBA")
    w, h = img.size
    pixels = img.load()
    print(f"  Size: {w}x{h}")

    # --- Pass 1: exterior flood fill from borders ---
    print("Pass 1: Flood-filling exterior from edges...")
    visited = set()
    bg = set()
    queue = deque()

    for x in range(w):
        for y in (0, h - 1):
            r, g, b, a = pixels[x, y]
            if is_dark(r, g, b, BORDER_THRESH):
                visited.add((x, y))
                queue.append((x, y))
                bg.add((x, y))

    for y in range(h):
        for x in (0, w - 1):
            if (x, y) not in visited:
                r, g, b, a = pixels[x, y]
                if is_dark(r, g, b, BORDER_THRESH):
                    visited.add((x, y))
                    queue.append((x, y))
                    bg.add((x, y))

    while queue:
        cx, cy = queue.popleft()
        for dx, dy in ((-1, 0), (1, 0), (0, -1), (0, 1)):
            nx, ny = cx + dx, cy + dy
            if 0 <= nx < w and 0 <= ny < h and (nx, ny) not in visited:
                visited.add((nx, ny))
                r, g, b, a = pixels[nx, ny]
                if is_dark(r, g, b, BORDER_THRESH):
                    bg.add((nx, ny))
                    queue.append((nx, ny))

    print(f"  Exterior pixels: {len(bg)}")

    # Apply exterior transparency
    for x, y in bg:
        r, g, b, a = pixels[x, y]
        pixels[x, y] = (r, g, b, 0)

    # --- Pass 2: find enclosed dark regions (handle hole) ---
    print("Pass 2: Finding enclosed dark regions...")
    remaining_dark = set()
    for y in range(h):
        for x in range(w):
            if (x, y) not in bg:
                r, g, b, a = pixels[x, y]
                if is_dark(r, g, b, INNER_THRESH):
                    remaining_dark.add((x, y))

    # Connected components
    visited2 = set()
    holes = []
    for p in remaining_dark:
        if p in visited2:
            continue
        comp = []
        q = deque([p])
        visited2.add(p)
        while q:
            cx, cy = q.popleft()
            comp.append((cx, cy))
            for dx, dy in ((-1, 0), (1, 0), (0, -1), (0, 1)):
                nx, ny = cx + dx, cy + dy
                if (nx, ny) in remaining_dark and (nx, ny) not in visited2:
                    visited2.add((nx, ny))
                    q.append((nx, ny))

        # Check if this component looks like a background hole
        if len(comp) >= HOLE_MIN_SIZE:
            avg_r = sum(pixels[x, y][0] for x, y in comp) / len(comp)
            avg_g = sum(pixels[x, y][1] for x, y in comp) / len(comp)
            avg_b = sum(pixels[x, y][2] for x, y in comp) / len(comp)
            avg_brightness = (avg_r + avg_g + avg_b) / 3
            xs = [p[0] for p in comp]
            ys = [p[1] for p in comp]
            print(f"  Component: {len(comp)} px, "
                  f"bbox=({min(xs)},{min(ys)})-({max(xs)},{max(ys)}), "
                  f"avg=({avg_r:.1f},{avg_g:.1f},{avg_b:.1f})")
            if avg_brightness < HOLE_MAX_AVG:
                holes.append(comp)
                print(f"    -> Identified as handle hole")

    hole_count = sum(len(c) for c in holes)
    print(f"  Handle hole pixels: {hole_count}")

    for comp in holes:
        for x, y in comp:
            r, g, b, a = pixels[x, y]
            pixels[x, y] = (r, g, b, 0)

    # --- Crop and resize ---
    print("Cropping to content...")
    bbox = img.getbbox()
    if bbox:
        img = img.crop(bbox)
    print(f"  Cropped size: {img.size}")

    img_2x = img.resize((360, 360), Image.LANCZOS)
    img_1x = img.resize((180, 180), Image.LANCZOS)

    img_1x.save(DST_1X)
    img_2x.save(DST_2X)
    print(f"Saved {DST_1X} ({img_1x.size})")
    print(f"Saved {DST_2X} ({img_2x.size})")


if __name__ == "__main__":
    main()
