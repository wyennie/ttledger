import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
      // Attach event listener for change event
      const selectElement = this.element.querySelector('select');
      if (selectElement) {
        selectElement.addEventListener('change', this.submitField.bind(this));
      }
    }

  submitField(event) {
    console.log('Change detected', event.target);
    const form = event.target.closest("form");
    const formData = new FormData(form);

    fetch(form.action, {
      method: form.method,
      headers: {
        "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content,
      },
      body: formData,
    })
      .then((response) => {
        if (!response.ok) {
          throw new Error("Failed to save");
        }
        return response.json();
      })
      .then((data) => {
        console.log("Saved successfully:", data);
      })
      .catch((error) => {
        console.error("Error saving:", error);
      });
  }
}
