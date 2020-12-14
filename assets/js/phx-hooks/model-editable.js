import ModelSortable from "../libs/model-sortable.js"
import "../libs/type-changeable.js"
import "../libs/field-renamable.js"
import ListToggleable from "../libs/list-toggleable.js"

export default {
  mounted() {
    this.featureFlags = {
      sortable: true,
      typeChangeable: true,
      fieldRenameable: true,
      listToggleable: false
    }

    const phx = this
    phx.rootID = this.el.querySelector("[data-group='root']").id

    this.modelSortable = new ModelSortable(phx, "[data-group]")
    this.listToggleable = new ListToggleable(phx)

    if (this.featureFlags.sortable) {
      this.modelSortable.start()
    }
    if (this.featureFlags.listToggleable) {
      this.listToggleable.start()
    } else {
      this.listToggleable.stop()
    }
  },
  updated() {
  },
  beforeDestroy() {
    if (this.featureFlags.sortable) { this.modelSortable.stop() }
  }
}
