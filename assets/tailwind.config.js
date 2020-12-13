const colors = require("tailwindcss/colors")

module.exports = {

  variants: {
    extend: {
      borderColor: ["odd", "last"],
      borderWidth: ["hover", "focus", "odd", "last"],
    }
  },
  purge: {
    // enabled: true,
    content: [
      "../lib/fset_web/live/*.{leex,ex}",
      "../lib/fset_web/templates/**/*.{leex,eex}",
      "../lib/fset_web/views/*.ex",
      "./js/**/*.js"
    ],
    options: {
      safelist: ["multi", "/phx-*/"]
    }
  }
}
