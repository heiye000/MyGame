#!/usr/bin/env python3
"""Trace slash-sheet frames into centered CollisionPolygon2D points.

Stdout is JSON. Exit 0 only when every required direction passes the checks.
Last frame of each direction is an empty polygon unless --keep-last.

Example:
  python scripts/trace_slash_polygons.py --png slash.png --hframes 4 --vframes 5 ^
    --map left=0-3,up_left=16-19,down=8-11,down_left=4-7,up=12-15
"""

from __future__ import annotations

import argparse
import json
import sys
from collections import deque

try:
    from PIL import Image
except ImportError:
    print("ERROR: 需要 Pillow（pip install pillow）", file=sys.stderr)
    sys.exit(1)


REQUIRED = ("left", "up_left", "down", "down_left", "up")
MIRRORED = ("right", "up_right", "down_right")
NEIGHBORS = (
    (1, 0),
    (1, 1),
    (0, 1),
    (-1, 1),
    (-1, 0),
    (-1, -1),
    (0, -1),
    (1, -1),
)


def parse_map(text: str) -> dict[str, list[int]]:
    result: dict[str, list[int]] = {}
    if not text.strip():
        return result
    for part in text.split(","):
        name, span = part.split("=", 1)
        name = name.strip()
        start_s, end_s = span.split("-", 1)
        start, end = int(start_s), int(end_s)
        if end < start:
            raise SystemExit(f"ERROR: 帧范围颠倒 {name}={span}")
        result[name] = list(range(start, end + 1))
    return result


def components(mask: list[list[bool]]) -> list[list[tuple[int, int]]]:
    h = len(mask)
    w = len(mask[0]) if h else 0
    seen = [[False] * w for _ in range(h)]
    groups: list[list[tuple[int, int]]] = []
    for y in range(h):
        for x in range(w):
            if not mask[y][x] or seen[y][x]:
                continue
            group: list[tuple[int, int]] = []
            q: deque[tuple[int, int]] = deque([(x, y)])
            seen[y][x] = True
            while q:
                cx, cy = q.popleft()
                group.append((cx, cy))
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = cx + dx, cy + dy
                    if 0 <= nx < w and 0 <= ny < h and mask[ny][nx] and not seen[ny][nx]:
                        seen[ny][nx] = True
                        q.append((nx, ny))
            groups.append(group)
    groups.sort(key=len, reverse=True)
    return groups


def _opaque(mask: list[list[bool]], x: int, y: int) -> bool:
    h = len(mask)
    w = len(mask[0]) if h else 0
    return 0 <= x < w and 0 <= y < h and mask[y][x]


def trace_boundary(mask: list[list[bool]], pixels: set[tuple[int, int]]) -> list[tuple[int, int]]:
    """Moore neighborhood walk. Returns ordered boundary pixels."""
    if not pixels:
        return []
    start = min(pixels, key=lambda p: (p[1], p[0]))
    contour = [start]
    # 从起点西侧进入，先往顺时针找下一颗不透明像素。
    back_dir = 4  # (-1, 0) 在 NEIGHBORS 里的下标
    cx, cy = start
    guard = 0
    limit = len(pixels) * 8 + 8
    while guard < limit:
        guard += 1
        found = False
        # 从「来路的下一格」开始顺时针扫，避免立刻走回头路。
        begin = (back_dir + 1) % 8
        for step in range(8):
            d = (begin + step) % 8
            dx, dy = NEIGHBORS[d]
            nx, ny = cx + dx, cy + dy
            if _opaque(mask, nx, ny) and (nx, ny) in pixels:
                if (nx, ny) == start and len(contour) > 2:
                    return contour
                contour.append((nx, ny))
                cx, cy = nx, ny
                # 下一轮的来路是当前方向的反方向。
                back_dir = (d + 4) % 8
                found = True
                break
        if not found:
            break
    return contour


def rdp(points: list[tuple[float, float]], epsilon: float) -> list[tuple[float, float]]:
    if len(points) < 3:
        return points
    start = points[0]
    end = points[-1]
    sx, sy = start
    ex, ey = end
    dx, dy = ex - sx, ey - sy
    denom = (dx * dx + dy * dy) ** 0.5 or 1.0
    worst_i = 0
    worst = -1.0
    for i in range(1, len(points) - 1):
        px, py = points[i]
        dist = abs(dy * px - dx * py + ex * sy - ey * sx) / denom
        if dist > worst:
            worst = dist
            worst_i = i
    if worst > epsilon:
        left = rdp(points[: worst_i + 1], epsilon)
        right = rdp(points[worst_i:], epsilon)
        return left[:-1] + right
    return [start, end]


def shoelace(points: list[tuple[float, float]]) -> float:
    area = 0.0
    for i, (x1, y1) in enumerate(points):
        x2, y2 = points[(i + 1) % len(points)]
        area += x1 * y2 - x2 * y1
    return abs(area) * 0.5


def rdp_closed(points: list[tuple[float, float]], epsilon: float) -> list[tuple[float, float]]:
    """闭合轮廓不能拿首尾当弦：两点重合时距离全是 0，RDP 会收成 1 个点。"""
    if len(points) < 4:
        return points
    sx, sy = points[0]
    far_i = max(
        range(1, len(points)),
        key=lambda i: (points[i][0] - sx) ** 2 + (points[i][1] - sy) ** 2,
    )
    left = rdp(points[: far_i + 1], epsilon)
    right = rdp(points[far_i:] + [points[0]], epsilon)
    merged = left[:-1] + right[:-1]
    return merged


def _dedupe_int(points: list[tuple[float, float]]) -> list[list[int]]:
    out: list[list[int]] = []
    for x, y in points:
        p = [int(round(x)), int(round(y))]
        if not out or p != out[-1]:
            out.append(p)
    if len(out) >= 2 and out[0] == out[-1]:
        out.pop()
    return out


def _segments_cross(a: list[int], b: list[int], c: list[int], d: list[int]) -> bool:
    def cross(p: list[int], q: list[int], r: list[int]) -> int:
        return (q[0] - p[0]) * (r[1] - p[1]) - (q[1] - p[1]) * (r[0] - p[0])

    c1, c2 = cross(a, b, c), cross(a, b, d)
    c3, c4 = cross(c, d, a), cross(c, d, b)
    return (c1 > 0) != (c2 > 0) and (c3 > 0) != (c4 > 0)


def self_crosses(poly: list[list[int]]) -> bool:
    n = len(poly)
    if n < 4:
        return False
    for i1 in range(n):
        a, b = poly[i1], poly[(i1 + 1) % n]
        for i2 in range(i1 + 2, n):
            if i1 == 0 and i2 == n - 1:
                continue
            c, d = poly[i2], poly[(i2 + 1) % n]
            if _segments_cross(a, b, c, d):
                return True
    return False


def simplify(contour: list[tuple[int, int]], frame_w: int, frame_h: int) -> list[list[int]]:
    centered = [
        (x + 0.5 - frame_w / 2.0, y + 0.5 - frame_h / 2.0) for x, y in contour
    ]
    cleaned: list[tuple[float, float]] = []
    for p in centered:
        if not cleaned or abs(p[0] - cleaned[-1][0]) + abs(p[1] - cleaned[-1][1]) > 0.01:
            cleaned.append(p)
    if len(cleaned) >= 2 and abs(cleaned[0][0] - cleaned[-1][0]) + abs(cleaned[0][1] - cleaned[-1][1]) < 0.01:
        cleaned.pop()
    if len(cleaned) < 3:
        return []
    # 优先不自交、点数落在判定盒能用的范围。epsilon 加大是为了吃掉像素锯齿。
    for epsilon in (1.25, 1.75, 2.25, 3.0, 4.0, 5.5, 7.0):
        reduced = _dedupe_int(rdp_closed(cleaned, epsilon))
        if len(reduced) < 8 or len(reduced) > 36:
            continue
        if not self_crosses(reduced):
            return reduced
    return []


def crop_mask(image: Image.Image, frame: int, hframes: int, vframes: int, alpha_min: int) -> list[list[bool]]:
    fw = image.width // hframes
    fh = image.height // vframes
    col = frame % hframes
    row = frame // hframes
    box = (col * fw, row * fh, (col + 1) * fw, (row + 1) * fh)
    crop = image.crop(box).convert("RGBA")
    raw = crop.load()
    mask = [[False] * fw for _ in range(fh)]
    for y in range(fh):
        for x in range(fw):
            mask[y][x] = raw[x, y][3] >= alpha_min
    return mask


def polygon_for_frame(mask: list[list[bool]], frame_w: int, frame_h: int) -> tuple[list[list[int]], str]:
    groups = components(mask)
    if not groups:
        return [], "空白帧"
    opaque = len(groups[0])
    if opaque < 6:
        return [], f"最大色块只有 {opaque} 像素"
    pixels = set(groups[0])
    # 只在最大色块上描边，火花散点不进判定。
    trimmed = [[(x, y) in pixels for x in range(frame_w)] for y in range(frame_h)]
    contour = trace_boundary(trimmed, pixels)
    poly = simplify(contour, frame_w, frame_h)
    if len(poly) < 3:
        return [], "轮廓点不足"
    if self_crosses(poly):
        return [], "多边形自交"
    area = shoelace([(p[0], p[1]) for p in poly])
    # 月牙是凹多边形，面积应接近不透明像素数。凸包会把月牙内部填满，面积明显偏大。
    if area > opaque * 2.2 or area < opaque * 0.25:
        return [], f"面积失真 area={area:.0f} opaque={opaque}"
    half_w = frame_w / 2.0 + 2.0
    half_h = frame_h / 2.0 + 2.0
    for x, y in poly:
        if abs(x) > half_w or abs(y) > half_h:
            return [], f"顶点越出帧 ({x},{y})"
    return poly, ""


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--png", required=True)
    parser.add_argument("--hframes", type=int, required=True)
    parser.add_argument("--vframes", type=int, required=True)
    parser.add_argument("--map", required=True, help="left=0-3,up_left=16-19,...")
    parser.add_argument("--alpha", type=int, default=16)
    parser.add_argument("--keep-last", action="store_true")
    parser.add_argument("--out", default="")
    args = parser.parse_args()

    mapping = parse_map(args.map)
    missing = [name for name in REQUIRED if name not in mapping]
    if missing:
        print("ERROR: 缺少实绘朝向 " + ", ".join(missing), file=sys.stderr)
        sys.exit(2)
    ignored = [name for name in mapping if name in MIRRORED]
    image = Image.open(args.png)
    if image.width % args.hframes or image.height % args.vframes:
        print("ERROR: 图尺寸不能整除网格", file=sys.stderr)
        sys.exit(2)
    frame_count = args.hframes * args.vframes
    frame_w = image.width // args.hframes
    frame_h = image.height // args.vframes
    problems: list[str] = []
    directions: dict[str, dict] = {}
    for name in REQUIRED:
        frames = mapping[name]
        if any(f < 0 or f >= frame_count for f in frames):
            problems.append(f"{name} 帧号越界")
            continue
        if len(frames) < 2:
            problems.append(f"{name} 至少要 2 帧（含末帧清空）")
            continue
        polygons: list[list[list[int]]] = []
        notes: list[str] = []
        last_good: list[list[int]] = []
        for index, frame in enumerate(frames):
            is_last = index == len(frames) - 1
            if is_last and not args.keep_last:
                polygons.append([])
                notes.append("末帧清空")
                continue
            mask = crop_mask(image, frame, args.hframes, args.vframes, args.alpha)
            poly, note = polygon_for_frame(mask, frame_w, frame_h)
            if len(poly) >= 3:
                last_good = poly
                polygons.append(poly)
                continue
            # 散点帧描不出干净月牙时，沿用这一向里上一张有效多边形。
            if last_good:
                polygons.append([p[:] for p in last_good])
                notes.append(f"frame {frame}: {note or '无效'}，沿用上一帧")
                continue
            polygons.append([])
            problems.append(f"{name} frame {frame}: {note or '多边形少于 3 点'}")
        directions[name] = {
            "frames": frames,
            "polygons": polygons,
            "notes": notes,
        }

    payload = {
        "png": args.png.replace("\\", "/"),
        "hframes": args.hframes,
        "vframes": args.vframes,
        "frame_w": frame_w,
        "frame_h": frame_h,
        "clear_last": not args.keep_last,
        "ignored_mirrored_directions": ignored,
        "directions": directions,
        "ok": not problems,
        "problems": problems,
    }
    text = json.dumps(payload, ensure_ascii=False, indent=2)
    if args.out:
        with open(args.out, "w", encoding="utf-8", newline="\n") as handle:
            handle.write(text + "\n")
    print(text)
    if problems:
        print("ERROR: " + " | ".join(problems), file=sys.stderr)
        sys.exit(3)


if __name__ == "__main__":
    main()
