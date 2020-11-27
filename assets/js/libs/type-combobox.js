import Combobox from '@github/combobox-nav'

export default class TypeCombobox {
  constructor(input, list, opts = {}) {
    this.comboboxController = new Combobox(input, list)

    const toggleList = (show) => {
      const hidden = show === true ? false : input.value.length === 0
      if (hidden) {
        this.comboboxController.stop()
      } else {
        this.comboboxController.start()
      }
      list.hidden = hidden
    }

    input.addEventListener('keydown', event => {
      if (!['ArrowDown', 'ArrowUp'].includes(event.key) || !list.hidden) return
      toggleList(true)
      this.comboboxController.navigate(event.key === 'ArrowDown' ? 1 : -1)
    })
    input.addEventListener('input', () => toggleList())
    input.addEventListener('focus', () => toggleList())
    input.addEventListener('blur', () => {
      list.hidden = true
      this.comboboxController.clearSelection()
      this.comboboxController.stop()
    })

    document.addEventListener('combobox-commit', event => {
      const commitFunc = opts.committed || ((a) => a)
      commitFunc(event)

      list.hidden = true
      this.comboboxController.clearSelection()
      this.comboboxController.stop()
    })
  }
  setOptions(options = []) {
    for (const option of options) {
      let li = document.createElement("li")
      li.setAttribute("role", "option")
      li.setAttribute("id", option)
      li.classList.add("border-2", "border-transparent", "rounded", "px-2")
      li.textContent = option
      this.comboboxController.list.appendChild(li)
    }
  }
}
