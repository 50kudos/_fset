(function () {
  const closeAllOpenedDetails = () => {
    for (const menu of document.querySelectorAll('details[open] > .details-menu')) {
      const opened = menu.closest('details')
      opened.removeAttribute('open')
    }
  }

  const closeAllMenues = (e) => {
    if (!e.target.closest("details")) { // Alternative to stopPropagation on current <details>
      closeAllOpenedDetails()
    }
  }

  window.addEventListener("click", closeAllMenues)
}).call(this)
