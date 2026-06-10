# FitForge

AI-powered fitness SaaS platform with workout planning, meal planning, progress tracking, and a trainer marketplace.

## Tech Stack

- **Frontend:** Next.js 14, Tailwind CSS, Recharts, Framer Motion
- **Backend:** Supabase (Auth, Database, Storage)
- **AI:** Claude API (`claude-sonnet-4-20250514`)
- **Payments:** Razorpay (subscriptions + marketplace splits)

## Getting Started

### 1. Install dependencies

```bash
npm install
```

### 2. Set up Supabase

1. Create a project at [supabase.com](https://supabase.com)
2. Run the SQL migration in `supabase/migrations/001_initial_schema.sql` in the SQL Editor
3. Create storage buckets: `avatars`, `progress-photos`, `program-covers`, `program-pdfs`
4. Copy your project URL and anon key

### 3. Configure environment

```bash
cp .env.example .env.local
```

Fill in your Supabase, Anthropic, and Razorpay credentials.

### 4. Run the dev server

```bash
npm run dev
```

Open [http://localhost:3000](http://localhost:3000).

## Pages

| Route | Description |
|-------|-------------|
| `/` | Landing page |
| `/auth/login` | Login |
| `/auth/signup` | Sign up (Fitness User or Trainer) |
| `/dashboard` | Main dashboard |
| `/workout` | AI Workout Planner + timer |
| `/meals` | AI Meal Planner + grocery list |
| `/progress` | Progress tracker + charts |
| `/marketplace` | Browse & buy trainer programs |
| `/trainer` | Trainer Studio dashboard |
| `/coach` | AI Coach chat |
| `/settings` | Profile & subscription |

## Subscription Tiers

| Tier | Price | Features |
|------|-------|----------|
| Free | ₹0 | 3 AI plans/month, marketplace browsing |
| Pro | ₹299/mo | Unlimited AI plans, analytics, no ads |
| Trainer | ₹799/mo | Create & sell programs, 80% revenue |

## Mobile App (Flutter)

The Flutter app lives in `mobile/` and shares the same Supabase backend.

```bash
cd mobile
cp .env.example .env   # add Supabase credentials
flutter pub get
flutter run
```

**Screens:** Onboarding, Home, Workout, Meals, Progress, Marketplace, Profile, AI Coach

**API_BASE_URL** points to your Next.js server for AI features:
- Android emulator: `http://10.0.2.2:3000`
- iOS simulator: `http://localhost:3000`
- Physical device: your machine's LAN IP

## Deploy

- **Web:** Deploy to Vercel, add env vars
- **Mobile:** Flutter + EAS Build / Play Store / App Store
