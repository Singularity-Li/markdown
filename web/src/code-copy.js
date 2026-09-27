(function () {
  const escapeHTML = (value) => value.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
  const colors = {
    'hljs-comment': '#6e7781', 'hljs-quote': '#6e7781',
    'hljs-keyword': '#cf222e', 'hljs-selector-tag': '#cf222e', 'hljs-literal': '#cf222e',
    'hljs-string': '#0a3069', 'hljs-regexp': '#0a3069',
    'hljs-title': '#953800', 'hljs-name': '#953800',
    'hljs-number': '#0550ae', 'hljs-variable': '#0550ae', 'hljs-symbol': '#0550ae',
    'hljs-type': '#8250df', 'hljs-attr': '#116329', 'hljs-meta': '#116329',
    'hljs-built_in': '#953800', 'hljs-addition': '#116329', 'hljs-deletion': '#cf222e',
  };

  function inlineHighlight(node) {
    if (node.nodeType === Node.TEXT_NODE) return escapeHTML(node.textContent);
    if (node.nodeType !== Node.ELEMENT_NODE) return '';
    const classes = Array.from(node.classList);
    const color = classes.map((name) => colors[name]).find(Boolean);
    const content = Array.from(node.childNodes).map(inlineHighlight).join('');
    return color ? `<span style="color:${color}">${content}</span>` : content;
  }

  window.copyFormattedCode = function (code, language) {
    const label = String(language || '').trim();
    let highlighted = escapeHTML(code);
    try {
      if (window.hljs) {
        const result = label && hljs.getLanguage(label)
          ? hljs.highlight(code, { language: label })
          : hljs.highlightAuto(code);
        const content = document.createElement('code');
        content.innerHTML = result.value;
        highlighted = Array.from(content.childNodes).map(inlineHighlight).join('');
      }
    } catch (_) { /* Unsupported languages still copy as a formatted code block. */ }
    const heading = label ? `<div style="font:12px -apple-system,sans-serif;color:#57606a;margin-bottom:6px">${escapeHTML(label)}</div>` : '';
    const html = `${heading}<pre style="font:13px/1.5 Menlo,monospace;white-space:pre-wrap;background:#f6f8fa;color:#24292f;padding:12px;border-radius:8px"><code>${highlighted}</code></pre>`;
    window.webkit?.messageHandlers.copyCode?.postMessage({ text: code, html });
  };
})();
