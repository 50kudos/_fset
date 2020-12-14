const throttle = (func, limit) => {
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

const fragment = (htmlString) => {
  return document.createRange().createContextualFragment(htmlString)
}

const element = (htmlString) => {
  let template = document.createElement("template")
  template.innerHTML = htmlString
  return template.content.firstElementChild
}

const swapTag = (src, dst) => {
  let srcAttributes = [...src.attributes]
  let srcChildNodes = [...src.childNodes]

  let dst_ = src.parentNode.insertBefore(dst, src)
  srcChildNodes.forEach(c => dst_.appendChild(c));
  srcAttributes.forEach(attr => dst_.setAttribute(attr.nodeName, attr.nodeValue))
  src.remove()
}

export { fragment, swapTag, element }
