"use client";

import { useState, useEffect } from "react";
import { Crown, Check } from "lucide-react";
import { Button } from "@/components/ui/button";
import { TIER_LABELS, formatINR } from "@/lib/utils";
import type { Profile } from "@/types/database";

declare global {
  interface Window {
    Razorpay: new (options: Record<string, unknown>) => { open: () => void };
  }
}

const PLANS = [
  {
    tier: "free",
    name: "Free",
    price: 0,
    features: ["3 AI plans/month", "Marketplace browsing", "Basic progress log"],
  },
  {
    tier: "pro",
    name: "Pro",
    price: 299,
    features: ["Unlimited AI plans", "No ads", "Progress analytics", "AI weekly insights"],
  },
  {
    tier: "trainer",
    name: "Trainer",
    price: 799,
    features: ["Everything in Pro", "Create & sell programs", "Analytics dashboard", "80% revenue share"],
  },
];

export default function SettingsPage() {
  const [profile, setProfile] = useState<Profile | null>(null);
  const [fullName, setFullName] = useState("");
  const [bio, setBio] = useState("");
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    fetch("/api/profile")
      .then((r) => r.json())
      .then((d) => {
        if (d.profile) {
          setProfile(d.profile);
          setFullName(d.profile.full_name || "");
          setBio(d.profile.bio || "");
        }
      });
  }, []);

  const saveProfile = async () => {
    setSaving(true);
    await fetch("/api/profile", {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ full_name: fullName, bio }),
    });
    setSaving(false);
  };

  const subscribe = async (tier: string) => {
    if (tier === "free") return;

    const script = document.createElement("script");
    script.src = "https://checkout.razorpay.com/v1/checkout.js";
    document.body.appendChild(script);
    await new Promise((r) => (script.onload = r));

    const res = await fetch("/api/payments/subscription", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ tier }),
    });
    const data = await res.json();
    if (!res.ok) return alert(data.error);

    const rzp = new window.Razorpay({
      key: data.keyId,
      subscription_id: data.subscriptionId,
      name: "FitForge",
      description: data.plan.description,
      handler: async (response: Record<string, string>) => {
        await fetch("/api/payments/verify", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ type: "subscription", tier, ...response }),
        });
        window.location.reload();
      },
    });
    rzp.open();
  };

  return (
    <div className="mx-auto max-w-3xl space-y-8">
      <div>
        <h1 className="text-3xl font-bold text-white">Settings</h1>
        <p className="mt-1 text-slate-400">Manage your profile and subscription</p>
      </div>

      <div className="card space-y-4">
        <h2 className="font-semibold text-white">Profile</h2>
        <div>
          <label className="label">Full Name</label>
          <input className="input" value={fullName} onChange={(e) => setFullName(e.target.value)} />
        </div>
        <div>
          <label className="label">Bio</label>
          <textarea className="input min-h-[80px]" value={bio} onChange={(e) => setBio(e.target.value)} />
        </div>
        <div>
          <label className="label">Email</label>
          <input className="input" value={profile?.email || ""} disabled />
        </div>
        <Button onClick={saveProfile} loading={saving}>
          Save Profile
        </Button>
      </div>

      <div className="card space-y-4">
        <div className="flex items-center gap-2">
          <Crown className="h-5 w-5 text-amber-400" />
          <h2 className="font-semibold text-white">Subscription</h2>
          {profile && (
            <span className="badge-primary ml-auto">
              Current: {TIER_LABELS[profile.subscription_tier]}
            </span>
          )}
        </div>
        <div className="grid gap-4 md:grid-cols-3">
          {PLANS.map((plan) => (
            <div
              key={plan.tier}
              className={`rounded-xl border p-4 ${
                profile?.subscription_tier === plan.tier
                  ? "border-primary bg-primary/5"
                  : "border-slate-700"
              }`}
            >
              <h3 className="font-semibold text-white">{plan.name}</h3>
              <p className="mt-1 text-2xl font-bold text-white">
                {plan.price === 0 ? "Free" : formatINR(plan.price)}
                {plan.price > 0 && <span className="text-sm text-slate-400">/mo</span>}
              </p>
              <ul className="mt-3 space-y-1">
                {plan.features.map((f) => (
                  <li key={f} className="flex items-center gap-1.5 text-xs text-slate-400">
                    <Check className="h-3 w-3 text-primary" />
                    {f}
                  </li>
                ))}
              </ul>
              {profile?.subscription_tier !== plan.tier && plan.tier !== "free" && (
                <Button
                  size="sm"
                  className="mt-4 w-full"
                  onClick={() => subscribe(plan.tier)}
                >
                  Upgrade
                </Button>
              )}
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
