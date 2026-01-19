from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[1] / 'ios' / 'Runner' / 'Assets.xcassets'
APPICON_DIR = ROOT / 'AppIcon.appiconset'
LAUNCH_DIR = ROOT / 'LaunchImage.imageset'


def _try_sf_font(size: int) -> ImageFont.ImageFont:
    try:
        return ImageFont.truetype('/System/Library/Fonts/SFNS.ttf', size)
    except Exception:
        return ImageFont.load_default()


def make_icon(size: int) -> Image.Image:
    """Final app icon: true-black + neon yellow ring + stylized Z."""
    im = Image.new('RGBA', (size, size), (0, 0, 0, 255))
    draw = ImageDraw.Draw(im)

    # Soft glow
    for radius, alpha, blur in [(0.44, 55, 10), (0.40, 90, 14), (0.36, 120, 18)]:
        r = int(size * radius)
        bbox = [(size // 2 - r, size // 2 - r), (size // 2 + r, size // 2 + r)]
        ring = Image.new('RGBA', (size, size), (0, 0, 0, 0))
        ring_draw = ImageDraw.Draw(ring)
        ring_draw.ellipse(
            bbox,
            outline=(255, 212, 0, alpha),
            width=max(2, size // 34),
        )
        ring = ring.filter(ImageFilter.GaussianBlur(radius=max(1, blur)))
        im = Image.alpha_composite(im, ring)

    # Main ring
    r = int(size * 0.38)
    bbox = [(size // 2 - r, size // 2 - r), (size // 2 + r, size // 2 + r)]
    draw.ellipse(bbox, outline=(255, 212, 0, 240), width=max(3, size // 28))

    # Inner panel
    inner_r = int(size * 0.30)
    inner_bbox = [
        (size // 2 - inner_r, size // 2 - inner_r),
        (size // 2 + inner_r, size // 2 + inner_r),
    ]
    draw.ellipse(inner_bbox, fill=(16, 16, 24, 255))

    # Stylized "Z"
    z = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    z_draw = ImageDraw.Draw(z)
    stroke = max(3, size // 18)
    pad = int(size * 0.28)
    x0, y0 = pad, pad
    x1, y1 = size - pad, size - pad

    z_draw.line([(x0, y0), (x1, y0)], fill=(255, 255, 255, 245), width=stroke)
    z_draw.line([(x1, y0), (x0, y1)], fill=(255, 212, 0, 245), width=stroke)
    z_draw.line([(x0, y1), (x1, y1)], fill=(255, 255, 255, 245), width=stroke)

    z = z.filter(ImageFilter.GaussianBlur(radius=max(1, size // 240)))
    im = Image.alpha_composite(im, z)

    return im


def make_splash(size: int) -> Image.Image:
    """Dark splash with ZyloFM mark + title."""
    im = Image.new('RGBA', (size, size), (0, 0, 0, 255))

    mark_size = int(size * 0.56)
    mark = make_icon(mark_size)
    im.alpha_composite(mark, ((size - mark_size) // 2, int(size * 0.16)))

    draw = ImageDraw.Draw(im)
    font = _try_sf_font(max(18, size // 9))
    text = 'ZyloFM'

    bbox = draw.textbbox((0, 0), text, font=font)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    x = (size - tw) // 2
    y = int(size * 0.78)

    glow = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.text((x, y), text, font=font, fill=(255, 212, 0, 140))
    glow = glow.filter(ImageFilter.GaussianBlur(radius=max(1, size // 90)))
    im = Image.alpha_composite(im, glow)

    draw.text((x, y), text, font=font, fill=(255, 212, 0, 235))
    return im


APPICON_MAP: dict[str, int] = {
    'Icon-App-20x20@1x.png': 20,
    'Icon-App-20x20@2x.png': 40,
    'Icon-App-20x20@3x.png': 60,
    'Icon-App-29x29@1x.png': 29,
    'Icon-App-29x29@2x.png': 58,
    'Icon-App-29x29@3x.png': 87,
    'Icon-App-40x40@1x.png': 40,
    'Icon-App-40x40@2x.png': 80,
    'Icon-App-40x40@3x.png': 120,
    'Icon-App-60x60@2x.png': 120,
    'Icon-App-60x60@3x.png': 180,
    'Icon-App-76x76@1x.png': 76,
    'Icon-App-76x76@2x.png': 152,
    'Icon-App-83.5x83.5@2x.png': 167,
    'Icon-App-1024x1024@1x.png': 1024,
}

LAUNCH_SIZES: dict[str, int] = {
    'LaunchImage.png': 400,
    'LaunchImage@2x.png': 800,
    'LaunchImage@3x.png': 1200,
}


def main() -> None:
    for filename, px in APPICON_MAP.items():
        out = APPICON_DIR / filename
        out.parent.mkdir(parents=True, exist_ok=True)
        make_icon(px).save(out, format='PNG', optimize=True)

    for filename, px in LAUNCH_SIZES.items():
        out = LAUNCH_DIR / filename
        out.parent.mkdir(parents=True, exist_ok=True)
        make_splash(px).save(out, format='PNG', optimize=True)

    print('OK: Generated final AppIcon + dark ZyloFM LaunchImage')


if __name__ == '__main__':
    main()
