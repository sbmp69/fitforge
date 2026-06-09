import Razorpay from "razorpay";

export function getRazorpayInstance() {
  return new Razorpay({
    key_id: process.env.RAZORPAY_KEY_ID!,
    key_secret: process.env.RAZORPAY_KEY_SECRET!,
  });
}

export const SUBSCRIPTION_PLANS = {
  pro: {
    plan_id: process.env.RAZORPAY_PRO_PLAN_ID || "plan_pro",
    amount: 29900,
    name: "FitForge Pro",
    description: "Unlimited AI plans, no ads, progress analytics",
  },
  trainer: {
    plan_id: process.env.RAZORPAY_TRAINER_PLAN_ID || "plan_trainer",
    amount: 79900,
    name: "FitForge Trainer",
    description: "Create & sell programs, analytics dashboard",
  },
};

export const MARKETPLACE_COMMISSION = 0.2;

export function calculateSplit(amountInr: number) {
  const commission = Math.round(amountInr * MARKETPLACE_COMMISSION);
  const trainerAmount = amountInr - commission;
  return { commission, trainerAmount };
}
