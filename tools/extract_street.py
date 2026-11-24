#!/usr/bin/env python3
"""从场景原图里把动植物抠成透明底单张，并把原图里的人物位置补上背景。

用法: python3 tools/extract_street.py
输入: assets/scene_street.webp
输出: assets/sprites/street/<id>.png（与 _make_patch 同一裁剪矩形，可直接替换补丁）
      assets/scene_street_anim.webp（抠掉人物后的背景板）
      tools/extract_street_report.json（每张的修正后世界坐标与遮罩包围盒）
方法: 边缘种子区域生长（容差）抠图 + 平移复制补背景。
"""
import json, math
from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter
from scipy import ndimage as ndi

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "assets" / "scene_street.webp"
OUTDIR = ROOT / "assets" / "sprites" / "street"
K = 1.2  # 世界坐标 -> 原图像素
WORLD = (1600.0, 1067.0)

# id, 名字, 世界中心 x, y, 半宽 hw, 半高 hh（世界单位）
# extra: 额外漫水种子（世界坐标），用于多部件
# er: 紧贴椭圆的半轴（世界单位，约人物实际尺寸 x1.1），用来兜底：
# 漫水缺了头/壶嘴/花瓣时，椭圆保证整个人物都在图里，边缘羽化。
SPECS = [
    ("cat_grey", "灰猫", 893, 729, 56, 56, [], (45, 40)),
    ("cat_orange", "橘猫", 435, 518, 56, 56, [], (50, 40)),
    ("bird", "小鸟", 587, 892, 50, 50, [], (40, 32)),
    ("kettle", "浇水壶", 1293, 726, 59, 59, [], (48, 35)),
    ("sunflower", "向日葵", 910, 184, 62, 62, [(910, 165), (910, 190), (910, 215)], (52, 62)),
    ("person_pink", "粉衣小人", 470, 255, 48, 48, [], (30, 34)),
    ("person_basket_green", "提篮绿衣人", 928, 360, 48, 48, [], (30, 34)),
    ("person_hat_pink", "粉帽小人", 709, 500, 48, 48, [], (30, 34)),
    ("person_basket", "提篮人", 765, 515, 48, 48, [], (30, 34)),
    ("person_purple", "紫衣小人", 829, 969, 48, 48, [], (30, 34)),
    ("cat_bw", "黑白猫", 1186, 1036, 48, 48, [], (36, 36)),
    ("cat_grey2", "灰猫（右上）", 1019, 330, 48, 48, [], (36, 33)),
    ("lamp", "路灯", 1181, 925, 35, 135, [(1181, 823), (1181, 980)], (24, 135)),
    ("flowers_pink", "粉花丛", 292, 933, 65, 56, [(335, 935), (285, 905), (330, 900)], (66, 52)),
]
TOL = 48.0


def outline_walls(arr: np.ndarray, dilate: int = 1) -> np.ndarray:
    """深暖棕描边当墙（亮度<105、R>G>B、R-B>55，见实测描边色）。
    颜色相似法会漏过浅色衣服（粉衣≈石板色），但描边墙与颜色无关。"""
    rgb = arr.astype(np.int16)
    lum = rgb.mean(axis=2)
    wall = (lum < 105) & (rgb[:, :, 0] > rgb[:, :, 1]) & (rgb[:, :, 1] > rgb[:, :, 2]) \
        & ((rgb[:, :, 0] - rgb[:, :, 2]) > 55)
    if dilate:
        wall = ndi.binary_dilation(wall, structure=np.ones((3, 3), bool),
                                   iterations=dilate)
    return wall


def ellipse_mask(shape, cy, cx, ry, rx) -> np.ndarray:
    """羽化椭圆遮罩（漫水漏出时的退路）：中心实、边缘渐隐，
    动起来没有硬方块边缘，比带背景的方块补丁好得多。"""
    yy, xx = np.mgrid[0:shape[0], 0:shape[1]]
    d = ((yy - cy) / max(ry, 1)) ** 2 + ((xx - cx) / max(rx, 1)) ** 2
    alpha = np.clip(1.25 - d, 0, 1)
    return (alpha * 255).astype(np.uint8)


MAX_FRAC = {"flowers_pink": 0.75, "sunflower": 0.5, "lamp": 0.3}


def _flood_from_seed(wall: np.ndarray, sy: int, sx: int) -> np.ndarray:
    """从一个种子点出发、遇墙即止的漫水，返回内部区域。"""
    h, w = wall.shape
    interior = np.zeros((h, w), dtype=bool)
    if not (0 <= sy < h and 0 <= sx < w):
        return interior
    if wall[sy, sx]:
        found = None
        for r in range(1, 13):
            for dy in range(-r, r + 1):
                for dx in range(-r, r + 1):
                    ny, nx = sy + dy, sx + dx
                    if 0 <= ny < h and 0 <= nx < w and not wall[ny, nx]:
                        found = (ny, nx)
                        break
                if found:
                    break
            if found:
                break
        if not found:
            return interior
        sy, sx = found
    dq = deque([(sy, sx)])
    interior[sy, sx] = True
    while dq:
        y, x = dq.popleft()
        for ny, nx in ((y - 1, x), (y + 1, x), (y, x - 1), (y, x + 1)):
            if 0 <= ny < h and 0 <= nx < w and not interior[ny, nx] \
                    and not wall[ny, nx]:
                interior[ny, nx] = True
                dq.append((ny, nx))
    return interior


def extract_character(arr: np.ndarray, seeds: list, sid: str) -> tuple:
    """每个种子单独漫水，漏出的（过大）直接丢掉，剩下的合并；
    再做闭运算把头/身、壶嘴、茎这些隔开的小部件连起来，
    填洞、贴上描边。背景物（长椅、木桶、路缘线）都在人物描边之外，
    碰不到；多部件（花盆簇、路灯杆、向日葵）用多个种子分别漫水。
    全部漏出才退回羽化椭圆。"""
    h, w = arr.shape[:2]
    cap = MAX_FRAC.get(sid, 0.25) * h * w
    for dil in (1, 2):
        wall = outline_walls(arr, dil)
        parts = []
        for sy, sx in seeds:
            part = _flood_from_seed(wall, int(sy), int(sx))
            if 150 <= int(part.sum()) <= cap:
                parts.append(part)
        if parts:
            frag = np.zeros((h, w), dtype=bool)
            for p in parts:
                frag |= p
            # 闭运算：9x9 结构元，连起相隔 8px 内的部件（头与身、嘴与壶）
            closed = ndi.binary_closing(frag, structure=np.ones((9, 9), bool))
            closed = ndi.binary_fill_holes(closed)
            keep = ndi.binary_dilation(closed, iterations=2) & (closed | wall)
            return keep, "flood"
    # 退路：羽化椭圆
    cy, cx = seeds[0]
    alpha = ellipse_mask((h, w), cy, cx, h * 0.48, w * 0.48)
    return alpha > 0, "ellipse"


def main() -> None:
    img = Image.open(SRC).convert("RGB")
    iw, ih = img.size
    arr_full = np.asarray(img)
    outdir = OUTDIR
    outdir.mkdir(parents=True, exist_ok=True)
    inpainted = img.copy()
    report = []
    for sid, name, wx, wy, hw, hh, extra, er in SPECS:
        cx, cy = wx * K, wy * K
        x0 = max(0, int(cx - hw * K))
        y0 = max(0, int(cy - hh * K))
        x1 = min(iw, int(cx + hw * K))
        y1 = min(ih, int(cy + hh * K))
        crop = img.crop((x0, y0, x1, y1))
        a = np.asarray(crop)
        seeds = [(cy - y0, cx - x0)] + [(ey * K - y0, ex * K - x0) for ex, ey in extra]
        if sid.startswith("person_"):
            # 小人头和身体常被内部描边隔开：头、身各一个种子
            seeds.append(((wy - 20) * K - y0, cx - x0))
            seeds.append(((wy + 12) * K - y0, cx - x0))
        keep, method = extract_character(a, seeds, sid)
        # 最终透明度 = 漫水（精确）与紧贴椭圆（兜底）取并：
        # 漫水缺了头/壶嘴/花瓣时，椭圆保证整个人物都在图里；
        # 椭圆只比人物大一圈、边缘羽化，动起来没有硬方块。
        erx, ery = er[0] * K * 0.88, er[1] * K * 0.88
        ell = ellipse_mask(a.shape[:2], cy - y0, cx - x0, ery, erx)
        if method == "ellipse":
            final_alpha = ell
        else:
            flood_a = np.asarray(
                Image.fromarray((keep * 255).astype(np.uint8)).filter(
                    ImageFilter.GaussianBlur(0.7)))
            final_alpha = np.maximum(flood_a, ell)
        rgba = crop.convert("RGBA")
        rgba.putalpha(Image.fromarray(final_alpha.astype(np.uint8)))
        rgba.save(outdir / f"{sid}.png")
        # 遮罩包围盒 -> 修正后的世界坐标（人物实际中心）
        ys, xs = np.nonzero(keep)
        if len(xs):
            mcx = (xs.min() + xs.max()) / 2 + x0
            mcy = (ys.min() + ys.max()) / 2 + y0
            ccx, ccy = mcx / K, mcy / K
            mbbox = [int(xs.min()), int(ys.min()), int(xs.max()), int(ys.max())]
        else:
            ccx, ccy, mbbox = wx, wy, []
        # 背景修补：按最终透明度的不透明核心抠掉人物，找一块平移后
        # 边界颜色最接近的邻近区域盖上去。
        inpaint_mask = final_alpha > 127
        best, best_score = None, 1e18
        ring = ndi.binary_dilation(inpaint_mask, iterations=3) & ~ndi.binary_erosion(inpaint_mask, iterations=1)
        ring = ring & ~inpaint_mask
        for dx, dy in [(140, 0), (-140, 0), (0, 140), (0, -140),
                       (140, 140), (-140, -140), (140, -140), (-140, 140),
                       (220, 0), (-220, 0), (0, 220), (0, -220)]:
            sx0, sy0 = x0 + dx, y0 + dy
            if sx0 < 0 or sy0 < 0 or sx0 + (x1 - x0) > iw or sy0 + (y1 - y0) > ih:
                continue
            src = arr_full[sy0:sy0 + (y1 - y0), sx0:sx0 + (x1 - x0)]
            tgt = arr_full[y0:y1, x0:x1]
            if ring.sum() == 0:
                continue
            diff = np.abs(src[ring].astype(np.int16) - tgt[ring].astype(np.int16)).mean()
            if diff < best_score:
                best_score, best = diff, (sx0, sy0)
        if best is not None:
            sx0, sy0 = best
            patch = Image.fromarray(arr_full[sy0:sy0 + (y1 - y0), sx0:sx0 + (x1 - x0)])
            # 用遮罩（羽化）把补丁贴回去
            base = inpainted.crop((x0, y0, x1, y1)).convert("RGBA")
            mask = Image.fromarray((inpaint_mask * 255).astype(np.uint8)).filter(
                ImageFilter.GaussianBlur(1.2))
            base.paste(patch.convert("RGBA"), (0, 0), mask)
            inpainted.paste(base.convert("RGB"), (x0, y0))
        report.append({
            "id": sid, "name": name, "orig_world": [wx, wy],
            "corrected_world": [round(ccx, 1), round(ccy, 1)],
            "crop_img": [x0, y0, x1, y1], "mask_bbox_in_crop": mbbox,
            "fg_px": int(keep.sum()), "method": method, "inpaint_offset": best,
            "inpaint_ring_diff": round(float(best_score), 1) if best else None,
        })
        print(f"{sid}: [{method}] 修正 ({ccx:.0f},{ccy:.0f}) 前景 {int(keep.sum())}px 补丁偏移 {best} 边界差 {best_score:.1f}")
    inpainted.save(ROOT / "assets" / "scene_street_anim.webp", quality=90)
    (ROOT / "tools" / "extract_street_report.json").write_text(
        json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
    print("done")


if __name__ == "__main__":
    main()
