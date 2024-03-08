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
  
      fontSize: {
        'xs': '.75rem',   
        'sm': '.875rem',
        'base': '1.125rem',
        'lg': '1.4625rem',
        'xl': '2.925rem',
        '2xl': '3.15rem',
      },
  
      fontWeight: {
        light: '300',
        'regular': '400',
        bold: '600',
        extrabold: '800',
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
        themes: ["light", "night"],
    }
  }
  
