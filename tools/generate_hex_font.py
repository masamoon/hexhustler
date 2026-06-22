#!/usr/bin/env python3
from pathlib import Path
import math
import random

from PIL import Image, ImageDraw, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "assets" / "fonts"
FONT_NAME = "HexHustlerBone"
PNG_NAME = "hex_hustler_bone.png"
FNT_NAME = "hex_hustler_bone.fnt"
BASE_FONT_CANDIDATES = [
    Path("/System/Library/Fonts/Supplemental/DIN Condensed Bold.ttf"),
    Path("/System/Library/Fonts/Supplemental/Arial Narrow Bold.ttf"),
    Path("/System/Library/Fonts/SFNSMono.ttf"),
]


def find_base_font() -> Path:
    for candidate in BASE_FONT_CANDIDATES:
        if candidate.exists():
            return candidate
    raise FileNotFoundError("No usable base font found for HexHustler font generation.")


def make_notch_mask(width: int, height: int, seed: int) -> Image.Image:
    rng = random.Random(seed)
    mask = Image.new("L", (width, height), 255)
    draw = ImageDraw.Draw(mask)
    notch_count = max(1, int((width + height) / 34))
    for _ in range(notch_count):
        side = rng.choice(("top", "bottom", "left", "right"))
        size = rng.randint(2, 6)
        if side in ("top", "bottom"):
            x = rng.randint(1, max(1, width - 2))
            y = 0 if side == "top" else height - 1
            points = [(x - size, y), (x + size, y), (x + rng.randint(-2, 2), y + (-size if side == "bottom" else size))]
        else:
            x = 0 if side == "left" else width - 1
            y = rng.randint(1, max(1, height - 2))
            points = [(x, y - size), (x, y + size), (x + (-size if side == "right" else size), y + rng.randint(-2, 2))]
        draw.polygon(points, fill=0)
    return mask.filter(ImageFilter.GaussianBlur(0.25))


def render_glyph(font: ImageFont.FreeTypeFont, ch: str, font_size: int, pad: int, seed: int) -> tuple[Image.Image, dict]:
    bbox = font.getbbox(ch, anchor="ls", stroke_width=2)
    advance = int(math.ceil(font.getlength(ch)))
    if ch == " ":
        return Image.new("RGBA", (max(advance, font_size // 3), 1), (0, 0, 0, 0)), {
            "xoffset": 0,
            "yoffset": 0,
            "xadvance": max(advance, font_size // 3),
        }

    left, top, right, bottom = bbox
    width = max(1, right - left + pad * 2)
    height = max(1, bottom - top + pad * 2)
    glyph = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    shadow = Image.new("RGBA", glyph.size, (0, 0, 0, 0))
    fill = Image.new("RGBA", glyph.size, (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    fill_draw = ImageDraw.Draw(fill)
    pos = (pad - left, pad - top)

    shadow_draw.text((pos[0] + 3, pos[1] + 3), ch, font=font, anchor="ls", fill=(18, 8, 22, 230), stroke_width=4, stroke_fill=(18, 8, 22, 230))
    fill_draw.text(pos, ch, font=font, anchor="ls", fill=(245, 236, 206, 255), stroke_width=2, stroke_fill=(44, 24, 48, 250))

    alpha = fill.getchannel("A")
    alpha = Image.composite(alpha, Image.new("L", glyph.size, 0), make_notch_mask(width, height, seed))
    fill.putalpha(alpha)

    glint = Image.new("RGBA", glyph.size, (0, 0, 0, 0))
    glint_draw = ImageDraw.Draw(glint)
    rng = random.Random(seed * 17 + 11)
    for _ in range(max(1, width // 24)):
        x = rng.randint(pad, max(pad, width - pad - 1))
        y = rng.randint(pad, max(pad, height - pad - 1))
        glint_draw.line((x - 3, y, x + 3, y), fill=(255, 206, 82, 92), width=1)
    glint.putalpha(Image.composite(glint.getchannel("A"), Image.new("L", glyph.size, 0), alpha))

    glyph.alpha_composite(shadow)
    glyph.alpha_composite(fill)
    glyph.alpha_composite(glint)
    return glyph, {
        "xoffset": left - pad,
        "yoffset": top + font_size - pad,
        "xadvance": max(advance + 1, right - left),
    }


def pack_glyphs(glyphs: dict[str, tuple[Image.Image, dict]], atlas_width: int = 1024) -> tuple[Image.Image, dict[str, dict]]:
    x = 2
    y = 2
    row_h = 0
    packed: dict[str, dict] = {}
    atlas = Image.new("RGBA", (atlas_width, 1024), (0, 0, 0, 0))

    for ch, (image, metrics) in glyphs.items():
        if x + image.width + 2 >= atlas_width:
            x = 2
            y += row_h + 2
            row_h = 0
        atlas.alpha_composite(image, (x, y))
        packed[ch] = {
            **metrics,
            "x": x,
            "y": y,
            "width": image.width,
            "height": image.height,
        }
        x += image.width + 2
        row_h = max(row_h, image.height)

    used_height = y + row_h + 2
    return atlas.crop((0, 0, atlas_width, used_height)), packed


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    font_size = 48
    pad = 8
    base_path = find_base_font()
    font = ImageFont.truetype(str(base_path), font_size)
    ascent, descent = font.getmetrics()
    line_height = font_size + descent + 12
    glyph_chars = "".join(chr(i) for i in range(32, 127))
    glyphs = {
        ch: render_glyph(font, ch, font_size, pad, ord(ch) * 131)
        for ch in glyph_chars
    }
    atlas, packed = pack_glyphs(glyphs)
    atlas.save(OUT_DIR / PNG_NAME)

    lines = [
        f'info face="{FONT_NAME}" size={font_size} bold=1 italic=0 charset="" unicode=1 stretchH=100 smooth=1 aa=1 padding=0,0,0,0 spacing=2,2 outline=0',
        f"common lineHeight={line_height} base={font_size} scaleW={atlas.width} scaleH={atlas.height} pages=1 packed=0 alphaChnl=1 redChnl=0 greenChnl=0 blueChnl=0",
        f'page id=0 file="{PNG_NAME}"',
        f"chars count={len(packed)}",
    ]
    for ch in glyph_chars:
        data = packed[ch]
        lines.append(
            "char id={id} x={x} y={y} width={width} height={height} xoffset={xoffset} yoffset={yoffset} xadvance={xadvance} page=0 chnl=15".format(
                id=ord(ch), **data
            )
        )
    (OUT_DIR / FNT_NAME).write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"Generated {OUT_DIR / FNT_NAME} from {base_path}")


if __name__ == "__main__":
    main()
