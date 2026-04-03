import { motion } from 'framer-motion'
import { Analytics } from '../utils/analytics'

const fadeUp = (delay = 0) => ({
  initial: { opacity: 0, y: 32 },
  animate: { opacity: 1, y: 0 },
  transition: { duration: 0.7, delay, ease: [0.22, 1, 0.36, 1] },
})

const stats = [
  { value: '10K+', label: 'Outfits Generated' },
  { value: '95%', label: 'Style Accuracy' },
  { value: '3 sec', label: 'Per Recommendation' },
]

/* ── Inline phone mockup showing DrapeAI home screen ── */
function PhoneMockup() {
  return (
    <div className="phone-frame animate-float">
      {/* Notch */}
      <div className="phone-notch" />

      <div className="phone-screen bg-[#0a0a18]">
        {/* Aurora background inside phone */}
        <div
          className="absolute inset-0 pointer-events-none"
          style={{
            background:
              'radial-gradient(ellipse at 70% 20%, rgba(155,93,229,0.25) 0%, transparent 60%), radial-gradient(ellipse at 20% 80%, rgba(247,37,133,0.18) 0%, transparent 55%)',
          }}
        />

        {/* Status bar */}
        <div className="relative z-10 flex justify-between items-center px-6 pt-10 pb-2 text-white text-[9px] font-semibold">
          <span>9:41</span>
          <div className="flex gap-1 items-center">
            <svg className="w-2.5 h-2.5" fill="currentColor" viewBox="0 0 24 24">
              <path d="M1.5 8.5C5.5 4.5 10.5 2.5 12 2.5s6.5 2 10.5 6l-2 2C17.5 7.5 14.5 5.5 12 5.5S6.5 7.5 3.5 10.5l-2-2z M5.5 12.5c1.7-1.7 3.9-2.7 6.5-2.7s4.8 1 6.5 2.7l-2 2c-1.2-1.2-2.8-1.9-4.5-1.9s-3.3.7-4.5 1.9l-2-2z M9.5 16.5c.7-.7 1.5-1 2.5-1s1.8.3 2.5 1l-2.5 2.5-2.5-2.5z" />
            </svg>
            <div className="flex gap-0.5 items-end">
              <div className="w-0.5 h-1.5 bg-white rounded-sm" />
              <div className="w-0.5 h-2 bg-white rounded-sm" />
              <div className="w-0.5 h-2.5 bg-white rounded-sm" />
              <div className="w-0.5 h-3 bg-white/40 rounded-sm" />
            </div>
          </div>
        </div>

        {/* Header */}
        <div className="relative z-10 flex justify-between items-start px-5 pb-3">
          <div>
            <p className="text-white/40 text-[9px] uppercase tracking-widest font-medium">Good Morning</p>
            <p
              className="text-white text-lg font-semibold mt-0.5"
              style={{ fontFamily: '"Cormorant Garamond", serif', fontWeight: 300 }}
            >
              Naresh ✨
            </p>
          </div>
          <div className="w-8 h-8 rounded-full bg-gradient-to-br from-purple to-pink flex items-center justify-center text-white text-[11px] font-bold border border-white/10">
            N
          </div>
        </div>

        <div className="h-px bg-gradient-to-r from-transparent via-white/10 to-transparent mx-5" />

        {/* Weather strip */}
        <div className="relative z-10 mx-4 mt-3 rounded-xl border border-purple/20 bg-purple/[0.08] p-3 flex items-center justify-between">
          <div className="flex items-center gap-2.5">
            <span className="text-xl">🌤</span>
            <div>
              <p className="text-white text-sm font-semibold">24°C</p>
              <p className="text-white/40 text-[8px]">Mumbai · Partly Cloudy</p>
            </div>
          </div>
          <p className="text-purple-light text-[8px] text-right leading-tight max-w-[80px]">
            Light layers work great today
          </p>
        </div>

        {/* Today's pick */}
        <div className="relative z-10 mx-4 mt-3">
          <p className="text-white/40 text-[9px] uppercase tracking-widest font-medium mb-2">Today's Outfit</p>
          <div className="grad-border p-3">
            <div className="flex gap-2">
              {[
                { emoji: '👕', label: 'White Tee', color: 'from-slate-400 to-slate-600' },
                { emoji: '👖', label: 'Navy Chinos', color: 'from-blue-600 to-blue-900' },
                { emoji: '👟', label: 'White Sneakers', color: 'from-gray-100 to-gray-300' },
              ].map((item) => (
                <div key={item.label} className="flex-1 rounded-lg bg-white/[0.05] p-2 text-center">
                  <div
                    className={`w-8 h-8 rounded-lg bg-gradient-to-br ${item.color} mx-auto mb-1 flex items-center justify-center text-sm`}
                  >
                    {item.emoji}
                  </div>
                  <p className="text-white/50 text-[7px] leading-tight">{item.label}</p>
                </div>
              ))}
            </div>
            <div className="mt-2 flex items-center justify-between">
              <div className="flex gap-1">
                <span className="text-[7px] text-purple-light bg-purple/20 px-1.5 py-0.5 rounded-full">Casual</span>
                <span className="text-[7px] text-cyan/80 bg-cyan/10 px-1.5 py-0.5 rounded-full">Weather ✓</span>
              </div>
              <span className="text-[7px] text-white/30">AI Generated</span>
            </div>
          </div>
        </div>

        {/* Wardrobe preview */}
        <div className="relative z-10 mx-4 mt-3">
          <p className="text-white/40 text-[9px] uppercase tracking-widest font-medium mb-2">Your Wardrobe</p>
          <div className="flex gap-2">
            {[
              { emoji: '🧥', bg: 'from-stone-600 to-stone-900' },
              { emoji: '👔', bg: 'from-blue-500 to-blue-800' },
              { emoji: '👗', bg: 'from-pink-400 to-pink-700' },
              { emoji: '🩳', bg: 'from-amber-500 to-amber-800' },
            ].map((item, i) => (
              <div
                key={i}
                className={`flex-1 aspect-square rounded-xl bg-gradient-to-br ${item.bg} flex items-center justify-center text-lg`}
              >
                {item.emoji}
              </div>
            ))}
          </div>
        </div>

        {/* Bottom nav */}
        <div className="absolute bottom-0 left-0 right-0 z-10 border-t border-white/[0.06] bg-[rgba(10,10,24,0.95)] flex justify-around py-3 px-4">
          {[
            { icon: '🏠', active: true },
            { icon: '👔', active: false },
            { icon: '✨', active: false },
            { icon: '👤', active: false },
          ].map((item, i) => (
            <div key={i} className={`flex flex-col items-center gap-0.5 ${item.active ? '' : 'opacity-30'}`}>
              <span className="text-base">{item.icon}</span>
              {item.active && (
                <div className="w-1 h-1 rounded-full bg-gradient-to-r from-purple to-pink" />
              )}
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}

export default function Hero() {
  return (
    <section className="relative min-h-screen flex items-center pt-16 overflow-hidden">
      {/* Aurora background blobs */}
      <div className="absolute inset-0 pointer-events-none overflow-hidden">
        <div
          className="absolute w-[600px] h-[600px] rounded-full animate-blob-1"
          style={{
            top: '-10%',
            left: '-5%',
            background: 'radial-gradient(circle, rgba(155,93,229,0.18) 0%, transparent 70%)',
            filter: 'blur(40px)',
          }}
        />
        <div
          className="absolute w-[500px] h-[500px] rounded-full animate-blob-2"
          style={{
            top: '20%',
            right: '-10%',
            background: 'radial-gradient(circle, rgba(247,37,133,0.14) 0%, transparent 70%)',
            filter: 'blur(40px)',
          }}
        />
        <div
          className="absolute w-[400px] h-[400px] rounded-full animate-blob-3"
          style={{
            bottom: '10%',
            left: '30%',
            background: 'radial-gradient(circle, rgba(0,245,212,0.1) 0%, transparent 70%)',
            filter: 'blur(40px)',
          }}
        />
        {/* Grid overlay */}
        <div
          className="absolute inset-0 opacity-[0.03]"
          style={{
            backgroundImage:
              'linear-gradient(rgba(255,255,255,0.8) 1px, transparent 1px), linear-gradient(90deg, rgba(255,255,255,0.8) 1px, transparent 1px)',
            backgroundSize: '60px 60px',
          }}
        />
      </div>

      <div className="section-container relative z-10 w-full py-16 md:py-24">
        <div className="flex flex-col lg:flex-row items-center gap-12 lg:gap-16">
          {/* ── Left: Text content ── */}
          <div className="flex-1 text-center lg:text-left max-w-xl mx-auto lg:mx-0">
            {/* Badge */}
            <motion.div {...fadeUp(0)} className="inline-flex items-center gap-2 glass px-4 py-2 rounded-full mb-6">
              <span className="w-2 h-2 rounded-full bg-cyan animate-pulse" />
              <span className="text-sm text-white/70 font-medium">AI-Powered Personal Stylist</span>
            </motion.div>

            {/* Headline */}
            <motion.h1
              {...fadeUp(0.1)}
              className="font-display text-5xl md:text-6xl lg:text-7xl leading-[1.05] mb-6"
            >
              Wear Smarter.
              <br />
              <span className="text-gradient italic">Every Day.</span>
            </motion.h1>

            {/* Subtext */}
            <motion.p
              {...fadeUp(0.2)}
              className="text-white/55 text-lg leading-relaxed mb-8 max-w-md mx-auto lg:mx-0"
            >
              Stop guessing what to wear. DrapeAI turns your wardrobe into a smart recommendation engine — powered by AI, weather, and your personal style.
            </motion.p>

            {/* CTA buttons */}
            <motion.div {...fadeUp(0.3)} className="flex flex-col sm:flex-row gap-3 justify-center lg:justify-start mb-10">
              <a href="#download" className="btn-primary btn-shimmer" onClick={() => Analytics.heroCTAClick()}>
                <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 24 24">
                  <path d="M17.05 20.28c-.98.95-2.05.8-3.08.35-1.09-.46-2.09-.48-3.24 0-1.44.62-2.2.44-3.06-.35C2.79 15.25 3.51 7.7 9.05 7.42c1.32.07 2.24.73 3.03.74.87-.02 2.48-.89 4.1-.76 2.66.2 4.64 1.77 4.92 4.76-3.41 1.36-3.95 6.2.06 7.12-.46 1.2-.97 2.36-2.11 3zm-3.05-18.27c.57 2.68-1.78 5.45-4.55 5.17-.5-2.56 1.74-5.5 4.55-5.17z" />
                </svg>
                Get on App Store
              </a>
              <a href="#how-it-works" className="btn-outline">
                See how it works
                <svg className="w-4 h-4" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" d="M9 5l7 7-7 7" />
                </svg>
              </a>
            </motion.div>

            {/* Stats */}
            <motion.div
              {...fadeUp(0.4)}
              className="flex gap-6 justify-center lg:justify-start"
            >
              {stats.map((stat, i) => (
                <div key={i} className="text-center lg:text-left">
                  <p className="text-2xl font-bold text-gradient">{stat.value}</p>
                  <p className="text-xs text-white/40 font-medium mt-0.5">{stat.label}</p>
                </div>
              ))}
            </motion.div>
          </div>

          {/* ── Right: Phone mockup ── */}
          <motion.div
            initial={{ opacity: 0, x: 60, scale: 0.92 }}
            animate={{ opacity: 1, x: 0, scale: 1 }}
            transition={{ duration: 0.9, delay: 0.2, ease: [0.22, 1, 0.36, 1] }}
            className="flex-shrink-0 flex justify-center"
          >
            {/* Glow ring behind phone */}
            <div className="relative">
              <div
                className="absolute inset-[-40px] rounded-full pointer-events-none"
                style={{
                  background:
                    'radial-gradient(ellipse at center, rgba(155,93,229,0.2) 0%, rgba(247,37,133,0.1) 50%, transparent 70%)',
                  filter: 'blur(20px)',
                }}
              />
              <PhoneMockup />
            </div>
          </motion.div>
        </div>
      </div>

      {/* Scroll indicator */}
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 1.5 }}
        className="absolute bottom-8 left-1/2 -translate-x-1/2 flex flex-col items-center gap-2"
      >
        <span className="text-white/25 text-xs tracking-widest uppercase font-medium">Scroll</span>
        <motion.div
          animate={{ y: [0, 8, 0] }}
          transition={{ repeat: Infinity, duration: 1.5, ease: 'easeInOut' }}
          className="w-px h-8 bg-gradient-to-b from-white/20 to-transparent"
        />
      </motion.div>
    </section>
  )
}
