import PhxSortable from "../libs/model-sortable.js"
import TypeCombobox from "../libs/type-combobox.js"
import FieldRenamable from "../libs/field-renamable.js"
import tippy from "tippy.js";
import "@github/filter-input-element"

export default {
  mounted() {
    this.rootID = this.el.querySelector("[data-group='root']").id
    this.phxSortable = new PhxSortable("[data-group]", this, { scope: this.el })
    this.bindToggle()
    this.bindChangeType()
    this.bindRenameKey()
  },
  updated() {
    this.phxSortable.destroyAll()
    this.phxSortable = new PhxSortable("[data-group]", this, { scope: this.el })

    this.tippies.forEach(a => a.destroy())
    this.bindChangeType()

    this.bindRenameKey()
  },
  destroyed() {
    this.phxSortable.destroyAll()
    this.tippies.forEach(a => a.destroy())
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
    this.tippies = tippy(".t", {
      trigger: "dblclick",
      placement: "bottom-start",
      onShow: (tippy) => {
        const template = document.querySelector("#types_combobox_template").content.cloneNode(true)
        const input = template.querySelector("#type-input")
        const list = template.querySelector("#list-id")
        const typeCombobox = new TypeCombobox(input, list, {
          committed: (e) => this.pushEvent("change_type", {
            path: this.rootID + e.target.closest(".sort-handle").id,
            value: e.target.id
          })
        })
        typeCombobox.setOptions(window.liveStore.typeOptions)
        tippy.setContent(template)
        setTimeout(() => { input.focus() }, 24)
      },
      onHide: (tippy) => tippy.setContent(""),
      allowHTML: true,
      interactive: true,
      hideOnClick: true,
      // touch: ["hold", 500],
      maxWidth: "100%"
    });
  },
  bindRenameKey() {
    this.fields = [...this.el.querySelectorAll("[data-group='root'] [data-group='keyed'] .k")]
    this.fields
      .map(k => new FieldRenamable(k, {
        committed: e => {
          this.pushEvent("rename_key", {
            parent_path: this.rootID + e.target.dataset.parentPath,
            value: e.target.value,
            old_key: e.target.dataset.oldKey
          })
        }
      }))

  }
}
