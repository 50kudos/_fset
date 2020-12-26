export default class Observer {
  constructor(el, config = {}) {
    this.el = el
    this.config = config
    this.observer = new MutationObserver(this._observeEditable.bind(this))
  }
  start() {
    this.observer.observe(this.el, { attributes: true, childList: true, subtree: true })
  }
  stop() {
    this.observer.disconnect()
  }
  _observeEditable(mutationsList, observer) {
    for (const mutation of mutationsList) {
      switch (mutation.type) {
        case "childList":
          for (let addedNode of mutation.addedNodes) {
            this.config.nodeAdded && this.config.nodeAdded(addedNode)
          }
          for (let removedNode of mutation.removedNodes) {
            this.config.nodeRemoved && this.config.nodeRemoved(removedNode)
          }
          if (mutation.target) {
            this.config.targetChanged && this.config.targetChanged(mutation.target)
          }
          break;
        case "attributes":
          if (mutation.target) {
            this.config.attrChanged && this.config.attrChanged(mutation.target)
          }
          break;
      }
    }
  }
}
