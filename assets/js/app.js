// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import "../css/app.scss"

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import deps with the dep name or local files with a relative path, for example:
//
//     import {Socket} from "phoenix"
//     import socket from "./socket"
//
import "phoenix_html"
import { Socket } from "phoenix"
import { LiveSocket } from "phoenix_live_view"
import phxHooks from "./phx-hooks"

import topbar from "topbar"
import "./menu"
import { Elm } from "../elm/elm.min.js"

window.elm = {}
window.elm.node = document.querySelector("[phx-hook='elm']")
window.elm.Main = Elm.Main.init({
  node: window.elm.node.appendChild(document.createElement("code")),
  flags: JSON.parse(window.fstore.dataset.store)
})
// document.querySelector("[phx-hook='elm']").appendChild(window.elm.node)


let moduleContainer = document.querySelector("#module_container")
let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken, module_container: { rect: moduleContainer.getBoundingClientRect() } },
  hooks: phxHooks
})
liveSocket.connect()
window.liveSocket = liveSocket

let indigo500 = "rgba(102, 126, 234, 1)"
let indigo700 = "rgba(102, 126, 234, 1)"
topbar.config({ barColors: [indigo700, indigo500], barThickness: 2 })
// window.addEventListener("phx:page-loading-start", info => topbar.show())
// window.addEventListener("phx:page-loading-stop", info => topbar.hide())
