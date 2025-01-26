import { Controller } from "@hotwired/stimulus";
import { marked } from "marked"
import DOMPurify from "dompurify"

export default class extends Controller {
  static targets = ["prompt", "chatFormContent", "textarea"]

  connect() {
    this.checkForPromptTarget();
    if (this.hasTextareaTarget) {
      this.setupFocus();
      this.setupKeyboardEvents();
    }
  }

  setupFocus() {
    const textarea = this.textareaTarget;
    textarea.focus();
  }

  setupKeyboardEvents() {
    const textarea = this.textareaTarget;

    textarea.addEventListener("keydown", (event) => {
      if (event.ctrlKey && event.key === "Enter") {
        event.preventDefault(); // Prevent default behavior (newline)
        textarea.form.requestSubmit(); // Submit the form programmatically
      }
    });
  }

  checkForPromptTarget() {
    const observer = new MutationObserver(() => {
      if (this.hasPromptTarget) {
        observer.disconnect();
        this.campaignId = this.element.dataset.campaignId;
        this.pageSlug = this.element.dataset.pageSlug;
      }
    });

    observer.observe(document.body, { childList: true, subtree: true });
  }

  toggleChat(event) {
    const chatFormContent = document.querySelector('[data-chat-target="chatFormContent"]');
    const chatFormInput   = document.querySelector('[data-chat-target="chatFormInput"]');
    chatFormContent.classList.toggle("hidden");
    const button = event.currentTarget;
    chatFormContent.scrollTop = chatFormContent.scrollHeight;
  }

  clearInput(event) {
    setTimeout(() => {
      this.promptTarget.value = "";
    }, 0);
  }

  disconnect() {
      if (this.eventSource) {
          this.eventSource.close()
      }
  }


  #setupEventSource() {
      this.eventSource = new EventSource(`/campaigns/${this.campaignId}/pages/${this.pageSlug}/chat_responses?prompt=${this.promptTarget.value}`)
      this.eventSource.addEventListener("error", this.#handleError.bind(this))
  }

  #parseMarkdown(text) {
    const parsedHtml = DOMPurify.sanitize(marked(text));

    const enhanceMarkdown = (html) => {
      return html
        .replace(/<h1>/g, '<h1 class="text-3xl font-bold mb-4">')
        .replace(/<h2>/g, '<h2 class="text-2xl font-semibold mb-3">')
        .replace(/<h3>/g, '<h3 class="text-xl font-medium mb-2">')
        .replace(/<ul>/g, '<ul class="list-disc pl-5 space-y-1">')
        .replace(/<ol>/g, '<ol class="list-decimal pl-5 space-y-1">')
        .replace(/<p>/g, '<p class="mb-4 text-base leading-relaxed">')
        .replace(/<blockquote>/g, '<blockquote class="border-l-4 border-gray-300 pl-4 italic text-gray-600">')
        .replace(/<pre>/g, '<pre class="bg-gray-800 text-gray-100 p-4 rounded overflow-x-auto">')
        .replace(/<hr>/g, '<hr class="border-gray-300 my-4">')
        .replace(/<a /g, '<a class="text-blue-500 hover:underline" ')
        .replace(/<table>/g, '<table class="table-auto border-collapse border border-gray-300 w-full">');
    };

    return enhanceMarkdown(parsedHtml)
  }

  #handleError(event) {
      if (event.eventPhase === EventSource.CLOSED) {
          this.eventSource.close()
      }
  }
}
