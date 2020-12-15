export default {
  mounted() { this.autoHeight() },
  updated() { this.autoHeight() },
  autoHeight() {
    let setHeight = () => {
      let style = window.getComputedStyle(this.el)
      var boxSizing = style.boxSizing === "border-box"
        ? parseInt(style.borderBottomWidth, 10) +
        parseInt(style.borderTopWidth, 10)
        : 0

      this.el.style.height = "auto"
      this.el.style.height = (this.el.scrollHeight + boxSizing) + "px"
    }

    setHeight()
    this.el.oninput = setHeight
  }
}
