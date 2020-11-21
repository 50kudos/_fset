import PhxSortable from "../model-sortable.js"

export default {
  mounted() {
    let phx = this
    this.phxSortable = new PhxSortable("[data-group]", phx, { scope: this.el })
    this.bindToggle()
  },
  updated() {
  },
  destroyed() {
    this.phxSortable.destroyAll()
  },
  bindToggle() {
    const maker = `<p class="absolute m-1 leading-4 text-gray-900 font-mono text-xs">
      <span class="close-marker cursor-pointer select-none">+</span>
      <span class="open-marker cursor-pointer select-none">-</span>
    </p>`

    this.el.querySelectorAll("details").forEach(details => {
      details.addEventListener("click", e => e.preventDefault())
    })
  }
}
