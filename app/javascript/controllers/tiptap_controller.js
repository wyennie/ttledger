import { Controller } from "@hotwired/stimulus";
import { Editor, Extension, mergeAttributes } from '@tiptap/core'
import StarterKit from '@tiptap/starter-kit'
import Link from '@tiptap/extension-link'
import Image from '@tiptap/extension-image'
import Mention from '@tiptap/extension-mention'
import Underline from '@tiptap/extension-underline'
import TaskList from '@tiptap/extension-task-list'
import TaskItem from '@tiptap/extension-task-item'
import Table from '@tiptap/extension-table'
import TableRow from '@tiptap/extension-table-row'
import TableHeader from '@tiptap/extension-table-header'
import TableCell from '@tiptap/extension-table-cell'
import Suggestion from '@tiptap/suggestion'
import { NodeSelection } from 'prosemirror-state'

const debounce = function(func, wait, immediate) {
  let timeout, result;
  return function() {
    let context = this, args = arguments;
    let later = function() {
      timeout = null;
      if (!immediate) result = func.apply(context, args);
    };
    let callNow = immediate && !timeout;
    clearTimeout(timeout);
    timeout = setTimeout(later, wait);
    if (callNow) result = func.apply(context, args);
    return result;
  };
};

const EntityMention = Mention.extend({
  name: "mention",
  addAttributes() {
    return {
      id: {
        default: null,
        parseHTML: el => el.getAttribute("data-entity-id"),
        renderHTML: attrs => attrs.id ? { "data-entity-id": attrs.id } : {},
      },
      label: {
        default: null,
        parseHTML: el => el.getAttribute("data-entity-label"),
        renderHTML: attrs => attrs.label ? { "data-entity-label": attrs.label } : {},
      },
      kind: {
        default: null,
        parseHTML: el => el.getAttribute("data-entity-type"),
        renderHTML: attrs => attrs.kind ? { "data-entity-type": attrs.kind } : {},
      },
    };
  },
  parseHTML() {
    return [{ tag: 'span[data-mention="entity"]' }];
  },
  renderHTML({ node, HTMLAttributes }) {
    return [
      "span",
      mergeAttributes({ "data-mention": "entity", class: "mention" }, HTMLAttributes),
      `@${node.attrs.label ?? node.attrs.id}`,
    ];
  },
  renderText({ node }) {
    return `@${node.attrs.label ?? node.attrs.id}`;
  },
});

const SLASH_ITEMS = [
  {
    title: "Heading 1",
    description: "Big section heading",
    keywords: ["h1", "heading", "title"],
    run: ({ editor, range }) => editor.chain().focus().deleteRange(range).setNode("heading", { level: 1 }).run(),
  },
  {
    title: "Heading 2",
    description: "Medium section heading",
    keywords: ["h2", "heading"],
    run: ({ editor, range }) => editor.chain().focus().deleteRange(range).setNode("heading", { level: 2 }).run(),
  },
  {
    title: "Heading 3",
    description: "Small section heading",
    keywords: ["h3", "heading"],
    run: ({ editor, range }) => editor.chain().focus().deleteRange(range).setNode("heading", { level: 3 }).run(),
  },
  {
    title: "Bullet list",
    description: "A simple bulleted list",
    keywords: ["bullet", "list", "ul"],
    run: ({ editor, range }) => editor.chain().focus().deleteRange(range).toggleBulletList().run(),
  },
  {
    title: "Ordered list",
    description: "A numbered list",
    keywords: ["ordered", "list", "ol", "numbered"],
    run: ({ editor, range }) => editor.chain().focus().deleteRange(range).toggleOrderedList().run(),
  },
  {
    title: "Task list",
    description: "Checkable to-do items",
    keywords: ["task", "todo", "checkbox", "check"],
    run: ({ editor, range }) => editor.chain().focus().deleteRange(range).toggleTaskList().run(),
  },
  {
    title: "Quote",
    description: "Blockquote",
    keywords: ["quote", "blockquote"],
    run: ({ editor, range }) => editor.chain().focus().deleteRange(range).toggleBlockquote().run(),
  },
  {
    title: "Code block",
    description: "Multi-line code",
    keywords: ["code", "codeblock", "pre"],
    run: ({ editor, range }) => editor.chain().focus().deleteRange(range).toggleCodeBlock().run(),
  },
  {
    title: "Divider",
    description: "Horizontal rule",
    keywords: ["divider", "hr", "rule", "line"],
    run: ({ editor, range }) => editor.chain().focus().deleteRange(range).setHorizontalRule().run(),
  },
  {
    title: "Image (URL)",
    description: "Insert an image from a URL",
    keywords: ["image", "img", "picture", "url"],
    run: ({ editor, range }) => {
      const url = window.prompt("Image URL");
      if (!url || !url.trim()) {
        editor.chain().focus().deleteRange(range).run();
        return;
      }
      editor.chain().focus().deleteRange(range).setImage({ src: url.trim() }).run();
    },
  },
  {
    title: "Table",
    description: "Insert a 3×3 table",
    keywords: ["table", "grid"],
    run: ({ editor, range }) => editor.chain().focus().deleteRange(range)
      .insertTable({ rows: 3, cols: 3, withHeaderRow: true }).run(),
  },
];

function filterSlashItems(query) {
  const q = (query || "").trim().toLowerCase();
  if (!q) return SLASH_ITEMS;
  return SLASH_ITEMS.filter(item => {
    const haystack = [item.title, item.description, ...(item.keywords || [])].join(" ").toLowerCase();
    return haystack.includes(q);
  });
}

class SlashMenu {
  constructor() {
    this.el = document.createElement("div");
    this.el.className = "slash-menu hidden";
    document.body.appendChild(this.el);
    this.items = [];
    this.selected = 0;
    this.command = null;
  }

  show({ items, command, clientRect }) {
    this.items = items;
    this.command = command;
    this.selected = 0;
    this.render();
    this.position(clientRect);
    this.el.classList.remove("hidden");
  }

  update({ items, command, clientRect }) {
    this.items = items;
    this.command = command;
    if (this.selected >= items.length) this.selected = 0;
    this.render();
    this.position(clientRect);
  }

  hide() { this.el.classList.add("hidden"); }
  destroy() { if (this.el.parentNode) this.el.parentNode.removeChild(this.el); }

  position(clientRect) {
    if (!clientRect) return;
    const rect = clientRect();
    if (!rect) return;
    this.el.style.top  = `${window.scrollY + rect.bottom + 4}px`;
    this.el.style.left = `${window.scrollX + rect.left}px`;
  }

  render() {
    if (this.items.length === 0) {
      this.el.innerHTML = `<div class="slash-menu__empty">No matches.</div>`;
      return;
    }
    this.el.innerHTML = this.items.map((item, idx) => `
      <button type="button" data-idx="${idx}"
              class="slash-menu__option ${idx === this.selected ? 'slash-menu__option--active' : ''}">
        <span class="slash-menu__title">${escapeHtml(item.title)}</span>
        <span class="slash-menu__desc">${escapeHtml(item.description)}</span>
      </button>
    `).join("");
    this.el.querySelectorAll("button[data-idx]").forEach(btn => {
      btn.addEventListener("mousedown", (event) => {
        event.preventDefault();
        this.selected = Number(btn.dataset.idx);
        this.commit();
      });
    });
  }

  onKeyDown({ event }) {
    if (this.el.classList.contains("hidden")) return false;
    if (event.key === "ArrowDown") {
      this.selected = (this.selected + 1) % Math.max(this.items.length, 1);
      this.render();
      return true;
    }
    if (event.key === "ArrowUp") {
      this.selected = (this.selected - 1 + this.items.length) % Math.max(this.items.length, 1);
      this.render();
      return true;
    }
    if (event.key === "Enter") {
      this.commit();
      return true;
    }
    if (event.key === "Escape") {
      this.hide();
      return true;
    }
    return false;
  }

  commit() {
    const item = this.items[this.selected];
    if (item && this.command) this.command(item);
  }
}

function escapeHtml(str) {
  return String(str ?? "").replace(/[&<>"']/g, c => ({
    "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;"
  }[c]));
}

const SlashCommand = (slashMenu) => Extension.create({
  name: "slashCommand",
  addProseMirrorPlugins() {
    return [
      Suggestion({
        editor: this.editor,
        char: "/",
        startOfLine: true,
        allowSpaces: true,
        items: ({ query }) => filterSlashItems(query),
        command: ({ editor, range, props }) => {
          props.run({ editor, range });
        },
        render: () => ({
          onStart: props => slashMenu.show({
            items: props.items,
            clientRect: props.clientRect,
            command: (item) => props.command(item),
          }),
          onUpdate: props => slashMenu.update({
            items: props.items,
            clientRect: props.clientRect,
            command: (item) => props.command(item),
          }),
          onKeyDown: props => slashMenu.onKeyDown(props),
          onExit: () => slashMenu.hide(),
        }),
      }),
    ];
  },
});

class DragHandle {
  constructor({ editor }) {
    this.editor = editor;
    this.blockPos = null;
    this.draggingFrom = null;

    this.handle = document.createElement("div");
    this.handle.className = "editor-drag-handle hidden";
    this.handle.setAttribute("draggable", "true");
    this.handle.setAttribute("contenteditable", "false");
    this.handle.title = "Drag to move block";
    this.handle.innerHTML = `<svg viewBox="0 0 10 16" width="10" height="16" fill="currentColor" aria-hidden="true">
      <circle cx="2" cy="3"  r="1.4"/><circle cx="8" cy="3"  r="1.4"/>
      <circle cx="2" cy="8"  r="1.4"/><circle cx="8" cy="8"  r="1.4"/>
      <circle cx="2" cy="13" r="1.4"/><circle cx="8" cy="13" r="1.4"/>
    </svg>`;
    document.body.appendChild(this.handle);

    this.onMove      = this.onMove.bind(this);
    this.onLeave     = () => this.scheduleHide();
    this.onDragStart = this.onDragStart.bind(this);
    this.onDragEnd   = this.onDragEnd.bind(this);
    this.onDragOver  = this.onDragOver.bind(this);
    this.onDrop      = this.onDrop.bind(this);

    editor.view.dom.addEventListener("mousemove", this.onMove);
    editor.view.dom.addEventListener("mouseleave", this.onLeave);
    editor.view.dom.addEventListener("dragover", this.onDragOver);
    editor.view.dom.addEventListener("drop", this.onDrop);

    this.handle.addEventListener("mouseenter", () => this.cancelHide());
    this.handle.addEventListener("mouseleave", () => this.scheduleHide());
    this.handle.addEventListener("dragstart", this.onDragStart);
    this.handle.addEventListener("dragend",   this.onDragEnd);
  }

  onMove(event) {
    if (this.draggingFrom !== null) return;
    const view = this.editor.view;
    const result = view.posAtCoords({ top: event.clientY, left: event.clientX });
    if (!result) {
      this.scheduleHide();
      return;
    }
    const $pos = view.state.doc.resolve(result.pos);
    if ($pos.depth < 1) {
      this.scheduleHide();
      return;
    }
    const blockStart = $pos.before(1);
    const node = view.state.doc.nodeAt(blockStart);
    if (!node) {
      this.scheduleHide();
      return;
    }
    this.blockPos = blockStart;
    const dom = view.nodeDOM(blockStart);
    if (!dom || dom.nodeType !== 1) {
      this.scheduleHide();
      return;
    }
    const rect = dom.getBoundingClientRect();
    this.handle.style.top  = `${window.scrollY + rect.top + 4}px`;
    this.handle.style.left = `${window.scrollX + rect.left - 22}px`;
    this.handle.classList.remove("hidden");
    this.cancelHide();
  }

  scheduleHide() {
    this.cancelHide();
    this.hideTimer = setTimeout(() => this.handle.classList.add("hidden"), 200);
  }

  cancelHide() { clearTimeout(this.hideTimer); }

  onDragStart(event) {
    if (this.blockPos === null) {
      event.preventDefault();
      return;
    }
    const { state, view } = this.editor;
    const node = state.doc.nodeAt(this.blockPos);
    if (!node) {
      event.preventDefault();
      return;
    }
    this.draggingFrom = { from: this.blockPos, size: node.nodeSize };
    event.dataTransfer.setData("application/x-tiptap-block", "1");
    event.dataTransfer.effectAllowed = "move";
    try {
      view.dispatch(state.tr.setSelection(NodeSelection.create(state.doc, this.blockPos)));
      const dom = view.nodeDOM(this.blockPos);
      if (dom && dom.nodeType === 1) {
        event.dataTransfer.setDragImage(dom, 0, 0);
      }
    } catch (_e) {}
  }

  onDragEnd() {
    this.draggingFrom = null;
  }

  onDragOver(event) {
    if (this.draggingFrom === null) return;
    event.preventDefault();
    event.dataTransfer.dropEffect = "move";
  }

  onDrop(event) {
    if (this.draggingFrom === null) return;
    event.preventDefault();
    const { from, size } = this.draggingFrom;
    this.draggingFrom = null;
    const view = this.editor.view;
    const result = view.posAtCoords({ top: event.clientY, left: event.clientX });
    if (!result) return;
    const $drop = view.state.doc.resolve(result.pos);
    if ($drop.depth < 1) return;
    const targetStart = $drop.before(1);
    const targetNode  = view.state.doc.nodeAt(targetStart);
    if (!targetNode) return;
    const targetDom = view.nodeDOM(targetStart);
    let insertAt = targetStart;
    if (targetDom && targetDom.nodeType === 1) {
      const rect = targetDom.getBoundingClientRect();
      const midpoint = rect.top + rect.height / 2;
      if (event.clientY > midpoint) insertAt = targetStart + targetNode.nodeSize;
    }
    if (insertAt === from || insertAt === from + size) return;

    const node = view.state.doc.nodeAt(from);
    if (!node) return;
    let tr = view.state.tr.delete(from, from + size);
    let adjustedInsert = insertAt;
    if (insertAt > from) adjustedInsert -= size;
    tr = tr.insert(adjustedInsert, node);
    view.dispatch(tr);
    this.scheduleHide();
  }

  destroy() {
    const dom = this.editor.view?.dom;
    if (dom) {
      dom.removeEventListener("mousemove", this.onMove);
      dom.removeEventListener("mouseleave", this.onLeave);
      dom.removeEventListener("dragover", this.onDragOver);
      dom.removeEventListener("drop", this.onDrop);
    }
    if (this.handle.parentNode) this.handle.parentNode.removeChild(this.handle);
  }
}

class LinkPopover {
  constructor({ editor }) {
    this.editor = editor;
    this.el = document.createElement("div");
    this.el.className = "editor-link-popover hidden";
    this.el.innerHTML = `
      <input type="url" class="editor-link-popover__input" placeholder="https://example.com" />
      <button type="button" class="editor-link-popover__btn" data-action="save">Save</button>
      <a class="editor-link-popover__btn editor-link-popover__open" target="_blank" rel="noopener">Open</a>
      <button type="button" class="editor-link-popover__btn editor-link-popover__btn--danger" data-action="remove">Remove</button>
    `;
    document.body.appendChild(this.el);
    this.input    = this.el.querySelector("input");
    this.saveBtn  = this.el.querySelector('[data-action="save"]');
    this.removeBtn= this.el.querySelector('[data-action="remove"]');
    this.openA    = this.el.querySelector('.editor-link-popover__open');
    this.markRange = null;
    this.suppressAutoUntil = 0;

    this.input.addEventListener("keydown", (event) => {
      if (event.key === "Enter") {
        event.preventDefault();
        this.commit();
      } else if (event.key === "Escape") {
        event.preventDefault();
        this.hide();
        this.editor.commands.focus();
      }
    });
    this.saveBtn.addEventListener("mousedown", (event) => {
      event.preventDefault();
      this.commit();
    });
    this.removeBtn.addEventListener("mousedown", (event) => {
      event.preventDefault();
      this.remove();
    });

    this.onSelectionChange = this.onSelectionChange.bind(this);
    this.onScrollOrResize = this.onScrollOrResize.bind(this);
    editor.on("selectionUpdate", this.onSelectionChange);
    editor.on("transaction", this.onSelectionChange);
    window.addEventListener("scroll", this.onScrollOrResize, true);
    window.addEventListener("resize", this.onScrollOrResize);
    document.addEventListener("mousedown", (event) => {
      if (this.el.contains(event.target)) return;
      if (this.editor.view.dom.contains(event.target)) return;
      this.hide();
    });
  }

  onSelectionChange() {
    if (Date.now() < this.suppressAutoUntil) return;
    const editor = this.editor;
    const { state } = editor;
    const { from, to, empty } = state.selection;
    if (!empty) {
      this.hide();
      return;
    }
    if (!editor.isActive("link")) {
      this.hide();
      return;
    }
    this.openForExistingLink();
  }

  openForExistingLink() {
    const range = this.markRangeAtSelection("link");
    if (!range) return this.hide();
    const href = this.editor.getAttributes("link")?.href || "";
    this.show({ range, href, focusInput: false });
  }

  openForSelection() {
    const editor = this.editor;
    const { state } = editor;
    const { from, to, empty } = state.selection;
    if (empty && !editor.isActive("link")) return;

    if (editor.isActive("link")) {
      this.openForExistingLink();
      this.input.focus();
      this.input.select();
      return;
    }
    this.show({ range: { from, to }, href: "", focusInput: true });
  }

  markRangeAtSelection(markName) {
    const { state } = this.editor;
    const { $from } = state.selection;
    const mark = state.schema.marks[markName];
    if (!mark) return null;
    let start = $from.pos;
    let end = $from.pos;
    const node = $from.parent;
    const offset = $from.parentOffset;
    let pos = $from.start();
    let cursor = 0;
    node.forEach((child, _o, _i) => {
      const childEnd = cursor + child.nodeSize;
      if (offset >= cursor && offset <= childEnd && child.marks.some(m => m.type === mark)) {
        start = pos + cursor;
        end = pos + childEnd;
      }
      cursor = childEnd;
    });
    if (start === end) return null;
    return { from: start, to: end };
  }

  show({ range, href, focusInput }) {
    this.markRange = range;
    this.input.value = href || "";
    this.openA.href = href || "#";
    this.openA.style.visibility = href ? "visible" : "hidden";
    this.removeBtn.style.display = href ? "" : "none";
    this.position(range);
    this.el.classList.remove("hidden");
    if (focusInput) {
      requestAnimationFrame(() => {
        this.input.focus();
        this.input.select();
      });
    }
  }

  hide() {
    this.el.classList.add("hidden");
    this.markRange = null;
  }

  commit() {
    const url = this.input.value.trim();
    if (!url) {
      this.remove();
      return;
    }
    const editor = this.editor;
    if (this.markRange) {
      editor.chain().focus()
        .setTextSelection(this.markRange)
        .extendMarkRange("link")
        .setLink({ href: url })
        .run();
    } else {
      editor.chain().focus().extendMarkRange("link").setLink({ href: url }).run();
    }
    this.suppressAutoUntil = Date.now() + 200;
    this.hide();
  }

  remove() {
    const editor = this.editor;
    if (this.markRange) {
      editor.chain().focus()
        .setTextSelection(this.markRange)
        .extendMarkRange("link")
        .unsetLink()
        .run();
    } else {
      editor.chain().focus().unsetLink().run();
    }
    this.suppressAutoUntil = Date.now() + 200;
    this.hide();
  }

  onScrollOrResize() {
    if (this.el.classList.contains("hidden") || !this.markRange) return;
    this.position(this.markRange);
  }

  position(range) {
    try {
      const start = this.editor.view.coordsAtPos(range.from);
      const end   = this.editor.view.coordsAtPos(range.to);
      const top  = Math.max(start.bottom, end.bottom) + 6;
      const left = (start.left + end.left) / 2;
      this.el.style.top  = `${window.scrollY + top}px`;
      this.el.style.left = `${window.scrollX + left - this.el.offsetWidth / 2}px`;
    } catch (_e) {
      this.hide();
    }
  }

  destroy() {
    window.removeEventListener("scroll", this.onScrollOrResize, true);
    window.removeEventListener("resize", this.onScrollOrResize);
    if (this.el.parentNode) this.el.parentNode.removeChild(this.el);
  }
}

class BubbleMenu {
  constructor({ editor, linkPopover }) {
    this.editor = editor;
    this.linkPopover = linkPopover;
    this.el = document.createElement("div");
    this.el.className = "editor-bubble-menu hidden";
    this.el.innerHTML = this.template();
    document.body.appendChild(this.el);

    this.bind();
    this.onSelectionChange = this.onSelectionChange.bind(this);
    this.onScrollOrResize = this.onScrollOrResize.bind(this);
    editor.on("selectionUpdate", this.onSelectionChange);
    editor.on("transaction", this.onSelectionChange);
    editor.on("blur", () => this.hide());
    window.addEventListener("scroll", this.onScrollOrResize, true);
    window.addEventListener("resize", this.onScrollOrResize);
  }

  template() {
    const icon = (svg) => `<svg viewBox="0 0 16 16" width="14" height="14" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${svg}</svg>`;
    return `
      <button type="button" data-cmd="bold"      title="Bold (⌘B)">${icon('<path d="M4 3h4.5a2.5 2.5 0 0 1 0 5H4zM4 8h5a2.5 2.5 0 0 1 0 5H4z"/>')}</button>
      <button type="button" data-cmd="italic"    title="Italic (⌘I)">${icon('<line x1="10" y1="3" x2="6" y2="13"/><line x1="6" y1="3" x2="12" y2="3"/><line x1="4" y1="13" x2="10" y2="13"/>')}</button>
      <button type="button" data-cmd="underline" title="Underline (⌘U)">${icon('<path d="M4 3v5a4 4 0 0 0 8 0V3"/><line x1="3" y1="13" x2="13" y2="13"/>')}</button>
      <button type="button" data-cmd="strike"    title="Strikethrough">${icon('<path d="M5 5a3 3 0 0 1 6 0"/><path d="M5 11a3 3 0 0 0 6 0"/><line x1="2.5" y1="8" x2="13.5" y2="8"/>')}</button>
      <button type="button" data-cmd="code"      title="Inline code">${icon('<polyline points="5 5 2 8 5 11"/><polyline points="11 5 14 8 11 11"/>')}</button>
      <span class="editor-bubble-menu__sep"></span>
      <button type="button" data-cmd="link"      title="Link">${icon('<path d="M7 9a3 3 0 0 0 4 0l2-2a3 3 0 0 0-4-4L8 4"/><path d="M9 7a3 3 0 0 0-4 0L3 9a3 3 0 0 0 4 4l1-1"/>')}</button>
    `;
  }

  bind() {
    this.el.querySelectorAll("button[data-cmd]").forEach(btn => {
      btn.addEventListener("mousedown", (event) => {
        event.preventDefault();
        const cmd = btn.dataset.cmd;
        this.run(cmd);
      });
    });
  }

  run(cmd) {
    const editor = this.editor;
    switch (cmd) {
      case "bold":      editor.chain().focus().toggleBold().run();      break;
      case "italic":    editor.chain().focus().toggleItalic().run();    break;
      case "underline": editor.chain().focus().toggleUnderline().run(); break;
      case "strike":    editor.chain().focus().toggleStrike().run();    break;
      case "code":      editor.chain().focus().toggleCode().run();      break;
      case "link":      this.linkPopover?.openForSelection();           break;
    }
    this.refreshActiveStates();
  }

  refreshActiveStates() {
    const editor = this.editor;
    this.el.querySelectorAll("button[data-cmd]").forEach(btn => {
      const cmd = btn.dataset.cmd;
      let active = false;
      if (cmd === "bold")      active = editor.isActive("bold");
      if (cmd === "italic")    active = editor.isActive("italic");
      if (cmd === "underline") active = editor.isActive("underline");
      if (cmd === "strike")    active = editor.isActive("strike");
      if (cmd === "code")      active = editor.isActive("code");
      if (cmd === "link")      active = editor.isActive("link");
      btn.classList.toggle("editor-bubble-menu__btn--active", active);
    });
  }

  onSelectionChange() {
    const { state } = this.editor;
    const { from, to, empty } = state.selection;
    if (empty || !this.editor.isFocused) {
      this.hide();
      return;
    }
    this.position(from, to);
    this.refreshActiveStates();
    this.el.classList.remove("hidden");
  }

  onScrollOrResize() {
    if (this.el.classList.contains("hidden")) return;
    const { from, to } = this.editor.state.selection;
    this.position(from, to);
  }

  position(from, to) {
    try {
      const start = this.editor.view.coordsAtPos(from);
      const end   = this.editor.view.coordsAtPos(to);
      const rect = {
        top: Math.min(start.top, end.top),
        left: (start.left + end.left) / 2,
        bottom: Math.max(start.bottom, end.bottom),
      };
      this.el.style.top  = `${window.scrollY + rect.top - this.el.offsetHeight - 8}px`;
      this.el.style.left = `${window.scrollX + rect.left - this.el.offsetWidth / 2}px`;
    } catch (_e) {
      this.hide();
    }
  }

  hide() {
    this.el.classList.add("hidden");
  }

  destroy() {
    window.removeEventListener("scroll", this.onScrollOrResize, true);
    window.removeEventListener("resize", this.onScrollOrResize);
    if (this.el.parentNode) this.el.parentNode.removeChild(this.el);
  }
}

class SuggestionPopup {
  constructor({ onCreate } = {}) {
    this.el = document.createElement("div");
    this.el.className = "mention-popup hidden";
    document.body.appendChild(this.el);
    this.items = [];
    this.selected = 0;
    this.command = null;
    this.query = "";
    this.onCreate = onCreate;
    this.creating = false;
  }

  show({ items, command, clientRect, query }) {
    this.items = items;
    this.command = command;
    this.query = query || "";
    this.selected = 0;
    this.render();
    this.position(clientRect);
    this.el.classList.remove("hidden");
  }

  update({ items, command, clientRect, query }) {
    this.items = items;
    this.command = command;
    this.query = query || "";
    if (this.selected >= items.length) this.selected = 0;
    this.render();
    this.position(clientRect);
  }

  hide() {
    this.el.classList.add("hidden");
  }

  destroy() {
    if (this.el.parentNode) this.el.parentNode.removeChild(this.el);
  }

  position(clientRect) {
    if (!clientRect) return;
    const rect = clientRect();
    if (!rect) return;
    this.el.style.top = `${window.scrollY + rect.bottom + 4}px`;
    this.el.style.left = `${window.scrollX + rect.left}px`;
  }

  render() {
    if (this.items.length === 0) {
      const trimmed = this.query.trim();
      if (trimmed && this.onCreate) {
        this.el.innerHTML = `
          <div class="mention-popup__empty">No matching entities.</div>
          <button type="button"
                  data-create
                  class="mention-popup__option mention-popup__option--create">
            <span class="mention-popup__name">${this.creating ? "Creating…" : `Create entity “${this.escape(trimmed)}”`}</span>
          </button>
        `;
        const btn = this.el.querySelector("button[data-create]");
        if (btn) {
          btn.addEventListener("mousedown", (event) => {
            event.preventDefault();
            this.createFromQuery();
          });
        }
      } else {
        this.el.innerHTML = `<div class="mention-popup__empty">No matching entities. <span class="mention-popup__empty-hint">Type a name to create one.</span></div>`;
      }
      return;
    }
    this.el.innerHTML = this.items.map((item, idx) => `
      <button type="button"
              data-idx="${idx}"
              class="mention-popup__option ${idx === this.selected ? 'mention-popup__option--active' : ''}">
        <span class="mention-popup__name">${this.escape(item.name)}</span>
        <span class="mention-popup__kind">${this.escape(item.kind)}</span>
      </button>
    `).join("");
    this.el.querySelectorAll("button[data-idx]").forEach(btn => {
      btn.addEventListener("mousedown", (event) => {
        event.preventDefault();
        this.selected = Number(btn.dataset.idx);
        this.commit();
      });
    });
  }

  async createFromQuery() {
    if (this.creating) return;
    const name = this.query.trim();
    if (!name || !this.onCreate || !this.command) return;
    this.creating = true;
    this.render();
    try {
      const entity = await this.onCreate(name);
      if (entity && entity.id) {
        this.command({ id: entity.id, label: entity.name, kind: entity.kind });
      }
    } finally {
      this.creating = false;
    }
  }

  escape(str) {
    return String(str).replace(/[&<>"']/g, c => ({
      "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;"
    }[c]));
  }

  onKeyDown({ event }) {
    if (this.el.classList.contains("hidden")) return false;

    if (event.key === "Enter" && this.items.length === 0) {
      const trimmed = this.query.trim();
      if (trimmed && this.onCreate) {
        this.createFromQuery();
        return true;
      }
    }

    if (event.key === "ArrowDown") {
      this.selected = (this.selected + 1) % Math.max(this.items.length, 1);
      this.render();
      return true;
    }
    if (event.key === "ArrowUp") {
      this.selected = (this.selected - 1 + this.items.length) % Math.max(this.items.length, 1);
      this.render();
      return true;
    }
    if (event.key === "Enter") {
      this.commit();
      return true;
    }
    if (event.key === "Escape") {
      this.hide();
      return true;
    }
    return false;
  }

  commit() {
    const item = this.items[this.selected];
    if (item && this.command) {
      this.command({ id: item.id, label: item.name, kind: item.kind });
    }
  }
}

export default class extends Controller {
  static values = { campaignId: Number };

  connect() {
    const masterElement = this.element;

    masterElement.setAttribute("data-action", "input->tiptap#formSubmit");
    masterElement.setAttribute("data-action", "keyup->tiptap#formSubmit");

    this.popup = new SuggestionPopup({
      onCreate: name => this.quickCreateEntity(name),
    });
    this.slashMenu = new SlashMenu();
    this.initTiptap(masterElement);
    this.formSubmit = debounce(this.formSubmit.bind(this), 500);
    masterElement.addEventListener('click', this.handleClick.bind(this));
  }

  formSubmit(event) {
    event.preventDefault();
    event.stopPropagation();
    const formField = this.element.querySelector(".tiptap__field-content");
    formField.value = this.element.editor.getHTML();
    Turbo.navigator.submitForm(this.element);
  }

  initTiptap(masterElement) {
    const textArea = this.element.querySelector(".tiptap__textarea");
    const tipTapContent = textArea.innerHTML;
    textArea.innerHTML = "";

    const popup = this.popup;
    const fetchSuggestions = this.fetchSuggestions.bind(this);

    const editor = new Editor({
      element: textArea,
      extensions: [
        StarterKit,
        Underline,
        TaskList,
        TaskItem.configure({ nested: true }),
        Table.configure({ resizable: true }),
        TableRow,
        TableHeader,
        TableCell,
        SlashCommand(this.slashMenu),
        Link,
        Image,
        EntityMention.configure({
          HTMLAttributes: { class: "mention" },
          suggestion: {
            char: "@",
            items: ({ query }) => fetchSuggestions(query),
            render: () => ({
              onStart: props => popup.show(props),
              onUpdate: props => popup.update(props),
              onKeyDown: props => popup.onKeyDown(props),
              onExit: () => popup.hide(),
            }),
          },
        }),
      ],
      content: tipTapContent,
      editable: true,
    });

    masterElement.editor = editor;
    this.linkPopover = new LinkPopover({ editor });
    this.bubble = new BubbleMenu({ editor, linkPopover: this.linkPopover });
    this.dragHandle = new DragHandle({ editor });
    this.attachImageHandlers(textArea, editor);
  }

  attachImageHandlers(textArea, editor) {
    const insertImageFile = (file) => {
      if (!file || !file.type.startsWith("image/")) return;
      const reader = new FileReader();
      reader.onload = () => {
        editor.chain().focus().setImage({ src: reader.result }).run();
      };
      reader.readAsDataURL(file);
    };

    const handlePaste = (event) => {
      const items = event.clipboardData?.items || [];
      for (const item of items) {
        if (item.kind === "file" && item.type.startsWith("image/")) {
          event.preventDefault();
          insertImageFile(item.getAsFile());
          return;
        }
      }
    };

    const handleDragOver = (event) => {
      if (event.dataTransfer?.types?.includes("Files")) {
        event.preventDefault();
      }
    };

    const handleDrop = (event) => {
      const files = event.dataTransfer?.files;
      if (!files || files.length === 0) return;
      const images = Array.from(files).filter(f => f.type.startsWith("image/"));
      if (images.length === 0) return;
      event.preventDefault();
      images.forEach(insertImageFile);
    };

    textArea.addEventListener("paste", handlePaste);
    textArea.addEventListener("dragover", handleDragOver);
    textArea.addEventListener("drop", handleDrop);
    this._imageHandlers = { textArea, handlePaste, handleDragOver, handleDrop };
  }

  async fetchSuggestions(query) {
    if (!this.hasCampaignIdValue) return [];
    const url = `/campaigns/${this.campaignIdValue}/entities/suggestions?q=${encodeURIComponent(query || "")}`;
    try {
      const res = await fetch(url, { headers: { "Accept": "application/json" } });
      if (!res.ok) return [];
      return await res.json();
    } catch (_e) {
      return [];
    }
  }

  async quickCreateEntity(name) {
    if (!this.hasCampaignIdValue) return null;
    const csrf = document.querySelector('meta[name="csrf-token"]')?.content;
    try {
      const res = await fetch(`/campaigns/${this.campaignIdValue}/entities/quick_create`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          ...(csrf ? { "X-CSRF-Token": csrf } : {}),
        },
        body: JSON.stringify({ name }),
      });
      if (!res.ok) return null;
      return await res.json();
    } catch (_e) {
      return null;
    }
  }

  disconnect() {
    this.element.editor.destroy();
    this.popup?.destroy();
    this.slashMenu?.destroy();
    this.bubble?.destroy();
    this.linkPopover?.destroy();
    this.dragHandle?.destroy();
    if (this._imageHandlers) {
      const { textArea, handlePaste, handleDragOver, handleDrop } = this._imageHandlers;
      textArea.removeEventListener("paste", handlePaste);
      textArea.removeEventListener("dragover", handleDragOver);
      textArea.removeEventListener("drop", handleDrop);
    }
    this.element.removeEventListener('click', this.handleClick.bind(this));
  }

  handleClick(event) {
    const textArea = this.element.querySelector(".tiptap__textarea");
    if (textArea.contains(event.target)) return;
    const position = this.getClickPosition(event);
    if (this.isClickBelowContent(position)) {
      this.addNewLine();
    }
  }

  getClickPosition(event) {
    return { x: event.clientX, y: event.clientY };
  }

  isClickBelowContent(position) {
    const editorRect = this.element.querySelector(".tiptap__textarea").getBoundingClientRect();
    return position.y > editorRect.bottom;
  }

  getLastEmptyLine() {
    const lines = this.element.editor.state.doc.content.content;
    return lines.find(line => line.content.size === 0);
  }

  addNewLine() {
    const editor = this.element.editor;
    this.selectLine(this.getLastEmptyLine());
    editor.chain().focus().insertContent("<p></p>").run();
  }

  selectLine(line) {
    const position = this.element.editor.state.doc.content.size;
    this.element.editor.commands.setTextSelection(position);
  }
}
