"use client";

import { useState, useEffect } from "react";
import { ShoppingCart, RefreshCw } from "lucide-react";
import { Button } from "@/components/ui/button";
import { DIET_LABELS } from "@/lib/utils";
import type { MealPlan, DietaryPreference, GroceryItem } from "@/types/database";

export default function MealsPage() {
  const [plan, setPlan] = useState<MealPlan | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [showForm, setShowForm] = useState(false);
  const [showGrocery, setShowGrocery] = useState(false);
  const [activeDay, setActiveDay] = useState(0);

  const [calorieTarget, setCalorieTarget] = useState(2000);
  const [dietaryPreference, setDietaryPreference] = useState<DietaryPreference>("non_veg");
  const [allergies, setAllergies] = useState("");

  useEffect(() => {
    fetch("/api/meals/active")
      .then((r) => r.json())
      .then((d) => d.plan && setPlan(d.plan))
      .catch(() => {});
  }, []);

  const generatePlan = async () => {
    setLoading(true);
    setError("");

    try {
      const res = await fetch("/api/ai/meals", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          calorieTarget,
          dietaryPreference,
          allergies: allergies.split(",").map((a) => a.trim()).filter(Boolean),
        }),
      });

      const data = await res.json();
      if (!res.ok) throw new Error(data.error);
      setPlan(data.plan);
      setShowForm(false);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Generation failed");
    } finally {
      setLoading(false);
    }
  };

  const substituteMeal = async (meal: object, mealType: string) => {
    setLoading(true);
    try {
      const res = await fetch("/api/ai/meals", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          dietaryPreference,
          allergies: allergies.split(",").map((a) => a.trim()).filter(Boolean),
          substituteMeal: { meal, mealType },
        }),
      });
      const data = await res.json();
      if (res.ok && data.meal) {
        alert(`Alternative: ${data.meal.name} (${data.meal.calories} kcal)`);
      }
    } finally {
      setLoading(false);
    }
  };

  const days = plan?.plan_data?.days || [];
  const day = days[activeDay];
  const grocery: GroceryItem[] = plan?.grocery_list || [];

  const MacroBar = ({ label, value, color }: { label: string; value: number; color: string }) => (
    <div className="text-center">
      <p className={`text-lg font-bold ${color}`}>{value}g</p>
      <p className="text-xs text-slate-500">{label}</p>
    </div>
  );

  const MealCard = ({
    title,
    meal,
    mealType,
  }: {
    title: string;
    meal: { name: string; calories: number; protein: number; carbs: number; fat: number };
    mealType: string;
  }) => (
    <div className="rounded-xl bg-navy-700/50 p-4">
      <div className="mb-2 flex items-center justify-between">
        <h4 className="text-sm font-medium text-slate-400">{title}</h4>
        <button
          onClick={() => substituteMeal(meal, mealType)}
          className="text-xs text-primary hover:underline"
        >
          <RefreshCw className="inline h-3 w-3" /> Swap
        </button>
      </div>
      <p className="font-medium text-white">{meal.name}</p>
      <p className="mt-1 text-sm text-amber-400">{meal.calories} kcal</p>
      <div className="mt-3 flex justify-between">
        <MacroBar label="Protein" value={meal.protein} color="text-red-400" />
        <MacroBar label="Carbs" value={meal.carbs} color="text-blue-400" />
        <MacroBar label="Fat" value={meal.fat} color="text-yellow-400" />
      </div>
    </div>
  );

  return (
    <div className="space-y-8">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-white">Meal Planner</h1>
          <p className="mt-1 text-slate-400">AI-powered nutrition with macro tracking</p>
        </div>
        <div className="flex gap-2">
          {plan && (
            <Button variant="secondary" onClick={() => setShowGrocery(!showGrocery)}>
              <ShoppingCart className="h-4 w-4" />
              Grocery List
            </Button>
          )}
          <Button variant="secondary" onClick={() => setShowForm(!showForm)}>
            {plan ? "New Plan" : "Generate Plan"}
          </Button>
        </div>
      </div>

      {error && (
        <div className="rounded-xl bg-red-500/10 px-4 py-3 text-sm text-red-400">{error}</div>
      )}

      {showForm && (
        <div className="card space-y-5">
          <h2 className="text-lg font-semibold text-white">Nutrition Preferences</h2>
          <div className="grid gap-5 md:grid-cols-2">
            <div>
              <label className="label">Daily Calorie Target: {calorieTarget}</label>
              <input
                type="range"
                min={1200}
                max={4000}
                step={100}
                value={calorieTarget}
                onChange={(e) => setCalorieTarget(Number(e.target.value))}
                className="w-full accent-primary"
              />
            </div>
            <div>
              <label className="label">Dietary Preference</label>
              <select
                className="input"
                value={dietaryPreference}
                onChange={(e) => setDietaryPreference(e.target.value as DietaryPreference)}
              >
                {Object.entries(DIET_LABELS).map(([k, v]) => (
                  <option key={k} value={k}>{v}</option>
                ))}
              </select>
            </div>
          </div>
          <div>
            <label className="label">Allergies (comma-separated)</label>
            <input
              className="input"
              placeholder="e.g. peanuts, shellfish, gluten"
              value={allergies}
              onChange={(e) => setAllergies(e.target.value)}
            />
          </div>
          <Button onClick={generatePlan} loading={loading}>
            Generate Meal Plan
          </Button>
        </div>
      )}

      {showGrocery && grocery.length > 0 && (
        <div className="card">
          <h3 className="mb-4 font-semibold text-white">Grocery List</h3>
          <div className="grid gap-2 sm:grid-cols-2 lg:grid-cols-3">
            {grocery.map((item, i) => (
              <div key={i} className="flex items-center justify-between rounded-lg bg-navy-700/50 px-3 py-2">
                <span className="text-sm text-white">{item.item}</span>
                <span className="text-xs text-slate-400">{item.quantity}</span>
              </div>
            ))}
          </div>
        </div>
      )}

      {plan && day && (
        <div>
          <div className="mb-4 flex gap-2 overflow-x-auto pb-2">
            {days.map((d, i) => (
              <button
                key={d.day}
                onClick={() => setActiveDay(i)}
                className={`shrink-0 rounded-xl px-4 py-2 text-sm font-medium transition-colors ${
                  activeDay === i
                    ? "bg-primary text-white"
                    : "bg-navy-800 text-slate-400 hover:bg-navy-700"
                }`}
              >
                {d.day}
              </button>
            ))}
          </div>
          <div className="grid gap-4 md:grid-cols-2">
            <MealCard title="Breakfast" meal={day.breakfast} mealType="breakfast" />
            <MealCard title="Lunch" meal={day.lunch} mealType="lunch" />
            <MealCard title="Dinner" meal={day.dinner} mealType="dinner" />
            {day.snacks?.map((snack, i) => (
              <MealCard key={i} title={`Snack ${i + 1}`} meal={snack} mealType="snack" />
            ))}
          </div>
        </div>
      )}

      {!plan && !showForm && (
        <div className="card flex flex-col items-center justify-center py-16 text-center">
          <p className="text-slate-400">No meal plan yet</p>
          <Button className="mt-4" onClick={() => setShowForm(true)}>
            Generate Your First Plan
          </Button>
        </div>
      )}
    </div>
  );
}
