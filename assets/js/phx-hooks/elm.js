// import { Elm } from "../../elm/elm.min.js"

// export default {
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
