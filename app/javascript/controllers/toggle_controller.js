import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["container", "triangle"];

  toggle() {
    const container = this.containerTarget;
    const triangle = this.triangleTarget;

    if (container.classList.contains("hidden")) {
      container.classList.remove("hidden");
      container.classList.add("block");
      triangle.classList.add("rotate-90");
    } else {
      container.classList.remove("block");
      container.classList.add("hidden");
      triangle.classList.remove("rotate-90");
    }
  }
}
