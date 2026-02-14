import { Controller } from "@hotwired/stimulus";
import { Editor, mergeAttributes } from '@tiptap/core'
import StarterKit from '@tiptap/starter-kit'
import Link from '@tiptap/extension-link'
import Image from '@tiptap/extension-image'
import Mention from '@tiptap/extension-mention'

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

class SuggestionPopup {
  constructor() {
    this.el = document.createElement("div");
    this.el.className = "tiptap__mention-popup hidden absolute z-50 bg-white border border-gray-300 rounded-md shadow-lg max-h-64 overflow-y-auto min-w-[220px] text-sm";
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
      this.el.innerHTML = `<div class="px-3 py-2 text-gray-500">No matching entities. <span class="text-xs">Create one in Entities.</span></div>`;
      return;
    }
    this.el.innerHTML = this.items.map((item, idx) => `
      <button type="button"
              data-idx="${idx}"
              class="w-full text-left px-3 py-2 hover:bg-indigo-50 flex items-center justify-between gap-2 ${idx === this.selected ? 'bg-indigo-100' : ''}">
        <span class="font-medium">${this.escape(item.name)}</span>
        <span class="text-xs text-gray-500">${this.escape(item.kind)}</span>
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

  escape(str) {
    return String(str).replace(/[&<>"']/g, c => ({
      "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;"
    }[c]));
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

    this.popup = new SuggestionPopup();
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
        Link.configure({ HTMLAttributes: { class: "cursor-pointer" } }),
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

  disconnect() {
    this.element.editor.destroy();
    this.popup?.destroy();
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
