module.exports = {
  variants: {
    borderWidth: ['responsive', 'hover', 'focus', 'odd', 'last'],
    borderColor: ['responsive', 'hover', 'focus', 'odd', 'last'],
    textColor: ['responsive', 'hover', 'focus', 'focus-within']
  },
  future: {
    purgeLayersByDefault: true,
    removeDeprecatedGapUtilities: true,
  },
  purge: {
    // enabled: true,
    content: [
      '../lib/fset_web/live/*.{leex,ex}',
      '../lib/fset_web/templates/**/*.{leex,eex}',
      '../lib/fset_web/views/*.ex',
      './js/phx-hooks.js'
    ],
    options: {
      safelist: ['multi', '/phx-*/']
    }
  }
}
