import Sortable, { MultiDrag } from "sortablejs"

let Hooks = {}

Hooks.expandableSortable = {
  resetHighLight() {
    document.querySelectorAll(".dragover-hl").forEach(a => a.classList.remove("bg-indigo-700", "bg-opacity-75"))
  },
  setupSortable() {
    const findOrCreateSortable = (el, opts = {}) => {
      let sortableEl = Sortable.get(el)
      let sortableOpts = Object.assign({
        group: "nested",
        fallbackOnBody: true,
        swapThreshold: 0.35,
        multiDrag: true,
        multiDragKey: "Shift",
        dragoverBubble: true,
        filter: ".filtered",
        handle: ".sort-handle",
        draggable: ".sort-handle",
        emptyInsertThreshold: 16,
        direction: "vertical"
      }, opts)

      sortableEl || (new Sortable(el, sortableOpts))
    }
    const pushItem = (drop) => {
      return {
        to: drop.to.dataset.path,
        newIndices: drop.newIndicies.length == 0 ? [drop.newIndex] : drop.newIndicies.map(a => a.index),
        from: drop.from.dataset.path,
        oldIndices: drop.oldIndicies.length == 0 ? [drop.oldIndex] : drop.oldIndicies.map(a => a.index)
      }
    }

    findOrCreateSortable(this.el, {
      onEnd: (droppedItem) => {
        this.pushEvent("move", pushItem(droppedItem))
        this.resetHighLight()
      },
      onMove: (evt) => {
        let boxHeader = evt.to.querySelector(".dragover-hl")
        let boxIdent = boxHeader.dataset.indent
        let draggedHeader = evt.dragged.querySelector(".dragover-hl") || evt.dragged

        this.resetHighLight()
        boxHeader.classList.add("bg-indigo-700", "bg-opacity-75")
        draggedHeader.classList.add("bg-indigo-700")
        draggedHeader.style.paddingLeft = boxIdent
      }
    })
  },
  mounted() {
    let el = this.el
    el.expand = this.el.open

    this.el.addEventListener("toggle", event => {
      el.expand = event.target.open
    })

    this.setupSortable()
  },
  updated() {
    let el = this.el
    el.open = el.expand

    this.setupSortable()
  }
}

Sortable.mount(new MultiDrag())
export default Hooks
