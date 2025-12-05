# Assets Directory

This directory contains all graphic assets for the Kasparex dApp Marketplace.

## Structure

```
public/img/
├── dapps/      # Featured images for dApps (16:9 aspect ratio)
├── icons/      # SVG icon files for UI elements
├── logos/      # Logo files for networks, developers, and brands
└── tokens/     # Token logo files (for future use)
```

## Adding Network Logos

Network logos should be placed in the `logos/` directory and referenced in the Sidebar component.

### Supported Formats
- PNG (with transparent background, minimum 32x32px, default format)
- SVG (alternative format for scalability)

### Current Network Logo Paths
- Kasplex L2: `/img/logos/kasplex.png`
- Igra L2: `/img/logos/igra.png`

### Adding New Network Logos

1. Place the logo file in `public/img/logos/`
2. Update the `networkOptions` array in `src/components/Sidebar.tsx` to include the logo path

Example:
```typescript
{ label: 'Network Name', logo: '/img/logos/network-name.png' }
```

## Adding Developer Logos

Developer logos should be placed in the `logos/` directory and will display next to developer names in the Developer filter section.

### Supported Formats
- PNG (with transparent background, minimum 32x32px, default format)
- SVG (alternative format for scalability)

### Current Developer Logo Paths
- Kasparex: `/img/logos/kasparex.png`
- KaspaCom: `/img/logos/kaspacom.png`
- KasTools: `/img/logos/kastools.png`
- Kasplex: `/img/logos/kasplex.png`

### Adding New Developer Logos

1. Place the logo file in `public/img/logos/`
2. Update the `developerOptions` array in `src/components/Sidebar.tsx` to include the logo path

Example:
```typescript
{ label: 'Developer Name', logo: '/img/logos/developer-name.png' }
```

## Adding Token Logos

Token logos can be placed in the `tokens/` directory for future use.

### Supported Formats
- PNG (with transparent background, minimum 32x32px, default format)
- SVG (alternative format for scalability)

### Token Logo Structure

Token logos should be named using the token's contract address or ticker symbol:
- By contract address: `/img/tokens/{contract-address}.png`
- By ticker symbol: `/img/tokens/{ticker-symbol}.png`

### Future Integration

When token integration is implemented:
1. Place token logo files in `public/img/tokens/`
2. Reference logos in the token data structure or token display components

Example path:
```
/img/tokens/krex.png
/img/tokens/0x1234...abcd.png
```

## Adding dApp Featured Images

Featured images should be placed in the `dapps/` directory and will be displayed in the sidebar of each dApp page.

### Supported Formats
- PNG (recommended for photos)
- JPG/JPEG (for compressed images)
- WebP (for optimized web images)

### Image Specifications
- **Aspect Ratio**: 16:9 (recommended)
- **Minimum Size**: 800x450px
- **Maximum Size**: 1920x1080px
- **File Naming**: Use the dApp slug (e.g., `subscription-checker.png`)

### Adding Featured Images

1. Create or obtain a 16:9 featured image for the dApp
2. Place the image file in `public/img/dapps/` with a filename matching the dApp slug
3. Update the dApp data in `src/lib/dapps.ts` to include the `featuredImage` field:

Example:
```typescript
{
  id: '1',
  name: 'Subscription Checker',
  slug: 'subscription-checker',
  featuredImage: '/img/dapps/subscription-checker.png',
  // ... other fields
}
```

### Default Placeholder

If a dApp doesn't have a featured image, a placeholder icon will be displayed automatically in the sidebar.

## Icon Guidelines

- Icons should be single-color outlines
- Use consistent stroke width (2px recommended)
- Maintain 24x24 viewBox for consistency
- Icons should work in both light and dark themes

