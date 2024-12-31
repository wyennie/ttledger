import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["chatMessage"]

  clearInput(event) {
    console.log("hello from chat-controller")
    console.log(this.chatMessageTarget)
    this.chatMessageTarget.value = ""; // Clears the input field
  }
}
