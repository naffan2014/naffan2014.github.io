#!/bin/bash
set -euo pipefail

echo "=== 1. 检查 ImageMagick ==="
which convert && convert --version | head -2
echo ""

echo "=== 2. 查看 favicon.ico 信息 ==="
identify assets/img/favicons/favicon.ico
echo ""

echo "=== 3. 生成 PNG 各尺寸(从 16x16 放大,会模糊) ==="
convert assets/img/favicons/favicon.ico -resize 96x96 -background none assets/img/favicons/favicon-96x96.png
convert assets/img/favicons/favicon.ico -resize 180x180 -background none assets/img/favicons/apple-touch-icon.png
convert assets/img/favicons/favicon.ico -resize 192x192 -background none assets/img/favicons/web-app-manifest-192x192.png
convert assets/img/favicons/favicon.ico -resize 512x512 -background none assets/img/favicons/web-app-manifest-512x512.png
echo "PNG 生成完成"
echo ""

echo "=== 4. 生成 SVG (用 base64 嵌入 96x96 PNG) ==="
png_b64=$(base64 -w 0 assets/img/favicons/favicon-96x96.png 2>/dev/null || base64 assets/img/favicons/favicon-96x96.png | tr -d "\n")
cat > assets/img/favicons/favicon.svg <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="96" height="96" viewBox="0 0 96 96">
  <image href="data:image/png;base64,${png_b64}" width="96" height="96"/>
</svg>
EOF
echo "SVG 生成完成"
echo ""

echo "=== 5. 验证生成结果 ==="
ls -la assets/img/favicons/
echo ""

echo "=== 6. 验证文件类型 ==="
file assets/img/favicons/*
