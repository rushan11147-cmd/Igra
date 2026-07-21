"""Industrial concrete floor albedo — flat, seamless, no checker / sphere."""
from PIL import Image, ImageDraw, ImageFilter, ImageEnhance
import math
import random

SIZE = 1024
OUT_FLOOR = r"C:\Users\1\Desktop\Igra\assets\textures\floors\concrete_floor.png"
OUT_WORN = r"C:\Users\1\Desktop\Igra\assets\textures\floors\concrete_floor_worn.png"


def _noise_field(size: int, seed: int, octaves: int = 4) -> list[list[float]]:
	rng = random.Random(seed)
	grid = [[0.0 for _ in range(size)] for _ in range(size)]
	amplitude = 1.0
	freq = 4
	total = 0.0
	for _o in range(octaves):
		cell = max(1, size // freq)
		coarse_w = size // cell + 3
		coarse = [[rng.random() for _ in range(coarse_w)] for _ in range(coarse_w)]
		for y in range(size):
			for x in range(size):
				fx = x / cell
				fy = y / cell
				x0 = int(fx) % (coarse_w - 1)
				y0 = int(fy) % (coarse_w - 1)
				tx = fx - int(fx)
				ty = fy - int(fy)
				tx = tx * tx * (3 - 2 * tx)
				ty = ty * ty * (3 - 2 * ty)
				v00 = coarse[y0][x0]
				v10 = coarse[y0][x0 + 1]
				v01 = coarse[y0 + 1][x0]
				v11 = coarse[y0 + 1][x0 + 1]
				v = v00 * (1 - tx) * (1 - ty) + v10 * tx * (1 - ty) + v01 * (1 - tx) * ty + v11 * tx * ty
				grid[y][x] += v * amplitude
		total += amplitude
		amplitude *= 0.5
		freq *= 2
	for y in range(size):
		for x in range(size):
			grid[y][x] /= total
	return grid


def make_concrete(base: tuple[int, int, int], stain: tuple[int, int, int], seed: int, darken: float = 0.0) -> Image.Image:
	n1 = _noise_field(SIZE, seed, 5)
	n2 = _noise_field(SIZE, seed + 17, 3)
	img = Image.new("RGB", (SIZE, SIZE))
	px = img.load()
	for y in range(SIZE):
		for x in range(SIZE):
			t = n1[y][x] * 0.75 + n2[y][x] * 0.25
			t = max(0.0, min(1.0, t - darken))
			r = int(base[0] * (0.82 + 0.28 * t) + stain[0] * (1.0 - t) * 0.18)
			g = int(base[1] * (0.82 + 0.28 * t) + stain[1] * (1.0 - t) * 0.18)
			b = int(base[2] * (0.82 + 0.28 * t) + stain[2] * (1.0 - t) * 0.18)
			# fine grain
			grain = (n2[y][x] - 0.5) * 14
			px[x, y] = (
				max(0, min(255, int(r + grain))),
				max(0, min(255, int(g + grain))),
				max(0, min(255, int(b + grain * 0.9))),
			)
	# subtle cracks / scuffs
	draw = ImageDraw.Draw(img)
	rng = random.Random(seed + 99)
	for _ in range(40):
		x0, y0 = rng.randrange(SIZE), rng.randrange(SIZE)
		pts = [(x0, y0)]
		ang = rng.uniform(0, math.tau)
		for __ in range(10):
			ang += rng.uniform(-0.5, 0.5)
			x0 = (x0 + math.cos(ang) * rng.uniform(8, 22)) % SIZE
			y0 = (y0 + math.sin(ang) * rng.uniform(8, 22)) % SIZE
			pts.append((x0, y0))
		c = (
			max(0, base[0] - 28),
			max(0, base[1] - 28),
			max(0, base[2] - 26),
		)
		draw.line(pts, fill=c, width=1)
	img = img.filter(ImageFilter.GaussianBlur(radius=0.6))
	return ImageEnhance.Contrast(img).enhance(1.05)


def main() -> None:
	floor = make_concrete((118, 112, 102), (70, 62, 52), 3)
	worn = make_concrete((92, 86, 78), (55, 42, 36), 11, darken=0.08)
	floor.save(OUT_FLOOR, "PNG")
	worn.save(OUT_WORN, "PNG")
	print("wrote", OUT_FLOOR)
	print("wrote", OUT_WORN)


if __name__ == "__main__":
	main()
