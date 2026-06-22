#!/usr/bin/env python3
from pathlib import Path
import math

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "ui" / "occult_fx_primitives.png"


def soft_disc(size):
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    w, h = size
    cx, cy = w * 0.5, h * 0.5
    for i in range(32):
        t = i / 31
        r = min(w, h) * (0.46 - t * 0.42)
        alpha = int(10 + (1.0 - t) ** 2.6 * 190)
        draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(255, 255, 255, alpha))
    return image.filter(ImageFilter.GaussianBlur(1.0))


def ring(size, thick=5, spokes=0):
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    w, h = size
    cx, cy = w * 0.5, h * 0.5
    for i in range(4):
        r = min(w, h) * (0.34 + i * 0.045)
        alpha = max(45, 205 - i * 42)
        draw.ellipse((cx - r, cy - r, cx + r, cy + r), outline=(255, 255, 255, alpha), width=max(1, thick - i))
    for i in range(spokes):
        a = math.tau * i / spokes
        r1 = min(w, h) * 0.30
        r2 = min(w, h) * 0.45
        draw.line((cx + math.cos(a) * r1, cy + math.sin(a) * r1, cx + math.cos(a) * r2, cy + math.sin(a) * r2), fill=(255, 255, 255, 95), width=1)
    return image.filter(ImageFilter.GaussianBlur(0.2))


def beam(size, soft=False):
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    w, h = size
    cy = h * 0.5
    bands = [(h * 0.36, 42), (h * 0.20, 115), (h * 0.08, 235)]
    if not soft:
        bands = [(h * 0.24, 58), (h * 0.12, 210)]
    for half, alpha in bands:
        draw.rounded_rectangle((2, cy - half, w - 3, cy + half), radius=int(max(2, half)), fill=(255, 255, 255, alpha))
    for x in range(12, w - 12, 34):
        draw.line((x, cy - h * 0.24, x + 16, cy + h * 0.22), fill=(255, 230, 128, 35), width=1)
    return image.filter(ImageFilter.GaussianBlur(0.4 if soft else 0.15))


def dot(size, sharp=False):
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    w, h = size
    cx, cy = w * 0.5, h * 0.5
    radii = ((0.42, 80), (0.24, 185), (0.10, 255)) if not sharp else ((0.36, 220), (0.18, 255))
    for scale, alpha in radii:
        r = min(w, h) * scale
        draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(255, 255, 255, alpha))
    return image.filter(ImageFilter.GaussianBlur(0.5 if not sharp else 0.1))


def rect_tile(size, dark=False):
	image = Image.new("RGBA", size, (0, 0, 0, 0))
	draw = ImageDraw.Draw(image)
	w, h = size
	fill = (255, 255, 255, 190 if not dark else 230)
	draw.rectangle((0, 0, w - 1, h - 1), fill=fill)
	return image


def frame(size):
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    w, h = size
    draw.rectangle((4, 4, w - 5, h - 5), outline=(255, 255, 255, 235), width=4)
    draw.rectangle((10, 10, w - 11, h - 11), outline=(255, 255, 255, 90), width=1)
    for sx, sy in ((1, 1), (-1, 1), (1, -1), (-1, -1)):
        cx = 15 if sx > 0 else w - 16
        cy = 15 if sy > 0 else h - 16
        draw.line((cx - sx * 7, cy, cx + sx * 7, cy), fill=(255, 255, 255, 185), width=2)
        draw.line((cx, cy - sy * 7, cx, cy + sy * 7), fill=(255, 255, 255, 130), width=2)
    return image


def stripes(size):
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    w, h = size
    for x in range(-h, w + h, 22):
        draw.line((x, 0, x + h, h), fill=(255, 255, 255, 105), width=4)
        draw.line((x + 7, 0, x + 7 + h, h), fill=(255, 225, 130, 42), width=1)
    return image


def eye(size):
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    w, h = size
    box = (8, 8, w - 9, h - 9)
    draw.arc(box, 198, 342, fill=(255, 255, 255, 235), width=4)
    draw.arc(box, 18, 162, fill=(255, 255, 255, 235), width=4)
    cx, cy = w * 0.5, h * 0.5
    draw.ellipse((cx - 12, cy - 12, cx + 12, cy + 12), fill=(180, 255, 238, 210))
    draw.ellipse((cx - 5, cy - 5, cx + 5, cy + 5), fill=(7, 5, 12, 245))
    return image.filter(ImageFilter.GaussianBlur(0.2))


def place(atlas, region, image):
    x, y, w, h = region
    atlas.alpha_composite(image.resize((w, h), Image.Resampling.LANCZOS), (x, y))


def main():
    atlas = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
    regions = {
        "soft_disc": (0, 0, 128, 128),
        "soft_ring": (128, 0, 128, 128),
        "thin_ring": (256, 0, 128, 128),
        "hot_ring": (384, 0, 128, 128),
        "beam": (0, 144, 192, 32),
        "beam_soft": (0, 192, 192, 48),
        "dot": (208, 144, 64, 64),
        "spark": (288, 144, 64, 64),
        "rect_fill": (0, 256, 96, 96),
        "rect_dark": (96, 256, 96, 96),
        "frame": (192, 256, 96, 96),
        "zone_haze": (288, 256, 96, 96),
        "zone_stripes": (384, 256, 96, 96),
        "eye_glyph": (0, 384, 128, 64),
        "gate_arc": (128, 368, 128, 128),
    }
    place(atlas, regions["soft_disc"], soft_disc((128, 128)))
    place(atlas, regions["soft_ring"], ring((128, 128), 5, 12))
    place(atlas, regions["thin_ring"], ring((128, 128), 3, 0))
    place(atlas, regions["hot_ring"], ring((128, 128), 7, 16))
    place(atlas, regions["beam"], beam((192, 32)))
    place(atlas, regions["beam_soft"], beam((192, 48), True))
    place(atlas, regions["dot"], dot((64, 64)))
    place(atlas, regions["spark"], dot((64, 64), True))
    place(atlas, regions["rect_fill"], rect_tile((96, 96)))
    place(atlas, regions["rect_dark"], rect_tile((96, 96), True))
    place(atlas, regions["frame"], frame((96, 96)))
    place(atlas, regions["zone_haze"], soft_disc((96, 96)))
    place(atlas, regions["zone_stripes"], stripes((96, 96)))
    place(atlas, regions["eye_glyph"], eye((128, 64)))
    place(atlas, regions["gate_arc"], ring((128, 128), 6, 10))
    OUT.parent.mkdir(parents=True, exist_ok=True)
    atlas.save(OUT)
    print(f"Generated {OUT}")


if __name__ == "__main__":
    main()
