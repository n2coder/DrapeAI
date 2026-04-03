import { motion } from 'framer-motion'

const steps = [
  {
    number: '01',
    icon: (
      <svg className="w-6 h-6" fill="none" stroke="currentColor" strokeWidth="1.5" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" d="M6.827 6.175A2.31 2.31 0 015.186 7.23c-.38.054-.757.112-1.134.175C2.999 7.58 2.25 8.507 2.25 9.574V18a2.25 2.25 0 002.25 2.25h15A2.25 2.25 0 0021.75 18V9.574c0-1.067-.75-1.994-1.802-2.169a47.865 47.865 0 00-1.134-.175 2.31 2.31 0 01-1.64-1.055l-.822-1.316a2.192 2.192 0 00-1.736-1.039 48.774 48.774 0 00-5.232 0 2.192 2.192 0 00-1.736 1.039l-.821 1.316z" />
        <path strokeLinecap="round" strokeLinejoin="round" d="M16.5 12.75a4.5 4.5 0 11-9 0 4.5 4.5 0 019 0zM18.75 10.5h.008v.008h-.008V10.5z" />
      </svg>
    ),
    title: 'Snap & Upload',
    desc: 'Photograph each clothing item from your wardrobe. Our AI instantly identifies category, color, fabric, and style.',
    accent: '#9b5de5',
    accentEnd: 'rgba(155,93,229,0.3)',
    glow: 'rgba(155,93,229,0.25)',
    /* Phone screen content */
    screen: <SnapScreen />,
  },
  {
    number: '02',
    icon: (
      <svg className="w-6 h-6" fill="none" stroke="currentColor" strokeWidth="1.5" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" d="M9.813 15.904L9 18.75l-.813-2.846a4.5 4.5 0 00-3.09-3.09L2.25 12l2.846-.813a4.5 4.5 0 003.09-3.09L9 5.25l.813 2.846a4.5 4.5 0 003.09 3.09L15.75 12l-2.846.813a4.5 4.5 0 00-3.09 3.09zM18.259 8.715L18 9.75l-.259-1.035a3.375 3.375 0 00-2.455-2.456L14.25 6l1.036-.259a3.375 3.375 0 002.455-2.456L18 2.25l.259 1.035a3.375 3.375 0 002.456 2.456L21.75 6l-1.035.259a3.375 3.375 0 00-2.456 2.456zM16.894 20.567L16.5 21.75l-.394-1.183a2.25 2.25 0 00-1.423-1.423L13.5 18.75l1.183-.394a2.25 2.25 0 001.423-1.423l.394-1.183.394 1.183a2.25 2.25 0 001.423 1.423l1.183.394-1.183.394a2.25 2.25 0 00-1.423 1.423z" />
      </svg>
    ),
    title: 'AI Analyzes',
    desc: 'DrapeAI learns your style preferences, body type, and the occasion. It factors in real-time weather from your city.',
    accent: '#f72585',
    accentEnd: 'rgba(247,37,133,0.3)',
    glow: 'rgba(247,37,133,0.25)',
    screen: <AnalyzeScreen />,
  },
  {
    number: '03',
    icon: (
      <svg className="w-6 h-6" fill="none" stroke="currentColor" strokeWidth="1.5" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" d="M9 12.75L11.25 15 15 9.75M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
      </svg>
    ),
    title: 'Get Dressed',
    desc: 'Receive a complete top-to-toe outfit recommendation in under 3 seconds. One tap for a fresh look anytime.',
    accent: '#00f5d4',
    accentEnd: 'rgba(0,245,212,0.3)',
    glow: 'rgba(0,245,212,0.25)',
    screen: <OutfitScreen />,
  },
]

/* ── Phone screen: Step 1 — Snap & Upload ── */
function SnapScreen() {
  return (
    <div className="w-full h-full bg-[#0a0a18] flex flex-col">
      {/* Status bar */}
      <div className="flex justify-between items-center px-5 pt-8 pb-2 text-white text-[9px] font-semibold flex-shrink-0">
        <span>9:41</span>
        <div className="flex gap-1">
          <div className="w-3 h-1.5 bg-white/60 rounded-sm" />
          <div className="w-1 h-1.5 bg-white/30 rounded-sm" />
        </div>
      </div>

      {/* Header */}
      <div className="px-4 pb-3 flex-shrink-0">
        <p className="text-white/40 text-[9px] uppercase tracking-widest">Add to Wardrobe</p>
        <p className="text-white text-base font-semibold mt-0.5" style={{ fontFamily: 'Cormorant Garamond, serif', fontWeight: 300 }}>
          Snap your item
        </p>
      </div>

      {/* Camera viewfinder */}
      <div className="mx-4 flex-1 rounded-2xl bg-[#111128] border border-purple/20 relative overflow-hidden flex items-center justify-center mb-4">
        {/* Corner guides */}
        {[['top-2 left-2', 'border-t border-l'], ['top-2 right-2', 'border-t border-r'], ['bottom-2 left-2', 'border-b border-l'], ['bottom-2 right-2', 'border-b border-r']].map(([pos, border], i) => (
          <div key={i} className={`absolute ${pos} w-5 h-5 ${border} border-purple/60`} />
        ))}

        {/* Clothing emoji placeholder */}
        <div className="text-center">
          <div className="text-5xl mb-2">👕</div>
          <div className="flex gap-1 justify-center">
            {['Top', 'Blue', 'Cotton'].map((tag) => (
              <span key={tag} className="text-[8px] bg-purple/20 text-purple-light px-1.5 py-0.5 rounded-full border border-purple/20">{tag}</span>
            ))}
          </div>
        </div>

        {/* AI scanning animation */}
        <motion.div
          className="absolute left-0 right-0 h-px"
          style={{ background: 'linear-gradient(90deg, transparent, rgba(155,93,229,0.8), transparent)' }}
          animate={{ top: ['20%', '80%', '20%'] }}
          transition={{ duration: 2.5, repeat: Infinity, ease: 'easeInOut' }}
        />
      </div>

      {/* Capture button */}
      <div className="flex justify-center pb-5 flex-shrink-0">
        <div className="w-12 h-12 rounded-full border-2 border-purple/50 flex items-center justify-center">
          <div className="w-9 h-9 rounded-full bg-gradient-to-br from-purple to-pink" />
        </div>
      </div>
    </div>
  )
}

/* ── Phone screen: Step 2 — AI Analyzes ── */
function AnalyzeScreen() {
  const tags = [
    { label: 'Top', color: '#9b5de5' },
    { label: 'Casual', color: '#f72585' },
    { label: 'Cotton', color: '#00f5d4' },
    { label: 'Summer', color: '#fb923c' },
    { label: 'Light Blue', color: '#60a5fa' },
  ]
  return (
    <div className="w-full h-full bg-[#0a0a18] flex flex-col px-4 pt-8">
      <p className="text-white/40 text-[9px] uppercase tracking-widest flex-shrink-0">AI Analysis</p>
      <p className="text-white text-base font-semibold mt-0.5 mb-4 flex-shrink-0" style={{ fontFamily: 'Cormorant Garamond, serif', fontWeight: 300 }}>
        Analyzing item...
      </p>

      {/* Item preview */}
      <div className="flex gap-3 mb-4 flex-shrink-0">
        <div className="w-14 h-14 rounded-xl bg-gradient-to-br from-blue-400 to-blue-700 flex items-center justify-center text-2xl flex-shrink-0">👕</div>
        <div className="flex-1">
          <p className="text-white text-sm font-semibold">White Linen Tee</p>
          <p className="text-white/40 text-[10px] mt-0.5">Category detected</p>
          {/* Progress bar */}
          <div className="mt-2 h-1 rounded-full bg-white/10 overflow-hidden">
            <motion.div
              className="h-full rounded-full"
              style={{ background: 'linear-gradient(90deg, #9b5de5, #f72585)' }}
              initial={{ width: '0%' }}
              animate={{ width: '100%' }}
              transition={{ duration: 1.8, repeat: Infinity, repeatDelay: 0.5 }}
            />
          </div>
        </div>
      </div>

      {/* Detected tags */}
      <p className="text-white/30 text-[9px] uppercase tracking-widest mb-2 flex-shrink-0">Detected attributes</p>
      <div className="flex flex-wrap gap-1.5 mb-4 flex-shrink-0">
        {tags.map((tag, i) => (
          <motion.span
            key={tag.label}
            initial={{ opacity: 0, scale: 0.7 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ delay: i * 0.15, duration: 0.3 }}
            className="text-[9px] font-semibold px-2 py-1 rounded-full"
            style={{ background: `${tag.color}18`, color: tag.color, border: `1px solid ${tag.color}30` }}
          >
            {tag.label}
          </motion.span>
        ))}
      </div>

      {/* Weather context */}
      <div className="rounded-xl border border-pink/20 bg-pink/[0.06] p-3 flex items-center gap-2 flex-shrink-0">
        <span className="text-base">🌤</span>
        <div>
          <p className="text-white/60 text-[9px]">Weather context</p>
          <p className="text-white text-[11px] font-medium">24°C · Mumbai — Good match ✓</p>
        </div>
      </div>
    </div>
  )
}

/* ── Phone screen: Step 3 — Get Dressed ── */
function OutfitScreen() {
  return (
    <div className="w-full h-full bg-[#0a0a18] flex flex-col px-4 pt-8">
      <p className="text-white/40 text-[9px] uppercase tracking-widest flex-shrink-0">Today's Outfit</p>
      <div className="flex items-center justify-between mt-0.5 mb-4 flex-shrink-0">
        <p className="text-white text-base font-semibold" style={{ fontFamily: 'Cormorant Garamond, serif', fontWeight: 300 }}>
          Ready in 2.4s ⚡
        </p>
        <span className="text-[9px] text-cyan/80 bg-cyan/10 px-2 py-0.5 rounded-full border border-cyan/20">AI Pick</span>
      </div>

      {/* Outfit items */}
      <div className="flex gap-2 mb-4 flex-shrink-0">
        {[
          { emoji: '👕', label: 'White Tee', sub: 'Casual · Cotton', bg: 'from-slate-500 to-slate-700' },
          { emoji: '👖', label: 'Navy Chinos', sub: 'Slim Fit', bg: 'from-blue-700 to-blue-900' },
          { emoji: '👟', label: 'Sneakers', sub: 'White · Clean', bg: 'from-gray-200 to-gray-400' },
        ].map((item, i) => (
          <motion.div
            key={item.label}
            initial={{ opacity: 0, y: 16 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: i * 0.18, duration: 0.4 }}
            className="flex-1 rounded-xl bg-white/[0.04] border border-white/[0.07] p-2 text-center"
          >
            <div className={`w-8 h-8 rounded-lg bg-gradient-to-br ${item.bg} mx-auto mb-1 flex items-center justify-center text-sm`}>
              {item.emoji}
            </div>
            <p className="text-white text-[9px] font-semibold leading-tight">{item.label}</p>
            <p className="text-white/30 text-[8px] mt-0.5 leading-tight">{item.sub}</p>
          </motion.div>
        ))}
      </div>

      {/* Tags row */}
      <div className="flex gap-1.5 mb-4 flex-shrink-0">
        {['Casual', 'Weather ✓', 'Style match'].map((t, i) => (
          <span key={t} className="text-[8px] px-2 py-0.5 rounded-full"
            style={{
              background: ['rgba(155,93,229,0.15)', 'rgba(0,245,212,0.12)', 'rgba(247,37,133,0.12)'][i],
              color: ['#c084fc', '#00f5d4', '#f72585'][i],
              border: `1px solid ${ ['rgba(155,93,229,0.25)', 'rgba(0,245,212,0.2)', 'rgba(247,37,133,0.2)'][i]}`,
            }}>
            {t}
          </span>
        ))}
      </div>

      {/* CTA */}
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 0.7 }}
        className="rounded-xl py-2.5 text-center text-white text-xs font-semibold flex-shrink-0"
        style={{ background: 'linear-gradient(135deg, #9b5de5, #f72585)' }}
      >
        Wear This Today →
      </motion.div>
    </div>
  )
}

/* ── Mini phone frame ── */
function PhoneCard({ step, index }) {
  return (
    <motion.div
      initial={{ opacity: 0, x: -60 }}
      whileInView={{ opacity: 1, x: 0 }}
      viewport={{ once: true, margin: '-60px' }}
      transition={{ duration: 0.65, delay: index * 0.18, ease: [0.22, 1, 0.36, 1] }}
      whileHover={{ y: -8, transition: { duration: 0.25 } }}
      className="flex flex-col items-center group"
    >
      {/* Phone frame */}
      <div
        className="relative mb-6"
        style={{
          filter: `drop-shadow(0 20px 60px ${step.glow})`,
        }}
      >
        {/* Outer glow ring */}
        <div
          className="absolute -inset-px rounded-[30px] opacity-0 group-hover:opacity-100 transition-opacity duration-500 pointer-events-none"
          style={{
            background: `linear-gradient(135deg, ${step.accent}40, ${step.accentEnd})`,
            filter: 'blur(8px)',
          }}
        />

        {/* Phone shell */}
        <div
          className="relative w-[170px] h-[340px] rounded-[30px] overflow-hidden"
          style={{
            background: '#0a0a18',
            boxShadow: `0 0 0 1.5px rgba(255,255,255,0.08), 0 0 0 3px #0a0a18, 0 0 0 4px rgba(255,255,255,0.04)`,
          }}
        >
          {/* Notch */}
          <div className="absolute top-0 left-1/2 -translate-x-1/2 w-16 h-4 bg-[#0a0a18] rounded-b-xl z-10" />

          {/* Screen content */}
          <div className="absolute inset-0">
            {step.screen}
          </div>

          {/* Gradient overlay at bottom */}
          <div
            className="absolute bottom-0 left-0 right-0 h-10 pointer-events-none"
            style={{ background: 'linear-gradient(to top, #0a0a18, transparent)' }}
          />
        </div>

        {/* Step number badge */}
        <div
          className="absolute -top-3 -right-3 w-8 h-8 rounded-full flex items-center justify-center text-white text-xs font-bold shadow-lg"
          style={{ background: `linear-gradient(135deg, ${step.accent}, ${step.accentEnd.replace('0.3)', '0.8)')})` }}
        >
          {step.number}
        </div>
      </div>

      {/* Icon + Text below phone */}
      <div className="text-center max-w-[180px]">
        <div
          className="w-9 h-9 rounded-xl mx-auto mb-3 flex items-center justify-center"
          style={{
            background: `${step.accent}18`,
            border: `1px solid ${step.accent}30`,
            color: step.accent,
          }}
        >
          {step.icon}
        </div>
        <h3 className="text-white font-semibold text-base mb-1.5">{step.title}</h3>
        <p className="text-white/40 text-xs leading-relaxed">{step.desc}</p>
      </div>
    </motion.div>
  )
}

export default function HowItWorks() {
  return (
    <section id="how-it-works" className="relative py-24 md:py-32 overflow-hidden">
      <div className="absolute top-0 left-0 right-0 h-32 bg-gradient-to-b from-bg to-transparent pointer-events-none" />

      <div className="section-container relative z-10">
        {/* Header */}
        <motion.div
          initial={{ opacity: 0, y: 24 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6 }}
          className="text-center mb-16"
        >
          <span className="inline-block text-xs text-purple-light font-semibold uppercase tracking-[3px] mb-3">
            Simple as 1 – 2 – 3
          </span>
          <h2 className="font-display text-4xl md:text-5xl text-white">
            How <span className="text-gradient italic">DrapeAI</span> works
          </h2>
          <p className="text-white/45 mt-4 max-w-lg mx-auto leading-relaxed">
            From a chaotic wardrobe to a perfectly styled outfit in three effortless steps.
          </p>
        </motion.div>

        {/* Phone cards */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-10 md:gap-6 lg:gap-12 items-start">
          {/* Connector line (desktop) */}
          <div className="hidden md:block absolute left-0 right-0 pointer-events-none"
            style={{ top: 'calc(50% - 80px)' }}>
          </div>

          {steps.map((step, i) => (
            <div key={step.number} className="flex flex-col items-center">
              {/* Connector arrow between cards on desktop */}
              {i < steps.length - 1 && (
                <motion.div
                  initial={{ opacity: 0, scaleX: 0 }}
                  whileInView={{ opacity: 1, scaleX: 1 }}
                  viewport={{ once: true }}
                  transition={{ delay: 0.4 + i * 0.18, duration: 0.5 }}
                  className="hidden md:block absolute"
                  style={{
                    top: '170px',
                    left: `calc(${(i + 1) * 33.33}% - 20px)`,
                    transformOrigin: 'left',
                  }}
                />
              )}
              <PhoneCard step={step} index={i} />
            </div>
          ))}
        </div>

        {/* Horizontal connector line on desktop */}
        <motion.div
          initial={{ scaleX: 0, opacity: 0 }}
          whileInView={{ scaleX: 1, opacity: 1 }}
          viewport={{ once: true }}
          transition={{ duration: 0.8, delay: 0.3 }}
          className="hidden md:block absolute h-px"
          style={{
            background: 'linear-gradient(90deg, rgba(155,93,229,0.3), rgba(247,37,133,0.3), rgba(0,245,212,0.3))',
            top: 'calc(50% - 60px)',
            left: 'calc(16.6% + 85px)',
            right: 'calc(16.6% + 85px)',
            transformOrigin: 'left',
          }}
        />
      </div>
    </section>
  )
}
