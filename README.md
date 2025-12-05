# Kasparex Hub

A modern landing page for the Kasparex Hub platform, built with React Router (formerly Remix) and deployed on Cloudflare Pages.

## Features

- 🚀 **dApps** - Discover and use decentralized applications
- 🪙 **Tokens** - Explore KRC-20 tokens and assets
- ⚡ **Nodes** - Manage your Krex Nodes

## Tech Stack

- **Framework**: React Router (v7) with Cloudflare Pages adapter
- **Styling**: Tailwind CSS
- **Language**: TypeScript
- **Deployment**: Cloudflare Pages

## Development

### Prerequisites

- Node.js 20+
- npm or pnpm

### Install Dependencies

```bash
npm install
```

### Run Development Server

```bash
npm run dev
```

### Build for Production

```bash
npm run build
```

### Preview Production Build

```bash
npm start
```

## Deployment

This project is configured for deployment on Cloudflare Pages. The build output is automatically deployed when changes are pushed to the main branch.

### Manual Deployment

1. Build the project: `npm run build`
2. Deploy using Wrangler: `wrangler pages deploy ./build/client`

## Project Structure

```
kasparex-hub/
├── app/
│   ├── components/      # React components
│   ├── routes/          # Route handlers
│   └── styles/          # CSS styles
├── public/              # Static assets
└── contracts/           # Smart contracts
```

## License

Copyright © 2024 Kasparex Hub. All rights reserved.


