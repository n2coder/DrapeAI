import { motion } from 'framer-motion'

const features = [
  {
    icon: (
      <svg className="w-5 h-5" fill="none" stroke="currentColor" strokeWidth="1.5" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" d="M6.827 6.175A2.31 2.31 0 015.186 7.23c-.38.054-.757.112-1.134.175C2.999 7.58 2.25 8.507 2.25 9.574V18a2.25 2.25 0 002.25 2.25h15A2.25 2.25 0 0021.75 18V9.574c0-1.067-.75-1.994-1.802-2.169a47.865 47.865 0 00-1.134-.175 2.31 2.31 0 01-1.64-1.055l-.822-1.316a2.192 2.192 0 00-1.736-1.039 48.774 48.774 0 00-5.232 0 2.192 2.192 0 00-1.736 1.039l-.821 1.316z" />
      </svg>
    ),
    title: 'Smart Wardrobe',
    desc: 'Snap a photo — AI extracts category, color, fabric, pattern and season suitability instantly.',
    color: '#9b5de5',
    size: 'md:col-span-1',
  },
  {
    icon: (
      <svg className="w-5 h-5" fill="none" stroke="currentColor" strokeWidth="1.5" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" d="M2.25 15a4.5 4.5 0 004.5 4.5H18a3.75 3.75 0 001.332-7.257 3 3 0 00-3.758-3.848 5.25 5.25 0 00-10.233 2.33A4.502 4.502 0 002.25 15z" />
      </svg>
    ),
    title: 'Weather-Aware Outfits',
    desc: 'Real-time weather from your city shapes every recommendation. Never overdress or underdress again.',
    color: '#00f5d4',
    size: 'md:col-span-1',
  },
  {
    icon: (
      <svg className="w-5 h-5" fill="none" stroke="currentColor" strokeWidth="1.5" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" d="M9.813 15.904L9 18.75l-.813-2.846a4.5 4.5 0 00-3.09-3.09L2.25 12l2.846-.813a4.5 4.5 0 003.09-3.09L9 5.25l.813 2.846a4.5 4.5 0 003.09 3.09L15.75 12l-2.846.813a4.5 4.5 0 00-3.09 3.09z" />
      </svg>
    ),
    title: 'Style Learning AI',
    desc: "The more you use it, the smarter it gets. DrapeAI adapts to your taste — no two users get the same wardrobe experience.",
    color: '#f72585',
    size: 'md:col-span-2',
    wide: true,
  },
  {
    icon: (
      <svg className="w-5 h-5" fill="none" stroke="currentColor" strokeWidth="1.5" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" d="M15.75 6a3.75 3.75 0 11-7.5 0 3.75 3.75 0 017.5 0zM4.501 20.118a7.5 7.5 0 0114.998 0A17.933 17.933 0 0112 21.75c-2.676 0-5.216-.584-7.499-1.632z" />
      </svg>
    ),
    title: 'Occasion Ready',
    desc: 'Casual, formal, date night, gym — pick your vibe and get a perfectly matched outfit every time.',
    color: '#fb923c',
    size: 'md:col-span-1',
  },
  {
    icon: (
      <svg className="w-5 h-5" fill="none" stroke="currentColor" strokeWidth="1.5" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" d="M3.75 13.5l10.5-11.25L12 10.5h8.25L9.75 21.75 12 13.5H3.75z" />
      </svg>
    ),
    title: 'Instant Recommendations',
    desc: 'Full outfit in under 3 seconds — top, bottom, and footwear. One tap, zero decision fatigue.',
    color: '#fbbf24',
    size: 'md:col-span-1',
  },
  {
    icon: (
      <svg className="w-5 h-5" fill="none" stroke="currentColor" strokeWidth="1.5" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" d="M16.5 10.5V6.75a4.5 4.5 0 10-9 0v3.75m-.75 11.25h10.5a2.25 2.25 0 002.25-2.25v-6.75a2.25 2.25 0 00-2.25-2.25H6.75a2.25 2.25 0 00-2.25 2.25v6.75a2.25 2.25 0 002.25 2.25z" />
      </svg>
    ),
    title: 'Private & Secure',
    desc: 'Your wardrobe data stays yours. End-to-end encrypted with Firebase Auth + GDPR compliance built-in.',
    color: '#34d399',
    size: 'md:col-span-1',
  },
]

const containerVariants = {
  hidden: {},
  visible: { transition: { staggerChildren: 0.08 } },
}

const cardVariants = {
  hidden: { opacity: 0, y: 30 },
  visible: { opacity: 1, y: 0, transition: { duration: 0.55, ease: [0.22, 1, 0.36, 1] } },
}

export default function Features() {
  return (
    <section id="features" className="py-24 md:py-32 relative overflow-hidden">
      {/* Ambient glow */}
      <div
        className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[800px] h-[400px] pointer-events-none"
        style={{
          background: 'radial-gradient(ellipse at center, rgba(155,93,229,0.07) 0%, transparent 60%)',
          filter: 'blur(40px)',
        }}
      />

      <div className="section-container relative z-10">
        <motion.div
          initial={{ opacity: 0, y: 24 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6 }}
          className="text-center mb-14"
        >
          <span className="inline-block text-xs text-pink/80 font-semibold uppercase tracking-[3px] mb-3">
            What makes us different
          </span>
          <h2 className="font-display text-4xl md:text-5xl text-white">
            Built for <span className="text-gradient italic">real style.</span>
          </h2>
          <p className="text-white/45 mt-4 max-w-lg mx-auto leading-relaxed">
            Every feature is designed with one goal — helping you look and feel your best without any effort.
          </p>
        </motion.div>

        <motion.div
          variants={containerVariants}
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true, margin: '-60px' }}
          className="grid grid-cols-1 md:grid-cols-3 gap-4"
        >
          {features.map((feat, i) => (
            <motion.div
              key={i}
              variants={cardVariants}
              whileHover={{ y: -5, transition: { duration: 0.2 } }}
              className={`grad-border p-6 relative group overflow-hidden ${feat.size}`}
            >
              {/* Hover glow */}
              <div
                className="absolute inset-0 rounded-[20px] opacity-0 group-hover:opacity-100 transition-opacity duration-500 pointer-events-none"
                style={{ boxShadow: `0 0 50px ${feat.color}18` }}
              />

              {/* Background shimmer */}
              <div
                className="absolute top-0 right-0 w-40 h-40 rounded-full opacity-[0.06] group-hover:opacity-[0.12] transition-opacity duration-500 pointer-events-none"
                style={{
                  background: `radial-gradient(circle, ${feat.color}, transparent)`,
                  filter: 'blur(30px)',
                  transform: 'translate(30%, -30%)',
                }}
              />

              <div className="relative z-10">
                {/* Icon */}
                <div
                  className="w-10 h-10 rounded-xl flex items-center justify-center mb-4"
                  style={{
                    background: `${feat.color}18`,
                    border: `1px solid ${feat.color}30`,
                    color: feat.color,
                  }}
                >
                  {feat.icon}
                </div>

                <h3 className="text-white font-semibold text-lg mb-2">{feat.title}</h3>
                <p className="text-white/45 text-sm leading-relaxed">{feat.desc}</p>

                {/* Wide card: show extra badge */}
                {feat.wide && (
                  <div className="mt-5 flex gap-2 flex-wrap">
                    {['Gender-aware', 'Age-range adaptive', 'City-based', 'Self-improving'].map((tag) => (
                      <span
                        key={tag}
                        className="text-[11px] font-medium px-2.5 py-1 rounded-full"
                        style={{
                          background: `${feat.color}15`,
                          border: `1px solid ${feat.color}25`,
                          color: feat.color,
                        }}
                      >
                        {tag}
                      </span>
                    ))}
                  </div>
                )}
              </div>
            </motion.div>
          ))}
        </motion.div>
      </div>
    </section>
  )
}
