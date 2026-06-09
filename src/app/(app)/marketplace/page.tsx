"use client";

import { useState, useEffect } from "react";
import Image from "next/image";
import { Star, Users, Clock, ShoppingBag, Eye } from "lucide-react";
import { Button } from "@/components/ui/button";
import { formatINR } from "@/lib/utils";
import type { Program } from "@/types/database";

declare global {
  interface Window {
    Razorpay: new (options: Record<string, unknown>) => { open: () => void };
  }
}

export default function MarketplacePage() {
  const [programs, setPrograms] = useState<Program[]>([]);
  const [loading, setLoading] = useState(true);
  const [preview, setPreview] = useState<Program | null>(null);
  const [purchased, setPurchased] = useState<Set<string>>(new Set());

  useEffect(() => {
    Promise.all([
      fetch("/api/marketplace").then((r) => r.json()),
      fetch("/api/marketplace/purchases").then((r) => r.json()),
    ]).then(([marketData, purchaseData]) => {
      setPrograms(marketData.programs || []);
      setPurchased(new Set(purchaseData.purchased || []));
      setLoading(false);
    });
  }, []);

  const loadRazorpay = () =>
    new Promise<void>((resolve) => {
      if (window.Razorpay) return resolve();
      const script = document.createElement("script");
      script.src = "https://checkout.razorpay.com/v1/checkout.js";
      script.onload = () => resolve();
      document.body.appendChild(script);
    });

  const handlePurchase = async (program: Program) => {
    await loadRazorpay();
    const res = await fetch("/api/payments/marketplace", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ programId: program.id }),
    });
    const data = await res.json();
    if (!res.ok) return alert(data.error);

    const rzp = new window.Razorpay({
      key: data.keyId,
      amount: data.amount * 100,
      currency: "INR",
      name: "FitForge",
      description: data.programName,
      order_id: data.orderId,
      handler: async (response: Record<string, string>) => {
        await fetch("/api/payments/verify", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            type: "marketplace",
            programId: program.id,
            ...response,
          }),
        });
        setPurchased((prev) => new Set([...Array.from(prev), program.id]));
        alert("Purchase successful!");
      },
    });
    rzp.open();
  };

  if (loading) {
    return (
      <div className="flex h-64 items-center justify-center">
        <div className="h-8 w-8 animate-spin rounded-full border-2 border-primary border-t-transparent" />
      </div>
    );
  }

  return (
    <div className="space-y-8">
      <div>
        <h1 className="text-3xl font-bold text-white">Program Marketplace</h1>
        <p className="mt-1 text-slate-400">
          Expert trainer programs — preview week one free
        </p>
      </div>

      {preview && (
        <div className="card">
          <div className="mb-4 flex items-center justify-between">
            <h3 className="font-semibold text-white">
              Preview: {preview.name} — Week 1
            </h3>
            <Button variant="ghost" size="sm" onClick={() => setPreview(null)}>
              Close
            </Button>
          </div>
          <div className="space-y-3">
            {preview.preview_week_data?.days?.map((day) => (
              <div key={day.day} className="rounded-xl bg-navy-700/50 p-4">
                <p className="font-medium text-primary">{day.day} — {day.focus}</p>
                <ul className="mt-2 space-y-1">
                  {day.exercises?.slice(0, 3).map((ex, i) => (
                    <li key={i} className="text-sm text-slate-400">
                      {ex.name}: {ex.sets}×{ex.reps}
                    </li>
                  ))}
                </ul>
              </div>
            )) || (
              <p className="text-slate-500">Preview content coming soon</p>
            )}
          </div>
        </div>
      )}

      <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
        {programs.map((program) => (
          <div key={program.id} className="card overflow-hidden p-0">
            <div className="relative h-40 bg-navy-700">
              {program.cover_image_url ? (
                <Image
                  src={program.cover_image_url}
                  alt={program.name}
                  fill
                  className="object-cover"
                />
              ) : (
                <div className="flex h-full items-center justify-center text-slate-600">
                  <ShoppingBag className="h-12 w-12" />
                </div>
              )}
            </div>
            <div className="p-5">
              <h3 className="font-semibold text-white">{program.name}</h3>
              <p className="mt-1 line-clamp-2 text-sm text-slate-400">
                {program.description}
              </p>
              <div className="mt-3 flex items-center gap-4 text-xs text-slate-500">
                <span className="flex items-center gap-1">
                  <Star className="h-3.5 w-3.5 text-amber-400" fill="currentColor" />
                  {program.avg_rating.toFixed(1)} ({program.review_count})
                </span>
                <span className="flex items-center gap-1">
                  <Clock className="h-3.5 w-3.5" />
                  {program.duration_weeks}w
                </span>
                <span className="flex items-center gap-1">
                  <Users className="h-3.5 w-3.5" />
                  {program.purchase_count}
                </span>
              </div>
              <div className="mt-4 flex items-center justify-between">
                <span className="text-xl font-bold text-primary">
                  {formatINR(program.price_inr)}
                </span>
                <div className="flex gap-2">
                  <Button
                    variant="ghost"
                    size="sm"
                    onClick={() => setPreview(program)}
                  >
                    <Eye className="h-4 w-4" />
                    Preview
                  </Button>
                  {purchased.has(program.id) ? (
                    <span className="badge-primary">Owned</span>
                  ) : (
                    <Button size="sm" onClick={() => handlePurchase(program)}>
                      Buy
                    </Button>
                  )}
                </div>
              </div>
            </div>
          </div>
        ))}
      </div>

      {programs.length === 0 && (
        <div className="card py-16 text-center text-slate-500">
          No programs available yet. Trainers can publish from Trainer Studio.
        </div>
      )}
    </div>
  );
}
