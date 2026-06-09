import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

export function formatINR(amount: number): string {
  return new Intl.NumberFormat("en-IN", {
    style: "currency",
    currency: "INR",
    maximumFractionDigits: 0,
  }).format(amount);
}

export function formatDate(date: string | Date): string {
  return new Intl.DateTimeFormat("en-IN", {
    day: "numeric",
    month: "short",
    year: "numeric",
  }).format(new Date(date));
}

export const GOAL_LABELS: Record<string, string> = {
  lose_weight: "Lose Weight",
  build_muscle: "Build Muscle",
  endurance: "Endurance",
};

export const LEVEL_LABELS: Record<string, string> = {
  beginner: "Beginner",
  intermediate: "Intermediate",
  advanced: "Advanced",
};

export const DIET_LABELS: Record<string, string> = {
  veg: "Vegetarian",
  non_veg: "Non-Vegetarian",
  vegan: "Vegan",
};

export const TIER_LABELS: Record<string, string> = {
  free: "Free",
  pro: "Pro",
  trainer: "Trainer",
};

export const AI_PLAN_LIMITS: Record<string, number> = {
  free: 3,
  pro: Infinity,
  trainer: Infinity,
};
