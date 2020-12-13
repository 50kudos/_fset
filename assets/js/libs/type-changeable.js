import autoComplete from "@tarekraafat/autocomplete.js"
import tippy from "tippy.js";
import Observer from "./observer.js"
import { fragment } from "../utils.js"

export default class TypeChangeable {
  constructor(phx, typeSelector) {
    this.phx = phx
    this.el = phx.el
    this.typeSelector = typeSelector
  }
  start() {
    this._typeEls().forEach(typeEl => {
      this._newTippy(typeEl)
      // Tippy already does `typeEl._tippy = instance`
    })
    this._startObserve()
  }
  _startObserve() {
    if (!this._observer) {
      this._observer = new Observer(this.el, {
        nodeRemoved: (removedNode) => {
          removedNode._tippy?.destroy()
          delete removedNode._tippy
        }
      })
      this._observer.start()
    }
  }
  stop() {
    this._typeEls().forEach(a => a._tippy?.destroy())
    this._observer.stop()
  }
  _typeEls() {
    return Array.from(this.el.querySelectorAll(this.typeSelector))
  }
  _newTippy(el) {
    return el._tippy || tippy(el, {
      duration: 0,
      trigger: "click",
      placement: "auto",
      onShow: this._showCombobox.bind(this),
      onHide: (tippy) => tippy.setContent(""),
      allowHTML: true,
      interactive: true,
      hideOnClick: true,
      maxWidth: "100%"
    })
  }
  _showCombobox(tippy) {
    const inputId = "typeInput"
    const typePath = () => tippy.reference.closest("[data-group='root']").id + tippy.reference.closest(".sort-handle").id

    tippy.setContent(fragment(`
      <span>Change type to:</span>
      <input id="${inputId}" class="my-2 px-2 py-1 w-full rounded border border-gray-700" type="text" autofocus>
    `))

    const autoCompleteJS = new autoComplete({
      selector: `#${inputId}`,
      trigger: {
        event: ["input", "focus"],
      },
      data: {
        src: window.liveStore.typeOptions,
        cache: false
      },
      highlight: true,

      onSelection: (feedback) => {
        document.querySelector(`#${inputId}`).value = feedback.selection.value
        this.phx.pushEvent("change_type", {
          path: typePath(),
          value: feedback.selection.value
        })
      },
      noResults: (dataFeedback, generateList) => {
        // Generate autoComplete List
        generateList(autoCompleteJS, dataFeedback, dataFeedback.results)
        const result = fragment(`<li class="autoComplete_result notfound">Found No Results for "${dataFeedback.query}"</li>`)
        document.querySelector(`#${autoCompleteJS.resultsList.idName}`).appendChild(result)
      }
    })

    setTimeout(() => document.querySelector(`#${inputId}`).focus(), 50)
  }
}
