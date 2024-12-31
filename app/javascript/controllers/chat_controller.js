import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["chatMessage"]

  clearInput(event) {
    setTimeout(() => {
      this.chatMessageTarget.value = "";
    }, 0);
  }
}
