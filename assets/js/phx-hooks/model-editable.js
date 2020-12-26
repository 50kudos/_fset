import ModelSortable from "../libs/model-sortable.js"
import "../libs/type-changeable.js"
import "../libs/field-renamable.js"
import ListToggleable from "../libs/list-toggleable.js"
import FieldAddable from "../libs/field-addable.js"

export default {
  mounted() {
    this.featureFlags = {
      sortable: true,
      typeChangeable: true,
      fieldRenameable: true,
      listToggleable: false,
      fieldAddable: true
    }

    const phx = this
    phx.rootID = this.el.querySelector("[data-group='root']").id

    this.modelSortable = new ModelSortable(phx, "[data-group]")
    this.listToggleable = new ListToggleable(phx)
    this.fieldAddable = new FieldAddable(phx)

    if (this.featureFlags.sortable) {
      this.modelSortable.start()
    }
    if (this.featureFlags.listToggleable) {
      this.listToggleable.start()
    } else {
      this.listToggleable.stop()
    }
    if (this.featureFlags.fieldAddable) {
      this.fieldAddable.start()
    }
  },
  updated() {
    this.fieldAddable.start()
    this.listToggleable.stop()
  },
  beforeDestroy() {
    if (this.featureFlags.sortable) { this.modelSortable.stop() }
  }
}
