const defaultTheme = require('tailwindcss/defaultTheme')

module.exports = {
  content: [
    './public/*.html.erb',
    './app/helpers/**/*.rb',
    './app/javascript/**/*.js',
    './app/views/**/*.{erb,haml,html,slim}'
    '.app/assets/sylesheets/**/*.css'
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ['Inter var', ...defaultTheme.fontFamily.sans],
      },
    },
  },
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/typography'),
    require('@tailwindcss/container-queries'),
  ]
}
