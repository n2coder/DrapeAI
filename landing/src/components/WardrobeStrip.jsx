import { useRef } from 'react'
import { motion } from 'framer-motion'

const occasions = [
  {
    label: 'Casual Friday',
    mood: 'Relaxed & Cool',
    items: ['👕', '👖', '👟'],
    gradient: 'from-purple/30 to-purple/5',
    accent: '#9b5de5',
    tag: 'Casual',
  },
  {
    label: 'Office Ready',
    mood: 'Sharp & Confident',
    items: ['👔', '👔', '🥿'],
    gradient: 'from-blue-600/25 to-blue-900/5',
    accent: '#3b82f6',
    tag: 'Formal',
  },
  {
    label: 'Date Night',
    mood: 'Elegant & Bold',
    items: ['👗', '👠', '💍'],
    gradient: 'from-pink/30 to-pink/5',
    accent: '#f72585',
    tag: 'Evening',
  },
  {
    label: 'Weekend Brunch',
    mood: 'Fresh & Airy',
    items: ['🧥', '👜', '🩴'],
    gradient: 'from-amber-500/25 to-amber-900/5',
    accent: '#f59e0b',
    tag: 'Brunch',
  },
  {
    label: 'Gym & Sport',
    mood: 'Energetic & Light',
    items: ['🩱', '🩲', '👟'],
    gradient: 'from-cyan/25 to-cyan/5',
    accent: '#00f5d4',
    tag: 'Active',
  },
  {
    label: 'Winter Layer',
    mood: 'Cosy & Stylish',
    items: ['🧤', '🧣', '🥾'],
    gradient: 'from-slate-400/20 to-slate-800/5',
    accent: '#94a3b8',
    tag: 'Winter',
  },
]

export default function WardrobeStrip() {
  const scrollRef = useRef(null)

  return (
    <section id="wardrobe" className="py-20 md:py-28 overflow-hidden">
      <div className="section-container">
        <motion.div
          initial={{ opacity: 0, y: 24 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6 }}
          className="flex flex-col sm:flex-row sm:items-end justify-between gap-4 mb-10"
        >
          <div>
            <span className="inline-block text-xs text-cyan/80 font-semibold uppercase tracking-[3px] mb-3">
              Outfit Library
            </span>
            <h2 className="font-display text-4xl md:text-5xl text-white">
              Every occasion,{' '}
              <span className="text-gradient-cyan italic">covered.</span>
            </h2>
          </div>
          <p className="text-white/40 text-sm max-w-xs leading-relaxed">
            DrapeAI generates outfit combinations for any moment — from morning coffee to midnight events.
          </p>
        </motion.div>
      </div>

      {/* Horizontal scroll strip — full bleed */}
      <motion.div
        initial={{ opacity: 0, x: 40 }}
        whileInView={{ opacity: 1, x: 0 }}
        viewport={{ once: true }}
        transition={{ duration: 0.7 }}
        ref={scrollRef}
        className="flex gap-4 overflow-x-auto no-scrollbar px-6 pb-3 cursor-grab active:cursor-grabbing"
        style={{ paddingLeft: 'max(24px, calc(50vw - 588px))' }}
      >
        {occasions.map((item, i) => (
          <motion.div
            key={i}
            whileHover={{ y: -8, scale: 1.02, transition: { duration: 0.2 } }}
            whileTap={{ scale: 0.97 }}
            className={`flex-shrink-0 w-56 rounded-3xl bg-gradient-to-br ${item.gradient} border border-white/[0.07] p-5 relative overflow-hidden group cursor-pointer`}
          >
            {/* Background glow */}
            <div
              className="absolute -top-10 -right-10 w-32 h-32 rounded-full opacity-20 group-hover:opacity-40 transition-opacity"
              style={{ background: `radial-gradient(circle, ${item.accent}, transparent)`, filter: 'blur(20px)' }}
            />

            {/* Tag */}
            <span
              className="inline-block text-[10px] font-bold uppercase tracking-widest px-2.5 py-1 rounded-full mb-4"
              style={{
                background: `${item.accent}22`,
                color: item.accent,
                border: `1px solid ${item.accent}33`,
              }}
            >
              {item.tag}
            </span>

            {/* Clothing emojis */}
            <div className="flex gap-2 mb-4">
              {item.items.map((emoji, j) => (
                <div
                  key={j}
                  className="w-12 h-12 rounded-xl bg-white/[0.06] border border-white/[0.08] flex items-center justify-center text-xl"
                >
                  {emoji}
                </div>
              ))}
            </div>

            <h4 className="text-white font-semibold text-base mb-1">{item.label}</h4>
            <p className="text-white/40 text-xs">{item.mood}</p>

            {/* Arrow */}
            <div
              className="absolute bottom-4 right-4 w-7 h-7 rounded-full flex items-center justify-center opacity-0 group-hover:opacity-100 transition-all duration-300 translate-x-2 group-hover:translate-x-0"
              style={{ background: `${item.accent}30`, border: `1px solid ${item.accent}50` }}
            >
              <svg className="w-3 h-3" fill="none" stroke={item.accent} strokeWidth="2" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" d="M9 5l7 7-7 7" />
              </svg>
            </div>
          </motion.div>
        ))}

        {/* End spacer */}
        <div className="flex-shrink-0 w-6" />
      </motion.div>
    </section>
  )
}
