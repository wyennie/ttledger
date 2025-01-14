import { Controller } from "@hotwired/stimulus";
import { marked } from "marked"
import DOMPurify from "dompurify"

export default class extends Controller {
  static targets = ["prompt", "conversation"]

  connect() {
    this.checkForPromptTarget();
  }

  checkForPromptTarget() {
    const observer = new MutationObserver(() => {
      if (this.hasPromptTarget) {
        observer.disconnect();
        this.campaignId = this.element.dataset.campaignId;
        this.pageSlug = this.element.dataset.pageSlug;
        this.accumulatedMessage = "";
        this.promptTarget.addEventListener("keydown", this.handleKeyDown.bind(this));
      }
    });

    observer.observe(document.body, { childList: true, subtree: true });
  }

  toggleChat(event) {
    const chatFormContent = document.querySelector('[data-chat-target="chatFormContent"]');
    const chatFormInput   = document.querySelector('[data-chat-target="chatFormInput"]');
    chatFormContent.classList.toggle("hidden");
    chatFormInput.classList.toggle("hidden");
    const button = event.currentTarget;
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

  generateResponse(event) {
      this.accumulatedMessage = ""
      event.preventDefault()
      this.#createLabel('You')
      this.#createMessage(this.promptTarget.value)
      this.#createLabel('Assistant')
      this.currentPre = this.#createMessage()

      this.#setupEventSource()

      this.promptTarget.value = ""
  }

  handleKeyDown(event) {
    if (event.key === "Enter" && !event.ctrlKey && !event.shiftKey) {
      // Submit the form when Enter is pressed, without Ctrl
      event.preventDefault();  // Prevent new line
      this.generateResponse(event);  // Call the generateResponse method to submit
    } else if (
        (event.key === "Enter" && event.ctrlKey) || 
        (event.key === "Enter" && event.shiftKey)) {
      // Allow new line if Ctrl + Enter is pressed
      event.preventDefault();  // Prevent form submission
      const cursorPos = this.promptTarget.selectionStart;
      this.promptTarget.value = this.promptTarget.value.slice(0, cursorPos) + "\n" + this.promptTarget.value.slice(cursorPos);
    }
  }

  #createLabel(text) {
      const label = document.createElement('strong');
      label.innerHTML = `${text}:`;
      this.conversationTarget.appendChild(label);
  }

  #createMessage(text = '') {
      const preElement = document.createElement('p');
      preElement.className = "bg-white p-4 rounded-lg text-gray-800"
      preElement.innerHTML = text;
      this.conversationTarget.appendChild(preElement);
      return preElement
  }

  #setupEventSource() {
      this.eventSource = new EventSource(`/campaigns/${this.campaignId}/pages/${this.pageSlug}/chat_responses?prompt=${this.promptTarget.value}`)
      this.eventSource.addEventListener("message", this.#handleMessage.bind(this))
      this.eventSource.addEventListener("error", this.#handleError.bind(this))
  }

  #handleMessage(event) {
    const parsedData = JSON.parse(event.data);
    this.accumulatedMessage += parsedData.message;
    const parsedMarkdown = this.#parseMarkdown(this.accumulatedMessage);
    this.currentPre.innerHTML = parsedMarkdown;
    this.conversationTarget.scrollTop = this.conversationTarget.scrollHeight;
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
