import { Controller } from "@hotwired/stimulus";

// possibly replace with stimulus-use debounces
const debounce = function(func, wait, immediate) {
  let timeout, result;
  return function() {
    let context = this, args = arguments;
    let later = function() {
      timeout = null;
      if (!immediate) result = func.apply(context, args);
    };
    let callNow = immediate && !timeout;
    clearTimeout(timeout);
    timeout = setTimeout(later, wait);
    if (callNow) result = func.apply(context, args);
    return result;
  };
};

export default class extends Controller {
  static targets = ["content", "input"]

  changed = debounce (() => {
    this.inputTarget.value = this.contentTarget.innerHTML;
    this.inputTarget.form.requestSubmit();
  }, 1000)
}
