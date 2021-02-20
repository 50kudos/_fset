import ModelSortable from "../libs/model-sortable.js"
import { TypeChangeable } from "../libs/type-changeable.js"
import "../libs/field-renamable.js"
import ListToggleable from "../libs/list-toggleable.js"
import FieldAddable from "../libs/field-addable.js"

export default {
  mounted() {
    window.phx = this
    this.featureFlags = {
      sortable: true,
      typeChangeable: true,
      fieldRenameable: true,
      listToggleable: false,
      fieldAddable: true
    }

    this.handleEvent("changeable_types", ({ typeOptions }) => {
      window.liveStore.typeOptions = typeOptions
      const phx = this
      const scope = document.querySelector("[data-group='root']")
      phx.rootID = scope.id

      this.modelSortable = new ModelSortable(phx, scope, "[data-group]")
      this.listToggleable = new ListToggleable(phx)
      this.fieldAddable = new FieldAddable(phx)
      this.typeChangeable = new TypeChangeable(scope)


      if (this.featureFlags.sortable) this.modelSortable.start()

      if (this.featureFlags.listToggleable) this.listToggleable.start()
      else this.listToggleable.stop()

      if (this.featureFlags.fieldAddable) this.fieldAddable.start()

      if (this.featureFlags.typeChangeable) this.typeChangeable.start()
    })
    this.handleEvent("update", ({ cmds }) => {
      for (let { target, action, props } of cmds) {
        switch (action) {
          case "replace":
            [...document.querySelectorAll(target)]
              .forEach(el => el.outerHTML = props.innerHTML)

            this.fieldAddable = new FieldAddable(this)
            this.fieldAddable.start()
            this.listToggleable = new ListToggleable(phx)
            this.listToggleable.stop()
            break;
        }
      }
    })
    this.handleEvent("current_path", ({ paths }) => {
      let sorters = this._sortableLists().map(a => a._sorter)
      console.log(paths)
      SortableList.selectCurrentItems(sorters, paths, this._listConfig)
    })
    document.addEventListener("keydown", this.handleKeydown)




  },
  updated() {
    this.fieldAddable.start()
    this.listToggleable.stop()
  },
  beforeDestroy() {
    this.modelSortable?.stop()
    this.typeChangeable?.stop()
  },
  destroyed() {
    window.liveStore = null
  },
  handleKeydown(e) {
    switch (e.key) {
      case "+":
        const schEl = e.target.querySelector(".sortable-selected")
        const path = schEl.id.replace("main", "")
        const level = schEl.getAttribute("aria-level")
        const rootID = e.target.querySelector("[data-group='root']").id

        window.phx.pushEvent("add_field", {
          path: rootID + path,
          field: "Record",
          level: level
        })

        break
    }
  }
}
