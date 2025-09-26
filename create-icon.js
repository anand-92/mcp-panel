const fs = require('fs');
const path = require('path');

// Create a simple SVG icon for the app
const svgIcon = `<?xml version="1.0" encoding="UTF-8"?>
<svg width="512" height="512" viewBox="0 0 512 512" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="gradient" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#667eea;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#764ba2;stop-opacity:1" />
    </linearGradient>
  </defs>
  <rect width="512" height="512" rx="100" fill="url(#gradient)"/>
  <text x="256" y="320" font-family="Arial, sans-serif" font-size="200" font-weight="bold" text-anchor="middle" fill="white">M</text>
</svg>`;

// Save SVG icon
fs.writeFileSync(path.join(__dirname, 'assets', 'icon.svg'), svgIcon);

console.log('Icon created successfully!');
console.log('Note: For production, you should convert this SVG to .icns format for macOS.');
console.log('You can use online tools or the following command if you have ImageMagick:');
console.log('  convert assets/icon.svg -resize 512x512 assets/icon.png');
console.log('  Then use an online converter to create icon.icns from the PNG');