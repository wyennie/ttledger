import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["prompt", "conversation"]

  connect() {
    this.campaignId = this.element.dataset.campaignId;
    this.pageSlug = this.element.dataset.pageSlug;
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
      this.currentPre.innerHTML += parsedData.message;
      this.conversationTarget.scrollTop = this.conversationTarget.scrollHeight;
  }

  #handleError(event) {
      if (event.eventPhase === EventSource.CLOSED) {
          this.eventSource.close()
      }
  }
}
