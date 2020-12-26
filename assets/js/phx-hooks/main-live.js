import FieldAddable from "../libs/field-addable.js"
import ListToggleable from "../libs/list-toggleable.js"

export default {
  mounted() {
    window.phx = this
    this.handleEvent("changeable_types", ({ typeOptions }) => {
      window.liveStore.typeOptions = typeOptions
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
  },
  destroyed() {
    window.liveStore = null
  }
}
