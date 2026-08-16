import { defineConfig } from 'vite'
import elmPlugin from 'vite-plugin-elm'

// vite-plugin-elm (≤ 3.1.x) emits `import.meta.hot.accept([""])` when an
// Elm module imports no other local .elm files; Vite 8's import analysis
// rejects the empty specifier. Rewrite it to a bare self-accept.
// (Carried over from cryovault, same plugin/Vite pairing.)
const fixElmEmptyHmrAccept = {
  name: 'fix-elm-empty-hmr-accept',
  transform(code, id) {
    if (!id.endsWith('.elm')) return null
    const fixed = code.replace(
      /import\.meta\.hot\.accept\(\[\s*""\s*\],/,
      'import.meta.hot.accept([],'
    )
    return fixed === code ? null : { code: fixed, map: null }
  },
}

export default defineConfig({
  plugins: [elmPlugin(), fixElmEmptyHmrAccept],
  build: {
    // Pre-16.4 iOS WebKit can't parse minified range media queries
    // (`(width<=960px)`); pin an older CSS floor so queries ship in the
    // universally-parsed form. (Seen live on cryovault 2026-08-06.)
    cssTarget: ['chrome87', 'safari13.1', 'firefox78'],
  },
})
