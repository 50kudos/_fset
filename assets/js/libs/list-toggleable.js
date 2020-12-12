import { fragment } from "../utils.js"

export default class ListToggleable {
  constructor(phx) {
    this.phx = phx
    this.el = phx.el
    this.prevent = e => e.preventDefault()
  }
  stop() {
    this.el.querySelectorAll("details").forEach(details => {
      details.addEventListener("click", this.prevent)
      let h = details.querySelector(".h")

      if (h) {
        for (let c of h.children) {
          c.removeEventListener("click", this.prevent)
        }
        details.querySelector(".spring")?.remove()
        details.querySelector(".toggler")?.remove()
      }
    })
  }
  start() {
    const marker = fragment(`
    <p class="toggler absolute m-1 leading-4 text-gray-500 font-mono text-xs">
      <span class="close-marker cursor-pointer select-none">+</span>
      <span class="open-marker cursor-pointer select-none">-</span>
    </p>`)

    const spring = fragment(`
      <span class="spring flex-1"></span>
    `)

    this.el.querySelectorAll("details").forEach(details => {
      details.removeEventListener("click", this.prevent)
      let h = details.querySelector(".h")

      if (h) {
        h.appendChild(spring.cloneNode(true))
        h.classList.add("relative")
        for (let c of h.children) {
          c.addEventListener("click", this.prevent)
        }
        h.prepend(marker.cloneNode(true))
      }
    })
  }
}
