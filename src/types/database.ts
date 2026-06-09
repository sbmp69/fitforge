export type UserRole = "fitness_user" | "trainer";
export type SubscriptionTier = "free" | "pro" | "trainer";
export type FitnessGoal = "lose_weight" | "build_muscle" | "endurance";
export type FitnessLevel = "beginner" | "intermediate" | "advanced";
export type DietaryPreference = "veg" | "non_veg" | "vegan";

export interface Exercise {
  name: string;
  sets: number;
  reps: string;
  restSeconds: number;
  notes?: string;
}

export interface WorkoutDay {
  day: string;
  focus: string;
  exercises: Exercise[];
  warmup?: string;
  cooldown?: string;
}

export interface WorkoutPlanData {
  days: WorkoutDay[];
  summary?: string;
}

export interface MealItem {
  name: string;
  calories: number;
  protein: number;
  carbs: number;
  fat: number;
  ingredients?: string[];
}

export interface DayMeals {
  day: string;
  breakfast: MealItem;
  lunch: MealItem;
  dinner: MealItem;
  snacks: MealItem[];
}

export interface MealPlanData {
  days: DayMeals[];
  dailyCalorieTarget: number;
  summary?: string;
}

export interface GroceryItem {
  item: string;
  quantity: string;
  category: string;
}

export interface Profile {
  id: string;
  email: string;
  full_name: string | null;
  avatar_url: string | null;
  role: UserRole;
  subscription_tier: SubscriptionTier;
  ai_plans_used_this_month: number;
  follower_count: number;
  bio: string | null;
  created_at: string;
}

export interface WorkoutPlan {
  id: string;
  user_id: string;
  title: string;
  goal: FitnessGoal;
  level: FitnessLevel;
  days_per_week: number;
  equipment: string[];
  plan_data: WorkoutPlanData;
  is_active: boolean;
  created_at: string;
}

export interface MealPlan {
  id: string;
  user_id: string;
  title: string;
  calorie_target: number;
  dietary_preference: DietaryPreference;
  allergies: string[];
  plan_data: MealPlanData;
  grocery_list: GroceryItem[];
  is_active: boolean;
  created_at: string;
}

export interface ProgressLog {
  id: string;
  user_id: string;
  log_date: string;
  weight_kg: number | null;
  workout_completed: boolean;
  water_ml: number;
  sleep_hours: number | null;
  notes: string | null;
}

export interface Program {
  id: string;
  trainer_id: string;
  name: string;
  description: string;
  duration_weeks: number;
  price_inr: number;
  cover_image_url: string | null;
  workout_plan_data: WorkoutPlanData;
  meal_plan_data: MealPlanData;
  pdf_resources: { name: string; url: string }[];
  preview_week_data: WorkoutPlanData;
  is_published: boolean;
  purchase_count: number;
  avg_rating: number;
  review_count: number;
  created_at: string;
  profiles?: Profile;
}

export interface ProgramReview {
  id: string;
  program_id: string;
  user_id: string;
  rating: number;
  review_text: string | null;
  created_at: string;
  profiles?: Profile;
}

export interface ChatMessage {
  id: string;
  role: "user" | "assistant";
  content: string;
  created_at: string;
}
