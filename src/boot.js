// Boot: styles first (tokens -> components), then the Elm app.
// Browser.application owns the whole <body> and reads the URL itself —
// there is no mount node to hand it.
//
// The theme attribute lives on <html>, which Elm does not own, so the
// shell reaches it through the saveTheme port (theme plan Phase 3).
import './theme.css'
import './fonts.css'
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

// ---- the contents rail's active row ----
//
// Elm has no scroll subscription (elm/browser offers resize,
// visibility, keys, clicks and animation frames — nothing for scroll),
// so which section the reader is inside is computed here and sent in
// through the `sectionSeen` port.
//
// The rule: the last section whose top has passed the reading line, a
// third of the way down the viewport. Deliberately NOT a copy of
// Main.jumpTo's sticky-chrome measurement — this is "what am I
// reading", not "where must I scroll to", and a second copy of that
// arithmetic in another language is a number that would drift.
const READING_LINE = 0.3

let lastSeen = null
let queued = false

function readSection() {
  queued = false
  const sections = document.querySelectorAll('.sheet section[id]')
  if (!sections.length) {
    lastSeen = null
    return
  }

  const line = window.innerHeight * READING_LINE
  let seen = sections[0].id
  for (const section of sections) {
    if (section.getBoundingClientRect().top <= line) seen = section.id
  }

  // a final section shorter than the reading line would never become
  // active on its own, however far you scrolled
  const atBottom =
    window.innerHeight + window.scrollY >=
    document.documentElement.scrollHeight - 2
  if (atBottom) seen = sections[sections.length - 1].id

  if (seen !== lastSeen) {
    lastSeen = seen
    app.ports.sectionSeen.send(seen)
  }
}

function scheduleRead() {
  if (queued) return
  queued = true
  requestAnimationFrame(readSection)
}

addEventListener('scroll', scheduleRead, { passive: true })
addEventListener('resize', scheduleRead)

// Elm renders asynchronously and a route change fires no scroll event,
// so the DOM itself is the signal that the section list may have
// changed. The handler only schedules one rAF read, and that read
// sends nothing when the answer is unchanged — which is what makes
// this cheap enough to point at the whole body.
new MutationObserver(scheduleRead).observe(document.body, {
  childList: true,
  subtree: true,
})

scheduleRead()
