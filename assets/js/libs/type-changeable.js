import Combobox from '@github/combobox-nav'
import "@github/filter-input-element"
import tippy from "tippy.js";
import Observer from "./observer.js"

export default class TypeChangeable {
  constructor(phx, typeSelector) {
    this.phx = phx
    this.el = phx.el
    this.typeSelector = typeSelector
  }
  start() {
    this._typeEls().forEach(typeEl => {
      // Tippy already does `typeEl._tippy = instance`
      this._newTippy(typeEl)
    })
    this._startObserve()
  }
  _startObserve() {
    this._observer = new Observer(this.el, {
      nodeAdded: (addedNode) => {
        let typeNode = this._typeEl(addedNode)
        typeNode && this._newTippy(typeNode)
      },
      nodeRemoved: (removedNode) => {
        let typeNode = this._typeEl(removedNode)
        typeNode && typeNode._tippy?.destroy()
      }
    })
    this._observer.start()
  }
  stop() {
    this._typeEls().forEach(a => a._tippy?.destroy())
  }
  _typeEls() {
    return Array.from(this.el.querySelectorAll(this.typeSelector))
  }
  _typeEl(node) {
    return node.nodeType == Node.ELEMENT_NODE && node.querySelector(this.typeSelector)
  }
  _newTippy(el) {
    return tippy(el, {
      trigger: "dblclick",
      placement: "auto",
      onShow: this._showCombobox.bind(this),
      onHide: (tippy) => {
        tippy.setContent("")
      },
      allowHTML: true,
      interactive: true,
      hideOnClick: true,
      // touch: ["hold", 500],
      maxWidth: "100%"
    })
  }
  _showCombobox(tippy) {
    const template = document.querySelector("#types_combobox_template").content.cloneNode(true)
    const input = template.querySelector("#type-input")
    const list = template.querySelector("#list-id")

    const typeCombobox = new TypeCombobox(input, list, {
      committed: (e) => this.phx.pushEvent("change_type", {
        path: e.target.closest("[data-group='root']").id + e.target.closest(".sort-handle").id,
        value: e.target.id
      })
    })
    typeCombobox.setOptions(window.liveStore.typeOptions)
    tippy.setContent(template)
    setTimeout(() => { input.focus() }, 24)
  }
}

class TypeCombobox {
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
