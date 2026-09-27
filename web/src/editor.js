import { Crepe, CrepeFeature } from '@milkdown/crepe';
import { commandsCtx } from '@milkdown/kit/core';
import {
  clearTextInCurrentBlockCommand, toggleEmphasisCommand, toggleInlineCodeCommand,
  toggleLinkCommand, toggleStrongCommand,
} from '@milkdown/kit/preset/commonmark';
import { toggleStrikethroughCommand } from '@milkdown/kit/preset/gfm';
import './crepe-common.css';
import '@milkdown/crepe/theme/classic.css';
import './editor.css';

const bridge = window.webkit?.messageHandlers;
let editor;
let userInteracted = false;
let lastMarkdown;
const pendingUploads = new Map();
let uploadSequence = 0;
const formatIcon = (letter) => `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24"><text x="12" y="17" text-anchor="middle" font-size="16" font-weight="600" fill="currentColor">${letter}</text></svg>`;

function formatCommand(command, payload) {
  return (ctx) => {
    const commands = ctx.get(commandsCtx);
    commands.call(clearTextInCurrentBlockCommand.key);
    commands.call(command.key, payload);
  };
}

function imageURL(url) {
  try {
    const parsed = new URL(url, document.baseURI);
    return parsed.protocol === 'file:' ? `md-image://local${parsed.pathname}` : url;
  } catch (_) {
    return url;
  }
}

async function uploadImage(file) {
  const data = await new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => resolve(String(reader.result).split(',')[1]);
    reader.onerror = reject;
    reader.readAsDataURL(file);
  });
  const id = ++uploadSequence;
  return new Promise((resolve, reject) => {
    pendingUploads.set(id, { resolve, reject });
    bridge?.imageUpload.postMessage({ id, name: file.name, type: file.type, data });
  });
}

window.markdownImageUploadResult = (id, path, error) => {
  const pending = pendingUploads.get(id);
  if (!pending) return;
  pendingUploads.delete(id);
  if (error) pending.reject(new Error(error));
  else pending.resolve(path);
};

window.startMarkdownEditor = async (markdown, sourceOffset) => {
  for (const event of ['beforeinput', 'keydown', 'pointerdown', 'paste', 'drop', 'cut']) {
    document.addEventListener(event, () => { userInteracted = true; }, { capture: true });
  }
  editor = new Crepe({
    root: '#editor',
    defaultValue: markdown,
    features: { [CrepeFeature.Latex]: false, [CrepeFeature.TopBar]: false, [CrepeFeature.AI]: false },
    featureConfigs: {
      [CrepeFeature.Placeholder]: { text: '输入内容，或键入 / 插入内容' },
      [CrepeFeature.BlockEdit]: {
        buildMenu: (builder) => {
          const inline = builder.addGroup('inline', '行内格式');
          inline.addItem('bold', { label: '加粗', icon: formatIcon('B'), onRun: formatCommand(toggleStrongCommand) });
          inline.addItem('italic', { label: '斜体', icon: formatIcon('I'), onRun: formatCommand(toggleEmphasisCommand) });
          inline.addItem('strike', { label: '删除线', icon: formatIcon('S'), onRun: formatCommand(toggleStrikethroughCommand) });
          inline.addItem('inline-code', { label: '行内代码', icon: formatIcon('<>'), onRun: formatCommand(toggleInlineCodeCommand) });
          inline.addItem('link', { label: '链接', icon: formatIcon('↗'), onRun: formatCommand(toggleLinkCommand, { href: 'https://' }) });
        },
        textGroup: {
          label: '文字与标题', text: { label: '正文' },
          h1: { label: '一级标题' }, h2: { label: '二级标题' },
          h3: { label: '三级标题' }, h4: { label: '四级标题' },
          h5: { label: '五级标题' }, h6: { label: '六级标题' },
          quote: { label: '引用' }, divider: { label: '分割线' },
        },
        listGroup: {
          label: '列表与任务', bulletList: { label: '项目列表' },
          orderedList: { label: '编号列表' }, taskList: { label: '复选框' },
        },
        advancedGroup: {
          label: '插入内容', image: { label: '图片' },
          codeBlock: { label: '代码块' }, table: { label: '表格' }, math: null,
        },
      },
      [CrepeFeature.ImageBlock]: {
        onUpload: uploadImage,
        inlineOnUpload: uploadImage,
        blockOnUpload: uploadImage,
        proxyDomURL: imageURL,
      },
    },
  });
  editor.on((listener) => {
    listener.markdownUpdated((_ctx, value) => {
      if (!userInteracted || value === lastMarkdown) return;
      lastMarkdown = value;
      bridge?.markdownChanged.postMessage(value);
    });
  });
  try {
    await editor.create();
    lastMarkdown = editor.getMarkdown();
    const surface = document.querySelector('.ProseMirror');
    surface?.setAttribute('aria-label', '可视化 Markdown 编辑器');
    document.querySelectorAll('a').forEach((link) => link.setAttribute('target', '_blank'));
    const fraction = markdown.length ? Math.min(1, Math.max(0, sourceOffset / markdown.length)) : 0;
    requestAnimationFrame(() => window.scrollTo(0, fraction * (document.body.scrollHeight - innerHeight)));
    window.addEventListener('scroll', () => {
      const height = Math.max(1, document.body.scrollHeight - innerHeight);
      bridge?.viewport.postMessage(Math.round(window.scrollY / height * editor.getMarkdown().length));
    }, { passive: true });
    bridge?.ready.postMessage(true);
  } catch (error) {
    bridge?.error.postMessage(String(error?.stack || error));
  }
};

window.markdownEditorFocus = () => document.querySelector('.ProseMirror')?.focus();
