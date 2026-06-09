import Link from "next/link";
import {
  Zap,
  Dumbbell,
  UtensilsCrossed,
  TrendingUp,
  Store,
  MessageCircle,
  Check,
  ArrowRight,
} from "lucide-react";

const features = [
  {
    icon: Dumbbell,
    title: "AI Workout Planner",
    description:
      "Personalized weekly plans with sets, reps, rest times, and a built-in workout timer.",
  },
  {
    icon: UtensilsCrossed,
    title: "AI Meal Planner",
    description:
      "7-day meal plans with macro breakdowns and auto-generated grocery lists.",
  },
  {
    icon: TrendingUp,
    title: "Progress Tracker",
    description:
      "Log weight, workouts, sleep & water. Charts, streaks, and AI weekly insights.",
  },
  {
    icon: Store,
    title: "Program Marketplace",
    description:
      "Browse and buy expert trainer programs. Preview week one free before you buy.",
  },
  {
    icon: MessageCircle,
    title: "AI Coach",
    description:
      "24/7 fitness & nutrition coaching powered by Claude. Ask anything, anytime.",
  },
];

const plans = [
  {
    name: "Free",
    price: "₹0",
    period: "forever",
    features: ["3 AI plans/month", "Marketplace browsing", "Basic progress log"],
    cta: "Get Started",
    highlighted: false,
  },
  {
    name: "Pro",
    price: "₹299",
    period: "/month",
    features: [
      "Unlimited AI plans",
      "No ads",
      "Progress analytics",
      "AI weekly insights",
    ],
    cta: "Start Pro",
    highlighted: true,
  },
  {
    name: "Trainer",
    price: "₹799",
    period: "/month",
    features: [
      "Everything in Pro",
      "Create & sell programs",
      "Analytics dashboard",
      "80% revenue share",
    ],
    cta: "Become a Trainer",
    highlighted: false,
  },
];

export default function LandingPage() {
  return (
    <div className="min-h-screen bg-navy-900">
      {/* Nav */}
      <nav className="fixed top-0 z-50 w-full border-b border-slate-700/30 bg-navy-900/80 backdrop-blur-xl">
        <div className="mx-auto flex max-w-7xl items-center justify-between px-6 py-4">
          <div className="flex items-center gap-2">
            <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-primary">
              <Zap className="h-5 w-5 text-white" />
            </div>
            <span className="text-xl font-bold text-white">
              Fit<span className="text-primary">Forge</span>
            </span>
          </div>
          <div className="flex items-center gap-3">
            <Link href="/auth/login" className="btn-ghost">
              Log in
            </Link>
            <Link href="/auth/signup" className="btn-primary">
              Start Free
            </Link>
          </div>
        </div>
      </nav>

      {/* Hero */}
      <section className="relative overflow-hidden px-6 pb-24 pt-32">
        <div className="pointer-events-none absolute inset-0 bg-[radial-gradient(ellipse_at_top,_#1D9E7520,_transparent_60%)]" />
        <div className="relative mx-auto max-w-4xl text-center">
          <div className="mb-6 inline-flex items-center gap-2 rounded-full border border-primary/30 bg-primary/10 px-4 py-1.5 text-sm text-primary">
            <Zap className="h-4 w-4" />
            AI-Powered Fitness Platform
          </div>
          <h1 className="mb-6 text-5xl font-extrabold leading-tight tracking-tight text-white md:text-7xl">
            Forge Your
            <br />
            <span className="bg-gradient-to-r from-primary to-emerald-300 bg-clip-text text-transparent">
              Best Self
            </span>
          </h1>
          <p className="mx-auto mb-10 max-w-2xl text-lg text-slate-400">
            Personalized AI workout & meal plans, progress tracking, and a
            marketplace of expert trainer programs — all in one platform.
          </p>
          <div className="flex flex-col items-center justify-center gap-4 sm:flex-row">
            <Link href="/auth/signup" className="btn-primary px-8 py-3 text-base">
              Start Free Trial
              <ArrowRight className="h-5 w-5" />
            </Link>
            <Link href="#features" className="btn-secondary px-8 py-3 text-base">
              See Features
            </Link>
          </div>
        </div>
      </section>

      {/* Features */}
      <section id="features" className="px-6 py-24">
        <div className="mx-auto max-w-7xl">
          <h2 className="mb-4 text-center text-3xl font-bold text-white">
            Everything you need to transform
          </h2>
          <p className="mb-16 text-center text-slate-400">
            Five powerful modules working together for your fitness journey
          </p>
          <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
            {features.map(({ icon: Icon, title, description }) => (
              <div key={title} className="card group transition-colors hover:border-primary/30">
                <div className="mb-4 flex h-12 w-12 items-center justify-center rounded-xl bg-primary/15 transition-colors group-hover:bg-primary/25">
                  <Icon className="h-6 w-6 text-primary" />
                </div>
                <h3 className="mb-2 text-lg font-semibold text-white">{title}</h3>
                <p className="text-sm text-slate-400">{description}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Pricing */}
      <section className="px-6 py-24">
        <div className="mx-auto max-w-5xl">
          <h2 className="mb-4 text-center text-3xl font-bold text-white">
            Simple, transparent pricing
          </h2>
          <p className="mb-16 text-center text-slate-400">
            Start free, upgrade when you&apos;re ready
          </p>
          <div className="grid gap-6 md:grid-cols-3">
            {plans.map((plan) => (
              <div
                key={plan.name}
                className={`card relative ${
                  plan.highlighted
                    ? "border-primary ring-1 ring-primary/30"
                    : ""
                }`}
              >
                {plan.highlighted && (
                  <span className="badge-primary absolute -top-3 left-1/2 -translate-x-1/2">
                    Most Popular
                  </span>
                )}
                <h3 className="text-lg font-semibold text-white">{plan.name}</h3>
                <div className="my-4">
                  <span className="text-4xl font-bold text-white">{plan.price}</span>
                  <span className="text-slate-400">{plan.period}</span>
                </div>
                <ul className="mb-6 space-y-2">
                  {plan.features.map((f) => (
                    <li key={f} className="flex items-center gap-2 text-sm text-slate-300">
                      <Check className="h-4 w-4 shrink-0 text-primary" />
                      {f}
                    </li>
                  ))}
                </ul>
                <Link
                  href="/auth/signup"
                  className={plan.highlighted ? "btn-primary w-full" : "btn-secondary w-full"}
                >
                  {plan.cta}
                </Link>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="border-t border-slate-700/30 px-6 py-12">
        <div className="mx-auto flex max-w-7xl flex-col items-center justify-between gap-4 md:flex-row">
          <div className="flex items-center gap-2">
            <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-primary">
              <Zap className="h-4 w-4 text-white" />
            </div>
            <span className="font-bold text-white">
              Fit<span className="text-primary">Forge</span>
            </span>
          </div>
          <p className="text-sm text-slate-500">
            © {new Date().getFullYear()} FitForge. Built with Next.js & Supabase.
          </p>
        </div>
      </footer>
    </div>
  );
}
