import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["slide"]

  connect() {
    this.index = 0
    this.interval = setInterval(() => this.next(), 2000)
  }

  disconnect() {
    clearInterval(this.interval)
  }

  next() {
    this.slideTargets[this.index].classList.add("hidden")
    this.index = (this.index + 1) % this.slideTargets.length
    this.slideTargets[this.index].classList.remove("hidden")
  }
}
