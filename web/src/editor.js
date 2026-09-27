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
import './code-copy.js';

const bridge = window.webkit?.messageHandlers;
let editor;
let userInteracted = false;
let lastMarkdown;
const pendingUploads = new Map();
let uploadSequence = 0;
let copiedBlock;
const searchable = (label, pinyin, initials) => `${label} · ${pinyin} ${initials}`;
const aliases = {
  正文: ['zhengwen', 'zw'], 一级标题: ['yijibiaoti', 'yjbt'], 二级标题: ['erjibiaoti', 'ejbt'],
  三级标题: ['sanjibiaoti', 'sjbt'], 四级标题: ['sijibiaoti', 'sjbt'], 五级标题: ['wujibiaoti', 'wjbt'],
  六级标题: ['liujibiaoti', 'ljbt'], 引用: ['yinyong', 'yy'], 分割线: ['fengexian', 'fgx'],
  项目列表: ['xiangmuliebiao', 'xmlb'], 编号列表: ['bianhaoliebiao', 'bhlb'],
  复选框: ['fuxuankuang', 'fxk'], 图片: ['tupian', 'tp'], 代码块: ['daimakuai', 'dmk'],
  表格: ['biaoge', 'bg'], 加粗: ['jiacu', 'jc'], 斜体: ['xieti', 'xt'],
  删除线: ['shanchuxian', 'scx'], 行内代码: ['hangneidaima', 'hndm'], 链接: ['lianjie', 'lj'],
};
const label = (value) => searchable(value, ...aliases[value]);

function decorateEditor() {
  document.querySelectorAll('.milkdown-slash-menu .menu-groups li span:last-child').forEach((element) => {
    if (element.textContent.includes(' · ')) element.textContent = element.textContent.split(' · ')[0];
  });
  document.querySelectorAll('.milkdown-code-block').forEach((block) => {
    const group = block.querySelector('.tools-button-group');
    if (!group || group.querySelector('.code-theme-button')) return;
    const button = document.createElement('button');
    button.type = 'button';
    button.className = 'code-theme-button';
    button.textContent = '◐';
    button.title = '切换代码块深色/浅色';
    button.setAttribute('aria-label', button.title);
    button.addEventListener('click', () => {
      block.dataset.codeTheme = block.dataset.codeTheme === 'dark' ? 'light' : 'dark';
      button.setAttribute('aria-pressed', String(block.dataset.codeTheme === 'dark'));
    });
    group.insertBefore(button, group.firstChild);
  });
}
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
          inline.addItem('bold', { label: label('加粗'), icon: formatIcon('B'), onRun: formatCommand(toggleStrongCommand) });
          inline.addItem('italic', { label: label('斜体'), icon: formatIcon('I'), onRun: formatCommand(toggleEmphasisCommand) });
          inline.addItem('strike', { label: label('删除线'), icon: formatIcon('S'), onRun: formatCommand(toggleStrikethroughCommand) });
          inline.addItem('inline-code', { label: label('行内代码'), icon: formatIcon('<>'), onRun: formatCommand(toggleInlineCodeCommand) });
          inline.addItem('link', { label: label('链接'), icon: formatIcon('↗'), onRun: formatCommand(toggleLinkCommand, { href: 'https://' }) });
        },
        textGroup: {
          label: '文字与标题', text: { label: label('正文') },
          h1: { label: label('一级标题') }, h2: { label: label('二级标题') },
          h3: { label: label('三级标题') }, h4: { label: label('四级标题') },
          h5: { label: label('五级标题') }, h6: { label: label('六级标题') },
          quote: { label: label('引用') }, divider: { label: label('分割线') },
        },
        listGroup: {
          label: '列表与任务', bulletList: { label: label('项目列表') },
          orderedList: { label: label('编号列表') }, taskList: { label: label('复选框') },
        },
        advancedGroup: {
          label: '插入内容', image: { label: label('图片') },
          codeBlock: { label: label('代码块') }, table: { label: label('表格') }, math: null,
        },
      },
      [CrepeFeature.CodeMirror]: {
        copyText: '复制',
        onCopy: (text) => {
          const language = copiedBlock?.querySelector('.language-button')?.textContent?.trim() || '';
          window.copyFormattedCode(text, language);
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
    document.addEventListener('click', (event) => {
      const button = event.target.closest?.('.milkdown-code-block .copy-button');
      if (button) copiedBlock = button.closest('.milkdown-code-block');
    }, { capture: true });
    new MutationObserver(decorateEditor).observe(document.body, { childList: true, subtree: true, characterData: true });
    decorateEditor();
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
