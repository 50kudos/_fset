import Sortable, { MultiDrag } from "sortablejs"
import Observer from "./observer.js"
Sortable.mount(new MultiDrag())

export default class ModelSortable {
  constructor(phx, listSelector) {
    this.phx = phx
    this.el = phx.el
    this.listSelector = listSelector
  }
  start() {
    this._sortableLists().forEach(list => this._newSorter(list))
    this._startObserve()

    this.phx.handleEvent("current_path", ({ paths }) => {
      let sorters = this._sortableLists().map(a => a._sorter)
      SortableList.selectCurrentItems(sorters, paths)
    })
  }
  _startObserve() {
    this._observer = new Observer(this.el, {
      nodeAdded: (addedNode) => {
        if (this._isList(addedNode)) { this._newSorter(addedNode) }
      },
      nodeRemoved: (removedNode) => {
        if (this._isList(removedNode)) { removedNode._sorter?.destroy() }
      }
    })
    this._observer.start()
  }
  stop() {
    this._sortableLists().forEach(list => { list._sorter?.destroy() })
    this._observer.stop()
  }
  _sortableLists() {
    return [...this.el.querySelectorAll(this.listSelector)]
  }
  _isList(node) {
    node.nodeType == Node.ELEMENT_NODE && node.querySelector(this.listSelector)
  }
  _newSorter(list) {
    list._sorter = new SortableList(list, {
      list: {
        rootID: this.phx.rootID,
        itemClass: ".sort-handle",
        highlightClass: ".h",
        heighlightStyle: ["bg-indigo-700", "bg-opacity-25"],
        indentClass: ".k"
      },
      sorter: {
        moved: (movedItems) => this.phx.pushEvent("move", movedItems),
        selected: (selectedItemPaths) => this.phx.pushEvent("select_sch", { paths: selectedItemPaths })
      }
    })

    return list
  }
}

class SortableList {
  constructor(el, config = {}) {
    this.el = el
    this.config = config
    this.meta = {}

    // List semantic
    const listConfig = this.config.list
    this.rootID = listConfig.rootID
    this.itemClass = listConfig.itemClass
    this.highlightClass = listConfig.highlightClass
    this.heighlightStyle = listConfig.heighlightStyle
    this.indentClass = listConfig.indentClass

    this.sorter = Sortable.get(this.el) || this.setupSortable(this.el)
  }
  destroy() {
    this.sorter.destroy()
  }
  resetHighLight() {
    document.querySelectorAll(this.highlightClass).forEach(a => a.classList.remove(...this.heighlightStyle))
  }
  highlightBoxHeader(box) {
    let boxParent = box.closest(this.itemClass)
    let boxHeader = boxParent && boxParent.querySelector(this.highlightClass)
    boxHeader && boxHeader.classList.add(...this.heighlightStyle)
  }
  setItemIndent(item, box) {
    let indentEl = item.querySelector(this.indentClass)
    let indentBox = box.querySelector(this.indentClass)
    if (indentEl && indentBox) { indentEl.style.paddingLeft = indentBox.style.paddingLeft || "0rem" }
  }
  itemPath(el) {
    let item = Sortable.utils.closest(el, this.itemClass)

    if (item.id.startsWith("main")) { item.id = item.id.replace("main", "") }
    if (item.id == this.rootID) { return item.id }
    else { return this.rootID + item.id }
  }
  static selectCurrentItems(sorters, paths) {
    sorters.forEach(sorter => {
      if (!sorter?.el) { return }
      sorter.el.querySelectorAll(this.itemClass).forEach(item => Sortable.utils.deselect(item))

      paths.forEach(currentPath => {
        if (currentPath == this.rootID) {
          currentPath = "main"
        } else {
          currentPath = currentPath.replace(this.rootID, "")
        }
        let item = sorter.el.querySelector(`[id='${currentPath}']`)
        if (!item) { return }

        item.from = sorter.el
        item.multiDragKeyDown = false
        Sortable.utils.select(item)

        if (paths.length > 1) { item.classList.add("multi") }
        // item.scrollIntoView({ behavior: "smooth", block: "center" })
      })
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
  setupSortable(el) {
    let sortableOpts = {
      group: el.dataset.group || "nested",
      // group: "nested",
      // disabled: !!el.dataset.group,
      // swapThreshold: 0.1,
      // invertedSwapThreshold: 0.2,
      // invertSwap: true,
      animation: 0,
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
        this.config.sorter.moved(this.movedItems(evt))
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
        if (!evt.item.multiDragKeyDown && !this.meta.shiftSelect) {
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
        const ShiftSelect = evt.items.length == this.meta.shiftSelect
        const isMetaSelect = evt.item.multiDragKeyDown

        if (ShiftSelect || isMetaSelect || evt.items.length == 1) {
          this.config.sorter.selected(evt.items.map(a => this.itemPath(a)))
        }

      },
      onChoose: (evt) => {
        evt.item.multiDragKeyDown = evt.originalEvent.metaKey

        // Prepare for onSelect to pick up shiftSelect to prevent select_sch from firing EVERY time.
        // This makes pushEvent only firing when all items are shift-selected.
        if (evt.originalEvent.shiftKey) {
          let minIndex = Math.min(this.meta.lastChoosed, evt.oldIndex)
          let maxIndex = Math.max(this.meta.lastChoosed, evt.oldIndex)
          this.meta.shiftSelect = maxIndex - minIndex + 1
        } else {
          this.meta.lastChoosed = evt.oldIndex
        }
      },
    }

    return new Sortable(el, sortableOpts)
  }
}
