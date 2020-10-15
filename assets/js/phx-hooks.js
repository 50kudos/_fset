import Sortable, { MultiDrag } from "sortablejs"
import hljs from 'highlight.js/lib/core';
import json from 'highlight.js/lib/languages/json';
import 'highlight.js/styles/agate.css';

let Hooks = {}
let Utils = {}

Utils.throttle = (func, limit) => {
  let inThrottle
  return function () {
    const args = arguments
    const context = this
    if (!inThrottle) {
      func.apply(context, args)
      inThrottle = true
      setTimeout(() => inThrottle = false, limit)
    }
  }
}

hljs.registerLanguage('json', json);
Hooks.syntaxHighlight = {
  mounted() {
    hljs.highlightBlock(this.el)
  },
  updated() {
    hljs.highlightBlock(this.el)
  }
}

Hooks.InfiniteScroll = {
  load_model() {
    return Utils.throttle(e => {
      let page = Math.round(this.el.scrollTop / 1500)
      this.pushEvent("load_models", { page: page })
    }, 300)
  },
  mounted() {
    let load_fun = this.load_model()

    this.el.addEventListener("scroll", load_fun, true)
    this.handleEvent("load_models", ({ modelState }) => {
      if (modelState == "done") {
        this.el.removeEventListener("scroll", load_fun, true)
      }
    })
  }
}

Hooks.focusOnOpen = {
  mounted() {
    this.el.closest("details").addEventListener("toggle", event => {
      if (event.target.open) { this.focusFirstInput() }
    })
  },
  focusFirstInput() {
    let field = this.el.querySelector("input[autofocus]")
    field.focus()
  }
}

Hooks.renameable = {
  mounted() {
    this.el.addEventListener("keydown", e => {
      if (e.code == "Enter") { e.preventDefault() }
    })
    this.focus()
    this.autoHeight()
  },
  updated() {
    this.focus()
    this.autoHeight()
  },
  focus() {
    let field = this.el
    field.focus()
    field.selectionStart = field.selectionEnd = field.value.length
    // field.select()
  },
  autoHeight() {
    let setHeight = () => {
      this.el.scrollTop = this.el.scrollHeight
      this.el.style.height = Math.min(this.el.scrollHeight, 300) + "px"
    }

    setHeight()
    this.el.oninput = setHeight
  }
}

Hooks.autoResize = {
  mounted() { this.autoHeight() },
  updated() { this.autoHeight() },
  autoHeight() {
    let setHeight = () => {
      this.el.scrollTop = this.el.scrollHeight
      this.el.style.height = this.el.scrollHeight + 2 + "px"
    }

    setHeight()
    this.el.oninput = setHeight
  }
}

Hooks.updateSch = {
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

Hooks.moveable = {
  mounted() {
    this.setupSortable()
    this.handleEvent("current_path", ({ paths }) => {
      this.selectCurrentItems(paths)
    })
  },
  updated() {
    this.setupSortable()
  },
  destroyed() {
    Sortable.get(this.el).destroy()
  },
  // User defined functions and properties
  itemClass: ".sort-handle",
  highlightClass: ".dragover-hl",
  heighlightStyle: ["bg-indigo-700", "bg-opacity-25"],
  indentClass: ".indent",
  cursorLoadingStyle: "phx-click-loading",

  resetHighLight() {
    document.querySelectorAll(this.highlightClass).forEach(a => a.classList.remove(...this.heighlightStyle))
  },
  highlightBoxHeader(box) {
    let boxHeader = box.closest(this.itemClass)
    if (boxHeader) {
      boxHeader = boxHeader.querySelector(this.highlightClass)
      boxHeader.classList.add(...this.heighlightStyle)
    }
  },
  setItemIndent(item, box) {
    let indentEl = item.querySelector(this.indentClass)
    if (indentEl) { indentEl.style.paddingLeft = box.dataset.indent || "0rem" }
  },
  sortableRoot() {
    return document.querySelector("[data-group='body']")
  },
  itemPath(el) {
    let item = Sortable.utils.closest(el, this.itemClass) || this.sortableRoot()
    return item.id
  },
  selectCurrentItems(paths) {
    const currentPaths = paths
    const itemBox = this.el

    Sortable.get(itemBox).multiDrag._deselectMultiDrag()
    currentPaths.forEach(currentPath => {
      let item = itemBox.querySelector(`[id='${currentPath}']`)
      if (!item) { return }

      item.from = itemBox
      item.multiDragKeyDown = false
      Sortable.utils.select(item)

      if (currentPaths.length > 1) { item.classList.add("multi") }
      // item.scrollIntoView({ behavior: "smooth", block: "center" })
    })
  },
  movedItems(drop) {
    let newIndexItem = [{ to: this.itemPath(drop.to), index: drop.newIndex }]
    let oldIndexItem = [{ from: this.itemPath(drop.from), index: drop.oldIndex }]

    let oldIndexItems = drop.oldIndicies.map(a => { return { from: this.itemPath(a.multiDragElement.from), index: a.index } })
    let newIndexItems = drop.newIndicies.map(a => { return { to: this.itemPath(drop.to), index: a.index } })

    return {
      oldIndices: drop.oldIndicies.length == 0 ? oldIndexItem : oldIndexItems,
      newIndices: drop.newIndicies.length == 0 ? newIndexItem : newIndexItems
    }
  },
  setupSortable() {
    let sortableEl = this.el
    let sortableOpts = {
      group: this.el.dataset.group || "nested",
      // group: "nested",
      // disabled: !!this.el.dataset.group,
      fallbackOnBody: true,
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
      forceFallback: true,

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
          this.pushEvent("select_sch", { paths: evt.items.map(a => this.itemPath(a)) })
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

    Sortable.get(sortableEl) || new Sortable(sortableEl, sortableOpts)
  }
}
window.Sortable = Sortable
Sortable.mount(new MultiDrag())

export default Hooks
