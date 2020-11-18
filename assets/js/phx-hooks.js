import Sortable, { MultiDrag } from "sortablejs"
import hljs from 'highlight.js/lib/core';
import json from 'highlight.js/lib/languages/json';
import 'highlight.js/styles/agate.css';
// import { Elm } from "../elm/elm.min.js"
import PhxSortable from "./model-sortable.js"

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

// Hooks.elm = {
//   mounted() {
//     let elmMain = window.elm.Main

//     this.handleEvent("file_change", ({ currentFile, anchorsModels }) => {
//       elmMain.ports.stateUpdate.send({ currentFile, anchorsModels })
//       // this.rebindSortable(currentFile.id)
//     })

//     this.handleEvent("model_change", ({ path, sch, id }) => {
//       elmMain.ports.stateUpdate.send({ id, path, sch })
//       // this.rebindSortable(id)
//     })
//   },
//   destroyed() {
//     PhxSortable.destroy(this)
//   },
//   rebindSortable(fileId) {
//     setTimeout(() => {
//       let moveableHookEls = document.querySelectorAll("[phx-hook='moveable']")
//       let phx = this

//       moveableHookEls.forEach(el => {
//         phx.el = el
//         phx.fileId = fileId
//         let phxSortable = new PhxSortable(phx, { rootId: fileId })
//       })
//     }, 300)
//   }
// }

hljs.registerLanguage('json', json);
Hooks.syntaxHighlight = {
  mounted() {
    hljs.highlightBlock(this.el)
  },
  updated() {
    hljs.highlightBlock(this.el)
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
    let phxSortable = new PhxSortable(this)
  },
  updated() {
    // let phxSortable = new PhxSortable(this)
  },
  destroyed() {
    PhxSortable.destroy(this)
  }
}

Sortable.mount(new MultiDrag())

export default Hooks
