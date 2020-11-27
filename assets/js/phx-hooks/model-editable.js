import PhxSortable from "../libs/model-sortable.js"
import TypeCombobox from '../libs/type-combobox.js'
import tippy from 'tippy.js';
import "@github/filter-input-element"

export default {
  mounted() {
    let phx = this
    this.rootID = this.el.querySelector("[data-group='root']").id
    // this.phxSortable = new PhxSortable("[data-group]", phx, { scope: this.el })
    this.bindToggle()
    this.bindChangeType()
  },
  updated() {
  },
  destroyed() {
    // this.phxSortable.destroyAll()
  },
  bindToggle() {
    const maker = `
    <p class="absolute m-1 leading-4 text-gray-900 font-mono text-xs">
      <span class="close-marker cursor-pointer select-none">+</span>
      <span class="open-marker cursor-pointer select-none">-</span>
    </p>`

    this.el.querySelectorAll("details").forEach(details => {
      details.addEventListener("click", e => e.preventDefault())
    })
  },
  bindChangeType() {
    tippy(".t", {
      trigger: "click",
      placement: 'bottom-start',
      onShow: (tippy) => {
        const template = document.querySelector('#types_combobox_template').content.cloneNode(true)
        const input = template.querySelector('#type-input')
        const list = template.querySelector('#list-id')
        const typeCombobox = new TypeCombobox(input, list, {
          committed: (e) => this.pushEvent("change_type", {
            path: this.rootID + e.target.closest(".sort-handle").id,
            value: e.target.id
          })
        })
        typeCombobox.setOptions(window.liveStore.typeOptions)
        tippy.setContent(template)
        setTimeout(() => { input.focus() }, 50)
      },
      onHide: (tippy) => tippy.setContent(""),
      allowHTML: true,
      interactive: true,
      hideOnClick: true,
      maxWidth: "100%"
    });
  }
}
