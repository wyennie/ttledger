import { Controller } from "@hotwired/stimulus";

const debounce = (fn, ms) => {
  let t;
  return (...args) => {
    clearTimeout(t);
    t = setTimeout(() => fn(...args), ms);
  };
};

export default class extends Controller {
  initialize() {
    this.submit = debounce(() => this.element.requestSubmit(), 800);
  }

  changed() {
    this.submit();
  }
}
