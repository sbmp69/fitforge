"use client";

import { motion } from "framer-motion";
import { Flame } from "lucide-react";
import { cn } from "@/lib/utils";

interface StreakFireProps {
  streak: number;
  className?: string;
}

export function StreakFire({ streak, className }: StreakFireProps) {
  const intensity = Math.min(streak / 30, 1);

  return (
    <div className={cn("flex items-center gap-2", className)}>
      <motion.div
        animate={{ scale: [1, 1.15, 1] }}
        transition={{ repeat: Infinity, duration: 1.5, ease: "easeInOut" }}
      >
        <Flame
          className="h-8 w-8"
          style={{
            color: `hsl(${30 - intensity * 10}, 100%, ${50 + intensity * 10}%)`,
          }}
          fill="currentColor"
        />
      </motion.div>
      <div>
        <p className="text-2xl font-bold text-white">{streak}</p>
        <p className="text-xs text-slate-400">day streak</p>
      </div>
    </div>
  );
}
