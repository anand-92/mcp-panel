const path = require('path');

module.exports = {
  content: [
    path.resolve(__dirname, 'index.html'),
    path.resolve(__dirname, 'src/**/*.{js,jsx,ts,tsx}')
  ],
  theme: {
    extend: {
      colors: {
        brand: {
          DEFAULT: '#1d9bf0',
          muted: '#0f172a'
        }
      }
    }
  },
  plugins: []
};
