import hljs from 'highlight.js/lib/core';
import json from 'highlight.js/lib/languages/json';
import 'highlight.js/styles/agate.css';

export default {
  mounted() {
    hljs.registerLanguage('json', json);
    hljs.highlightBlock(this.el)
  },
  updated() {
    hljs.highlightBlock(this.el)
  }
}
