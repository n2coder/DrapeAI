import { motion } from 'framer-motion'
import WaitlistForm from './WaitlistForm'
import { Analytics } from '../utils/analytics'

export default function CTA() {
  return (
    <section id="download" className="py-24 md:py-32 relative overflow-hidden">
      {/* Ambient glow */}
      <div
        className="absolute inset-0 pointer-events-none"
        style={{
          background:
            'radial-gradient(ellipse at 50% 100%, rgba(155,93,229,0.15) 0%, rgba(247,37,133,0.08) 40%, transparent 70%)',
        }}
      />

      <div className="section-container relative z-10">
        <motion.div
          initial={{ opacity: 0, y: 40 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.75, ease: [0.22, 1, 0.36, 1] }}
          className="grad-border relative overflow-hidden"
        >
          {/* Background gradients */}
          <div
            className="absolute inset-0 rounded-[20px] pointer-events-none"
            style={{
              background:
                'radial-gradient(ellipse at 30% 50%, rgba(155,93,229,0.1) 0%, transparent 60%), radial-gradient(ellipse at 70% 50%, rgba(247,37,133,0.07) 0%, transparent 60%)',
            }}
          />
          <div className="absolute -top-20 -left-20 w-64 h-64 rounded-full pointer-events-none"
            style={{ background: 'radial-gradient(circle, rgba(155,93,229,0.15) 0%, transparent 70%)', filter: 'blur(30px)' }} />
          <div className="absolute -bottom-20 -right-20 w-64 h-64 rounded-full pointer-events-none"
            style={{ background: 'radial-gradient(circle, rgba(247,37,133,0.12) 0%, transparent 70%)', filter: 'blur(30px)' }} />

          <div className="relative z-10 grid md:grid-cols-2 gap-0">
            {/* ── Left: Headline + badges ── */}
            <div className="p-10 md:p-14 flex flex-col justify-center">
              <motion.div
                initial={{ opacity: 0, scale: 0.85 }}
                whileInView={{ opacity: 1, scale: 1 }}
                viewport={{ once: true }}
                transition={{ delay: 0.1, duration: 0.45 }}
                className="inline-flex items-center gap-2 glass px-4 py-2 rounded-full mb-6 w-fit"
              >
                <span className="w-2 h-2 rounded-full bg-cyan animate-pulse" />
                <span className="text-sm text-white/70 font-medium">Early Access — Be First In</span>
              </motion.div>

              <h2 className="font-display text-4xl md:text-5xl text-white mb-4 leading-tight">
                Get early access
                <br />
                <span className="text-gradient italic">before launch.</span>
              </h2>

              <p className="text-white/50 text-base leading-relaxed mb-8">
                DrapeAI is almost ready. Drop your email to be first to know — plus get exclusive founding user perks when we go live.
              </p>

              {/* Perks */}
              <ul className="space-y-2.5">
                {[
                  { icon: '⚡', text: 'First access when we launch' },
                  { icon: '🎁', text: 'Founding member badge in-app' },
                  { icon: '🔒', text: 'No spam — just the launch email' },
                ].map((perk) => (
                  <li key={perk.text} className="flex items-center gap-3">
                    <span className="text-base">{perk.icon}</span>
                    <span className="text-white/55 text-sm">{perk.text}</span>
                  </li>
                ))}
              </ul>
            </div>

            {/* ── Right: Waitlist form ── */}
            <div className="p-10 md:p-14 flex flex-col justify-center border-t md:border-t-0 md:border-l border-white/[0.06]">
              <p className="text-white/30 text-xs font-semibold uppercase tracking-[2px] mb-5">
                Join the waitlist
              </p>
              <WaitlistForm />
            </div>
          </div>
        </motion.div>

        {/* ── Store buttons below ── */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ delay: 0.3, duration: 0.5 }}
          className="mt-8 text-center"
        >
          <p className="text-white/25 text-sm mb-5">Available soon on</p>
          <div className="flex flex-col sm:flex-row gap-3 justify-center items-center">
            <motion.a
              href="#"
              onClick={() => Analytics.downloadClick('app_store')}
              whileHover={{ scale: 1.04 }}
              whileTap={{ scale: 0.97 }}
              className="flex items-center gap-3 glass px-6 py-3.5 rounded-2xl border border-white/10 hover:border-white/25 transition-all"
            >
              <svg className="w-6 h-6 text-white" fill="currentColor" viewBox="0 0 24 24">
                <path d="M17.05 20.28c-.98.95-2.05.8-3.08.35-1.09-.46-2.09-.48-3.24 0-1.44.62-2.2.44-3.06-.35C2.79 15.25 3.51 7.7 9.05 7.42c1.32.07 2.24.73 3.03.74.87-.02 2.48-.89 4.1-.76 2.66.2 4.64 1.77 4.92 4.76-3.41 1.36-3.95 6.2.06 7.12-.46 1.2-.97 2.36-2.11 3zm-3.05-18.27c.57 2.68-1.78 5.45-4.55 5.17-.5-2.56 1.74-5.5 4.55-5.17z" />
              </svg>
              <div className="text-left">
                <p className="text-white/40 text-[10px] font-medium uppercase tracking-wider">Coming to</p>
                <p className="text-white font-semibold text-sm">App Store</p>
              </div>
            </motion.a>

            <motion.a
              href="#"
              onClick={() => Analytics.downloadClick('google_play')}
              whileHover={{ scale: 1.04 }}
              whileTap={{ scale: 0.97 }}
              className="flex items-center gap-3 glass px-6 py-3.5 rounded-2xl border border-white/10 hover:border-white/25 transition-all"
            >
              <svg className="w-6 h-6" viewBox="0 0 24 24" fill="none">
                <path d="M3.18 23.76c.32.17.68.18 1.02.05l11.37-6.57-2.48-2.48-9.91 9z" fill="#EA4335" />
                <path d="M20.82 10.33c-.38-.57-.93-.99-1.63-1.26L17.06 7.9 14.25 10.7l2.81 2.81 2.13-1.23c.7-.41 1.16-1.08 1.16-1.93 0-.03-.02-.05-.02-.08-.01-.33-.18-.66-.51-.94z" fill="#FBBC04" />
                <path d="M3.18.24C2.83.13 2.44.18 2.1.39a2.1 2.1 0 00-.86 1.8v19.62c0 .73.32 1.39.86 1.8.34.21.73.26 1.08.15l12.15-11.76L3.18.24z" fill="#4285F4" />
                <path d="M4.2.29L15.57 6.86l-2.48 2.48L4.2.29z" fill="#34A853" />
              </svg>
              <div className="text-left">
                <p className="text-white/40 text-[10px] font-medium uppercase tracking-wider">Coming to</p>
                <p className="text-white font-semibold text-sm">Google Play</p>
              </div>
            </motion.a>
          </div>
        </motion.div>
      </div>
    </section>
  )
}
