/** @type {import('tailwindcss').Config} */
module.exports = {
    content: ["./templates/**/*.html"],
    theme: {
      extend: {},
      fontFamily: {
        sans: [
          'Cantarell',
          'Source Sans Pro',
          'Droid Sans',
          'Ubuntu',
          'DejaVu Sans',
          'Arial',
          'sans-serif',
        ],
        mono: [
          'Monaco',
          'monospace',
          'Menlo',
        ],
      },
  
      borderWidth: {
        DEFAULT: '1px',
        '0': '0',
        '2': '2px',
        '3': '3px',
        '4': '4px',
        '8': '8px',
      },  
    },
    plugins: [
        require('@tailwindcss/typography'),
        require("daisyui")
    ],
    daisyui: {
        themes: ["light", "dim"],
    }
  }
  
