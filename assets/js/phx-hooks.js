import Sortable, { MultiDrag } from "sortablejs"

let Hooks = {}

Hooks.expandableSortable = {
  mounted() {
    this.el.expand = this.el.open
    this.el.addEventListener("toggle", event => this.el.expand = event.target.open)
    this.setupSortable()
  },
  updated() {
    this.el.open = this.el.expand
    this.setupSortable()
  },
  // User defined functions and properties
  itemClass: ".sort-handle",
  highlightClass: ".dragover-hl",
  heighlightStyle: ["bg-indigo-700", "bg-opacity-75"],
  indentClass: ".indent",

  resetHighLight() {
    document.querySelectorAll(this.highlightClass).forEach(a => a.classList.remove(...this.heighlightStyle))
  },
  highlightBoxHeader(box) {
    let boxHeader = box.querySelector(this.highlightClass)
    boxHeader.classList.add(...this.heighlightStyle)
  },
  setItemIndent(item, box) {
    let indentEl = item.querySelector(this.indentClass) || item
    let boxHeader = box.querySelector(this.indentClass)

    indentEl.style.paddingLeft = boxHeader.dataset.indent
  },
  itemPath(item) {
    return item.dataset.path || item.querySelector("details").dataset.path
  },
  movedItems(drop) {
    let newIndexItem = [{ from: this.itemPath(drop.from), index: drop.newIndex }]
    let oldIndexItem = [{ from: this.itemPath(drop.from), index: drop.oldIndex }]

    let oldIndexItems = drop.oldIndicies.map(a => { return { from: this.itemPath(a.multiDragElement.from), index: a.index } })
    let newIndexItems = drop.newIndicies.map(a => { return { from: this.itemPath(a.multiDragElement.from), index: a.index } })

    return {
      to: drop.to.dataset.path,
      oldIndices: drop.oldIndicies.length == 0 ? oldIndexItem : oldIndexItems,
      newIndices: drop.newIndicies.length == 0 ? newIndexItem : newIndexItems
    }
  },
  setupSortable() {
    let sortableEl = Sortable.get(this.el)
    let sortableOpts = {
      group: "nested",
      fallbackOnBody: true,
      swapThreshold: 0.35,
      multiDrag: true,
      multiDragKey: "Meta",
      dragoverBubble: true,
      filter: ".filtered",
      handle: this.itemClass,
      draggable: this.itemClass,
      direction: "vertical",
      revertOnSpill: true,

      onEnd: (evt) => {
        this.pushEvent("move", this.movedItems(evt))
        evt.items.forEach(item => this.setItemIndent(item, evt.to))
        this.resetHighLight()
      },
      onMove: (evt) => {
        this.resetHighLight()
        this.highlightBoxHeader(evt.to)
        this.setItemIndent(evt.dragged, evt.to)
      },
      onSelect: (evt) => {
        // workaround for multi-select items from multiple lists
        evt.item.from = evt.from
        this.pushEvent("select_sch", { path: evt.items.map(this.itemPath) })
      },
      onDeselect: (evt) => { console.log("deselect") }
    }

    sortableEl || (new Sortable(this.el, sortableOpts))
  }
}

Sortable.mount(new MultiDrag())

export default Hooks
