import Sortable, { MultiDrag } from "sortablejs"

let Hooks = {}

Hooks.autoFocus = {
  focus() {
    let field = this.el
    field.focus()
    field.selectionStart = field.selectionEnd = field.value.length
    field.select()
  },
  autoHeight() {
    let setHeight = () => {
      this.el.scrollTop = this.el.scrollHeight
      this.el.style.height = Math.min(this.el.scrollHeight, 300) + "px"
    }

    setHeight()
    this.el.oninput = setHeight
  },
  mounted() {
    this.focus()
    this.autoHeight()
  },
  updated() {
    this.focus()
    this.autoHeight()
  }
}

Hooks.updateSch = {
  updateSch() {
    return (event) => this.pushEvent("update_sch", {
      key: this.el.getAttribute("phx-value-key"),
      value: event.target.value
    })
  },
  mounted() {
    this.el.addEventListener("change", this.updateSch(), true)
  }
}

Hooks.expandableSortable = {
  mounted() {
    this.el.expand = this.el.open
    this.el.addEventListener("toggle", event => this.el.expand = event.target.open)
    this.setupSortable()
  },
  updated() {
    this.el.open = this.el.expand
    this.setupSortable()
    this.selectCurrentItems()
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
    let indentEl = item.querySelector(this.indentClass)
    indentEl.style.paddingLeft = box.dataset.indent
  },
  itemPath(item) {
    return item.dataset.path
  },
  selectCurrentItems() {
    const root = document.querySelector("[data-group='root']")
    const currentPaths = root.dataset.currentPaths

    if (currentPaths) {
      JSON.parse(currentPaths).forEach(currentPath => {
        let item = root.querySelector("[data-path='" + currentPath + "']")
        let itemBox = Sortable.utils.closest(item, "[phx-hook='expandableSortable']")

        item.from = itemBox
        Sortable.utils.select(item)
      })
    }
  },
  movedItems(drop) {
    // Frontend needs to use 1 based index due to technical limitation that we use <summary>
    // tag as first child so that draghover can insert right after it, otherwise we could not
    // drag it right after a list header as a first child (visually).
    let newIndexItem = [{ to: this.itemPath(drop.to), index: drop.newIndex - 1 }]
    let oldIndexItem = [{ from: this.itemPath(drop.from), index: drop.oldIndex - 1 }]

    let oldIndexItems = drop.oldIndicies.map(a => { return { from: this.itemPath(a.multiDragElement.from), index: a.index - 1 } })
    let newIndexItems = drop.newIndicies.map(a => { return { to: this.itemPath(drop.to), index: a.index - 1 } })

    return {
      oldIndices: drop.oldIndicies.length == 0 ? oldIndexItem : oldIndexItems,
      newIndices: drop.newIndicies.length == 0 ? newIndexItem : newIndexItems
    }
  },
  setupSortable() {
    let sortableEl = this.el
    let sortableOpts = {
      group: this.el.dataset.group || "nested",
      fallbackOnBody: true,
      swapThreshold: 0.35,
      multiDrag: true,
      multiDragKey: "Meta",
      dragoverBubble: true,
      filter: ".filtered",
      preventOnFilter: false,
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

        const ShiftSelect = evt.items.length == this.el.shiftSelect
        const isMetaSelect = evt.item.multiDragKeyDown

        if (ShiftSelect || isMetaSelect || evt.items.length == 1) {
          this.pushEvent("select_sch", { path: evt.items.map(this.itemPath) })
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

    let sortableInstance = Sortable.get(sortableEl)
    if (sortableInstance) { sortableInstance.destroy() }

    new Sortable(sortableEl, sortableOpts)
  }
}

Sortable.mount(new MultiDrag())

export default Hooks
