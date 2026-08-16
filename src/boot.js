// Boot: styles first (tokens -> components), then the Elm app.
// Browser.application owns the whole <body> and reads the URL itself —
// there is no mount node to hand it.
//
// The theme attribute lives on <html>, which Elm does not own, so the
// shell reaches it through the saveTheme port (theme plan Phase 3).
import './theme.css'
import './protocol.css'
import { Elm } from './Main.elm'

const THEME_KEY = 'autophagous-theme'

// Apply the stored preference BEFORE Elm boots — the page must never
// flash the wrong theme. "system" is represented by absence: no
// attribute, no stored key, the prefers-color-scheme query governs.
let storedTheme = null
try {
  storedTheme = localStorage.getItem(THEME_KEY)
} catch (_) {
  // storage unavailable: fall through as system
}
if (storedTheme === 'light' || storedTheme === 'dark') {
  document.documentElement.dataset.theme = storedTheme
}

const app = Elm.Main.init({
  flags: { theme: storedTheme },
})

app.ports.saveTheme.subscribe((theme) => {
  if (theme === 'light' || theme === 'dark') {
    document.documentElement.dataset.theme = theme
  } else {
    delete document.documentElement.dataset.theme
  }
  try {
    if (theme === 'light' || theme === 'dark') {
      localStorage.setItem(THEME_KEY, theme)
    } else {
      localStorage.removeItem(THEME_KEY)
    }
  } catch (_) {
    // storage full or unavailable: the attribute still applied, so the
    // choice holds for this session even if it can't persist
  }
})
