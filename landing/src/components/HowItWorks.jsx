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
    accent: 'from-purple to-purple/40',
    glow: 'rgba(155,93,229,0.2)',
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
    accent: 'from-pink to-pink/40',
    glow: 'rgba(247,37,133,0.2)',
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
    accent: 'from-cyan to-cyan/40',
    glow: 'rgba(0,245,212,0.2)',
  },
]

const containerVariants = {
  hidden: {},
  visible: { transition: { staggerChildren: 0.15 } },
}

const itemVariants = {
  hidden: { opacity: 0, y: 40 },
  visible: { opacity: 1, y: 0, transition: { duration: 0.65, ease: [0.22, 1, 0.36, 1] } },
}

export default function HowItWorks() {
  return (
    <section id="how-it-works" className="relative py-24 md:py-32 overflow-hidden">
      {/* Section fade divider top */}
      <div className="absolute top-0 left-0 right-0 h-32 bg-gradient-to-b from-bg to-transparent pointer-events-none" />

      <div className="section-container relative z-10">
        {/* Section header */}
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

        {/* Steps */}
        <motion.div
          variants={containerVariants}
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true, margin: '-80px' }}
          className="grid md:grid-cols-3 gap-6 lg:gap-8 relative"
        >
          {/* Connector line (desktop) */}
          <div className="hidden md:block absolute top-12 left-[calc(16.6%+32px)] right-[calc(16.6%+32px)] h-px bg-gradient-to-r from-purple/30 via-pink/30 to-cyan/30 pointer-events-none" />

          {steps.map((step) => (
            <motion.div
              key={step.number}
              variants={itemVariants}
              whileHover={{ y: -6, transition: { duration: 0.25 } }}
              className="grad-border p-7 relative group"
            >
              {/* Glow on hover */}
              <div
                className="absolute inset-0 rounded-[20px] opacity-0 group-hover:opacity-100 transition-opacity duration-500 pointer-events-none"
                style={{ boxShadow: `0 0 40px ${step.glow}` }}
              />

              {/* Number + Icon */}
              <div className="flex items-center gap-4 mb-5">
                <div
                  className={`w-12 h-12 rounded-2xl bg-gradient-to-br ${step.accent} p-0.5 flex-shrink-0`}
                >
                  <div className="w-full h-full rounded-[14px] bg-bg/90 flex items-center justify-center text-white">
                    {step.icon}
                  </div>
                </div>
                <span
                  className="font-display text-5xl font-light leading-none"
                  style={{
                    background: `linear-gradient(135deg, rgba(255,255,255,0.12), rgba(255,255,255,0.04))`,
                    WebkitBackgroundClip: 'text',
                    WebkitTextFillColor: 'transparent',
                  }}
                >
                  {step.number}
                </span>
              </div>

              <h3 className="text-white text-xl font-semibold mb-3">{step.title}</h3>
              <p className="text-white/45 text-sm leading-relaxed">{step.desc}</p>
            </motion.div>
          ))}
        </motion.div>
      </div>
    </section>
  )
}
