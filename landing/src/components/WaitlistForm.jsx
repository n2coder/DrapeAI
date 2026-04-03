import { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { Analytics } from '../utils/analytics'

const API_URL = import.meta.env.VITE_API_URL || 'https://drapeai-wnum.onrender.com'

const states = { idle: 'idle', loading: 'loading', success: 'success', error: 'error' }

export default function WaitlistForm() {
  const [email, setEmail] = useState('')
  const [name, setName] = useState('')
  const [status, setStatus] = useState(states.idle)
  const [message, setMessage] = useState('')
  const [count, setCount] = useState(null)

  async function handleSubmit(e) {
    e.preventDefault()
    if (!email.trim()) return
    setStatus(states.loading)

    try {
      const res = await fetch(`${API_URL}/waitlist`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email: email.trim(), name: name.trim() || undefined }),
      })
      const data = await res.json()

      if (res.ok && data.success) {
        setStatus(states.success)
        setMessage(data.message)
        // Track GA4 event — only pass domain for privacy
        const domain = email.split('@')[1] || 'unknown'
        Analytics.waitlistSignup(domain)
        // Fetch live count to show social proof
        fetchCount()
      } else {
        setStatus(states.error)
        setMessage(data.message || 'Something went wrong. Please try again.')
      }
    } catch {
      setStatus(states.error)
      setMessage('Could not connect. Please check your connection and try again.')
    }
  }

  async function fetchCount() {
    try {
      const res = await fetch(`${API_URL}/waitlist/count`)
      const data = await res.json()
      if (data?.data?.count) setCount(data.data.count)
    } catch {
      // non-critical
    }
  }

  if (status === states.success) {
    return (
      <motion.div
        initial={{ opacity: 0, scale: 0.9 }}
        animate={{ opacity: 1, scale: 1 }}
        transition={{ duration: 0.4, ease: [0.22, 1, 0.36, 1] }}
        className="grad-border p-8 text-center"
      >
        {/* Animated checkmark */}
        <motion.div
          initial={{ scale: 0 }}
          animate={{ scale: 1 }}
          transition={{ delay: 0.1, type: 'spring', stiffness: 200, damping: 15 }}
          className="w-16 h-16 rounded-full mx-auto mb-4 flex items-center justify-center"
          style={{ background: 'linear-gradient(135deg, #9b5de5, #f72585)' }}
        >
          <svg className="w-8 h-8 text-white" fill="none" stroke="currentColor" strokeWidth="2.5" viewBox="0 0 24 24">
            <motion.path
              strokeLinecap="round"
              strokeLinejoin="round"
              d="M4.5 12.75l6 6 9-13.5"
              initial={{ pathLength: 0 }}
              animate={{ pathLength: 1 }}
              transition={{ delay: 0.3, duration: 0.5 }}
            />
          </svg>
        </motion.div>

        <h3 className="text-white text-xl font-semibold mb-2">You're in! 🎉</h3>
        <p className="text-white/50 text-sm leading-relaxed mb-4">{message}</p>

        {count && (
          <motion.p
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 0.5 }}
            className="text-xs font-medium"
            style={{ color: '#9b5de5' }}
          >
            You're one of {count.toLocaleString()} people waiting for DrapeAI
          </motion.p>
        )}
      </motion.div>
    )
  }

  return (
    <motion.form
      onSubmit={handleSubmit}
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.5 }}
      className="w-full"
    >
      <div className="flex flex-col gap-3">
        {/* Name input */}
        <div className="relative">
          <input
            type="text"
            value={name}
            onChange={(e) => setName(e.target.value)}
            placeholder="Your name (optional)"
            maxLength={80}
            className="w-full px-4 py-3.5 rounded-xl text-sm text-white placeholder-white/30 outline-none transition-all"
            style={{
              background: 'rgba(255,255,255,0.06)',
              border: '1px solid rgba(255,255,255,0.1)',
            }}
            onFocus={(e) => (e.target.style.borderColor = 'rgba(155,93,229,0.5)')}
            onBlur={(e) => (e.target.style.borderColor = 'rgba(255,255,255,0.1)')}
          />
        </div>

        {/* Email + Submit row */}
        <div className="flex gap-2">
          <input
            type="email"
            required
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            placeholder="your@email.com"
            className="flex-1 min-w-0 px-4 py-3.5 rounded-xl text-sm text-white placeholder-white/30 outline-none transition-all"
            style={{
              background: 'rgba(255,255,255,0.06)',
              border: '1px solid rgba(255,255,255,0.1)',
            }}
            onFocus={(e) => (e.target.style.borderColor = 'rgba(155,93,229,0.5)')}
            onBlur={(e) => (e.target.style.borderColor = 'rgba(255,255,255,0.1)')}
          />
          <motion.button
            type="submit"
            disabled={status === states.loading}
            whileHover={{ scale: 1.03 }}
            whileTap={{ scale: 0.97 }}
            className="btn-primary px-5 py-3.5 flex-shrink-0 disabled:opacity-60 disabled:cursor-not-allowed"
          >
            {status === states.loading ? (
              <motion.span
                animate={{ rotate: 360 }}
                transition={{ repeat: Infinity, duration: 0.8, ease: 'linear' }}
                className="block w-4 h-4 border-2 border-white/30 border-t-white rounded-full"
              />
            ) : (
              <>
                <span>Join</span>
                <svg className="w-4 h-4" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" d="M13 7l5 5m0 0l-5 5m5-5H6" />
                </svg>
              </>
            )}
          </motion.button>
        </div>

        {/* Error message */}
        <AnimatePresence>
          {status === states.error && (
            <motion.p
              initial={{ opacity: 0, y: -6 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0 }}
              className="text-xs text-red-400 flex items-center gap-1.5"
            >
              <svg className="w-3.5 h-3.5 flex-shrink-0" fill="currentColor" viewBox="0 0 20 20">
                <path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clipRule="evenodd" />
              </svg>
              {message}
            </motion.p>
          )}
        </AnimatePresence>

        <p className="text-white/25 text-[11px] text-center">
          No spam. We'll only email you when DrapeAI launches. 🔒
        </p>
      </div>
    </motion.form>
  )
}
