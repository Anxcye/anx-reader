import 'dart:convert';

/// 注入到微信读书网页版的 CSS/JS。
///
/// 目标（对齐 anx-reader 的沉浸式阅读体验）：
/// 1. 隐藏干扰元素（下载 App 引导、二维码浮层）；
/// 2. 左右边缘点击翻页（模拟 ArrowLeft / ArrowRight）；
/// 3. 空格 / PgUp / PgDn 翻页；
/// 4. 沉浸模式：隐藏顶栏、左侧工具栏、底部章节条，可由 AppBar 按钮切换。
///
/// 说明：微信读书的正文是 canvas 渲染，无法改字体排版，
/// 因此这里只做"容器级"优化，字号仍走微信读书自带的 Aa 设置。
class WeReadInjection {
  WeReadInjection._();

  /// 基础样式 + 沉浸样式（沉浸样式挂在 html.anx-immersive 下）
  static const String css = r'''
/* ---------- 基础：滚动条 ---------- */
::-webkit-scrollbar { width: 8px; height: 8px; }
::-webkit-scrollbar-thumb { background: rgba(0,0,0,.18); border-radius: 4px; }
::-webkit-scrollbar-thumb:hover { background: rgba(0,0,0,.32); }
::-webkit-scrollbar-track { background: transparent; }

/* ---------- 隐藏“下载 App / 打开客户端”引导浮层 ---------- */
.wr_download_app,
.wr_reader_download_app,
[class*="downloadApp"],
[class*="DownloadApp"] {
  display: none !important;
}

/* ---------- 沉浸模式 ---------- */
html.anx-immersive .readerTopBar,
html.anx-immersive [class*="readerTopBar"],
html.anx-immersive .readerControls,
html.anx-immersive [class*="readerControls"],
html.anx-immersive .readerFooter,
html.anx-immersive [class*="readerFooter"] {
  display: none !important;
}

/* 沉浸模式下压缩上下留白，让正文占满窗口 */
html.anx-immersive .renderTargetWrapper,
html.anx-immersive [class*="renderTargetWrapper"] {
  padding-top: 0 !important;
  padding-bottom: 0 !important;
}
''';

  /// 完整注入脚本（含内联 CSS），可重复执行，内部做了幂等保护。
  static String js() {
    return r'''
(function () {
  var CSS = __CSS__;

  function ensureStyle() {
    var id = 'anx-weread-style';
    var old = document.getElementById(id);
    if (old) old.remove();
    var style = document.createElement('style');
    style.id = id;
    style.textContent = CSS;
    (document.head || document.documentElement).appendChild(style);
  }

  /* 是否点击在正文区域（canvas 或空白容器），避免和工具栏冲突 */
  function isBookSurface(el) {
    if (!el) return false;
    var tag = el.tagName;
    if (tag === 'CANVAS' || tag === 'BODY' || tag === 'HTML') return true;
    if (el.closest && el.closest('canvas')) return true;
    if (el.closest && el.closest('.renderTargetWrapper, .bookReaderContent, #renderTargetWrapper')) return true;
    return false;
  }

  function fireKey(key, keyCode) {
    var target = (document.activeElement && document.activeElement !== document.body)
      ? document.activeElement : document.body;
    [target, document, window].forEach(function (t) {
      ['keydown', 'keyup'].forEach(function (type) {
        t.dispatchEvent(new KeyboardEvent(type, {
          key: key, code: key, keyCode: keyCode, which: keyCode,
          bubbles: true, cancelable: true
        }));
      });
    });
  }

  function flipPage(dir) {
    if (dir < 0) fireKey('ArrowLeft', 37);
    else fireKey('ArrowRight', 39);
  }

  function onClickCapture(e) {
    var w = window.innerWidth;
    var x = e.clientX;
    if (x > w * 0.15 && x < w * 0.85) return;
    if (!isBookSurface(e.target)) return;
    flipPage(x < w * 0.5 ? -1 : 1);
  }

  function onKeyDown(e) {
    var el = document.activeElement;
    if (el && /INPUT|TEXTAREA/.test(el.tagName)) return;
    if (e.code === 'Space' && !e.defaultPrevented) {
      e.preventDefault();
      flipPage(e.shiftKey ? -1 : 1);
    }
  }

  /* 交给 Flutter 侧调用的开关 */
  function toggleImmersive() {
    document.documentElement.classList.toggle('anx-immersive');
    return document.documentElement.classList.contains('anx-immersive');
  }

  if (window.__anxWeread && window.__anxWeread.reapply) {
    window.__anxWeread.reapply();
    return;
  }

  window.__anxWeread = {
    toggleImmersive: toggleImmersive,
    reapply: function () {
      ensureStyle();
      if (!window.__anxWeread._bound) {
        document.addEventListener('click', onClickCapture, true);
        document.addEventListener('keydown', onKeyDown);
        window.__anxWeread._bound = true;
      }
    }
  };

  window.__anxWeread.reapply();
  console.log('[anx-weread] injected');
})();
'''
        .replaceAll('__CSS__', jsonEncode(css));
  }
}
