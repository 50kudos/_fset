import { fragment, element } from "../utils"
import Observer from "./observer.js"

export default class FieldAddable {
  constructor(phx) {
    this.phx = phx
    this.el = phx.el
  }
  start() {
    document.querySelectorAll(".h").forEach(a => a.querySelector(".add-field") || a.appendChild(this.button()))
    // this.startObserve()
  }
  stop() {
    document.querySelectorAll(".add-field").forEach(a => a.removeEventListener(this.addField))
  }
  startObserve() {
    if (this._observer) { return }

    this._observer = new Observer(this.el, {
      attrChanged: (targetNode) => {
        if (targetNode.classList.contains("sortable-selected")) {
          targetNode.querySelector(".add-field") ||
            targetNode.querySelector(".h").appendChild(this.button())
        }
      }
    })
  }
  button() {
    let addFieldBtn = element(`<span class="add-field px-2 bg-indigo-500 rounded cursor-pointer self-start">+</span>`)

    addFieldBtn.addEventListener("click", this.addField.bind(this))
    return addFieldBtn
  }
  addField(e) {
    const schEl = e.target.closest(".sort-handle")
    const path = schEl.id.replace("main", "")
    const level = schEl.getAttribute("aria-level")
    const rootID = e.target.closest("[data-group='root']").id

    this.phx.pushEvent("add_field", {
      path: rootID + path,
      field: "Record",
      level: level
    })
  }
}
