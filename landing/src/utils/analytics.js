/**
 * Analytics initializer — GA4 + Microsoft Clarity
 *
 * Configure via Vite env vars (set in Render static site):
 *   VITE_GA4_ID      — Google Analytics 4 Measurement ID  (e.g. G-XXXXXXXXXX)
 *   VITE_CLARITY_ID  — Microsoft Clarity Project ID       (e.g. xxxxxxxxxx)
 */

const GA4_ID = import.meta.env.VITE_GA4_ID
const CLARITY_ID = import.meta.env.VITE_CLARITY_ID

function injectScript(src, id, onload) {
  if (document.getElementById(id)) return
  const s = document.createElement('script')
  s.id = id
  s.src = src
  s.async = true
  if (onload) s.onload = onload
  document.head.appendChild(s)
}

function injectInlineScript(id, code) {
  if (document.getElementById(id)) return
  const s = document.createElement('script')
  s.id = id
  s.textContent = code
  document.head.appendChild(s)
}

/** Load GA4 */
function initGA4() {
  if (!GA4_ID) return
  injectScript(
    `https://www.googletagmanager.com/gtag/js?id=${GA4_ID}`,
    'ga4-script',
    () => {
      window.dataLayer = window.dataLayer || []
      function gtag() { window.dataLayer.push(arguments) }
      window.gtag = gtag
      gtag('js', new Date())
      gtag('config', GA4_ID, { send_page_view: true })
    }
  )
}

/** Load Microsoft Clarity */
function initClarity() {
  if (!CLARITY_ID) return
  injectInlineScript(
    'clarity-script',
    `(function(c,l,a,r,i,t,y){
      c[a]=c[a]||function(){(c[a].q=c[a].q||[]).push(arguments)};
      t=l.createElement(r);t.async=1;t.src="https://www.clarity.ms/tag/"+i;
      y=l.getElementsByTagName(r)[0];y.parentNode.insertBefore(t,y);
    })(window, document, "clarity", "script", "${CLARITY_ID}");`
  )
}

/** Call once on app mount */
export function initAnalytics() {
  initGA4()
  initClarity()
}

/**
 * Track a custom GA4 event.
 * Falls back silently if GA4 is not loaded.
 *
 * @param {string} eventName  — snake_case event name
 * @param {object} params     — optional GA4 event parameters
 */
export function trackEvent(eventName, params = {}) {
  if (typeof window.gtag === 'function') {
    window.gtag('event', eventName, params)
  }
  // Clarity custom event (optional tagging)
  if (typeof window.clarity === 'function') {
    window.clarity('event', eventName)
  }
}

/** Convenience helpers — call these at specific UX moments */
export const Analytics = {
  /** User submitted the waitlist form */
  waitlistSignup: (email_domain) =>
    trackEvent('waitlist_signup', { email_domain }),

  /** User clicked a download / store button */
  downloadClick: (store) =>
    trackEvent('download_click', { store }),

  /** User scrolled to a section */
  sectionView: (section) =>
    trackEvent('section_view', { section_name: section }),

  /** User clicked the hero CTA */
  heroCTAClick: () =>
    trackEvent('hero_cta_click'),
}
