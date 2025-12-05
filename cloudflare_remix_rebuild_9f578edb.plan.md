---
name: Cloudflare Remix Rebuild
overview: Complete rebuild of Kasparex Hub on Remix + Cloudflare with mobile-first responsive design, Hub page as homepage, subdomain architecture, fresh Kaspa wallet integration (Kasware + Kastle), Krex Nodes system, and full SEO optimization.
todos: []
---

# Complete Rebuild: Kasparex Hub on Remix + Cloudflare

## Project Details

- **Project Name**: Kasparex Hub
- **Local Folder**: `kasparex-hub/` (new base folder)
- **GitHub Repository**: `Kasparex Hub`
- **Main Homepage**: Kasparex Hub page**** 

## Framework: Remix on Cloudflare Pages

**Why Remix:**

- Native Cloudflare adapter (official support)
- No static export issues
- Full React support (RainbowKit + Wagmi for EVM, custom Kaspa wallets)
- Built-in data loading patterns
- File-based routing
- SSR + Static generation support
- Edge-optimized performance

## Cost Analysis

### Remix on Cloudflare Pages

- **Bandwidth**: Unlimited (FREE) ✅
- **Builds**: Unlimited (FREE) ✅
- **Edge Network**: 300+ locations (FREE) ✅
- **Total Frontend Cost**: **$0/month**

### Cloudflare Workers (Kasparex API)

- **Free Tier**: 100,000 requests/day (3M/month) - FREE
- **Paid Tier**: $5/month for 10M requests
- **KV Storage**: $0.50 per 1M reads
- **D1 Database**: $0.001 per 1M reads
- **R2 Storage**: $0.015 per GB stored
- **Estimated Cost**: **$5-10/month**

### Total Cost Comparison

- **Vercel**: $150-500/month
- **Cloudflare + Remix**: **$5-10/month**
- **Savings**: **95-98% cost reduction** 🎯

## Project Structure

```
kasparex-hub/
├── app/
│   ├── routes/
│   │   ├── _index.tsx           # Hub page (main homepage)
│   │   ├── dapps.$slug.tsx       # dApp detail
│   │   ├── vblog.$slug.tsx       # Blog article
│   │   └── ...
│   ├── components/
│   │   ├── layout/
│   │   │   ├── Header.tsx        # Logo left, menu icon right
│   │   │   ├── MobileMenu.tsx     # Mobile menu with wallet buttons
│   │   │   ├── Sidebar.tsx        # Collapsible sidebar (chevron toggle)
│   │   │   └── Footer.tsx
│   │   ├── wallets/
│   │   │   ├── KaspaWalletModal.tsx  # RainbowKit-style modal
│   │   │   ├── KaswareButton.tsx      # Kasware integration
│   │   │   ├── KastleButton.tsx       # Kastle integration
│   │   │   └── EVMWalletButton.tsx    # EVM wallets (RainbowKit)
│   │   ├── modals/               # All modals (mobile-responsive)
│   │   └── ...                   # All other components
│   ├── lib/
│   │   ├── wagmi.ts              # EVM network configs
│   │   ├── kaspa/                # Kaspa wallet integration (NEW)
│   │   │   ├── kasware.ts        # Kasware wallet (fresh implementation)
│   │   │   ├── kastle.ts         # Kastle wallet (fresh implementation)
│   │   │   ├── provider.tsx      # Kaspa wallet provider
│   │   │   └── hooks.ts          # useKaspaWallet hook
│   │   ├── storage/
│   │   │   ├── decentralized.ts  # Asset resolver with Krex Nodes
│   │   │   └── krex-nodes.ts     # Krex Node discovery
│   │   ├── contracts/           # OpenZeppelin contracts integration
│   │   ├── config/
│   │   │   └── domains.ts         # Subdomain configuration
│   │   └── ipfs/
│   ├── styles/
│   │   └── globals.css           # Mobile-first responsive styles
│   └── root.tsx
├── contracts/
│   ├── @openzeppelin/           # OpenZeppelin contracts
│   └── ...                      # All ecosystem contracts
├── workers/
│   ├── index.ts
│   ├── kasparex-api/            # Kasparex API (not Prime API)
│   │   ├── nodes.ts              # Krex Node management
│   │   ├── rewards.ts            # Reward engine
│   │   └── public.ts
│   └── api/
├── public/
├── wrangler.toml
└── package.json
```

## Implementation Phases

### Phase 1: Core Setup & Mobile-First Foundation

1. **Initialize Remix Project**

   - Use `create-remix` with Cloudflare template
   - Configure TypeScript, Tailwind CSS
   - Set up mobile-first responsive design system

2. **Mobile-First CSS Framework**

   - Responsive breakpoints: mobile (< 640px), tablet (640-1024px), desktop (> 1024px)
   - All modals: `max-height: 100vh`, `overflow-y: auto`, fit within viewport
   - Compact UI: proper spacing, stacking on mobile
   - No horizontal overflow: `overflow-x: hidden` on body
   - Touch-friendly: minimum 44x44px touch targets

3. **Cloudflare Configuration**

   - Configure `wrangler.toml` for Pages + Workers
   - Set up KV namespaces for caching
   - Configure D1 database for Kasparex API
   - Set up R2 buckets for asset backup storage

4. **Subdomain Configuration**

   - Set up subdomain structure:
     - `hub.kasparex.com` - Main Hub (homepage)
     - `dapps.kasparex.com` - dApp marketplace
     - `tokens.kasparex.com` - Token directory
     - `api.kasparex.com` - Kasparex API (Workers)
     - `nodes.kasparex.com` - Krex Node dashboard
     - `docs.kasparex.com` - Documentation
   - Create `app/lib/config/domains.ts` with subdomain utilities

### Phase 2: Layout Components (Mobile-First)

1. **Header Component** (`app/components/layout/Header.tsx`)

   - **Left side**: Logo + "Kasparex Hub" title
   - **Right side**: Menu icon (hamburger) button
   - Mobile-responsive: stacks on small screens
   - Sticky header: `position: sticky, top: 0`

2. **Mobile Menu** (`app/components/layout/MobileMenu.tsx`)

   - Opens from right side (slide-in drawer)
   - Contains:
     - Wallet connect buttons (Kasware, Kastle, EVM)
     - Navigation links
     - User profile (if connected)
     - Settings
   - Full viewport height, scrollable content
   - Close button (X icon) in top-right
   - Backdrop overlay (click to close)

3. **Sidebar Component** (`app/components/layout/Sidebar.tsx`)

   - Collapsible with chevron icon toggle
   - Smooth animation (slide in/out)
   - Mobile: overlay mode (full height, backdrop)
   - Desktop: fixed position, collapsible width
   - Chevron icon rotates on toggle

4. **Modal System** (`app/components/modals/`)

   - All modals:
     - `max-width: 95vw` on mobile
     - `max-height: 90vh` with `overflow-y: auto`
     - Centered with backdrop
     - Close button always visible
     - Touch-friendly controls
   - Responsive padding: `p-4 sm:p-6 lg:p-8`

### Phase 3: Kaspa Wallet Integration (Fresh Implementation)

1. **Kasware Wallet Integration** (`app/lib/kaspa/kasware.ts`)

   - Fresh implementation from scratch
   - Detect Kasware extension
   - Connect/disconnect functionality
   - Get address, balance, network
   - Sign messages, send transactions
   - KRC-20 token support
   - Event listeners (accountsChanged, etc.)

2. **Kastle Wallet Integration** (`app/lib/kaspa/kastle.ts`)

   - Fresh implementation from scratch
   - Detect Kastle extension
   - Connect/disconnect functionality
   - Get address, balance, network
   - Sign messages, send transactions
   - Event listeners

3. **Kaspa Wallet Provider** (`app/lib/kaspa/provider.tsx`)

   - React context provider
   - Manages connection state
   - Supports both Kasware and Kastle
   - Unified API for both wallets

4. **Kaspa Wallet Hooks** (`app/lib/kaspa/hooks.ts`)

   - `useKaspaWallet()` - Main hook
   - `useKaspaBalance()` - Balance hook
   - `useKaspaNetwork()` - Network hook

5. **Kaspa Wallet Modal** (`app/components/wallets/KaspaWalletModal.tsx`)

   - RainbowKit-style design
   - Shows Kasware and Kastle options
   - Wallet icons and names
   - "Install" button if wallet not detected
   - Smooth animations
   - Mobile-responsive (fits viewport)

6. **Wallet Buttons**

   - `KaswareButton.tsx` - Kasware connect button
   - `KastleButton.tsx` - Kastle connect button
   - Both in mobile menu and header

### Phase 4: EVM Wallet Integration

1. **RainbowKit + Wagmi Setup**

   - Copy `src/lib/wagmi.ts` → `app/lib/wagmi.ts`
   - Configure chains:
     - Kasplex L2 Mainnet (202555)
     - Kasplex L2 Testnet (167012)
     - Igra Caravel Testnet (19416)
   - Preserve vProgs placeholder chains

2. **EVM Wallet Button**

   - `EVMWalletButton.tsx` - RainbowKit connect button
   - Included in mobile menu

### Phase 5: Hub Page as Homepage

1. **Homepage Route** (`app/routes/_index.tsx`)

   - Hub page content (copy from `src/app/hub/page.tsx`)
   - Hero section
   - Projects grid
   - Ecosystem overview
   - Features section
   - Benefits and rewards
   - Fully responsive, mobile-optimized

2. **Subdomain Routing**

   - Detect current subdomain
   - Route to appropriate section
   - Cross-subdomain navigation utilities

### Phase 6: Smart Contracts (OpenZeppelin)

1. **OpenZeppelin Integration**

   - Install `@openzeppelin/contracts`
   - Use OpenZeppelin base contracts:
     - `Ownable`, `AccessControl`, `ReentrancyGuard`
     - `ERC20`, `ERC721`, `ERC1155`
     - `SafeMath`, `SafeERC20`
   - All contracts inherit from OpenZeppelin

2. **Contract System**

   - Copy `contracts/` directory
   - Update all contracts to use OpenZeppelin
   - Copy `hardhat.config.js` (same networks)
   - Copy deployment scripts
   - Copy `src/lib/contracts/` → `app/lib/contracts/`

3. **vProgs Preparation**

   - Copy `src/lib/vprogs/` → `app/lib/vprogs/`
   - Preserve placeholder chain configurations

### Phase 7: Kasparex API (Cloudflare Workers) - **BUILT FROM DAY ONE**

1. **Kasparex API Core** (`workers/kasparex-api/nodes.ts`)

   - `POST /kasparex/node/register` - Node registration
   - `POST /kasparex/node/ping` - Heartbeat (every 60s)
   - `GET /kasparex/nodes` - List all active nodes
   - `GET /kasparex/node/:id` - Node details
   - `GET /kasparex/nodes/pinned/:cid` - Find nodes with specific CID
   - Region-based node clustering
   - Uptime tracking in D1 database

2. **Reward Engine** (`workers/kasparex-api/rewards.ts`)

   - GRT (Global Reward Token) calculation
   - LRT (Local Reward Token per dApp) calculation
   - KREX multiplier tiers
   - Region multipliers (underserved regions get 1.2x)
   - **Node-tier multipliers**:
     - Light Node: **2x multiplier**
     - Mirror Node: **3x multiplier**
     - Super Node: **5x multiplier**
   - Daily epoch calculations
   - `GET /kasparex/rewards/:nodeId` - Node reward information
   - Reward storage in D1 database

3. **Public Data Endpoints** (`workers/kasparex-api/public.ts`)

   - `GET /kasparex/nodes` - List all active nodes
   - `GET /kasparex/node/:id` - Node details
   - `GET /kasparex/dapps/availability` - dApp mirror availability
   - `GET /kasparex/stats` - Network statistics

4. **D1 Database Schema** (for Kasparex API)
   ```sql
   -- Nodes table
   CREATE TABLE nodes (
     node_id TEXT PRIMARY KEY,
     node_name TEXT,
     role TEXT, -- 'light' | 'mirror' | 'super'
     owner_wallet TEXT,
     region TEXT,
     version TEXT,
     url TEXT,
     last_ping INTEGER,
     uptime_hours REAL,
     pinned_cids TEXT, -- JSON array
     created_at INTEGER
   );
   
   -- Node pings table
   CREATE TABLE node_pings (
     id INTEGER PRIMARY KEY AUTOINCREMENT,
     node_id TEXT,
     timestamp INTEGER,
     status TEXT,
     FOREIGN KEY (node_id) REFERENCES nodes(node_id)
   );
   
   -- Rewards table
   CREATE TABLE rewards (
     id INTEGER PRIMARY KEY AUTOINCREMENT,
     node_id TEXT,
     epoch_date TEXT,
     grt_amount REAL,
     lrt_amount REAL,
     krex_multiplier REAL,
     region_multiplier REAL,
     role_multiplier REAL, -- 2.0, 3.0, or 5.0
     total_reward REAL,
     FOREIGN KEY (node_id) REFERENCES nodes(node_id)
   );
   ```


### Phase 8: Krex Nodes Asset Resolver - **BUILT FROM DAY ONE**

1. **Enhanced Asset Resolver** (`app/lib/storage/decentralized.ts`)

   - Priority order (cost-optimized):

     1. **Krex Nodes** (nearest region) - FREE, community-powered
     2. **Storacha** - FREE tier
     3. **IPFS/Pinata** - $20/month (paid gateway)
     4. **Public IPFS Gateway** - FREE (slower)
     5. **Cloudflare R2** - $0.015/GB (backup storage)
     6. **Cloudflare Pages** - FREE (last resort)

2. **Krex Node Discovery** (`app/lib/storage/krex-nodes.ts`)
   ```typescript
   export async function getKrexNodeUrls(cid: string, region?: string): Promise<string[]> {
     // Fetch from Kasparex API
     const response = await fetch(
       `${KASPAREX_API_URL}/kasparex/nodes/pinned/${cid}?region=${region || 'auto'}`
     );
     const nodes = await response.json();
     
     // Sort by: region match → uptime → proximity
     return nodes
       .filter(node => node.pinnedCids.includes(cid))
       .sort((a, b) => {
         if (a.region === region && b.region !== region) return -1;
         if (b.region === region && a.region !== region) return 1;
         return b.uptime - a.uptime;
       })
       .map(node => `${node.url}/ipfs/${cid}`);
   }
   ```


### Phase 9: Component Migration (Mobile-First)

1. **Core Components** (preserve styling, make responsive)

   - Header, Footer, Sidebar (with chevron toggle)
   - DAppCard, DAppGrid, DAppDetail
   - All dApp widgets (mobile-responsive)
   - Admin components
   - User profile components
   - vBlog components
   - Rewards components

2. **Page Routes** (convert Next.js → Remix)

   - `/` → `app/routes/_index.tsx` (Hub page)
   - `/dapps/[slug] `→ `app/routes/dapps.$slug.tsx`
   - `/vblog/[slug] `→ `app/routes/vblog.$slug.tsx`
   - `/user/[walletAddress] `→ `app/routes/user.$walletAddress.tsx`
   - All other pages converted similarly

### Phase 10: SEO Optimization

1. **Meta Tags** (in `app/root.tsx`)

   - Title, description, keywords
   - Open Graph tags
   - Twitter Card tags
   - Canonical URLs

2. **Structured Data** (JSON-LD)

   - Organization schema
   - Website schema
   - Breadcrumb schema
   - Article schema (for vBlog)

3. **Image Optimization**

   - All images: `alt` attributes (descriptive)
   - Lazy loading: `loading="lazy"`
   - Responsive images: `srcset` and `sizes`
   - Decentralized images: proper fallbacks

4. **Accessibility**

   - Semantic HTML: `<nav>`, `<main>`, `<article>`, etc.
   - ARIA labels where needed
   - Keyboard navigation support
   - Focus management in modals

5. **Performance**

   - Preload critical resources
   - Optimize fonts (subset, display: swap)
   - Minimize JavaScript bundles
   - Code splitting per route

6. **Sitemap & Robots.txt**

   - Generate sitemap.xml
   - robots.txt configuration
   - Subdomain-specific sitemaps

## Mobile-First Design Principles

1. **Viewport Management**

   - All modals: `max-height: 90vh`, `overflow-y: auto`
   - No horizontal scrolling: `overflow-x: hidden`
   - Touch targets: minimum 44x44px

2. **Responsive Layout**

   - Mobile: single column, stacked elements
   - Tablet: 2 columns where appropriate
   - Desktop: multi-column layouts
   - Flexible grids: `grid-cols-1 md:grid-cols-2 lg:grid-cols-3`

3. **Typography**

   - Mobile: base 16px, readable line-height
   - Responsive font sizes: `text-sm sm:text-base lg:text-lg`
   - Proper heading hierarchy

4. **Navigation**

   - Mobile: hamburger menu
   - Desktop: horizontal navigation
   - Sidebars: collapsible with chevron

## Migration Checklist

- [ ] Initialize Remix project with Cloudflare template
- [ ] Set up mobile-first responsive design system
- [ ] Create Header with logo left, menu icon right
- [ ] Create mobile menu with wallet buttons
- [ ] Create collapsible sidebar with chevron toggle
- [ ] Implement Kasware wallet integration (fresh)
- [ ] Implement Kastle wallet integration (fresh)
- [ ] Create Kaspa wallet modal (RainbowKit-style)
- [ ] Set up Hub page as homepage
- [ ] Configure subdomain structure
- [ ] Set up Cloudflare resources (KV, D1, R2)
- [ ] Create D1 database schema for Kasparex API
- [ ] Implement Kasparex API core (Krex Node management)
- [ ] Implement Reward Engine (Light 2x, Mirror 3x, Super 5x)
- [ ] Implement Krex Node discovery in asset resolver
- [ ] Migrate EVM wallet configuration (Wagmi + RainbowKit)
- [ ] Integrate OpenZeppelin contracts
- [ ] Migrate all components (make mobile-responsive)
- [ ] Convert all pages to Remix routes
- [ ] Add SEO meta tags and structured data
- [ ] Add alt attributes to all images
- [ ] Test all modals fit viewport on mobile
- [ ] Test locally with Wrangler
- [ ] Deploy to Cloudflare Pages
- [ ] Deploy Kasparex API Workers
- [ ] Configure subdomains in DNS
- [ ] Verify all features work
- [ ] Update documentation