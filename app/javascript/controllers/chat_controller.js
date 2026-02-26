import { Controller } from "@hotwired/stimulus";
import { marked } from "marked"
import DOMPurify from "dompurify"

export default class extends Controller {
  static targets = ["prompt", "chatFormContent", "textarea"]

  connect() {
    this.checkForPromptTarget();
    if (this.hasTextareaTarget) {
      this.setupFocus();
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
    return DOMPurify.sanitize(marked(text));
  }

  #handleError(event) {
      if (event.eventPhase === EventSource.CLOSED) {
          this.eventSource.close()
      }
  }
}
