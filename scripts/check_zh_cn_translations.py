#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""检查简体中文资源完整性、占位符与复数格式。仅使用 Python 标准库。"""

from __future__ import annotations

import collections
import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "composeApp/src/commonMain/composeResources"
BASE = ROOT / "values/strings.xml"
ZH_CN = ROOT / "values-zh-rCN/strings.xml"
TYPES = {"string", "plurals", "string-array"}
PLACEHOLDER = re.compile(r"%(?:\\d+\\$)?[-+# 0,(]*\\d*(?:\\.\\d+)?[a-zA-Z%]")


def load(path: Path) -> dict[str, ET.Element]:
    root = ET.parse(path).getroot()
    result: dict[str, ET.Element] = {}
    for elem in root:
        if elem.tag not in TYPES:
            continue
        name = elem.attrib.get("name", "")
        if not name:
            raise ValueError(f"{path}: 找到缺少名称的资源")
        if name in result:
            raise ValueError(f"{path}: 资源名称重复：{name}")
        result[name] = elem
    return result


def value(node: ET.Element) -> str:
    return "".join(node.itertext())


def formats(node: ET.Element) -> collections.Counter[str]:
    return collections.Counter(m for m in PLACEHOLDER.findall(value(node)) if m != "%%")


def main() -> int:
    try:
        base = load(BASE)
        chinese = load(ZH_CN)
    except (OSError, ET.ParseError, ValueError) as exc:
        print(f"资源解析失败：{exc}", file=sys.stderr)
        return 1

    errors: list[str] = []
    required = {key: obj for key, obj in base.items() if obj.get("translatable") != "false"}
    for missing in sorted(required.keys() - chinese.keys()):
        errors.append(f"缺少翻译：{missing}")
    for extra in sorted(chinese.keys() - required.keys()):
        errors.append(f"中文资源多出未定义或不可翻译的名称：{extra}")

    for name in sorted(required.keys() & chinese.keys()):
        english = required[name]
        translated = chinese[name]
        if english.tag != translated.tag:
            errors.append(f"{name}: 资源类型不一致（{english.tag} / {translated.tag}）")
            continue
        if english.tag == "string":
            if formats(english) != formats(translated):
                errors.append(f"{name}: 格式化占位符不一致")
        else:
            english_items = {item.get("quantity", str(i)): item
                             for i, item in enumerate(english.findall("item"))}
            chinese_items = {item.get("quantity", str(i)): item
                             for i, item in enumerate(translated.findall("item"))}
            if english_items.keys() != chinese_items.keys():
                errors.append(f"{name}: 数量选项不一致")
                continue
            for key in english_items:
                if formats(english_items[key]) != formats(chinese_items[key]):
                    errors.append(f"{name}/{key}: 格式化占位符不一致")

    print(f"英文资源：{len(base)} 项，要求翻译：{len(required)} 项，"
          f"简体中文：{len(chinese)} 项，检查错误：{len(errors)} 项")
    for error in errors:
        print(f" - {error}", file=sys.stderr)
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
