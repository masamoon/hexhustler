#!/usr/bin/env python3
from pathlib import Path
import math

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "ui" / "occult_hud_fx_sprites.png"


def glow_layer(size, color, blur):
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    draw.rectangle((blur, blur, size[0] - blur - 1, size[1] - blur - 1), outline=color, width=2)
    return image.filter(ImageFilter.GaussianBlur(blur * 0.6))


def rect_frame(size, fill, edge, inset_edge=None, corner_marks=True):
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    w, h = size
    draw.rectangle((3, 3, w - 4, h - 4), fill=(3, 2, 7, 190))
    draw.rectangle((6, 6, w - 7, h - 7), fill=fill)
    draw.rectangle((4, 4, w - 5, h - 5), outline=edge, width=3)
    draw.rectangle((9, 9, w - 10, h - 10), outline=inset_edge or (255, 232, 156, 44), width=1)
    draw.line((15, h - 12, w - 18, 12), fill=(255, 205, 72, 22), width=1)
    draw.line((18, 12, w - 20, h - 14), fill=(95, 255, 220, 16), width=1)
    if corner_marks:
        for sx, sy in ((1, 1), (-1, 1), (1, -1), (-1, -1)):
            cx = 13 if sx > 0 else w - 14
            cy = 13 if sy > 0 else h - 14
            draw.line((cx - 5 * sx, cy, cx + 5 * sx, cy), fill=(255, 214, 88, 150), width=2)
            draw.line((cx, cy - 5 * sy, cx, cy + 5 * sy), fill=(255, 214, 88, 110), width=1)
    return image


def long_strip(size):
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    w, h = size
    draw.rectangle((0, 0, w - 1, h - 1), fill=(4, 3, 7, 218))
    draw.rectangle((4, 4, w - 5, h - 5), fill=(10, 7, 14, 170), outline=(222, 170, 54, 132), width=2)
    for x in range(12, w, 64):
        draw.line((x, 8, x + 42, h - 9), fill=(255, 205, 72, 20), width=1)
        draw.rectangle((x + 45, 10, x + 54, 18), outline=(142, 72, 170, 70), width=1)
    draw.line((10, h // 2, w - 11, h // 2), fill=(255, 224, 130, 46), width=1)
    return image


def label_chip(size):
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    w, h = size
    draw.rectangle((2, 2, w - 3, h - 3), fill=(5, 4, 9, 220), outline=(255, 210, 84, 124), width=2)
    draw.rectangle((7, 7, w - 8, h - 8), outline=(112, 255, 226, 45), width=1)
    draw.line((14, h - 8, w - 16, 8), fill=(255, 210, 84, 30), width=1)
    return image


def radial_ring(size, rings=3):
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    w, h = size
    cx, cy = w / 2, h / 2
    for i in range(rings):
        r = min(w, h) * (0.28 + 0.13 * i)
        alpha = int(180 - i * 46)
        draw.ellipse((cx - r, cy - r, cx + r, cy + r), outline=(255, 226, 90, alpha), width=max(2, 5 - i))
    for i in range(12):
        a = math.tau * i / 12
        r1 = min(w, h) * 0.30
        r2 = min(w, h) * 0.47
        draw.line((cx + math.cos(a) * r1, cy + math.sin(a) * r1, cx + math.cos(a) * r2, cy + math.sin(a) * r2), fill=(105, 255, 225, 90), width=1)
    return image.filter(ImageFilter.GaussianBlur(0.15))


def marked_overlay(size):
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    w, h = size
    cx, cy = w / 2, h / 2
    r = min(w, h) * 0.35
    draw.ellipse((cx - r, cy - r, cx + r, cy + r), outline=(255, 220, 82, 235), width=4)
    draw.ellipse((cx - r - 7, cy - r - 7, cx + r + 7, cy + r + 7), outline=(255, 80, 30, 160), width=2)
    draw.line((cx - r * 0.75, cy - r * 0.75, cx + r * 0.75, cy + r * 0.75), fill=(255, 220, 82, 230), width=3)
    draw.line((cx - r * 0.75, cy + r * 0.75, cx + r * 0.75, cy - r * 0.75), fill=(255, 220, 82, 230), width=3)
    return image


def glass_overlay(size):
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    w, h = size
    cx, cy = w / 2, h / 2
    r = min(w, h) * 0.33
    draw.ellipse((cx - r - 4, cy - r - 4, cx + r + 4, cy + r + 4), fill=(95, 255, 255, 36), outline=(155, 255, 255, 128), width=2)
    angles = (-0.8, 0.35, 1.7, 2.85, 4.2)
    for idx, a in enumerate(angles):
        start = (cx + math.cos(a) * r * 0.12, cy + math.sin(a) * r * 0.12)
        end = (cx + math.cos(a + 0.25) * r * (0.62 + idx * 0.045), cy + math.sin(a + 0.25) * r * (0.62 + idx * 0.045))
        draw.line((start[0], start[1], end[0], end[1]), fill=(220, 255, 255, 205), width=2)
        draw.line((end[0], end[1], end[0] + math.cos(a - 0.9) * r * 0.20, end[1] + math.sin(a - 0.9) * r * 0.20), fill=(220, 255, 255, 135), width=1)
    return image


def power_bar(size):
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    w, h = size
    draw.rounded_rectangle((2, 6, w - 3, h - 7), radius=7, fill=(4, 3, 8, 230), outline=(255, 225, 120, 90), width=2)
    for x in range(10, w - 10, 20):
        draw.line((x, 8, x + 6, h - 9), fill=(255, 225, 120, 36), width=1)
    return image


def place(atlas, region, image):
    x, y, w, h = region
    atlas.alpha_composite(image.resize((w, h), Image.Resampling.LANCZOS), (x, y))


def main():
    atlas = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
    regions = {
        "panel_frame": (0, 0, 96, 96),
        "panel_frame_hot": (96, 0, 96, 96),
        "button_frame": (192, 0, 96, 96),
        "button_frame_hot": (288, 0, 96, 96),
        "button_frame_dead": (384, 0, 96, 96),
        "long_strip": (0, 112, 256, 48),
        "label_chip": (272, 112, 128, 32),
        "tiny_chip": (400, 112, 96, 32),
        "glow_ring": (0, 176, 128, 128),
        "pulse_ring": (128, 176, 128, 128),
        "marked_overlay": (256, 176, 128, 128),
        "glass_overlay": (384, 176, 128, 128),
        "score_panel": (0, 320, 128, 80),
        "aim_panel": (128, 320, 160, 64),
        "power_bar": (288, 320, 160, 32),
    }
    place(atlas, regions["panel_frame"], rect_frame((96, 96), (11, 7, 17, 222), (220, 168, 58, 205)))
    place(atlas, regions["panel_frame_hot"], rect_frame((96, 96), (18, 7, 22, 230), (255, 110, 244, 205), (255, 218, 95, 65)))
    place(atlas, regions["button_frame"], rect_frame((96, 96), (18, 8, 24, 225), (205, 165, 76, 190)))
    place(atlas, regions["button_frame_hot"], rect_frame((96, 96), (28, 10, 24, 232), (255, 210, 82, 220)))
    place(atlas, regions["button_frame_dead"], rect_frame((96, 96), (9, 8, 12, 170), (95, 92, 105, 135), (120, 116, 132, 35), False))
    place(atlas, regions["long_strip"], long_strip((256, 48)))
    place(atlas, regions["label_chip"], label_chip((128, 32)))
    place(atlas, regions["tiny_chip"], label_chip((96, 32)))
    place(atlas, regions["glow_ring"], radial_ring((128, 128), 2).filter(ImageFilter.GaussianBlur(1.0)))
    place(atlas, regions["pulse_ring"], radial_ring((128, 128), 4))
    place(atlas, regions["marked_overlay"], marked_overlay((128, 128)))
    place(atlas, regions["glass_overlay"], glass_overlay((128, 128)))
    place(atlas, regions["score_panel"], rect_frame((128, 80), (7, 5, 12, 205), (255, 198, 74, 145), corner_marks=False))
    place(atlas, regions["aim_panel"], rect_frame((160, 64), (4, 4, 8, 190), (115, 255, 230, 155), corner_marks=False))
    place(atlas, regions["power_bar"], power_bar((160, 32)))
    OUT.parent.mkdir(parents=True, exist_ok=True)
    atlas.save(OUT)
    print(f"Generated {OUT}")


if __name__ == "__main__":
    main()
