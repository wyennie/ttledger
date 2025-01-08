import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["triangle", "container"];

  connect() {
    this.containerId = this.element.dataset.containerId;

    // Retrieve the saved state from localStorage
    const isOpen = localStorage.getItem(`sidebar-container-${this.containerId}`);
    if (isOpen === "true") {
      this.show();
    } else {
      this.hide();
    }
  }

  toggle() {
    if (this.containerTarget.classList.contains("hidden")) {
      this.show();
    } else {
      this.hide();
    }
  }

  show() {
    this.containerTarget.classList.remove("hidden");
    this.triangleTarget.classList.add("rotate-90");
    localStorage.setItem(`sidebar-container-${this.containerId}`, "true");
  }

  hide() {
    this.containerTarget.classList.add("hidden");
    this.triangleTarget.classList.remove("rotate-90");
    localStorage.setItem(`sidebar-container-${this.containerId}`, "false");
  }
}

