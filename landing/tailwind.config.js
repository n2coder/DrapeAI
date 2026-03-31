/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,jsx}'],
  theme: {
    extend: {
      fontFamily: {
        display: ['"Cormorant Garamond"', 'Georgia', 'serif'],
        sans: ['Inter', 'system-ui', 'sans-serif'],
      },
      colors: {
        bg: '#050510',
        card: 'rgba(255,255,255,0.04)',
        purple: {
          DEFAULT: '#9b5de5',
          light: '#c084fc',
          dark: '#7c3aed',
        },
        pink: {
          DEFAULT: '#f72585',
          light: '#fb7185',
        },
        cyan: {
          DEFAULT: '#00f5d4',
          light: '#67e8f9',
        },
      },
      backgroundImage: {
        'grad-primary': 'linear-gradient(135deg, #9b5de5, #f72585)',
        'grad-hero': 'linear-gradient(135deg, #050510 0%, #0d0a2e 100%)',
      },
      animation: {
        'blob-1': 'blob1 12s ease-in-out infinite',
        'blob-2': 'blob2 15s ease-in-out infinite',
        'blob-3': 'blob3 10s ease-in-out infinite',
        float: 'float 6s ease-in-out infinite',
        'spin-slow': 'spin 20s linear infinite',
        shimmer: 'shimmer 2.5s linear infinite',
      },
      keyframes: {
        blob1: {
          '0%, 100%': { transform: 'translate(0px, 0px) scale(1)' },
          '33%': { transform: 'translate(60px, -40px) scale(1.15)' },
          '66%': { transform: 'translate(-40px, 30px) scale(0.9)' },
        },
        blob2: {
          '0%, 100%': { transform: 'translate(0px, 0px) scale(1)' },
          '33%': { transform: 'translate(-70px, 50px) scale(1.1)' },
          '66%': { transform: 'translate(50px, -60px) scale(0.95)' },
        },
        blob3: {
          '0%, 100%': { transform: 'translate(0px, 0px) scale(1)' },
          '50%': { transform: 'translate(40px, -30px) scale(1.2)' },
        },
        float: {
          '0%, 100%': { transform: 'translateY(0px) rotate(-2deg)' },
          '50%': { transform: 'translateY(-18px) rotate(2deg)' },
        },
        shimmer: {
          '0%': { backgroundPosition: '-200% center' },
          '100%': { backgroundPosition: '200% center' },
        },
      },
      backdropBlur: {
        xs: '2px',
      },
    },
  },
  plugins: [],
}
