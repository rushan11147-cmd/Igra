"""Generate a flat seamless marble checker floor texture (not a sphere preview)."""
from PIL import Image, ImageFilter, ImageDraw
import math
import random

SIZE = 1024
TILES = 2
CELL = SIZE // TILES
OUT = r"C:\Users\1\Desktop\Igra\assets\textures\floors\marble_checker.png"


def marble_noise(w: int, h: int, base: tuple, vein: tuple, seed: int) -> Image.Image:
	rng = random.Random(seed)
	img = Image.new("RGB", (w, h), base)
	px = img.load()
	for _ in range(90):
		cx, cy = rng.randrange(w), rng.randrange(h)
		rad = rng.randint(40, 180)
		col = (
			int(base[0] + (vein[0] - base[0]) * rng.uniform(0.15, 0.55)),
			int(base[1] + (vein[1] - base[1]) * rng.uniform(0.15, 0.55)),
			int(base[2] + (vein[2] - base[2]) * rng.uniform(0.15, 0.55)),
		)
		for y in range(max(0, cy - rad), min(h, cy + rad)):
			for x in range(max(0, cx - rad), min(w, cx + rad)):
				d = math.hypot(x - cx, y - cy) / rad
				if d < 1.0:
					a = (1.0 - d) ** 2 * 0.35
					r, g, b = px[x, y]
					px[x, y] = (
						int(r * (1 - a) + col[0] * a),
						int(g * (1 - a) + col[1] * a),
						int(b * (1 - a) + col[2] * a),
					)
	draw = ImageDraw.Draw(img)
	for _ in range(28):
		x0, y0 = rng.randrange(w), rng.randrange(h)
		points = [(x0, y0)]
		ang = rng.uniform(0, math.tau)
		for __ in range(18):
			ang += rng.uniform(-0.6, 0.6)
			x0 = (x0 + math.cos(ang) * rng.uniform(12, 28)) % w
			y0 = (y0 + math.sin(ang) * rng.uniform(12, 28)) % h
			points.append((x0, y0))
		c = (
			int(base[0] * 0.55 + vein[0] * 0.45),
			int(base[1] * 0.55 + vein[1] * 0.45),
			int(base[2] * 0.55 + vein[2] * 0.45),
		)
		draw.line(points, fill=c, width=rng.randint(1, 3))
	return img.filter(ImageFilter.GaussianBlur(radius=1.2))


def main() -> None:
	light = marble_noise(CELL, CELL, (210, 198, 180), (150, 120, 95), 1)
	dark = marble_noise(CELL, CELL, (48, 46, 44), (120, 118, 115), 2)
	out = Image.new("RGB", (SIZE, SIZE))
	for ty in range(TILES):
		for tx in range(TILES):
			tile = light if (tx + ty) % 2 == 0 else dark
			out.paste(tile, (tx * CELL, ty * CELL))

	grout = ImageDraw.Draw(out)
	gw = 4
	gc = (90, 86, 80)
	for i in range(TILES):
		x = i * CELL
		grout.rectangle([x - gw // 2, 0, x + gw // 2, SIZE - 1], fill=gc)
		grout.rectangle([0, x - gw // 2, SIZE - 1, x + gw // 2], fill=gc)
	grout.rectangle([SIZE - 1 - gw // 2, 0, SIZE - 1, SIZE - 1], fill=gc)
	grout.rectangle([0, SIZE - 1 - gw // 2, SIZE - 1, SIZE - 1], fill=gc)

	out.save(OUT, "PNG")
	print("wrote", OUT, out.size)


if __name__ == "__main__":
	main()
