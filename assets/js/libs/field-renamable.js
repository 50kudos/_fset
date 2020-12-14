import { fragment, element } from "../utils"

window.customElements.define("sch-key", class extends HTMLElement {
  constructor() {
    super()
    this.addEventListener("dblclick", this.startEdit.bind(this))
  }
  connectedCallback() {
  }
  disconnectedCallback() {
    this.removeEventListener("dblclick", this.startEdit)
    this.input?.removeEventListener("keydown", this.handleKeyDown)
    this.input?.removeEventListener("blur", this.stopEdit)
    this.input?.removeEventListener("input", this.autoHeight)
  }
  _input(el) {
    let line = el.closest(".sort-handle")
    let parent = line.parentNode.closest(".sort-handle")

    return element(`
      <textarea
        class="filtered block px-2 box-border mr-2 min-w-0 h-full self-start text-xs leading-6 bg-gray-800 z-10 shadow-inner text-white"
        data-parent-path="${parent.id}"
        data-old-key="${el.textContent}"
        rows="1"
        spellcheck="false"
        autofocus
      >${el.textContent}</textarea>`)
  }
  startEdit(e) {
    this.keyNodes = [...this.childNodes].map(a => a.cloneNode(true))
    this.input = this._input(this)

    this.childNodes.forEach(c => c.remove())
    this.querySelectorAll("wbr").forEach(c => c.remove())
    this.appendChild(this.input)

    this.input.selectionStart = this.input.selectionEnd = this.input.value.length
    this.input.addEventListener("input", this.autoHeight.bind(this))
    this.input.addEventListener("keydown", this.handleKeyDown.bind(this))
    this.input.addEventListener("blur", this.stopEdit.bind(this))

    this.input.focus()
    this.autoHeight()
  }
  stopEdit(e) {
    this.childNodes.forEach(c => c.remove())
    this.keyNodes.forEach(c => this.appendChild(c))

    this.input.removeEventListener("keydown", this.handleKeyDown)
    this.input.removeEventListener("blur", this.stopEdit)
  }
  handleKeyDown(e) {
    switch (e.code) {
      case "Enter":
        if (!e.shiftKey) {
          e.preventDefault()
          window.phx?.pushEvent("rename_key", {
            parent_path: e.target.closest("[data-group='root']").id + e.target.dataset.parentPath,
            value: e.target.value,
            old_key: e.target.dataset.oldKey
          })
        }
        break;

      case "Escape":
        this.stopEdit(e)
    }
  }
  autoHeight() {
    this.input.scrollTop = this.input.scrollHeight
    this.input.style.height = Math.min(this.input.scrollHeight, 300) + "px"
  }
})
