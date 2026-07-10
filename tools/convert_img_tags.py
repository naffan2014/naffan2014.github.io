#!/usr/bin/env python3
"""
批量转换 _posts/*.md 里的 {% img [class] URL [width] [height] "title" ["alt"] %} 标签
为标准 Markdown 图片语法 ![title](URL){: .class }

参考 _plugins/image_tag.rb 的语法:
  {% img [class name(s)] [http[s]:/]/path/to/image [width [height]] [title text | "title text" ["alt text"]] %}

转换规则:
- post-img → 保留为 {: .post-img }（但 Chirpy 没有这个样式,所以干脆不保留 class）
- 实际上直接转成 ![title](URL) 最稳
"""
import re
from pathlib import Path

POSTS_DIR = Path("_posts")

# 匹配 {% img ... %} 标签
IMG_TAG_RE = re.compile(r"{%\s*img\s+(.+?)%}", re.DOTALL)


def parse_img_args(args_str: str):
    """
    解析 img 标签参数。
    语法: [class name(s)] [http[s]:/]/path/to/image [width [height]] [title text | "title text" ["alt text"]]
    """
    s = args_str.strip()

    # 提取 title/alt(带引号的字符串,在最后)
    title = None
    alt = None
    # 找所有引号段
    quoted = re.findall(r'"([^"]*)"', s)
    if quoted:
        if len(quoted) >= 2:
            title = quoted[0]
            alt = quoted[1]
        else:
            title = quoted[0]
        # 去掉引号部分,剩下的再解析
        s = re.sub(r'"[^"]*"', '', s).strip()

    # 剩下的: [class] URL [width] [height]
    parts = s.split()
    img_class = None
    url = None
    width = None
    height = None

    if not parts:
        return None

    # URL 是第一个以 http://、https://、/ 开头的
    url_idx = None
    for i, p in enumerate(parts):
        if p.startswith(('http://', 'https://', '/')):
            url_idx = i
            url = p
            break

    if url_idx is None:
        # 没找到 URL,跳过
        return None

    # URL 之前是 class
    if url_idx > 0:
        img_class = ' '.join(parts[:url_idx])

    # URL 之后是 width / height
    after = parts[url_idx + 1:]
    if len(after) >= 1 and after[0].isdigit():
        width = after[0]
    if len(after) >= 2 and after[1].isdigit():
        height = after[1]

    return {
        'class': img_class,
        'url': url,
        'width': width,
        'height': height,
        'title': title,
        'alt': alt,
    }


def convert_img_tag(match):
    info = parse_img_args(match.group(1))
    if not info or not info['url']:
        # 解析失败,保留原标签(让用户手动处理)
        return match.group(0)

    # alt 优先用 title
    alt_text = info['alt'] or info['title'] or ''
    title_text = info['title']

    # 构造 Markdown 图片
    if title_text:
        md = f'![{alt_text}]({info["url"]} "{title_text}")'
    else:
        md = f'![{alt_text}]({info["url"]})'

    return md


changed = []
total_tags = 0

for md_file in sorted(POSTS_DIR.glob("*.md")):
    content = md_file.read_text(encoding="utf-8")
    matches = list(IMG_TAG_RE.finditer(content))
    if not matches:
        continue
    total_tags += len(matches)
    new_content = IMG_TAG_RE.sub(convert_img_tag, content)
    if new_content != content:
        md_file.write_text(new_content, encoding="utf-8")
        changed.append((md_file.name, len(matches)))

print(f"转换 {len(changed)} 个文件,共 {total_tags} 个 img 标签")
for name, n in changed:
    print(f"  {name}: {n} 个")
