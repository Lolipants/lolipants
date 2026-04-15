# Lolipants — Backend Infrastructure Setup Guide

This document covers the complete setup of every backend service the Lolipants app depends on. Work through each section in order. By the end you will have all four environment variables populated and ready to drop into your `.env` file.

```env
BETTER_AUTH_BASE_URL=https://your-better-auth-instance.com
CLOUDFLARE_API_BASE=https://your-cloudflare-worker.com/api
API_BASE_URL=https://your-cloudflare-worker.com/api
CLOUDFLARE_R2_BASE_URL=https://your-r2-bucket.com
```

---

## Prerequisites

Install the following tools before starting. Run all commands in a terminal.

```bash
# Node.js (v18 or later)
node --version   # must be 18+

# Wrangler CLI (Cloudflare's dev and deployment tool)
npm install -g wrangler
wrangler --version

# Bun (used by Better Auth)
curl -fsSL https://bun.sh/install | bash
bun --version
```

You also need:
- A **Cloudflare account** — free tier is sufficient to start. Sign up at https://dash.cloudflare.com
- A **domain name** (optional for development, required for production) — any `.com` domain works

---

---

# PART 1 — Cloudflare Account & CLI Login

---

## 1.1 Log In to Cloudflare via Wrangler

```bash
wrangler login
```

This opens a browser window. Log in with your Cloudflare account. When the terminal shows `Successfully logged in`, continue.

Verify your account is connected:

```bash
wrangler whoami
```

You should see your account name and account ID. Copy the **Account ID** — you will need it shortly.

---

## 1.2 Create the Project Folder

All Cloudflare backend code lives in a separate repository from the Flutter app.

```bash
mkdir lolipants-backend
cd lolipants-backend
npm init -y
```

---

---

# PART 2 — Cloudflare D1 Database

D1 is Cloudflare's serverless SQLite-compatible database. All app data (users, designs, orders, etc.) is stored here.

---

## 2.1 Create the D1 Database

```bash
wrangler d1 create lolipants-db
```

The output will look like this:

```
✅ Successfully created DB 'lolipants-db'

[[d1_databases]]
binding = "DB"
database_name = "lolipants-db"
database_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
```

Copy the `database_id` value. You will add it to `wrangler.toml` in a moment.

---

## 2.2 Create the Database Schema

Create a file `schema.sql` in your `lolipants-backend` folder:

```sql
-- schema.sql

-- Users (managed by Better Auth, extended here)
CREATE TABLE IF NOT EXISTS users (
  id              TEXT PRIMARY KEY,
  name            TEXT NOT NULL,
  email           TEXT NOT NULL UNIQUE,
  role            TEXT NOT NULL DEFAULT 'user', -- 'user' | 'tailor' | 'admin' | 'designer'
  avatar_url      TEXT,
  bio             TEXT,
  follower_count  INTEGER DEFAULT 0,
  created_at      TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at      TEXT NOT NULL DEFAULT (datetime('now'))
);

-- Mannequin options
-- Reminder: manage these records from the admin dashboard; app clients should fetch from API.
CREATE TABLE IF NOT EXISTS mannequin_options (
  id              TEXT PRIMARY KEY,
  label_en        TEXT NOT NULL,
  label_ar        TEXT NOT NULL,
  is_active       INTEGER NOT NULL DEFAULT 1,
  sort_order      INTEGER NOT NULL DEFAULT 0,
  created_at      TEXT NOT NULL DEFAULT (datetime('now'))
);

-- Body measurements
CREATE TABLE IF NOT EXISTS measurements (
  id              TEXT PRIMARY KEY,
  user_id         TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  chest           REAL,
  waist           REAL,
  hips            REAL,
  shoulder_width  REAL,
  height          REAL,
  arm_length      REAL,
  preferred_size  TEXT,
  saved_at        TEXT NOT NULL DEFAULT (datetime('now'))
);

-- Garment designs
CREATE TABLE IF NOT EXISTS designs (
  id              TEXT PRIMARY KEY,
  user_id         TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name            TEXT NOT NULL,
  garment_type    TEXT NOT NULL,
  fabric_id       TEXT,
  fabric_quality  TEXT NOT NULL DEFAULT 'standard',
  primary_colour  TEXT NOT NULL,
  accent_colour   TEXT,
  pattern_id      TEXT,
  print_image_url TEXT,
  preset_style_id TEXT,
  text_layers     TEXT,             -- JSON array of DesignTextLayer
  is_public       INTEGER DEFAULT 0, -- 1 = shown in showcase
  order_count     INTEGER DEFAULT 0,
  created_at      TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at      TEXT NOT NULL DEFAULT (datetime('now'))
);

-- Fabric options (managed via admin panel)
CREATE TABLE IF NOT EXISTS fabric_options (
  id              TEXT PRIMARY KEY,
  name            TEXT NOT NULL,
  name_ar         TEXT NOT NULL,
  quality         TEXT NOT NULL,    -- 'standard' | 'premium' | 'suit_grade'
  garment_type    TEXT NOT NULL,
  is_available    INTEGER DEFAULT 1,
  created_at      TEXT NOT NULL DEFAULT (datetime('now'))
);

-- Preset designs / patterns (managed via admin panel)
CREATE TABLE IF NOT EXISTS presets (
  id              TEXT PRIMARY KEY,
  type            TEXT NOT NULL,    -- 'pattern' | 'embroidery' | 'style'
  name            TEXT NOT NULL,
  name_ar         TEXT NOT NULL,
  garment_type    TEXT,             -- null = applies to all
  image_url       TEXT,
  is_active       INTEGER DEFAULT 1,
  created_at      TEXT NOT NULL DEFAULT (datetime('now'))
);

-- Orders
CREATE TABLE IF NOT EXISTS orders (
  id              TEXT PRIMARY KEY,
  user_id         TEXT NOT NULL REFERENCES users(id),
  design_id       TEXT NOT NULL REFERENCES designs(id),
  designer_id     TEXT REFERENCES users(id),  -- showcase commission recipient
  tailor_id       TEXT REFERENCES users(id),
  status          TEXT NOT NULL DEFAULT 'placed',
  delivery_address TEXT NOT NULL,
  delivery_city   TEXT NOT NULL,
  delivery_phone  TEXT NOT NULL,
  delivery_notes  TEXT,
  base_price      REAL NOT NULL,
  fabric_fee      REAL NOT NULL DEFAULT 0,
  delivery_fee    REAL NOT NULL DEFAULT 0,
  total_price     REAL NOT NULL,
  payment_token   TEXT,
  estimated_delivery TEXT,
  placed_at       TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at      TEXT NOT NULL DEFAULT (datetime('now'))
);

-- Order status history
CREATE TABLE IF NOT EXISTS order_status_history (
  id              TEXT PRIMARY KEY,
  order_id        TEXT NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  status          TEXT NOT NULL,
  note            TEXT,
  updated_by      TEXT REFERENCES users(id),
  timestamp       TEXT NOT NULL DEFAULT (datetime('now'))
);

-- Community posts
CREATE TABLE IF NOT EXISTS posts (
  id              TEXT PRIMARY KEY,
  author_id       TEXT NOT NULL REFERENCES users(id),
  body            TEXT NOT NULL,
  image_urls      TEXT,             -- JSON array of R2 URLs
  tags            TEXT,             -- JSON array of tag strings
  reaction_count  INTEGER DEFAULT 0,
  comment_count   INTEGER DEFAULT 0,
  posted_at       TEXT NOT NULL DEFAULT (datetime('now'))
);

-- Post reactions
CREATE TABLE IF NOT EXISTS post_reactions (
  id              TEXT PRIMARY KEY,
  post_id         TEXT NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  user_id         TEXT NOT NULL REFERENCES users(id),
  reaction_type   TEXT NOT NULL,   -- 'love' | 'fire' | 'clap' | 'wow'
  created_at      TEXT NOT NULL DEFAULT (datetime('now')),
  UNIQUE(post_id, user_id)
);

-- Post comments
CREATE TABLE IF NOT EXISTS post_comments (
  id              TEXT PRIMARY KEY,
  post_id         TEXT NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  author_id       TEXT NOT NULL REFERENCES users(id),
  body            TEXT NOT NULL,
  created_at      TEXT NOT NULL DEFAULT (datetime('now'))
);

-- Follows
CREATE TABLE IF NOT EXISTS follows (
  follower_id     TEXT NOT NULL REFERENCES users(id),
  following_id    TEXT NOT NULL REFERENCES users(id),
  created_at      TEXT NOT NULL DEFAULT (datetime('now')),
  PRIMARY KEY(follower_id, following_id)
);

-- Consultations
CREATE TABLE IF NOT EXISTS consultations (
  id              TEXT PRIMARY KEY,
  user_id         TEXT NOT NULL REFERENCES users(id),
  designer_id     TEXT REFERENCES users(id),
  garment_type    TEXT NOT NULL,
  description     TEXT NOT NULL,
  budget_min      REAL,
  budget_max      REAL,
  status          TEXT NOT NULL DEFAULT 'open', -- 'open' | 'in_progress' | 'closed'
  created_at      TEXT NOT NULL DEFAULT (datetime('now'))
);

-- Workshop bookings
CREATE TABLE IF NOT EXISTS bookings (
  id              TEXT PRIMARY KEY,
  user_id         TEXT NOT NULL REFERENCES users(id),
  type            TEXT NOT NULL,   -- 'workshop_visit' | 'home_visit'
  address         TEXT,
  city            TEXT,
  date            TEXT NOT NULL,
  time_slot       TEXT NOT NULL,   -- 'morning' | 'afternoon' | 'evening'
  reference       TEXT NOT NULL UNIQUE,
  status          TEXT NOT NULL DEFAULT 'pending',
  created_at      TEXT NOT NULL DEFAULT (datetime('now'))
);

-- Push tokens
CREATE TABLE IF NOT EXISTS push_tokens (
  user_id         TEXT NOT NULL REFERENCES users(id),
  onesignal_id    TEXT NOT NULL,
  updated_at      TEXT NOT NULL DEFAULT (datetime('now')),
  PRIMARY KEY(user_id)
);
```

Apply the schema to your D1 database:

```bash
# Apply to local dev database
wrangler d1 execute lolipants-db --local --file=./schema.sql

# Apply to remote (production) database
wrangler d1 execute lolipants-db --remote --file=./schema.sql
```

Both commands should output `Executed X statement(s)` with no errors.

---

## 2.3 Seed Fabric Options

Create `seed.sql` for initial fabric data:

```sql
-- seed.sql
INSERT INTO fabric_options (id, name, name_ar, quality, garment_type) VALUES
  ('f1',  'Silk',    'حرير',      'premium',    'abaya'),
  ('f2',  'Linen',   'كتان',      'standard',   'abaya'),
  ('f3',  'Chiffon', 'شيفون',     'standard',   'abaya'),
  ('f4',  'Crepe',   'كريب',      'premium',    'abaya'),
  ('f5',  'Cotton',  'قطن',       'standard',   'thobe'),
  ('f6',  'Linen',   'كتان',      'standard',   'thobe'),
  ('f7',  'Silk',    'حرير',      'premium',    'thobe'),
  ('f8',  'Wool',    'صوف',       'suit_grade', 'suit'),
  ('f9',  'Cashmere','كشمير',     'suit_grade', 'suit'),
  ('f10', 'Cotton',  'قطن',       'standard',   'kandura'),
  ('f11', 'Silk',    'حرير',      'premium',    'kandura'),
  ('f12', 'Linen',   'كتان',      'standard',   'bisht'),
  ('f13', 'Wool',    'صوف',       'premium',    'bisht'),
  ('f14', 'Satin',   'ساتان',     'premium',    'dress'),
  ('f15', 'Tulle',   'تول',       'standard',   'dress'),
  ('f16', 'Organza', 'أورجانزا',  'premium',    'dress');

INSERT INTO presets (id, type, name, name_ar, garment_type) VALUES
  ('p1', 'pattern',    'Geometric',   'هندسي',          NULL),
  ('p2', 'pattern',    'Stripe',      'خطوط',           NULL),
  ('p3', 'pattern',    'Plain',       'سادة',           NULL),
  ('p4', 'pattern',    'Arabesque',   'عربيسك',         NULL),
  ('p5', 'pattern',    'Floral',      'زهري',           NULL),
  ('p6', 'embroidery', 'Gold collar', 'طوق ذهبي',       NULL),
  ('p7', 'embroidery', 'Hem border',  'حاشية مطرزة',    NULL),
  ('p8', 'embroidery', 'Chest motif', 'زخرفة الصدر',    NULL),
  ('p9', 'embroidery', 'Cuff band',   'شريط الكم',      NULL);
```

```bash
wrangler d1 execute lolipants-db --local --file=./seed.sql
wrangler d1 execute lolipants-db --remote --file=./seed.sql
```

---

---

# PART 3 — Cloudflare R2 Storage

R2 stores all user-uploaded images: design print images, post images, avatar photos, and audio tracks for the music player.

---

## 3.1 Create the R2 Bucket

```bash
wrangler r2 bucket create lolipants-media
```

Output confirms: `Created bucket 'lolipants-media'`

---

## 3.2 Configure Public Access

By default R2 buckets are private. To serve images publicly (needed for displaying them in the app):

1. Go to https://dash.cloudflare.com
2. Select your account → **R2 Object Storage** → **lolipants-media**
3. Click **Settings** tab
4. Under **Public access** → click **Allow Access**
5. Copy the **Public bucket URL** — it will look like:
   `https://pub-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.r2.dev`

This is your `CLOUDFLARE_R2_BASE_URL`. Save it.

> **For production:** use a custom domain instead of the `.r2.dev` URL. In R2 bucket settings → **Custom Domains** → add `media.lolipants.com` (or similar). This requires your domain to be on Cloudflare DNS.

---

## 3.3 CORS Configuration

The Worker will handle uploads server-side, so CORS on the bucket itself is not strictly required. But add it for safety:

```bash
wrangler r2 bucket cors put lolipants-media --rules '[
  {
    "AllowedOrigins": ["*"],
    "AllowedMethods": ["GET"],
    "AllowedHeaders": ["*"],
    "MaxAgeSeconds": 3600
  }
]'
```

GET is public (for reading images). Write operations go through the Worker only — never directly from the Flutter app.

---

---

# PART 4 — Cloudflare Worker (API)

The Worker is your API server. It handles all app requests, proxies to OpenAI and Tap Payments, manages R2 uploads, and talks to D1. It runs at the edge — no traditional server needed.

---

## 4.1 Initialise the Worker Project

```bash
cd lolipants-backend
npm create cloudflare@latest worker -- --type=hono
```

When prompted:
- **Name:** `lolipants-api`
- **Framework:** Hono (lightweight, edge-native)
- **Deploy:** No (we'll deploy manually)

Install dependencies:

```bash
cd lolipants-api
npm install hono @hono/zod-validator zod uuid
```

---

## 4.2 Configure `wrangler.toml`

Replace the contents of `wrangler.toml` with:

```toml
name = "lolipants-api"
main = "src/index.ts"
compatibility_date = "2024-01-01"
compatibility_flags = ["nodejs_compat"]

[[d1_databases]]
binding = "DB"
database_name = "lolipants-db"
database_id = "PASTE_YOUR_DATABASE_ID_HERE"

[[r2_buckets]]
binding = "R2"
bucket_name = "lolipants-media"

[vars]
ENVIRONMENT = "development"

# Secrets are set via `wrangler secret put` — not in this file
# Required secrets:
#   BETTER_AUTH_SECRET
#   OPENAI_API_KEY
#   TAP_SECRET_KEY
#   ONESIGNAL_API_KEY
#   ONESIGNAL_APP_ID
```

Replace `PASTE_YOUR_DATABASE_ID_HERE` with the `database_id` from Part 2.1.

---

## 4.3 Set Secrets

Secrets are environment variables that are encrypted and never exposed in code or logs. Set them one by one:

> If some third-party API keys are not ready yet, you can defer those safely and continue setup. See `API_SECRETS_SETUP_LATER.md` for a phased workflow, expected behavior while secrets are missing, and exact follow-up steps.

```bash
# The secret used by Better Auth to sign tokens — generate a random 32-char string
wrangler secret put BETTER_AUTH_SECRET
# When prompted, paste a random string e.g.: openssl rand -hex 32

# OpenAI API key (from https://platform.openai.com/api-keys)
wrangler secret put OPENAI_API_KEY

# Tap Payments secret key (from https://dashboard.tap.company)
wrangler secret put TAP_SECRET_KEY

# OneSignal API key (from https://dashboard.onesignal.com → Settings → Keys & IDs)
wrangler secret put ONESIGNAL_API_KEY
wrangler secret put ONESIGNAL_APP_ID
```

Each command prompts you to paste the value. The value is never stored in any file.

---

## 4.4 Worker Route Structure

Create `src/index.ts`:

```typescript
import { Hono } from 'hono'
import { cors } from 'hono/cors'
import { logger } from 'hono/logger'

// Route handlers (create each as a separate file)
import { authRoutes }        from './routes/auth'
import { designRoutes }      from './routes/designs'
import { orderRoutes }       from './routes/orders'
import { fabricRoutes }      from './routes/fabrics'
import { presetRoutes }      from './routes/presets'
import { measurementRoutes } from './routes/measurements'
import { postRoutes }        from './routes/posts'
import { communityRoutes }   from './routes/community'
import { bookingRoutes }     from './routes/bookings'
import { uploadRoutes }      from './routes/uploads'
import { aiRoutes }          from './routes/ai'
import { userRoutes }        from './routes/users'

export type Env = {
  DB: D1Database
  R2: R2Bucket
  BETTER_AUTH_SECRET: string
  OPENAI_API_KEY: string
  TAP_SECRET_KEY: string
  ONESIGNAL_API_KEY: string
  ONESIGNAL_APP_ID: string
  ENVIRONMENT: string
  CLOUDFLARE_R2_BASE_URL: string
}

const app = new Hono<{ Bindings: Env }>()

app.use('*', cors({
  origin: '*',
  allowMethods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowHeaders: ['Content-Type', 'Authorization'],
}))

app.use('*', logger())

// Mount routes
app.route('/auth',         authRoutes)
app.route('/designs',      designRoutes)
app.route('/orders',       orderRoutes)
app.route('/fabrics',      fabricRoutes)
app.route('/presets',      presetRoutes)
app.route('/measurements', measurementRoutes)
app.route('/posts',        postRoutes)
app.route('/community',    communityRoutes)
app.route('/bookings',     bookingRoutes)
app.route('/upload',       uploadRoutes)
app.route('/ai',           aiRoutes)
app.route('/users',        userRoutes)

app.get('/health', (c) => c.json({ status: 'ok', env: c.env.ENVIRONMENT }))

export default app
```

---

## 4.5 Authentication Middleware

Create `src/middleware/auth.ts`:

```typescript
import { Context, Next } from 'hono'
import { Env } from '../index'

export async function requireAuth(c: Context<{ Bindings: Env }>, next: Next) {
  const authHeader = c.req.header('Authorization')

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return c.json({ error: 'Unauthorised' }, 401)
  }

  const token = authHeader.replace('Bearer ', '')

  // Verify the session token with Better Auth
  const response = await fetch(`${c.env.BETTER_AUTH_BASE_URL}/auth/get-session`, {
    headers: { Cookie: `better-auth.session_token=${token}` },
  })

  if (!response.ok) {
    return c.json({ error: 'Invalid or expired session' }, 401)
  }

  const session = await response.json() as { user: { id: string; role: string } }
  c.set('userId', session.user.id)
  c.set('userRole', session.user.role)

  await next()
}

export async function requireRole(role: string) {
  return async (c: Context<{ Bindings: Env }>, next: Next) => {
    const userRole = c.get('userRole')
    if (userRole !== role && userRole !== 'admin') {
      return c.json({ error: 'Forbidden' }, 403)
    }
    await next()
  }
}
```

---

## 4.6 Key Route Implementations

Create each file under `src/routes/`. Below are the most important ones in full.

### `src/routes/uploads.ts`

```typescript
import { Hono } from 'hono'
import { requireAuth } from '../middleware/auth'
import { Env } from '../index'
import { v4 as uuidv4 } from 'uuid'

export const uploadRoutes = new Hono<{ Bindings: Env }>()

uploadRoutes.use('*', requireAuth)

// Upload any file to R2 — returns the public URL
uploadRoutes.post('/', async (c) => {
  const formData = await c.req.formData()
  const file = formData.get('file') as File | null

  if (!file) {
    return c.json({ error: 'No file provided' }, 400)
  }

  const allowedTypes = ['image/jpeg', 'image/png', 'image/webp']
  if (!allowedTypes.includes(file.type)) {
    return c.json({ error: 'File type not allowed. Use JPEG, PNG, or WebP.' }, 400)
  }

  const maxSize = 5 * 1024 * 1024 // 5 MB
  if (file.size > maxSize) {
    return c.json({ error: 'File too large. Maximum 5 MB.' }, 400)
  }

  const ext      = file.type.split('/')[1]
  const userId   = c.get('userId')
  const key      = `uploads/${userId}/${uuidv4()}.${ext}`
  const buffer   = await file.arrayBuffer()

  await c.env.R2.put(key, buffer, {
    httpMetadata: { contentType: file.type },
  })

  const url = `${c.env.CLOUDFLARE_R2_BASE_URL}/${key}`
  return c.json({ url, key })
})
```

### `src/routes/designs.ts`

```typescript
import { Hono } from 'hono'
import { requireAuth } from '../middleware/auth'
import { Env } from '../index'
import { v4 as uuidv4 } from 'uuid'

export const designRoutes = new Hono<{ Bindings: Env }>()

designRoutes.use('*', requireAuth)

// Get all designs for the current user
designRoutes.get('/', async (c) => {
  const userId = c.get('userId')
  const { results } = await c.env.DB
    .prepare('SELECT * FROM designs WHERE user_id = ? ORDER BY created_at DESC')
    .bind(userId)
    .all()
  return c.json(results)
})

// Get a single design
designRoutes.get('/:id', async (c) => {
  const id = c.req.param('id')
  const design = await c.env.DB
    .prepare('SELECT * FROM designs WHERE id = ?')
    .bind(id)
    .first()
  if (!design) return c.json({ error: 'Design not found' }, 404)
  return c.json(design)
})

// Create a design
designRoutes.post('/', async (c) => {
  const userId = c.get('userId')
  const body   = await c.req.json()
  const id     = uuidv4()

  await c.env.DB.prepare(`
    INSERT INTO designs (id, user_id, name, garment_type, fabric_id, fabric_quality,
      primary_colour, accent_colour, pattern_id, print_image_url, text_layers, is_public)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `).bind(
    id, userId, body.name, body.garmentType, body.fabricId ?? null,
    body.fabricQuality ?? 'standard', body.primaryColour, body.accentColour ?? null,
    body.patternId ?? null, body.printImageUrl ?? null,
    JSON.stringify(body.textLayers ?? []), body.isPublic ? 1 : 0,
  ).run()

  const design = await c.env.DB
    .prepare('SELECT * FROM designs WHERE id = ?')
    .bind(id)
    .first()

  return c.json(design, 201)
})

// Update a design
designRoutes.patch('/:id', async (c) => {
  const id     = c.req.param('id')
  const userId = c.get('userId')
  const body   = await c.req.json()

  const existing = await c.env.DB
    .prepare('SELECT * FROM designs WHERE id = ? AND user_id = ?')
    .bind(id, userId)
    .first()

  if (!existing) return c.json({ error: 'Design not found' }, 404)

  await c.env.DB.prepare(`
    UPDATE designs SET
      name = ?, fabric_id = ?, fabric_quality = ?, primary_colour = ?,
      accent_colour = ?, pattern_id = ?, print_image_url = ?, text_layers = ?,
      is_public = ?, updated_at = datetime('now')
    WHERE id = ? AND user_id = ?
  `).bind(
    body.name ?? existing.name,
    body.fabricId ?? existing.fabric_id,
    body.fabricQuality ?? existing.fabric_quality,
    body.primaryColour ?? existing.primary_colour,
    body.accentColour ?? existing.accent_colour,
    body.patternId ?? existing.pattern_id,
    body.printImageUrl ?? existing.print_image_url,
    body.textLayers ? JSON.stringify(body.textLayers) : existing.text_layers,
    body.isPublic !== undefined ? (body.isPublic ? 1 : 0) : existing.is_public,
    id, userId,
  ).run()

  const updated = await c.env.DB
    .prepare('SELECT * FROM designs WHERE id = ?')
    .bind(id)
    .first()

  return c.json(updated)
})

// Delete a design
designRoutes.delete('/:id', async (c) => {
  const id     = c.req.param('id')
  const userId = c.get('userId')

  await c.env.DB
    .prepare('DELETE FROM designs WHERE id = ? AND user_id = ?')
    .bind(id, userId)
    .run()

  return c.json({ deleted: true })
})
```

### `src/routes/orders.ts`

```typescript
import { Hono } from 'hono'
import { requireAuth } from '../middleware/auth'
import { Env } from '../index'
import { v4 as uuidv4 } from 'uuid'

export const orderRoutes = new Hono<{ Bindings: Env }>()

orderRoutes.use('*', requireAuth)

// Get all orders for current user
orderRoutes.get('/', async (c) => {
  const userId = c.get('userId')
  const { results } = await c.env.DB
    .prepare('SELECT * FROM orders WHERE user_id = ? ORDER BY placed_at DESC')
    .bind(userId)
    .all()

  // Attach status history to each order
  for (const order of results as any[]) {
    const { results: history } = await c.env.DB
      .prepare('SELECT * FROM order_status_history WHERE order_id = ? ORDER BY timestamp ASC')
      .bind(order.id)
      .all()
    order.statusHistory = history
  }

  return c.json(results)
})

// Get a single order
orderRoutes.get('/:id', async (c) => {
  const id     = c.req.param('id')
  const userId = c.get('userId')

  const order = await c.env.DB
    .prepare('SELECT * FROM orders WHERE id = ? AND user_id = ?')
    .bind(id, userId)
    .first() as any

  if (!order) return c.json({ error: 'Order not found' }, 404)

  const { results: history } = await c.env.DB
    .prepare('SELECT * FROM order_status_history WHERE order_id = ? ORDER BY timestamp ASC')
    .bind(id)
    .all()

  order.statusHistory = history
  return c.json(order)
})

// Place a new order (also processes Tap payment)
orderRoutes.post('/', async (c) => {
  const userId = c.get('userId')
  const body   = await c.req.json()

  // Verify payment with Tap Payments API
  const tapResponse = await fetch('https://api.tap.company/v2/charges', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${c.env.TAP_SECRET_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      amount:   body.totalPrice,
      currency: 'QAR',
      source:   { id: body.paymentToken },
      customer: { id: userId },
    }),
  })

  if (!tapResponse.ok) {
    const tapError = await tapResponse.json() as any
    return c.json({ error: tapError.message ?? 'Payment failed' }, 402)
  }

  const charge = await tapResponse.json() as any
  if (charge.status !== 'CAPTURED') {
    return c.json({ error: 'Payment not captured' }, 402)
  }

  // Create order in D1
  const id  = uuidv4()
  const now = new Date().toISOString()

  await c.env.DB.prepare(`
    INSERT INTO orders (id, user_id, design_id, designer_id, status,
      delivery_address, delivery_city, delivery_phone, delivery_notes,
      base_price, fabric_fee, delivery_fee, total_price, payment_token, placed_at)
    VALUES (?, ?, ?, ?, 'placed', ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `).bind(
    id, userId, body.designId, body.designerId ?? null,
    body.deliveryAddress, body.deliveryCity, body.deliveryPhone, body.deliveryNotes ?? null,
    body.basePrice, body.fabricFee ?? 0, body.deliveryFee ?? 0, body.totalPrice,
    charge.id, now,
  ).run()

  // Insert initial status history entry
  await c.env.DB.prepare(`
    INSERT INTO order_status_history (id, order_id, status, timestamp)
    VALUES (?, ?, 'placed', ?)
  `).bind(uuidv4(), id, now).run()

  const order = await c.env.DB
    .prepare('SELECT * FROM orders WHERE id = ?')
    .bind(id)
    .first()

  // TODO: send push notification to user
  // TODO: notify available tailors

  return c.json(order, 201)
})

// Update order status (tailor / admin only)
orderRoutes.patch('/:id/status', async (c) => {
  const id       = c.req.param('id')
  const userRole = c.get('userRole')
  const userId   = c.get('userId')
  const body     = await c.req.json()

  if (userRole !== 'tailor' && userRole !== 'admin') {
    return c.json({ error: 'Forbidden' }, 403)
  }

  const validStatuses = [
    'confirmed','cutting','stitching','embroidery',
    'quality_check','ready_to_ship','out_for_delivery','delivered','cancelled',
  ]

  if (!validStatuses.includes(body.status)) {
    return c.json({ error: 'Invalid status value' }, 400)
  }

  await c.env.DB.prepare(`
    UPDATE orders SET status = ?, updated_at = datetime('now') WHERE id = ?
  `).bind(body.status, id).run()

  await c.env.DB.prepare(`
    INSERT INTO order_status_history (id, order_id, status, note, updated_by, timestamp)
    VALUES (?, ?, ?, ?, ?, datetime('now'))
  `).bind(uuidv4(), id, body.status, body.note ?? null, userId).run()

  // TODO: send push notification to customer

  return c.json({ updated: true, status: body.status })
})
```

### `src/routes/ai.ts`

```typescript
import { Hono } from 'hono'
import { requireAuth } from '../middleware/auth'
import { Env } from '../index'

export const aiRoutes = new Hono<{ Bindings: Env }>()

aiRoutes.use('*', requireAuth)

// AI design generation proxy
aiRoutes.post('/design', async (c) => {
  const { prompt, garmentType, currentStyle } = await c.req.json()

  const systemPrompt = `
You are a fashion design AI for a Middle Eastern fashion app called Lolipants.
When given a design description, respond with ONLY a JSON object (no markdown, no extra text) with these fields:
{
  "primaryColour": "#hex",
  "accentColour": "#hex or null",
  "fabricId": "one of: f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 f11 f12 f13 f14 f15 f16",
  "patternId": "one of: p1 p2 p3 p4 p5 or null",
  "embroideryId": "one of: p6 p7 p8 p9 or null",
  "description": "2-sentence description in English",
  "descriptionAr": "2-sentence description in Arabic"
}
Only suggest colours and fabrics appropriate for the garment type: ${garmentType}.
Consider the current style context: ${currentStyle ?? 'none'}.
  `.trim()

  const response = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${c.env.OPENAI_API_KEY}`,
      'Content-Type':  'application/json',
    },
    body: JSON.stringify({
      model: 'gpt-4o-mini',
      messages: [
        { role: 'system',  content: systemPrompt },
        { role: 'user',    content: prompt },
      ],
      max_tokens: 400,
      temperature: 0.7,
    }),
  })

  if (!response.ok) {
    return c.json({ error: 'AI service unavailable' }, 503)
  }

  const data = await response.json() as any
  const raw  = data.choices?.[0]?.message?.content ?? ''

  try {
    const suggestion = JSON.parse(raw)
    return c.json(suggestion)
  } catch {
    return c.json({ error: 'Could not parse AI response' }, 500)
  }
})

// AI body measurement proxy (OpenAI Vision)
aiRoutes.post('/measure', async (c) => {
  const { imageBase64 } = await c.req.json()

  const response = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${c.env.OPENAI_API_KEY}`,
      'Content-Type':  'application/json',
    },
    body: JSON.stringify({
      model: 'gpt-4o',
      messages: [{
        role: 'user',
        content: [
          {
            type: 'text',
            text: `Analyse this full-body photo and estimate body measurements in centimetres.
Respond with ONLY a JSON object (no markdown) with these fields:
{ "chest": number, "waist": number, "hips": number, "shoulderWidth": number, "height": number, "armLength": number }
All values in cm. If a measurement cannot be estimated, use null.`,
          },
          {
            type: 'image_url',
            image_url: { url: `data:image/jpeg;base64,${imageBase64}`, detail: 'high' },
          },
        ],
      }],
      max_tokens: 200,
    }),
  })

  if (!response.ok) {
    return c.json({ error: 'AI measurement service unavailable' }, 503)
  }

  const data = await response.json() as any
  const raw  = data.choices?.[0]?.message?.content ?? ''

  try {
    const measurements = JSON.parse(raw)
    return c.json(measurements)
  } catch {
    return c.json({ error: 'Could not parse measurement response' }, 500)
  }
})
```

---

## 4.7 Deploy the Worker

Test locally first:

```bash
wrangler dev
```

The local server runs at `http://localhost:8787`. Test the health endpoint:

```bash
curl http://localhost:8787/health
# Expected: {"status":"ok","env":"development"}
```

Deploy to Cloudflare's edge network:

```bash
wrangler deploy
```

The output gives you your Worker URL:

```
Published lolipants-api (x.xx sec)
https://lolipants-api.YOUR-SUBDOMAIN.workers.dev
```

This is your `API_BASE_URL` and `CLOUDFLARE_API_BASE`. Save it.

---

## 4.8 Set the R2 Base URL as a Worker Variable

The Worker needs to know the public R2 URL when constructing file URLs:

```bash
wrangler secret put CLOUDFLARE_R2_BASE_URL
# Paste your R2 public URL from Part 3.2
```

---

---

# PART 5 — Better Auth

Better Auth is your authentication server. It runs as a separate service alongside the Cloudflare Worker.

---

## 5.1 Create the Better Auth Project

In a new folder (separate from `lolipants-backend`):

```bash
mkdir lolipants-auth
cd lolipants-auth
bun init -y
bun add better-auth @better-auth/cli
```

---

## 5.2 Configure Better Auth

Create `auth.ts`:

```typescript
// auth.ts
import { betterAuth } from 'better-auth'

export const auth = betterAuth({
  secret: process.env.BETTER_AUTH_SECRET!,

  database: {
    // Better Auth stores session and account data in its own tables
    // Use a separate SQLite file for auth — not D1 (to keep concerns separated)
    // For production: use a Postgres database (e.g. Neon, Supabase Postgres)
    type:     'sqlite',
    filename: './auth.db',
  },

  emailAndPassword: {
    enabled:         true,
    minPasswordLength: 8,
    requireEmailVerification: false,  // set to true in production
  },

  session: {
    expiresIn:         60 * 60 * 24 * 7,  // 7 days
    updateAge:         60 * 60 * 24,       // refresh if used within 1 day of expiry
    cookieName:        'better-auth.session_token',
  },

  trustedOrigins: [
    'http://localhost:3000',
    'https://lolipants-api.YOUR-SUBDOMAIN.workers.dev',
    // Add your production domain when ready
  ],

  user: {
    additionalFields: {
      role: {
        type:         'string',
        defaultValue: 'user',
        required:     false,
      },
    },
  },
})
```

---

## 5.3 Create the Auth Server

Create `server.ts`:

```typescript
// server.ts
import { serve } from 'bun'
import { auth }  from './auth'
import { toNodeHandler } from 'better-auth/node'

const handler = toNodeHandler(auth)

serve({
  port: 3001,
  async fetch(request) {
    const url = new URL(request.url)

    // All auth routes are under /auth/*
    if (url.pathname.startsWith('/auth')) {
      return handler(request)
    }

    return new Response('Not found', { status: 404 })
  },
})

console.log('Better Auth server running at http://localhost:3001')
```

---

## 5.4 Environment Variables for Better Auth

Create `.env` in the `lolipants-auth` folder:

```env
BETTER_AUTH_SECRET=your-32-character-random-secret-here
PORT=3001
```

Generate a secret:

```bash
openssl rand -hex 32
```

---

## 5.5 Run the Auth Server Locally

```bash
bun run server.ts
```

Test it:

```bash
# Should return 200 with session object (null session since not logged in)
curl http://localhost:3001/auth/get-session
```

---

## 5.6 Deploy Better Auth to Production

Better Auth needs to run on a persistent server. The simplest options in order of ease:

**Option A — Railway (recommended for getting started fast):**

1. Push `lolipants-auth` to a GitHub repository
2. Go to https://railway.app → New Project → Deploy from GitHub
3. Select your repo
4. Add environment variable `BETTER_AUTH_SECRET` in Railway dashboard
5. Set start command: `bun run server.ts`
6. Railway gives you a URL like `https://lolipants-auth.up.railway.app`

**Option B — Fly.io:**

```bash
# Install flyctl
curl -L https://fly.io/install.sh | sh

cd lolipants-auth
fly launch      # follow prompts
fly secrets set BETTER_AUTH_SECRET=your-secret
fly deploy
```

**Option C — VPS (DigitalOcean, Hetzner, etc.):**

```bash
# On your VPS
git clone your-repo
cd lolipants-auth
bun install
bun run server.ts &

# Use pm2 for process management
npm install -g pm2
pm2 start "bun run server.ts" --name lolipants-auth
pm2 startup
pm2 save
```

Use Nginx to reverse proxy to port 3001 and add an SSL certificate via Certbot.

After deployment, your `BETTER_AUTH_BASE_URL` is the URL of your deployed auth server (e.g. `https://lolipants-auth.up.railway.app`).

---

## 5.7 Update `wrangler.toml` with Auth URL

Add this to `wrangler.toml` under `[vars]`:

```toml
[vars]
ENVIRONMENT = "production"
BETTER_AUTH_BASE_URL = "https://your-deployed-auth-url.com"
```

Or set it as a secret (more secure):

```bash
wrangler secret put BETTER_AUTH_BASE_URL
```

---

---

# PART 6 — Final Environment Variables

You now have everything needed to fill in your `.env` files.

---

## Flutter App `.env`

In the root of your Flutter project (`lolipants/`), create `.env`:

```env
BETTER_AUTH_BASE_URL=https://your-deployed-auth-server.com
API_BASE_URL=https://lolipants-api.your-subdomain.workers.dev
CLOUDFLARE_API_BASE=https://lolipants-api.your-subdomain.workers.dev
CLOUDFLARE_R2_BASE_URL=https://pub-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.r2.dev
```

Add `.env` to `.gitignore` immediately:

```bash
echo ".env" >> .gitignore
```

---

## Cloudflare Worker Secrets (full list)

These should all be set via `wrangler secret put` — never in `wrangler.toml`:

```bash
wrangler secret put BETTER_AUTH_SECRET      # shared with auth server, same value
wrangler secret put BETTER_AUTH_BASE_URL    # URL of your auth server
wrangler secret put OPENAI_API_KEY          # from platform.openai.com
wrangler secret put TAP_SECRET_KEY          # from dashboard.tap.company
wrangler secret put ONESIGNAL_API_KEY       # from dashboard.onesignal.com
wrangler secret put ONESIGNAL_APP_ID        # from dashboard.onesignal.com
wrangler secret put CLOUDFLARE_R2_BASE_URL  # R2 public bucket URL
```

Verify all secrets are set:

```bash
wrangler secret list
```

---

---

# PART 7 — Quick Verification Checklist

Run through every item before starting Flutter development.

**Cloudflare D1:**
- [ ] `wrangler d1 list` shows `lolipants-db`
- [ ] `wrangler d1 execute lolipants-db --remote --command="SELECT name FROM sqlite_master WHERE type='table'"` lists all tables from `schema.sql`
- [ ] Fabric options and presets are present in the `fabric_options` and `presets` tables

**Cloudflare R2:**
- [ ] `wrangler r2 bucket list` shows `lolipants-media`
- [ ] Uploading a test file and fetching the public URL returns the image

**Cloudflare Worker:**
- [ ] `curl https://lolipants-api.YOUR-SUBDOMAIN.workers.dev/health` returns `{"status":"ok"}`
- [ ] `wrangler secret list` shows all 7 secrets

**Better Auth:**
- [ ] Auth server is running (local or deployed)
- [ ] `curl YOUR_AUTH_URL/auth/get-session` returns `{"session":null}` (not a 404 or connection error)
- [ ] Sign-up test: `curl -X POST YOUR_AUTH_URL/auth/sign-up/email -H "Content-Type: application/json" -d '{"name":"Test","email":"test@test.com","password":"password123"}'` returns a user object

**Flutter `.env`:**
- [ ] `.env` exists in project root
- [ ] `.env` is listed in `pubspec.yaml` under `flutter.assets`
- [ ] `.env` is in `.gitignore`
- [ ] All 4 variables are filled with real URLs (not placeholder text)

---

# PART 8 — Production Notes

These items are not required for initial development but must be done before going live.

**Custom domain:** Point `api.lolipants.com` to your Cloudflare Worker via Cloudflare DNS → Worker Routes. Update `API_BASE_URL` and `CLOUDFLARE_API_BASE` in Flutter `.env`.

**Auth database:** Replace the SQLite file in Better Auth with a Postgres database (Neon free tier works well) before going to production. SQLite is fine for development but not for a multi-instance deployed service.

**Email verification:** Set `requireEmailVerification: true` in Better Auth config and configure an email provider (Better Auth supports Resend, Nodemailer, and others).

**Rate limiting:** Add Cloudflare's built-in rate limiting to your Worker for auth endpoints (`/auth/sign-up`, `/auth/sign-in`) to prevent brute-force attacks. Available in the Cloudflare dashboard under Worker → Settings → Rate Limiting.

**HTTPS only:** Ensure Better Auth is served over HTTPS only. All major deployment platforms (Railway, Fly.io) handle this automatically.

**Backups:** Enable automatic D1 database backups in the Cloudflare dashboard → D1 → lolipants-db → Backups.
