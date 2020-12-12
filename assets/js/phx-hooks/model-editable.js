import ModelSortable, { SortableList } from "../libs/model-sortable.js"
import TypeChangeable from "../libs/type-changeable.js"
import FieldRenamable from "../libs/field-renamable.js"
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
    this.typeChangeable = new TypeChangeable(phx, ".t")
    this.listToggleable = new ListToggleable(phx)

    if (this.featureFlags.sortable) {
      this.modelSortable.start()
    } else {
      this.modelSortable.stop()
    }
    if (this.featureFlags.typeChangeable) {
      this.typeChangeable.start()
    } else {
      this.typeChangeable.stop()
    }
    if (this.featureFlags.listToggleable) {
      this.listToggleable.start()
    } else {
      this.listToggleable.stop()
    }

    this.bindRenameKey()
  },
  updated() {
    if (this.featureFlags.sortable) {
      this.typeChangeable.start()
    }
  },
  beforeDestroy() {
    if (this.featureFlags.sortable) { this.modelSortable.stop() }
    if (this.featureFlags.typeChangeable) { this.typeChangeable.stop() }
  },
  bindRenameKey() {
    this.fields = [...this.el.querySelectorAll("[data-group='root'] [data-group='keyed'] .k")]
    this.fields
      .map(k => new FieldRenamable(k, {
        committed: e => {
          this.pushEvent("rename_key", {
            parent_path: e.target.closest("[data-group='root']").id + e.target.dataset.parentPath,
            value: e.target.value,
            old_key: e.target.dataset.oldKey
          })
        }
      }))

  }
}
