"""Validate CollisionPolygon2D points from player attack animation."""
from __future__ import annotations

import re
from pathlib import Path


def parse_points(raw: str) -> list[tuple[float, float]]:
    nums = [float(x) for x in re.findall(r"-?\d+\.?\d*", raw)]
    return [(nums[i], nums[i + 1]) for i in range(0, len(nums), 2)]


def cross(o, a, b) -> float:
    return (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0])


def segments_intersect(p1, p2, p3, p4) -> bool:
    d1 = cross(p3, p4, p1)
    d2 = cross(p3, p4, p2)
    d3 = cross(p1, p2, p3)
    d4 = cross(p1, p2, p4)
    return ((d1 > 0 and d2 < 0) or (d1 < 0 and d2 > 0)) and (
        (d3 > 0 and d4 < 0) or (d3 < 0 and d4 > 0)
    )


def self_intersect(pts: list[tuple[float, float]]) -> bool:
    n = len(pts)
    if n < 4:
        return False
    for i in range(n):
        a, b = pts[i], pts[(i + 1) % n]
        for j in range(i + 2, n):
            if i == 0 and j == n - 1:
                continue
            c, d = pts[j], pts[(j + 1) % n]
            if segments_intersect(a, b, c, d):
                return True
    return False


def signed_area(pts: list[tuple[float, float]]) -> float:
    total = 0.0
    for i in range(len(pts)):
        x1, y1 = pts[i]
        x2, y2 = pts[(i + 1) % len(pts)]
        total += x1 * y2 - x2 * y1
    return total / 2.0


POLYS = [
    "(-1, 4, 16, 4, 19, 6, 16, 7, -1, 8)",
    "(14, 12, 16, 12, 13, 23, 5, 29, -2, 31, -6, 30, -5, 17, -3, 14, -1, 15, -1, 18, 7, 18, 13, 13)",
    "(-5, 6, -14, 14, -21, 17, -17, 26, -7, 30, 1, 31, 10, 26, 15, 17, 13, 13, 10, 18, 2, 21, -7, 17, -9, 14, -4, 10, -2, 7)",
    "(-4, 3, -23, 4, -23, 9, -17, 17, -15, 15, -17, 12, -16, 10, -10, 7, -3, 7)",
    "()",
]


def main() -> None:
    for i, raw in enumerate(POLYS):
        pts = parse_points(raw)
        area = signed_area(pts) if pts else 0.0
        print(
            f"poly_{i}: points={len(pts)} area={area:.1f} "
            f"cw={area < 0} self_intersect={self_intersect(pts) if len(pts) >= 4 else 'n/a'}"
        )


if __name__ == "__main__":
    main()
