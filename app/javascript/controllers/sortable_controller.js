import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["item"]

  dragstart(event) {
    this.draggedItem = event.currentTarget
    event.dataTransfer.effectAllowed = "move"
    event.currentTarget.classList.add("opacity-50")
  }

  dragend(event) {
    event.currentTarget.classList.remove("opacity-50")
  }

  dragover(event) {
    event.preventDefault()
    event.dataTransfer.dropEffect = "move"

    const target = event.currentTarget
    if (target === this.draggedItem) return

    const rect = target.getBoundingClientRect()
    const midY = rect.top + rect.height / 2

    if (event.clientY < midY) {
      target.parentNode.insertBefore(this.draggedItem, target)
    } else {
      target.parentNode.insertBefore(this.draggedItem, target.nextSibling)
    }
  }

  drop(event) {
    event.preventDefault()
    this.saveOrder()
  }

  saveOrder() {
    const ids = [...this.itemTargets].map(item => item.dataset.rooteinId)

    fetch("/rooteins/reorder", {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({ ids: ids })
    })
  }
}
