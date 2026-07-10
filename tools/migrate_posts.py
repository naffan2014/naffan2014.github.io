#!/usr/bin/env python3
"""
批改 _posts/*.md 的 front matter,迁移到 Chirpy 格式。
- 解析文件名日期,写入 date 字段
- category(单数)→ categories: [x]
- tag: a,b,c → tags: [a, b, c](小写化、去重)
- cover: URL → image: URL
- 删除 layout: graph(Chirpy 无此布局)
- 删除 picUrl
- excerpt 合并到 description(若 description 为空)
- 保留 title、author、description
- 计算 redirect_from 旧 URL: /<category>/<YYYY>/<MM>/<DD>/<N>.html
"""
import os
import re
import sys
from pathlib import Path

POSTS_DIR = Path("_posts")


def parse_front_matter(content: str):
    """返回 (fm_str, body, fm_end_idx),fm_str 不含 --- 分隔符行。"""
    if not content.startswith("---\n"):
        return None, content, 0
    # 找第二个 ---
    m = re.match(r"^---\n(.*?)\n---\n(.*)$", content, re.DOTALL)
    if not m:
        return None, content, 0
    return m.group(1), m.group(2), m.end()


def serialize_front_matter(fm: dict, order: list) -> str:
    """按指定顺序序列化 front matter。"""
    lines = []
    for key in order:
        if key not in fm:
            continue
        val = fm[key]
        if key in ("categories", "tags"):
            # 数组
            if isinstance(val, list):
                if len(val) == 1:
                    lines.append(f"{key}: [{val[0]}]")
                else:
                    lines.append(f"{key}: [{', '.join(val)}]")
            else:
                lines.append(f"{key}: [{val}]")
        elif key == "redirect_from":
            if isinstance(val, list):
                lines.append("redirect_from:")
                for u in val:
                    lines.append(f"  - {u}")
            else:
                lines.append(f"redirect_from: {val}")
        else:
            # 标量
            s = str(val)
            # 含特殊字符的用双引号包
            if any(c in s for c in [':', '#', '{', '}', '[', ']', ',', '&', '*', '?', '|', '<', '>', '=', '!', '%', '@', '`']) and not (s.startswith('"') and s.endswith('"')):
                # 但 URL 中的冒号在外层不需要引号,这里简单处理:仅当值含 # 或首字符为特殊时加引号
                if s.startswith('#') or '\n' in s:
                    lines.append(f'{key}: "{s}"')
                else:
                    lines.append(f"{key}: {s}")
            else:
                lines.append(f"{key}: {s}")
    return "\n".join(lines)


def parse_simple_fm(fm_str: str) -> dict:
    """简单行级 YAML 解析(只支持 key: value,够用了)。"""
    fm = {}
    current_key = None
    for line in fm_str.split("\n"):
        if not line.strip():
            continue
        # key: value
        m = re.match(r"^(\w+):\s*(.*)$", line)
        if m:
            key, val = m.group(1), m.group(2).strip()
            # 去掉两端引号
            if (val.startswith('"') and val.endswith('"')) or (val.startswith("'") and val.endswith("'")):
                val = val[1:-1]
            fm[key] = val
            current_key = key
        else:
            # 多行值(如 redirect_from 列表),此处忽略,因为我们不会读到这种
            pass
    return fm


def parse_tags(val: str) -> list:
    """tag: a,b,c → ['a', 'b', 'c'],小写化、去重、去空白。"""
    if not val or val.lower() == "null":
        return []
    parts = [p.strip() for p in val.split(",")]
    parts = [p for p in parts if p]
    # 小写化(Chirpy 区分大小写,统一小写避免标签云分裂)
    seen = []
    for p in parts:
        p_lower = p.lower()
        if p_lower not in [s.lower() for s in seen]:
            seen.append(p_lower)
    return seen


def parse_filename_date(filename: str):
    """
    从文件名 YYYY-MM-DD-N.md 或 YYYY-MM-DD-NN.md 解析日期和序号。
    返回 (date_str, num_str),date_str 形如 '2022-02-22 00:00:00 +0800',num_str 形如 '1' 或 '01'。
    """
    m = re.match(r"^(\d{4})-(\d{2})-(\d{2})-(\d+)\.md$", filename)
    if not m:
        return None, None
    y, mo, d, num = m.groups()
    return f"{y}-{mo}-{d} 00:00:00 +0800", num


def build_redirect_url(category: str, date_str: str, num: str) -> str:
    """
    旧 URL: /<category>/<YYYY>/<MM>/<DD>/<N>.html
    你旧的 permalink 规则是 /:category/:year/:month/:day/:N.html,N 是去掉前导零的序号。
    """
    m = re.match(r"^(\d{4})-(\d{2})-(\d{2})", date_str)
    if not m:
        return ""
    y, mo, d = m.groups()
    # 去掉前导零
    num_int = str(int(num))
    return f"/{category}/{y}/{mo}/{d}/{num_int}.html"


# 主流程
changed = []
skipped = []

for md_file in sorted(POSTS_DIR.glob("*.md")):
    original = md_file.read_text(encoding="utf-8")
    fm_str, body, _ = parse_front_matter(original)
    if fm_str is None:
        skipped.append((md_file.name, "no front matter"))
        continue

    fm = parse_simple_fm(fm_str)

    # 文件名日期
    date_str, num = parse_filename_date(md_file.name)
    if date_str is None:
        skipped.append((md_file.name, "bad filename"))
        continue

    # 提取原字段
    title = fm.get("title", "")
    author = fm.get("author")
    category = fm.get("category", "uncategorized")
    tags = parse_tags(fm.get("tag", ""))
    cover = fm.get("cover")
    description = fm.get("description", "")
    excerpt = fm.get("excerpt", "")
    pic_url = fm.get("picUrl")

    # description 优先,空则用 excerpt(去 HTML 标签)
    if not description and excerpt and excerpt.lower() != "null":
        # 简单去 <br> 等 HTML
        desc_clean = re.sub(r"<[^>]+>", " ", excerpt).strip()
        # 截断到合理长度
        if len(desc_clean) > 200:
            desc_clean = desc_clean[:200] + "..."
        description = desc_clean

    # 构建新 front matter
    new_fm = {}
    new_fm["title"] = title
    new_fm["author"] = author if author else None
    new_fm["date"] = date_str
    new_fm["categories"] = [category]
    if tags:
        new_fm["tags"] = tags
    if description:
        new_fm["description"] = description
    if cover and cover.lower() not in ("null", ""):
        # Chirpy 用 image 字段做封面
        new_fm["image"] = cover
    # 旧 URL 重定向
    redirect = build_redirect_url(category, date_str, num)
    if redirect:
        new_fm["redirect_from"] = [redirect]

    # 序列化(去掉 None)
    new_fm = {k: v for k, v in new_fm.items() if v is not None}

    order = ["title", "author", "date", "categories", "tags", "description", "image", "redirect_from"]
    fm_serialized = serialize_front_matter(new_fm, order)

    new_content = f"---\n{fm_serialized}\n---\n{body}"

    if new_content != original:
        md_file.write_text(new_content, encoding="utf-8")
        changed.append(md_file.name)
    else:
        skipped.append((md_file.name, "no change"))

print(f"已修改 {len(changed)} 篇")
print(f"跳过 {len(skipped)} 篇")
if skipped:
    print("跳过详情:")
    for name, reason in skipped:
        print(f"  {name}: {reason}")
