export default {
  mounted() {
    this.handleEvent("changeable_types", ({ typeOptions }) => {
      window.liveStore.typeOptions = typeOptions
    })
  }
}
