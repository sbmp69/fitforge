"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import {
  LayoutDashboard,
  Dumbbell,
  UtensilsCrossed,
  TrendingUp,
  Store,
  Palette,
  Settings,
  MessageCircle,
  LogOut,
  Zap,
} from "lucide-react";
import { cn } from "@/lib/utils";
import { createClient } from "@/lib/supabase/client";
import { useRouter } from "next/navigation";
import type { Profile } from "@/types/database";

const navItems = [
  { href: "/dashboard", label: "Dashboard", icon: LayoutDashboard },
  { href: "/workout", label: "Workout", icon: Dumbbell },
  { href: "/meals", label: "Meals", icon: UtensilsCrossed },
  { href: "/progress", label: "Progress", icon: TrendingUp },
  { href: "/marketplace", label: "Marketplace", icon: Store },
  { href: "/coach", label: "AI Coach", icon: MessageCircle },
];

const trainerItems = [
  { href: "/trainer", label: "Trainer Studio", icon: Palette },
];

interface SidebarProps {
  profile: Profile | null;
}

export function Sidebar({ profile }: SidebarProps) {
  const pathname = usePathname();
  const router = useRouter();
  const supabase = createClient();

  const handleLogout = async () => {
    await supabase.auth.signOut();
    router.push("/");
    router.refresh();
  };

  const isTrainer =
    profile?.role === "trainer" || profile?.subscription_tier === "trainer";

  return (
    <aside className="fixed left-0 top-0 z-40 flex h-screen w-64 flex-col border-r border-slate-700/50 bg-navy-950">
      <div className="flex items-center gap-2 border-b border-slate-700/50 px-6 py-5">
        <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-primary">
          <Zap className="h-5 w-5 text-white" />
        </div>
        <span className="text-xl font-bold text-white">
          Fit<span className="text-primary">Forge</span>
        </span>
      </div>

      <nav className="flex-1 space-y-1 overflow-y-auto px-3 py-4">
        {navItems.map(({ href, label, icon: Icon }) => (
          <Link
            key={href}
            href={href}
            className={cn(
              "flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-medium transition-colors",
              pathname.startsWith(href)
                ? "bg-primary/15 text-primary"
                : "text-slate-400 hover:bg-navy-800 hover:text-slate-200"
            )}
          >
            <Icon className="h-5 w-5" />
            {label}
          </Link>
        ))}

        {isTrainer && (
          <>
            <div className="my-3 border-t border-slate-700/50" />
            {trainerItems.map(({ href, label, icon: Icon }) => (
              <Link
                key={href}
                href={href}
                className={cn(
                  "flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-medium transition-colors",
                  pathname.startsWith(href)
                    ? "bg-primary/15 text-primary"
                    : "text-slate-400 hover:bg-navy-800 hover:text-slate-200"
                )}
              >
                <Icon className="h-5 w-5" />
                {label}
              </Link>
            ))}
          </>
        )}
      </nav>

      <div className="border-t border-slate-700/50 p-3">
        <Link
          href="/settings"
          className={cn(
            "flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-medium transition-colors",
            pathname.startsWith("/settings")
              ? "bg-primary/15 text-primary"
              : "text-slate-400 hover:bg-navy-800 hover:text-slate-200"
          )}
        >
          <Settings className="h-5 w-5" />
          Settings
        </Link>
        <button
          onClick={handleLogout}
          className="flex w-full items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-medium text-slate-400 transition-colors hover:bg-red-500/10 hover:text-red-400"
        >
          <LogOut className="h-5 w-5" />
          Log out
        </button>
      </div>
    </aside>
  );
}
