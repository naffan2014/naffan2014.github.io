/*=== 破损图片占位脚本 ===*/
/* 监听所有 <img> 的 error 事件,加载失败时替换成设计感占位块 */
(function () {
  "use strict";

  // SVG 图标(一个简洁的"图片损坏"线条图标)
  var BROKEN_ICON =
    '<svg class="img-broken-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">' +
    '<rect x="3" y="3" width="18" height="18" rx="2" ry="2"/>' +
    '<circle cx="8.5" cy="8.5" r="1.5"/>' +
    '<path d="M21 15l-5-5L5 21"/>' +
    '<path d="M3 3l18 18" stroke-dasharray="2 3" opacity="0.5"/>' +
    "</svg>";

  var BROKEN_TITLE = "图片暂时无法显示";
  var BROKEN_HINT = "图床可能已失效或防盗链拦截";

  /**
   * 把破损的 <img> 替换成占位 wrapper
   */
  function replaceBrokenImage(img) {
    // 避免重复处理
    if (img.dataset.brokenHandled === "1") return;
    img.dataset.brokenHandled = "1";

    // 跳过 lazy-polyfill 的小占位图(1x1 透明 gif,Chirpy 用于懒加载)
    // 这种图本身 src 是 data URI,不会触发 error
    var src = img.getAttribute("src") || "";
    if (!src || src.indexOf("data:") === 0) return;

    var wrapper = document.createElement("div");
    wrapper.className = "img-broken-wrapper";
    // 保留原 img 的 alt/title 作为提示
    var alt = img.getAttribute("alt") || "";
    var title = img.getAttribute("title") || "";

    var label = alt || title || BROKEN_TITLE;

    // Chirpy 给封面图自动生成的 alt 是 "Preview Image",信息量太低
    // 改用文章标题:优先从最近的 article 祖先里找 h1,否则用页面 h1 / title
    if (label === "Preview Image") {
      var articleRoot = img.closest("article") || img.closest(".post-preview") || img.closest(".card");
      var h1 = null;
      if (articleRoot) {
        h1 = articleRoot.querySelector("h1, h2, h3");
      }
      if (!h1) {
        h1 = document.querySelector("article h1, main h1, h1");
      }
      if (h1 && h1.textContent) {
        label = h1.textContent.trim();
      } else {
        label = document.title || BROKEN_TITLE;
      }
    }

    // 显示原 URL 的可读片段(去掉查询参数),方便定位是哪张图
    var urlForDisplay = src;
    try {
      var u = new URL(src, window.location.href);
      // 优先取 pathname 最后一段(文件名)
      var pathPart = u.pathname.split("/").filter(Boolean).pop() || "";
      // 如果 pathname 段没有扩展名(如 /timg),显示 hostname + path
      if (pathPart && /\.[a-zA-Z0-9]{2,5}$/.test(pathPart)) {
        urlForDisplay = pathPart;
      } else if (pathPart) {
        urlForDisplay = u.hostname + "/" + pathPart;
      } else {
        urlForDisplay = u.hostname;
      }
      if (urlForDisplay.length > 60) {
        urlForDisplay = urlForDisplay.slice(0, 57) + "...";
      }
    } catch (e) {
      urlForDisplay = src.length > 60 ? src.slice(0, 57) + "..." : src;
    }

    wrapper.innerHTML =
      BROKEN_ICON +
      '<div class="img-broken-title">' +
      escapeHtml(label) +
      "</div>" +
      '<div class="img-broken-hint">' +
      BROKEN_HINT +
      "</div>" +
      '<div class="img-broken-url">' +
      escapeHtml(urlForDisplay) +
      "</div>";

    // 保留原始 img 但隐藏(方便后续修复时恢复)
    img.style.display = "none";
    img.setAttribute("aria-hidden", "true");

    // 如果外层是 <a class="popup img-link">(Chirpy 的 glightbox 弹窗),
    // 破损图点开也是 404,禁用点击行为,避免体验不好
    var parent = img.parentNode;
    if (
      parent &&
      parent.tagName === "A" &&
      parent.classList.contains("img-link")
    ) {
      parent.classList.add("img-broken-link");
      parent.setAttribute("aria-disabled", "true");
      // 用 click 拦截 + pointer-events:none 双保险
      parent.addEventListener("click", function (e) {
        e.preventDefault();
        e.stopPropagation();
      });
    }

    // 插入 wrapper,把原 img 移进去(保留 DOM 结构,避免破坏父级布局逻辑)
    if (img.parentNode) {
      img.parentNode.insertBefore(wrapper, img);
      img.parentNode.removeChild(img); // 直接移除,wrapper 已包含足够信息
    }
  }

  function escapeHtml(s) {
    return String(s)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#39;");
  }

  /**
   * 检查单个 img 是否真的加载失败(naturalWidth === 0 表示失败)
   */
  function checkImage(img) {
    if (img.dataset.brokenHandled === "1") return;
    // 只处理 http(s) 和相对路径的 img,跳过 data: URI
    var src = img.getAttribute("src") || "";
    if (!src || src.indexOf("data:") === 0) return;
    // complete 表示浏览器已经尝试加载完
    if (img.complete) {
      if (img.naturalWidth === 0 || img.naturalHeight === 0) {
        replaceBrokenImage(img);
      }
    }
  }

  /**
   * 扫描整个文档的所有 img
   */
  function scanAllImages(root) {
    var imgs = (root || document).querySelectorAll("img");
    imgs.forEach(function (img) {
      checkImage(img);
    });
  }

  /**
   * 监听 error 事件(捕获阶段,因为 error 不冒泡)
   */
  document.addEventListener(
    "error",
    function (event) {
      var target = event.target;
      if (target && target.tagName === "IMG") {
        replaceBrokenImage(target);
      }
    },
    true
  );

  /**
   * 监听 DOM 新增节点(Chirpy 用 lazyload,图片会动态出现)
   */
  if (window.MutationObserver) {
    var observer = new MutationObserver(function (mutations) {
      mutations.forEach(function (m) {
        m.addedNodes.forEach(function (node) {
          if (node.nodeType !== 1) return;
          if (node.tagName === "IMG") {
            checkImage(node);
          } else if (node.querySelectorAll) {
            scanAllImages(node);
          }
        });
      });
    });
    observer.observe(document.documentElement, {
      childList: true,
      subtree: true,
    });
  }

  // 页面加载完成后再扫一遍(兜底)
  if (document.readyState === "complete") {
    scanAllImages();
  } else {
    window.addEventListener("load", function () {
      // 延迟一帧,等懒加载图片完成首屏加载判断
      requestAnimationFrame(function () {
        scanAllImages();
      });
    });
  }

  // 兜底:有些图床返回 200 但内容是错误页(如百度的 error.html),
  // naturalWidth 可能为 0,需要延迟再扫一次
  setTimeout(function () {
    scanAllImages();
  }, 1500);
  setTimeout(function () {
    scanAllImages();
  }, 3000);
})();
