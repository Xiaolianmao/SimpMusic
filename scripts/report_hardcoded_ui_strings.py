#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""列出 Kotlin 用户界面中直接写入的英文，供人工排查而不是自动误改。"""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
PATTERN = re.compile(
    r'(?:\bText\s*\(\s*(?:text\s*=\s*)?|\bcontentDescription\s*=\s*|'
    r'\btitle\s*=\s*|\bsubtitle\s*=\s*|\blabel\s*=\s*)'
    r'"([^"\n]{2,120})"'
)
count = 0
for path in sorted((ROOT / "composeApp/src").rglob("*.kt")):
    if not any(part in path.parts for part in ("commonMain", "jvmMain", "androidMain")):
        continue
    source = path.read_text(encoding="utf-8")
    for match in PATTERN.finditer(source):
        value = match.group(1)
        if not re.search(r"[A-Za-z]{3}", value):
            continue
        if value.startswith(("http://", "https://", "#")):
            continue
        line = source.count("\n", 0, match.start()) + 1
        print(f"{path.relative_to(ROOT)}:{line}: {value}")
        count += 1
print(f"潜在硬编码英文界面字符串：{count} 处（需逐项人工确认）")
