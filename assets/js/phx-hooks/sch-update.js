export default {
  updateSch() {
    return (event) => this.pushEvent("update_sch", {
      key: this.el.getAttribute("phx-value-key"),
      path: this.el.getAttribute("phx-value-path"),
      value: event.target.value
    })
  },
  mounted() {
    this.el.addEventListener("blur", this.updateSch(), true)
  }
}
