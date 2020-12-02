export default class FieldRenamable {
  constructor(el, opts = {}) {
    this.parent = el.parentNode
    this.input = this.input(el)
    this.el = el
    this.hanger = document.createElement("div")
    this.editable = false

    this.el.addEventListener("dblclick", e => {
      this.editable = true
      this.render()
    })
    this.input.addEventListener("blur", e => {
      this.editable = false
      this.render()
    })
    this.input.addEventListener("keydown", e => {
      switch (e.code) {
        case "Enter":
          if (!e.metaKey) {
            e.preventDefault()
            const commitFunc = opts.committed || ((a) => a)
            commitFunc(e)
          }
          break;

        case "Escape":
          this.editable = false
          this.render()
      }
    })
  }
  input(el) {
    let line = el.closest(".sort-handle")
    let parent = line.parentNode.closest(".sort-handle")
    let template = document.createElement("template")

    template.innerHTML = `
      <textarea
        class="filtered block px-2 box-border mr-2 min-w-0 h-full self-start text-xs leading-6 bg-gray-800 z-10 shadow-inner text-white"
        data-parent-path="${parent.id}"
        data-old-key="${el.textContent}"
        rows="1"
        spellcheck="false"
        autofocus
      >${el.textContent}</textarea>`

    let input = template.content.firstElementChild
    input.style.paddingLeft = el.style.paddingLeft
    return input
  }
  render() {
    this.editable ? this.swapEditorIn() : this.swapEditorOut()
  }
  swapEditorIn() {
    this.parent.insertBefore(this.input, this.el)
    this.hanger.appendChild(this.el)
    this.input.focus()
    this.input.selectionStart = this.input.selectionEnd = this.input.value.length
    this.input.scrollTop = this.input.scrollHeight
    this.input.style.height = Math.min(this.input.scrollHeight, 300) + "px"
  }
  swapEditorOut() {
    this.parent.insertBefore(this.el, this.input)
    this.hanger.appendChild(this.input)
  }
}
