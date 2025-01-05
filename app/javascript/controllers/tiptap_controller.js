import { Controller } from "@hotwired/stimulus";
import { Editor } from '@tiptap/core'
import StarterKit from '@tiptap/starter-kit'
import Link from '@tiptap/extension-link'
import Image from '@tiptap/extension-image'

// TODO: improve debouncer implementation.
// ideas:
// - put debouncer in it's own helper
// - replace with stimulus-use debounces
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

export default class extends Controller {
  connect() {
    const masterElement = this.element;

    masterElement.setAttribute("data-action", "input->tiptap#formSubmit");
    masterElement.setAttribute("data-action", "keyup->tiptap#formSubmit");
    
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

    const editor = new Editor({
      element: textArea,
      extensions: [StarterKit, Link.configure({ HTMLAttributes: { class: "cursor-pointer" }}), Image],
      content: tipTapContent,
      editable: true,
    });

    masterElement.editor = editor;
  }

  disconnect() {
    this.element.editor.destroy();
    this.element.removeEventListener('click', this.handleClick.bind(this));
  }
  handleClick(event) {
    const textArea = this.element.querySelector(".tiptap__textarea");

    if (textArea.contains(event.target)) {
      return; // Do nothing if click is inside the textarea
    }

    const position = this.getClickPosition(event);

    if (this.isClickBelowContent(position)) {
      this.addNewLine();
    } else {
      return
    }
  }

  getClickPosition(event) {
    const rect = this.element.querySelector(".tiptap__textarea").getBoundingClientRect();
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
