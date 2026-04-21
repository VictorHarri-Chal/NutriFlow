const defaultTheme = require('tailwindcss/defaultTheme')

module.exports = {
  content: [
    './public/*.html',
    './app/helpers/**/*.rb',
    './app/javascript/**/*.js',
    './app/views/**/*.{erb,haml,html,slim}',
    './app/components/**/*.{rb,erb}'
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ['Syne', ...defaultTheme.fontFamily.sans],
      },
      colors: {
        surface: {
          base:   '#18181B',
          raised: '#27272A',
          hover:  '#3F3F46',
          border: '#52525B',
        },
        brand: {
          DEFAULT: '#EAB308',
          dim:     '#854D0E',
          hover:   '#FDE047',
          muted:   '#713F12',
        },
        ink: {
          primary: '#F4F4F5',
          muted:   '#A1A1AA',
          subtle:  '#71717A',
        },
        macro: {
          calories: '#60A5FA',
          proteins: '#34D399',
          carbs:    '#FBBF24',
          fats:     '#F87171',
          sugars:   '#C084FC',
        },
        status: {
          success:     '#22C55E',
          success_dim: '#14532D',
          warning:     '#F59E0B',
          warning_dim: '#78350F',
          danger:      '#EF4444',
          danger_dim:  '#450A0A',
          info:        '#3B82F6',
          info_dim:    '#1E3A5F',
        },
      },
    },
  },
  safelist: [
    // wellbeing_rating_controller.js — dynamic class strings not statically analysable
    // active state
    'bg-amber-400/70', 'border-amber-400/90', 'text-amber-300',
    'bg-green-500/65', 'border-green-500/85', 'text-green-300',
    'bg-blue-500/65',  'border-blue-500/85',  'text-blue-300',
    // filled state
    'bg-amber-400/25', 'border-amber-400/35', 'text-amber-400/60',
    'bg-green-500/20', 'border-green-500/30', 'text-green-400/60',
    'bg-blue-500/20',  'border-blue-500/30',  'text-blue-400/60',
    // empty state
    'bg-surface-hover/30', 'border-surface-border/30', 'text-ink-subtle/30',
    // FoodLabel::COLOR_STYLES — defined in app/models/food_label.rb (not scanned by Tailwind)
    'bg-red-500/20',    'text-red-400',    'border-red-500/30',    'bg-red-400',
    'bg-orange-500/20', 'text-orange-400', 'border-orange-500/30', 'bg-orange-400',
    'bg-amber-400/20',  'text-amber-400',  'border-amber-400/30',  'bg-amber-400',
    'bg-yellow-400/20', 'text-yellow-400', 'border-yellow-400/30', 'bg-yellow-400',
    'bg-green-500/20',  'text-green-400',  'border-green-500/30',  'bg-green-400',
    'bg-teal-500/20',   'text-teal-400',   'border-teal-500/30',   'bg-teal-400',
    'bg-blue-500/20',   'text-blue-400',   'border-blue-500/30',   'bg-blue-400',
    'bg-violet-500/20', 'text-violet-400', 'border-violet-500/30', 'bg-violet-400',
    // _picker.html.erb — hover state on program day pills (inside ERB tags, not scanned by Tailwind)
    'hover:bg-brand/30', 'hover:border-brand', 'hover:text-ink-primary', 'hover:scale-[1.03]',
  ],
  plugins: [
    // require('@tailwindcss/forms'),
    // require('@tailwindcss/typography'),
    // require('@tailwindcss/container-queries'),
  ]
}
