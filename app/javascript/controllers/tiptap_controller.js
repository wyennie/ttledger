import { Controller } from "@hotwired/stimulus";
import { Editor, mergeAttributes } from '@tiptap/core'
import StarterKit from '@tiptap/starter-kit'
import Link from '@tiptap/extension-link'
import Image from '@tiptap/extension-image'
import Mention from '@tiptap/extension-mention'
import Underline from '@tiptap/extension-underline'

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
    return `
      <button type="button" data-cmd="bold"      title="Bold"><strong>B</strong></button>
      <button type="button" data-cmd="italic"    title="Italic"><em>I</em></button>
      <button type="button" data-cmd="underline" title="Underline"><u>U</u></button>
      <button type="button" data-cmd="strike"    title="Strikethrough"><s>S</s></button>
      <button type="button" data-cmd="code"      title="Inline code"><code>&lt;/&gt;</code></button>
      <span class="editor-bubble-menu__sep"></span>
      <button type="button" data-cmd="link"      title="Link">↗</button>
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
    this.bubble?.destroy();
    this.linkPopover?.destroy();
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
