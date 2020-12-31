import autoComplete from "@tarekraafat/autocomplete.js"
import tippy, { delegate } from "tippy.js";
import { fragment } from "../utils.js"

export class TypeChangeable {
  constructor(el) {
    this.el = el
  }
  stop() { this.el._tippy.destroy() }
  start() {
    delegate(this.el, {
      target: ".t",
      duration: 0,
      trigger: "click",
      placement: "auto",
      onShow: (tippy) => this._showCombobox(tippy),
      allowHTML: true,
      interactive: true,
      hideOnClick: true,
      plugins: [{
        name: 'hideOnEsc',
        defaultValue: false,
        fn({ hide }) {
          function onKeyDown(event) {
            if (event.keyCode === 27) { hide() }
          }
          return {
            onShow() { document.addEventListener('keydown', onKeyDown) },
            onHide() { document.removeEventListener('keydown', onKeyDown) },
          };
        }
      }],
      maxWidth: "100%"
    })
  }
  _showCombobox(tippy) {
    let inputId = "typeInput"
    let typePath = () => tippy.reference.closest("[data-group='root']").id + tippy.reference.closest(".sort-handle").id

    tippy.setContent(fragment(`
      <span>Change type to:</span>
      <input id="${inputId}" class="my-2 px-2 py-1 w-full rounded border border-gray-700" type="text" autofocus>
    `))

    let autoCompleteJS = new autoComplete({
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
        window.phx?.pushEvent("change_type", {
          path: typePath(),
          value: feedback.selection.value
        })
      },
      noResults: (dataFeedback, generateList) => {
        // Generate autoComplete List
        generateList(autoCompleteJS, dataFeedback, dataFeedback.results)
        let result = fragment(`<li class="autoComplete_result notfound">Found No Results for "${dataFeedback.query}"</li>`)
        document.querySelector(`#${autoCompleteJS.resultsList.idName}`).appendChild(result)
      }
    })

    setTimeout(() => document.querySelector(`#${inputId}`).focus(), 50)
  }
}
