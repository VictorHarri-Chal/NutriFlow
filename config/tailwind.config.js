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
        sans: ['Inter var', ...defaultTheme.fontFamily.sans],
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
  plugins: [
    // require('@tailwindcss/forms'),
    // require('@tailwindcss/typography'),
    // require('@tailwindcss/container-queries'),
  ]
}
