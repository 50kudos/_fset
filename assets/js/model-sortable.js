import Sortable, { MultiDrag } from "sortablejs"

export default class PhxSortable {
  constructor(phx, opts = {}) {
    this.phx = phx
    this.el = phx.el
    this.rootId = opts.rootId

    // User defined functions and properties
    this.itemClass = ".sort-handle"
    this.highlightClass = ".dragover-hl"
    this.heighlightStyle = ["bg-indigo-700", "bg-opacity-25"]
    this.indentClass = ".indent"
    this.cursorLoadingStyle = "phx-click-loading"

    this.findOrCreate()
  }

  findOrCreate() {
    let sortableEl = Sortable.get(this.el)
    if (!sortableEl) {
      this.setupSortable()
      this.phx.handleEvent("current_path", ({ paths }) => {
        this.selectCurrentItems(paths)
      })
    }
  }
  static destroy(phx) {
    this.el = phx.el
    let sortableEl = Sortable.get(this.el)
    sortableEl && sortableEl.destroy()
  }
  resetHighLight() {
    document.querySelectorAll(this.highlightClass).forEach(a => a.classList.remove(...this.heighlightStyle))
  }
  highlightBoxHeader(box) {
    let boxHeader = box.closest(this.itemClass)
    if (boxHeader) {
      boxHeader = boxHeader.querySelector(this.highlightClass)
      boxHeader.classList.add(...this.heighlightStyle)
    }
  }
  setItemIndent(item, box) {
    let indentEl = item.querySelector(this.indentClass)
    if (indentEl) { indentEl.style.paddingLeft = box.dataset.indent || "0rem" }
  }
  sortableRoot() {
    return document.querySelector("[data-group='body']")
  }
  rootID() {
    return this.rootId || this.sortableRoot().id
  }
  itemPath(el) {
    let item = Sortable.utils.closest(el, this.itemClass)
    let rootEl = this.sortableRoot()

    if (item == rootEl) {
      return item.id
    } else {
      return (this.rootId || rootEl.id) + item.id
    }
  }
  selectCurrentItems(paths) {
    const currentPaths = paths
    const itemBox = this.el
    const sortableEl = Sortable.get(itemBox)

    sortableEl && sortableEl.multiDrag._deselectMultiDrag()
    currentPaths.forEach(currentPath => {
      currentPath = currentPath.replace(this.rootID(), "")
      let item = itemBox.querySelector(`[id='${currentPath}']`)
      if (!item) { return }

      item.from = itemBox
      item.multiDragKeyDown = false
      Sortable.utils.select(item)

      if (currentPaths.length > 1) { item.classList.add("multi") }
      // item.scrollIntoView({ behavior: "smooth", block: "center" })
    })
  }
  movedItems(drop) {
    let newIndexItem = [{ to: this.itemPath(drop.to), index: drop.newIndex }]
    let oldIndexItem = [{ from: this.itemPath(drop.from), index: drop.oldIndex }]

    let oldIndexItems = drop.oldIndicies.map(a => { return { from: this.itemPath(a.multiDragElement.from), index: a.index } })
    let newIndexItems = drop.newIndicies.map(a => { return { to: this.itemPath(drop.to), index: a.index } })

    return {
      oldIndices: drop.oldIndicies.length == 0 ? oldIndexItem : oldIndexItems,
      newIndices: drop.newIndicies.length == 0 ? newIndexItem : newIndexItems
    }
  }
  setupSortable() {
    let sortableEl = this.el
    let sortableOpts = {
      group: this.el.dataset.group || "nested",
      // group: "nested",
      // disabled: !!this.el.dataset.group,
      // swapThreshold: 0.1,
      // invertedSwapThreshold: 0.2,
      // invertSwap: true,
      animation: 150,
      multiDrag: true,
      multiDragKey: "Meta",
      dragoverBubble: false,
      filter: ".filtered",
      preventOnFilter: false,
      handle: this.itemClass,
      draggable: this.itemClass,
      // direction: "horizontal",
      revertOnSpill: true,
      forceFallback: navigator.userAgent.indexOf("Safari") !== -1,
      fallbackOnBody: true,
      fallbackTolerance: 8,

      onEnd: (evt) => {
        this.phx.pushEvent("move", this.movedItems(evt))
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

        // Deselect all ancestors; do not allow selecting items that follow the same path.
        let ancestors = evt.items.filter(item => {
          return item != evt.item && (item.contains(evt.item) || evt.item.contains(item))
        })
        ancestors.forEach(selectableEl => Sortable.utils.deselect(selectableEl))
        evt.items = evt.items.filter(item => !ancestors.includes(item))


        // Do not multi-select across lists when multiDragKey is not pressed.
        if (!evt.item.multiDragKeyDown) {
          let fromDiffList = evt.items.filter(item => {
            return item != evt.item && item.from != evt.from
          })
          fromDiffList.forEach(diffListItem => diffListItem.parentNode && Sortable.utils.deselect(diffListItem))
          evt.items = evt.items.filter(item => !fromDiffList.includes(item))
        }

        // Do not multi-select same-list when multiDragKey is not pressed.
        // This is implemented separately from above. It may be better this way.
        if (!evt.item.multiDragKeyDown && !this.el.shiftSelect) {
          let exceptItselfItems = evt.items.filter(item => {
            return item != evt.item
          })
          exceptItselfItems.forEach(item => item.parentNode && Sortable.utils.deselect(item))
          evt.items = evt.items.filter(item => !exceptItselfItems.includes(item))
        }

        // Remove add_field buttons on multi-select, otherwise they do not look good.
        if (evt.items.length > 1) {
          evt.items.forEach(item => item.classList.add("multi"))
        } else {
          evt.item.classList.remove("multi")
        }

        // PushEvent only when necessary
        const ShiftSelect = evt.items.length == this.el.shiftSelect
        const isMetaSelect = evt.item.multiDragKeyDown

        if (ShiftSelect || isMetaSelect || evt.items.length == 1) {
          this.phx.pushEvent("select_sch", { paths: evt.items.map(a => this.itemPath(a)) })
        }

      },
      onChoose: function (evt) {
        evt.item.multiDragKeyDown = evt.originalEvent.metaKey

        // Prepare for onSelect to pick up shiftSelect to prevent select_sch from firing EVERY time.
        // This makes pushEvent only firing when all items are shift-selected.
        if (evt.originalEvent.shiftKey) {
          let minIndex = Math.min(this.el.lastChoosed, evt.oldIndex)
          let maxIndex = Math.max(this.el.lastChoosed, evt.oldIndex)
          this.el.shiftSelect = maxIndex - minIndex + 1
        } else {
          this.el.lastChoosed = evt.oldIndex
        }
      },
    }

    new Sortable(sortableEl, sortableOpts)
  }
}
