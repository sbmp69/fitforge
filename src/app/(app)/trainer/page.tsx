"use client";

import { useState, useEffect } from "react";
import { Plus, DollarSign, Users, Package, TrendingUp } from "lucide-react";
import { Button } from "@/components/ui/button";
import { formatINR } from "@/lib/utils";
import type { Program } from "@/types/database";

export default function TrainerStudioPage() {
  const [programs, setPrograms] = useState<Program[]>([]);
  const [stats, setStats] = useState({ revenue: 0, sales: 0, followers: 0 });
  const [showForm, setShowForm] = useState(false);
  const [loading, setLoading] = useState(false);

  const [form, setForm] = useState({
    name: "",
    description: "",
    duration_weeks: 4,
    price_inr: 999,
    cover_image_url: "",
  });

  useEffect(() => {
    fetch("/api/trainer")
      .then((r) => r.json())
      .then((d) => {
        setPrograms(d.programs || []);
        setStats(d.stats || { revenue: 0, sales: 0, followers: 0 });
      });
  }, []);

  const createProgram = async () => {
    setLoading(true);
    try {
      const res = await fetch("/api/trainer", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(form),
      });
      const data = await res.json();
      if (data.program) {
        setPrograms((prev) => [data.program, ...prev]);
        setShowForm(false);
        setForm({ name: "", description: "", duration_weeks: 4, price_inr: 999, cover_image_url: "" });
      }
    } finally {
      setLoading(false);
    }
  };

  const togglePublish = async (id: string, publish: boolean) => {
    await fetch("/api/trainer", {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ id, is_published: publish }),
    });
    setPrograms((prev) =>
      prev.map((p) => (p.id === id ? { ...p, is_published: publish } : p))
    );
  };

  return (
    <div className="space-y-8">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-white">Trainer Studio</h1>
          <p className="mt-1 text-slate-400">Create and sell fitness programs</p>
        </div>
        <Button onClick={() => setShowForm(!showForm)}>
          <Plus className="h-4 w-4" />
          New Program
        </Button>
      </div>

      <div className="grid gap-4 md:grid-cols-3">
        <div className="card flex items-center gap-4">
          <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-primary/15">
            <DollarSign className="h-6 w-6 text-primary" />
          </div>
          <div>
            <p className="text-sm text-slate-400">Total Revenue</p>
            <p className="text-2xl font-bold text-white">{formatINR(stats.revenue)}</p>
          </div>
        </div>
        <div className="card flex items-center gap-4">
          <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-blue-500/15">
            <Package className="h-6 w-6 text-blue-400" />
          </div>
          <div>
            <p className="text-sm text-slate-400">Total Sales</p>
            <p className="text-2xl font-bold text-white">{stats.sales}</p>
          </div>
        </div>
        <div className="card flex items-center gap-4">
          <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-purple-500/15">
            <Users className="h-6 w-6 text-purple-400" />
          </div>
          <div>
            <p className="text-sm text-slate-400">Followers</p>
            <p className="text-2xl font-bold text-white">{stats.followers}</p>
          </div>
        </div>
      </div>

      {showForm && (
        <div className="card space-y-4">
          <h2 className="text-lg font-semibold text-white">Create Program</h2>
          <div className="grid gap-4 md:grid-cols-2">
            <div>
              <label className="label">Program Name</label>
              <input
                className="input"
                value={form.name}
                onChange={(e) => setForm({ ...form, name: e.target.value })}
              />
            </div>
            <div>
              <label className="label">Price (INR)</label>
              <input
                type="number"
                className="input"
                value={form.price_inr}
                onChange={(e) => setForm({ ...form, price_inr: Number(e.target.value) })}
              />
            </div>
            <div>
              <label className="label">Duration (weeks)</label>
              <input
                type="number"
                className="input"
                value={form.duration_weeks}
                onChange={(e) => setForm({ ...form, duration_weeks: Number(e.target.value) })}
              />
            </div>
            <div>
              <label className="label">Cover Image URL</label>
              <input
                className="input"
                value={form.cover_image_url}
                onChange={(e) => setForm({ ...form, cover_image_url: e.target.value })}
                placeholder="https://..."
              />
            </div>
          </div>
          <div>
            <label className="label">Description</label>
            <textarea
              className="input min-h-[100px]"
              value={form.description}
              onChange={(e) => setForm({ ...form, description: e.target.value })}
            />
          </div>
          <Button onClick={createProgram} loading={loading}>
            Create Program
          </Button>
        </div>
      )}

      <div className="space-y-4">
        <h2 className="text-lg font-semibold text-white">Your Programs</h2>
        {programs.map((program) => (
          <div key={program.id} className="card flex items-center justify-between">
            <div>
              <div className="flex items-center gap-2">
                <h3 className="font-semibold text-white">{program.name}</h3>
                <span className={program.is_published ? "badge-primary" : "badge bg-slate-700 text-slate-400"}>
                  {program.is_published ? "Published" : "Draft"}
                </span>
              </div>
              <p className="mt-1 text-sm text-slate-400">
                {formatINR(program.price_inr)} · {program.duration_weeks} weeks · {program.purchase_count} sales
              </p>
            </div>
            <div className="flex items-center gap-2">
              <TrendingUp className="h-4 w-4 text-slate-500" />
              <Button
                variant="secondary"
                size="sm"
                onClick={() => togglePublish(program.id, !program.is_published)}
              >
                {program.is_published ? "Unpublish" : "Publish"}
              </Button>
            </div>
          </div>
        ))}
        {programs.length === 0 && (
          <div className="card py-12 text-center text-slate-500">
            No programs yet. Create your first program above.
          </div>
        )}
      </div>
    </div>
  );
}
