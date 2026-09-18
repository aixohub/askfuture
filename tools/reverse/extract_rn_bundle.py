#!/usr/bin/env python3
"""从易占师 iOS 包中提取 RN bundle 指定模块，用于起卦链路逆向取证。

官方包：`/Users/jupyter/app/ipa/yishihui/RN0615.app/main.jsbundle`

该 bundle 为 React Native 的 `__d(function(g, r, i, a, m, e, d){...}, ID, [deps])`
模块化打包格式，中文以 `\\uXXXX` 转义存储。脚本会：
  1. 将整包解码为可读 JS（保留原模块边界）
  2. 按模块 ID 切分并导出到输出目录
  3. 可选调用 npx prettier 格式化，便于人工阅读

用法：
    python3 tools/reverse/extract_rn_bundle.py --bundle <main.jsbundle> --out /tmp/ysh_re
"""

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import subprocess

MODULE_RE = re.compile(r"__d\(function\(")

# 首页"开始起卦"链路涉及的官方模块（ID → 说明）。
KEY_MODULES = {
    2416: "首页（埋点 Page_SuanGuaHome），含 _geZhanBuBox / _checkInput",
    2419: "占事分类表 typeDataNew（首页分类网格）",
    2325: "占事类型总表 typeData，顶层分类名",
    2501: "排盘方式选择页 paiPanType，含 _toPaiPan 提交参数组装",
    2394: "CopperQiguaAction：在线摇卦开始/停止/回调",
    2391: "铜钱组件（三枚铜钱 + 摇动动画）",
    2392: "摇卦动作 yaoguaAction",
    1897: "coinYaogua()：三枚铜钱正反 → 爻值",
    2293: "六十四卦 divineNameData（八宫卦名与卦码）",
    2441: "卦象结果页 guaXiangPage",
    2196: "路由表 tabPages / stackPages（页面名 → 模块）",
    430: "App Config（yaoMap、yaoGuaProIdSet 等）",
}


def decode_bundle(raw: str) -> str:
    """还原 unicode 转义，同时剔除无法编码的代理对字符。"""
    decoded = re.sub(
        r"\\u([0-9a-fA-F]{4})", lambda m: chr(int(m.group(1), 16)), raw
    )
    return decoded.encode("utf-8", "surrogatepass").decode("utf-8", "replace")


def split_modules(source: str) -> tuple[list[int], list[str]]:
    starts = [m.start() for m in MODULE_RE.finditer(source)]
    segments: list[str] = []
    ids: list[int] = []
    for index, start in enumerate(starts):
        end = starts[index + 1] if index + 1 < len(starts) else len(source)
        segment = source[start:end]
        segments.append(segment)
        match = re.search(r"\},\s*(\d+)\s*,\s*\[", segment)
        ids.append(int(match.group(1)) if match else -1)
    return ids, segments


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--bundle", required=True, help="main.jsbundle 路径")
    parser.add_argument("--out", default="/tmp/ysh_re", help="输出目录")
    parser.add_argument("--pretty", action="store_true", help="调用 npx prettier 格式化")
    args = parser.parse_args()

    with open(args.bundle, encoding="utf-8", errors="replace") as handle:
        raw = handle.read()
    decoded = decode_bundle(raw)

    os.makedirs(args.out, exist_ok=True)
    decoded_path = os.path.join(args.out, "bundle.decoded.js")
    with open(decoded_path, "w", encoding="utf-8") as handle:
        handle.write(decoded)

    ids, segments = split_modules(decoded)
    by_id = {module_id: segment for module_id, segment in zip(ids, segments)}
    print(f"模块总数：{len(segments)}")

    for module_id, description in KEY_MODULES.items():
        segment = by_id.get(module_id)
        if segment is None:
            print(f"  ! 未找到模块 {module_id}（{description}）")
            continue
        path = os.path.join(args.out, f"module_{module_id}.js")
        with open(path, "w", encoding="utf-8") as handle:
            handle.write(segment)
        print(f"  ✓ {module_id}: {description} -> {path}")
        if args.pretty and shutil.which("npx"):
            pretty_path = os.path.join(args.out, f"module_{module_id}.pretty.js")
            with open(pretty_path, "w", encoding="utf-8") as handle:
                subprocess.run(
                    [
                        "npx",
                        "--yes",
                        "prettier@3",
                        "--parser",
                        "babel",
                        "--print-width",
                        "140",
                        path,
                    ],
                    stdout=handle,
                    check=False,
                )

    index_path = os.path.join(args.out, "module_index.json")
    with open(index_path, "w", encoding="utf-8") as handle:
        json.dump(
            {str(mid): KEY_MODULES.get(mid, "") for mid in ids},
            handle,
            ensure_ascii=False,
            indent=2,
        )
    print(f"模块索引 -> {index_path}")


if __name__ == "__main__":
    main()
