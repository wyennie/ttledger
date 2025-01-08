import { Controller } from "@hotwired/stimulus";
import { marked } from "marked"
import DOMPurify from "dompurify"

export default class extends Controller {
  static targets = ["prompt", "conversation"]

  connect() {
    this.campaignId = this.element.dataset.campaignId;
    this.pageSlug = this.element.dataset.pageSlug;
    this.accumulatedMessage = ""
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
      event.preventDefault()
      this.#createLabel('You')
      this.#createMessage(this.promptTarget.value)
      this.#createLabel('ChatGPT')
      this.currentPre = this.#createMessage()

      this.#setupEventSource()

      this.promptTarget.value = ""
  }

  #createLabel(text) {
      const label = document.createElement('strong');
      label.innerHTML = `${text}:`;
      this.conversationTarget.appendChild(label);
  }

  #createMessage(text = '') {
      const preElement = document.createElement('p');
      preElement.className = "bg-gray-100 p-4 rounded-lg text-gray-800"
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

    // Accumulate the message chunks
    this.accumulatedMessage += parsedData.message;
    console.log(parsedData)

    // Parse the accumulated message with the markdown parser
    const parsedMarkdown = this.#parseMarkdown(this.accumulatedMessage);

    console.log(parsedMarkdown)
    // Update the current message element
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
