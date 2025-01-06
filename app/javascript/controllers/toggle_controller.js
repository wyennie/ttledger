
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["container", "triangle"];

  connect() {
    // Check cookie on page load and apply the state accordingly
    const isVisible = this.getCookie("containerState") === "visible";
    this.updateState(isVisible);
  }

  toggle() {
    const container = this.containerTarget;
    const triangle = this.triangleTarget;

    // Toggle state and update cookie
    const isVisible = container.classList.contains("block");
    const newState = !isVisible ? "visible" : "hidden";

    this.setCookie("containerState", newState, 7); // Cookie expires in 7 days
    this.updateState(!isVisible);
  }

  updateState(isVisible) {
    const container = this.containerTarget;
    const triangle = this.triangleTarget;

    if (isVisible) {
      container.classList.remove("hidden");
      container.classList.add("block");
      triangle.classList.add("rotate-90");
    } else {
      container.classList.remove("block");
      container.classList.add("hidden");
      triangle.classList.remove("rotate-90");
    }
  }

  // Helper function to set a cookie
  setCookie(name, value, days) {
    const d = new Date();
    d.setTime(d.getTime() + days * 24 * 60 * 60 * 1000);
    const expires = `expires=${d.toUTCString()}`;
    document.cookie = `${name}=${value}; ${expires}; path=/`;
  }

  // Helper function to get a cookie value
  getCookie(name) {
    const decodedCookie = decodeURIComponent(document.cookie);
    const ca = decodedCookie.split(";");
    for (let i = 0; i < ca.length; i++) {
      let c = ca[i].trim();
      if (c.indexOf(name) === 0) {
        return c.substring(name.length + 1, c.length);
      }
    }
    return "";
  }
}

