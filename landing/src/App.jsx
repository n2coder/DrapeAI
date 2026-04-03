import { useEffect } from 'react'
import Navbar from './components/Navbar'
import Hero from './components/Hero'
import HowItWorks from './components/HowItWorks'
import Features from './components/Features'
import WardrobeStrip from './components/WardrobeStrip'
import CTA from './components/CTA'
import Footer from './components/Footer'
import { initAnalytics, Analytics } from './utils/analytics'

export default function App() {
  // Init GA4 + Clarity on mount
  useEffect(() => {
    initAnalytics()
  }, [])

  // Track section views as user scrolls — fires once per section
  useEffect(() => {
    const sections = [
      { id: 'how-it-works', name: 'how_it_works' },
      { id: 'wardrobe', name: 'wardrobe' },
      { id: 'features', name: 'features' },
      { id: 'download', name: 'cta_download' },
    ]

    const observers = sections.map(({ id, name }) => {
      const el = document.getElementById(id)
      if (!el) return null

      const obs = new IntersectionObserver(
        ([entry]) => {
          if (entry.isIntersecting) {
            Analytics.sectionView(name)
            obs.disconnect() // fire once
          }
        },
        { threshold: 0.3 }
      )
      obs.observe(el)
      return obs
    })

    return () => observers.forEach((o) => o?.disconnect())
  }, [])

  return (
    <div className="min-h-screen bg-bg text-white overflow-x-hidden">
      <Navbar />
      <main>
        <Hero />
        <HowItWorks />
        <WardrobeStrip />
        <Features />
        <CTA />
      </main>
      <Footer />
    </div>
  )
}
